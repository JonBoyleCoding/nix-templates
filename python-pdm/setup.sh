#!/usr/bin/env bash
echo "=== PDM Project Setup ==="

# Stage files so nix can see them (nix reads only git-tracked files)
stage_for_nix() {
	git rev-parse --is-inside-work-tree &>/dev/null || return 0
	for f in "$@"; do
		[[ -f "$f" ]] && git add "$f"
	done
}

# Initialize pyproject.toml if it doesn't exist
if [[ -f "pyproject.toml" ]]; then
	echo "pyproject.toml already exists. Skipping pdm init."
else
	echo "Running pdm init..."
	if ! nix develop .#no-package --command pdm init; then
		echo "Error: nix failed to build the no-package dev shell (pdm). Aborting setup." >&2
		exit 1
	fi
	if [[ ! -f "pyproject.toml" ]]; then
		echo "Error: pdm init did not create pyproject.toml. Aborting setup." >&2
		exit 1
	fi
fi

# Stage flake files before the lock step (pdm init creates a git repo, leaving them untracked)
stage_for_nix flake.nix flake.lock ruff.toml pyproject.toml .gitignore

# Generate lock file via dream2nix
if [[ -f "pyproject.toml" ]]; then
	echo "Generating pdm.lock via nix..."
	if ! nix run .#default.lock; then
		echo "Error: 'nix run .#default.lock' failed to generate pdm.lock. Aborting setup." >&2
		exit 1
	fi
fi

# Stage the generated lock
stage_for_nix pdm.lock

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
