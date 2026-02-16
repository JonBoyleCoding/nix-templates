#!/usr/bin/env bash
echo "=== OCaml Project Setup ==="

# Initialize dune project if dune-project doesn't exist
if [[ -f "dune-project" ]]; then
	echo "dune-project already exists. Skipping dune init."
else
	echo "Running dune init project..."
	nix develop .#no-package --command bash -c 'dune init project myproject . && dune build'
fi

# Add template and project files to git so nix can see them
if [[ -d ".git" ]]; then
	echo "Adding files to git..."
	git add flake.nix .ocamlformat .claude/
	git add dune-project *.opam bin/ lib/ test/ 2>/dev/null || true
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
