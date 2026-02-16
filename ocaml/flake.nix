{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";

		opam-nix.url = "github:tweag/opam-nix";
		opam-nix.inputs.nixpkgs.follows = "nixpkgs";

		nix-precommit-hooks.url = "github:cachix/pre-commit-hooks.nix";
	};

	outputs = {
		self,
		nixpkgs,
		flake-utils,
		opam-nix,
		nix-precommit-hooks,
		...
	}: let
		supportedSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

		# TODO: Replace with your package name (must match the (name ...) in dune-project)
		package = "myproject";
	in
		flake-utils.lib.eachSystem supportedSystems (system: let
				pkgs =
					import nixpkgs {
						config.allowUnfree = true;
						inherit system;
					};
				inherit (pkgs) lib;

				on = opam-nix.lib.${system};

				devPackagesQuery = {
					ocaml-lsp-server = "*";
					ocamlformat = "*";
					utop = "*";
					odoc = "*";
					opam-dune-lint = "*";
				};

				query = devPackagesQuery // {
					ocaml-base-compiler = "*";
				};

				# Build all local packages discovered from .opam files
				scope = on.buildOpamProject' {} ./. query;

				overlay = final: prev: {
					${package} = prev.${package}.overrideAttrs (_: {
						doNixSupport = false;
					});
				};

				scope' = scope.overrideScope overlay;

				# The main package
				main = scope'.${package};

				devPackages = builtins.attrValues (
					lib.getAttrs (builtins.attrNames devPackagesQuery) scope'
				);

				pre-commit-check =
					nix-precommit-hooks.lib.${system}.run {
						src = ./.;
						hooks = {
							dune-fmt.enable = true;
							dune-opam-sync.enable = true;
							opam-lint.enable = true;
							statix.enable = true;
						};
					};

				claude-post-commit-hook = pkgs.writeShellScriptBin "claude-post-commit-check" ''
					file_path=$(${pkgs.jq}/bin/jq -r '.tool_input.file_path // empty')
					if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
						exit 0
					fi

					# Only check OCaml files
					if [[ ! "$file_path" =~ \.(ml|mli)$ ]]; then
						exit 0
					fi

					# Auto-format with ocamlformat
					${pkgs.ocamlPackages.ocamlformat}/bin/ocamlformat --inplace "$file_path" >&2 || exit 2

					# Run dune build for type checking if dune-project exists
					if [[ -f "dune-project" ]]; then
						dune build >&2 || exit 2
					fi
				'';
			in {
				legacyPackages = scope';

				packages.default = main;

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
						inputsFrom = [main];
						buildInputs = devPackages ++ [claude-post-commit-hook];
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
						buildInputs = with pkgs.ocamlPackages;
							[
								ocaml
								dune_3
								ocamlformat
							]
							++ [claude-post-commit-hook];
					};
			});
}
