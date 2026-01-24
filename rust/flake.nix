{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		flake-parts.url = "github:hercules-ci/flake-parts";
		systems.url = "github:nix-systems/default";

		treefmt-nix.url = "github:numtide/treefmt-nix";
		nix-precommit-hooks.url = "github:cachix/pre-commit-hooks.nix";

		fenix = {
			url = "github:nix-community/fenix";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		crane = {
			url = "github:ipetkov/crane";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs:
		inputs.flake-parts.lib.mkFlake {inherit inputs;} {
			systems = import inputs.systems;
			imports = [
				inputs.treefmt-nix.flakeModule
				inputs.nix-precommit-hooks.flakeModule
			];
			perSystem = {
				config,
				self',
				pkgs,
				lib,
				system,
				...
			}: let
				cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);

				fnx = inputs.fenix.packages.${system};

				rust-toolchain = with fnx;
					combine [
						stable.rustc
						stable.cargo
						stable.rust-src
						stable.rust-analyzer
						stable.clippy
						default.rustfmt
					];

				crn = (inputs.crane.mkLib pkgs).overrideToolchain rust-toolchain;

				cargoArtifacts = crn.buildDepsOnly {
					src = ./.;
					pname = cargoToml.package.name;
					strictDeps = true;
				};

				package = crn.buildPackage rec {
					inherit (cargoToml.package) name version;
					pname = cargoToml.package.name;
					src = ./.;
					inherit cargoArtifacts;
					doCheck = false;
				};

				claude-post-commit-hook = pkgs.writeShellScriptBin "claude-post-commit-check" ''
					file_path=$(${pkgs.jq}/bin/jq -r '.tool_input.file_path // empty')
					if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
						exit 0
					fi

					# Only check Rust files
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
				packages.default = package;

				pre-commit.settings = {
					hooks = {
						rustfmt = {
							enable = true;
							packageOverrides = {
								rustfmt = fnx.default.rustfmt;
								cargo = fnx.default.cargo;
							};
						};
						alejandra.enable = true;
					};
				};

				devShells = {
					default = crn.devShell {
						inputsFrom = [
							config.treefmt.build.devShell
						];
						shellHook = ''
							${config.pre-commit.installationScript}
							if [ -f .env ]; then
								set -a
								source .env
								set +a
							fi
						'';

						buildInputs = [
							claude-post-commit-hook
						];

						RUST_BACKTRACE = 1;
						RUST_SRC_PATH = "${fnx.stable.rust-src}/lib/rustlib/src/rust/library/";
					};

					no-package = pkgs.mkShell {
						buildInputs = [rust-toolchain];
					};
				};

				treefmt.config = {
					projectRootFile = "flake.nix";
					programs = {
						alejandra.enable = true;
						rustfmt.enable = true;
					};
				};
			};
		};
}
