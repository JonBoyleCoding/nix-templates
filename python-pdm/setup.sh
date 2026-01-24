#!/usr/bin/env bash
echo "=== PDM Project Setup ==="

# Initialize pyproject.toml if it doesn't exist
if [[ -f "pyproject.toml" ]]; then
	echo "pyproject.toml already exists. Skipping pdm init."
else
	echo "Running pdm init..."
	nix develop .#no-package --command pdm init
fi

# Generate lock file via dream2nix
if [[ -f "pyproject.toml" ]]; then
	echo "Generating pdm.lock via nix..."
	nix run .#default.lock
fi

# Create .envrc if it doesn't exist
if [[ ! -f ".envrc" ]]; then
	echo "Creating .envrc..."
	echo "use flake" >.envrc
else
	echo ".envrc already exists."
fi

# Allow direnv
if command -v direnv &>/dev/null; then
	echo "Allowing direnv..."
	direnv allow
else
	echo "direnv not found. Run 'direnv allow' manually after installing direnv."
fi

echo "=== Setup complete! ==="
