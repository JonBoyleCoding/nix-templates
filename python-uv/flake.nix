{
  description = "Python development environment with uv/pip and virtual environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  in
    flake-utils.lib.eachSystem supportedSystems (
      system: let
        pkgs = import nixpkgs {
          config.allowUnfree = true;
          inherit system;
        };

        # Specify Python version here
        python-interp = pkgs.python312;

        # Claude Code post-commit hook script
        claude-post-commit-hook = pkgs.writeShellScriptBin "claude-post-commit-check" ''
          # Only process Python files
          if [[ "$CLAUDE_MODIFIED_PATH" =~ \.py$ ]]; then
            echo "Linting $CLAUDE_MODIFIED_PATH..." >&2

            # Run ruff if available in venv or system
            if command -v ruff &> /dev/null; then
              ruff check "$CLAUDE_MODIFIED_PATH" 2>&1 >&2 || true
            fi

            # Run mypy if available in venv or system
            if command -v mypy &> /dev/null; then
              mypy "$CLAUDE_MODIFIED_PATH" 2>&1 >&2 || true
            fi
          fi
        '';
      in {
        devShells.default = pkgs.mkShell {
          inherit system;

          buildInputs = with pkgs; [
            python-interp
            uv
            direnv
            claude-post-commit-hook
          ];

          shellHook = ''
            # Source .env file if it exists
            if [ -f .env ]; then
              set -a
              source .env
              set +a
            fi

            # Set up virtual environment
            VENV_DIR=".venv"

            if [ ! -d "$VENV_DIR" ]; then
              echo "Creating virtual environment..."
              ${python-interp}/bin/python -m venv "$VENV_DIR"
            fi

            # Activate virtual environment
            source "$VENV_DIR/bin/activate"

            # Install uv in venv if not present
            if ! command -v uv &> /dev/null; then
              echo "Installing uv in virtual environment..."
              pip install uv
            fi

            echo "Python $(python --version) environment ready!"
            echo "Virtual environment: $VENV_DIR"
            echo ""
            echo "Quick start:"
            echo "  uv pip install <package>     # Fast package installation with uv"
            echo "  pip install <package>        # Standard pip installation"
            echo "  uv pip install -r requirements.txt  # Install from requirements.txt"
            echo "  uv pip install -e .          # Install project in editable mode"
          '';
        };
      }
    );
}
