{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";

		dream2nix.url = "github:nix-community/dream2nix";
		dream2nix.inputs.nixpkgs.follows = "nixpkgs";

		nix-precommit-hooks.url = "github:cachix/pre-commit-hooks.nix";
	};

	outputs = {
		self,
		nixpkgs,
		flake-utils,
		dream2nix,
		nix-precommit-hooks,
		...
	}: let
		supportedSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
	in
		flake-utils.lib.eachSystem supportedSystems (system: let
				# import nixpkgs
				pkgs =
					import nixpkgs {
						config.allowUnfree = true;
						inherit system;
					};
				inherit (pkgs) lib;

				# python interpreter to use
				python-interp = pkgs.python312;
				python-interp-pkgs = python-interp.pkgs;

				# Check if project files exist for conditional evaluation
				hasPyproject = builtins.pathExists ./pyproject.toml;
				hasLockfile = builtins.pathExists ./pdm.lock;

				# dream2nix
				module = {
					config,
					lib,
					dream2nix,
					...
				}: {
					imports = [dream2nix.modules.dream2nix.WIP-python-pdm];

					pdm.lockfile = ./pdm.lock;
					pdm.pyproject = ./pyproject.toml;

					deps = _: {
						python = python-interp;
					};

					mkDerivation = {
						src = ./.;
						buildInputs = [
							python-interp.pkgs.pdm-backend
							python-interp.pkgs.editables
						];
					};

					buildPythonPackage = {
						format = lib.mkForce "pyproject";
					};
				};

				# dream2nix eval
				evaled =
					dream2nix.lib.evalModules {
						packageSets.nixpkgs = pkgs;
						modules = [
							module
							{
								paths = {
									projectRoot = ./.;
									package = ./.;
									projectRootFile = "flake.nix";
								};
							}
						];
						specialArgs = {
							inherit dream2nix;
						};
					};

				package = evaled.config.public;

				# Extract dev dependencies from dream2nix package dynamically
				devPackages = let
					devGroup = package.config.groups.dev.packages or {};
					# Extract the actual built package from each versioned entry
					extractPackage = name: versions: let
						versionsList = builtins.attrValues versions;
						firstVersion =
							if builtins.length versionsList > 0
							then builtins.head versionsList
							else null;
						# Try to get the actual package derivation
						actualPackage =
							if firstVersion != null && firstVersion ? public
							then firstVersion.public
							else if firstVersion != null && firstVersion ? package
							then firstVersion.package
							else firstVersion;
					in
						actualPackage;
					# Get all packages and filter out nulls
					allPackages = builtins.attrValues (builtins.mapAttrs extractPackage devGroup);
					validPackages =
						builtins.filter (
							pkg:
								pkg != null && (lib.isDerivation pkg || (builtins.isAttrs pkg && pkg ? outPath))
						)
						allPackages;
				in
					validPackages;

				# Extract mypy from dev group (has access to project dependencies)
				devMypy =
					if hasPyproject && hasLockfile
					then let
						mypyVersions = package.config.groups.dev.packages.mypy or {};
						versionsList = builtins.attrValues mypyVersions;
						firstVersion =
							if builtins.length versionsList > 0
							then builtins.head versionsList
							else null;
					in
						if firstVersion != null && firstVersion ? public
						then firstVersion.public
						else python-interp-pkgs.mypy
					else python-interp-pkgs.mypy;

				pre-commit-check =
					nix-precommit-hooks.lib.${system}.run {
						src = ./.;
						hooks = {
							ruff.enable = true;
							mypy = {
								enable = true;
								settings.binPath = "${devMypy}/bin/mypy";
							};
							statix.enable = true;
						};
					};

			in {
				packages = {
					default = package;
				};

				devShells.default =
					pkgs.mkShell {
						inherit system;
						shellHook = ''
							${pre-commit-check.shellHook}
							if [ -f .env ]; then
								set -a
								source .env
								set +a
							fi
						'';
						inputsFrom = [self.packages.${system}.default.devShell];

						buildInputs = with pkgs; [ruff python-interp-pkgs.mypy] ++ devPackages;
					};

				devShells.no-package =
					pkgs.mkShell {
						inherit system;
						shellHook = ''
							${pre-commit-check.shellHook}
							if [ -f .env ]; then
								set -a
								source .env
								set +a
							fi
						'';

						buildInputs = with pkgs; [python-interp pdm];
					};
			});
}
