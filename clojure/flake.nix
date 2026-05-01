{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = {
		self,
		nixpkgs,
		flake-utils,
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
