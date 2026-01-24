{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";

		fenix = {
			url = "github:nix-community/fenix";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		nix-precommit-hooks.url = "github:cachix/pre-commit-hooks.nix";
	};

	outputs = {
		self,
		nixpkgs,
		flake-utils,
		fenix,
		nix-precommit-hooks,
		...
	}: let
		supportedSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
	in
		flake-utils.lib.eachSystem supportedSystems (system: let
				pkgs = import nixpkgs {
					inherit system;
					overlays = [fenix.overlays.default];
				};

				# Rust toolchain - latest stable with all components
				rust-toolchain = pkgs.fenix.stable.withComponents [
					"rustc"
					"cargo"
					"rust-src"
					"rust-analyzer"
					"clippy"
					"rustfmt"
				];

				pre-commit-check =
					nix-precommit-hooks.lib.${system}.run {
						src = ./.;
						hooks = {
							rustfmt.enable = true;
							clippy.enable = true;
							alejandra.enable = true;
						};
					};

				claude-post-commit-hook = pkgs.writeShellScriptBin "claude-post-commit-check" ''
					file_path=$(${pkgs.jq}/bin/jq -r '.tool_input.file_path // empty')
					if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
						exit 0
					fi

					# Only check Rust files (skip for non-Rust files)
					if [[ ! "$file_path" =~ \.rs$ ]]; then
						exit 0
					fi

					# Run rustfmt check
					${rust-toolchain}/bin/rustfmt --check "$file_path" >&2 || exit 2

					# Run clippy if Cargo.toml exists
					if [[ -f "Cargo.toml" ]]; then
						${rust-toolchain}/bin/cargo clippy --quiet -- -D warnings >&2 || exit 2
					fi
				'';
			in {
				devShells.default = pkgs.mkShell {
					inherit system;
					shellHook = ''
						${pre-commit-check.shellHook}
						if [ -f .env ]; then
							set -a
							source .env
							set +a
						fi
					'';

					buildInputs = [
						rust-toolchain
						claude-post-commit-hook
						pkgs.alejandra
					];
				};

				devShells.no-package = pkgs.mkShell {
					inherit system;
					shellHook = ''
						if [ -f .env ]; then
							set -a
							source .env
							set +a
						fi
					'';

					buildInputs = [
						rust-toolchain
					];
				};
			});
}
