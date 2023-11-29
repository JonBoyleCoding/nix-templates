{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = {self, nixpkgs, flake-utils, dream2nix, ...} :
		let
			supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
		in
		flake-utils.lib.eachSystem supportedSystems (system:
			let
				# import nixpkgs
				pkgs = import nixpkgs { config.allowUnfree = true; inherit system; };
				lib = pkgs.lib;

				# python interpreter to use
				python-interp = pkgs.python311;

				# python packages to use
				python-with-pkgs = python-interp.withPackages (ps: with ps; [
					typer
					rich
					tqdm
				]);
			in
			{
				devShells.default = pkgs.mkShell {
					inherit system;
					buildInputs = with pkgs; [ python-with-pkgs ];
				};
			});
}
