{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";

		dream2nix.url = "github:nix-community/dream2nix";
		dream2nix.inputs.nixpkgs.follows = "nixpkgs";

		nix-precommit-hooks.url = "github:cachix/pre-commit-hooks.nix";
	};

	outputs = {self, nixpkgs, flake-utils, dream2nix, nix-precommit-hooks, ...} :
		let
			supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
		in
		flake-utils.lib.eachSystem supportedSystems (system:
			let
				# import nixpkgs
				pkgs = import nixpkgs { config.allowUnfree = true; inherit system; };
				inherit (pkgs) lib;

				# python interpreter to use
				python-interp = pkgs.python311;
				python-interp-pkgs = python-interp.pkgs;

				# dream2nix
				module = {config, lib, dream2nix, ...}: {
					imports = [ dream2nix.modules.dream2nix.WIP-python-pdm ];

					pdm.lockfile = ./pdm.lock;
					pdm.pyproject = ./pyproject.toml;

					deps = _ : {
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
				evaled = dream2nix.lib.evalModules {
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

				pre-commit-check = nix-precommit-hooks.lib.${system}.run {
					src = ./.;
					hooks = {
						ruff.enable = true;
						statix.enable = true;
					};
				};
			in
			{
				packages = {
					default = package;
				};

				devShells.default = pkgs.mkShell {
					inherit system;
					inherit (pre-commit-check) shellHook;
					inputsFrom = [self.packages.${system}.default.devShell];

					buildInputs = with pkgs; [  ];
				};

				devShells.no-package = pkgs.mkShell {
					inherit system;
					inherit (pre-commit-check) shellHook;

					buildInputs = with pkgs; [ python-interp pdm ];
				};
			});
}
