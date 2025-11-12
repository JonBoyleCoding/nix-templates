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

				# python interpreter to use
				python-interp = pkgs.python312;

				# python packages to use
				python-with-pkgs =
					python-interp.withPackages (ps:
							with ps; [
								typer
								rich
								tqdm
							]);

				claude-pre-commit-hook = pkgs.writeShellScriptBin "claude-pre-commit-check" ''
					file_path=$(${pkgs.jq}/bin/jq -r '.tool_input.file_path // empty')
					if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
						exit 0
					fi

					# Run pre-commit on the specific file
					${pkgs.pre-commit}/bin/pre-commit run --files "$file_path" 2>&1 || exit 2
				'';
			in {
				devShells.default =
					pkgs.mkShell {
						inherit system;
						buildInputs = with pkgs; [python-with-pkgs claude-pre-commit-hook];
					};
			});
}
