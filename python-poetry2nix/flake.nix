{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		poetry2nix.url = "github:nix-community/poetry2nix";
		poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = {self, nixpkgs, flake-utils, poetry2nix, ...} :
		let
			supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
		in
		flake-utils.lib.eachSystem supportedSystems (system:
			let
				# import nixpkgs
				pkgs = import nixpkgs { config.allowUnfree = true; inherit system; };
				p2n = import poetry2nix { pkgs = pkgs; };
				lib = pkgs.lib;

				# python interpreter to use
				python-interp = pkgs.python311;

				poetry-env = p2n.mkPoetryEnv {
					python = python-interp;
					projectDir = ./.;
					preferWheels = true;
				};

				poetry-app = p2n.mkPoetryApplication {
					python = python-interp;
					projectDir = ./.;
					preferWheels = true;
				};
			in
			{
				packages = {
					myapp = poetry-app;
					default = self.packages.${system}.myapp;
				};

				devShells.default = pkgs.mkShell {
					inherit system;
					buildInputs = with pkgs; [ poetry ] ++ [ poetry-env ];
				};
			});
}
