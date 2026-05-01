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

				claude-post-commit-hook =
					pkgs.writeShellScriptBin "claude-post-commit-check" ''
						file_path=$(${pkgs.jq}/bin/jq -r '.tool_input.file_path // empty')
						if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
							exit 0
						fi

						# Only check Python files (skip for non-Python files)
						if [[ ! "$file_path" =~ \.py$ ]]; then
							exit 0
						fi

						# Run check-only commands (no auto-fixing) using same versions as pre-commit
						# Redirect output to stderr so Claude Code can display errors properly
						# Check the file AFTER it was written - much simpler than pre-hook!
						${pkgs.ruff}/bin/ruff check "$file_path" >&2 || exit 2
						${python-interp.pkgs.mypy}/bin/mypy "$file_path" >&2 || exit 2
					'';
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
						buildInputs = with pkgs; [python-with-pkgs claude-post-commit-hook];
					};
			});
}
