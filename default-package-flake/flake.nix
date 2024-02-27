{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";

	};

	outputs = {self, nixpkgs, flake-utils, ...}:
		flake-utils.lib.eachDefaultSystem (system:
			let
				pkgs = import nixpkgs {
					system = system;
				};

				default_package = pkgs.callPackage ./default.nix { };

			in {
				packages.default = default_package;
			});

}
