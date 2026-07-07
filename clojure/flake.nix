{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";

		clj-nix.url = "github:jlesquembre/clj-nix";
		clj-nix.inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = {
		self,
		nixpkgs,
		flake-utils,
		clj-nix,
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
				lib = pkgs.lib;

				jdk-version = pkgs.jdk25;
			in {
				# Uberjar package via clj-nix. Requires a deps-lock.json:
				#   nix run github:jlesquembre/clj-nix#deps-lock
				# Regenerate that lock whenever deps.edn dependencies change.
				# jdk pins the runtime JDK to match the dev shell; omit it and clj-nix
				# defaults to jdk21. Set nativeImage.enable = true for a GraalVM binary.
				# packages.default = clj-nix.lib.mkCljApp {
				# 	inherit pkgs;
				# 	modules = [
				# 		{
				# 			projectSrc = ./.;
				# 			name = "<project>/<project>";
				# 			main-ns = "<project>.<project>";
				# 			jdk = jdk-version;
				# 			# Run build.clj instead of clj-nix's builder, for asset/codegen builds
				# 			# buildCommand = "clojure -T:build ci";
				# 		}
				# 	];
				# };

				devShells.default =
					pkgs.mkShell {
						inherit system;
						shellHook = ''
							if [ -f .env ]; then
								set -a
								source .env
								set +a
							fi
						'';
						buildInputs = with pkgs; [clojure clojure-lsp] ++ [jdk-version];
					};
			});
}
