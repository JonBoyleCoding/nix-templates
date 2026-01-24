#!/usr/bin/env bash
echo "=== Rust Project Setup ==="

# Initialize Cargo.toml if it doesn't exist
if [[ -f "Cargo.toml" ]]; then
	echo "Cargo.toml already exists. Skipping cargo init."
else
	echo "Running cargo init..."
	nix develop .#no-package --command cargo init
fi

# Add flake files to git so nix can see them
if [[ -d ".git" ]]; then
	echo "Adding flake files to git..."
	git add flake.nix rustfmt.toml .claude/
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
