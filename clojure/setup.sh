#!/usr/bin/env bash
echo "=== Clojure Project Setup ==="

mode="$1"
name_arg="$2"

# Resolve layout mode: flag or interactive
if [[ "$mode" != "project" && "$mode" != "flat" ]]; then
	echo "Select project layout:"
	echo "  1) flat    - single scratch.clj in current dir, REPL-driven"
	echo "  2) project - full src/test tree via deps-new"
	read -rp "Choice [1]: " choice
	case "$choice" in
	2 | project) mode="project" ;;
	*) mode="flat" ;;
	esac
fi

# Scaffold unless a deps.edn is already present
if [[ -f "deps.edn" ]]; then
	echo "deps.edn already exists. Skipping scaffold."
elif [[ "$mode" == "flat" ]]; then
	echo "Scaffolding flat layout..."
	cat >deps.edn <<'EOF'
{:paths ["."]
 :aliases
 {:repl {:extra-deps {nrepl/nrepl {:mvn/version "1.3.1"}}
         :main-opts ["-m" "nrepl.cmdline"]}}}
EOF
	if [[ ! -f scratch.clj ]]; then
		cat >scratch.clj <<'EOF'
(ns scratch)

(comment
  (+ 1 2))
EOF
	fi
else
	# Resolve qualified project name: flag or interactive, default user/<dir>
	name="$name_arg"
	default_name="${USER:-$(id -un)}/$(basename "$PWD")"
	if [[ -z "$name" ]]; then
		read -rp "Project name (org/app) [$default_name]: " name
		name="${name:-$default_name}"
	fi
	echo "Running deps-new app into current dir as $name..."
	if ! nix develop --command clojure \
		-Sdeps '{:deps {io.github.seancorfield/deps-new {:git/tag "v0.12.2" :git/sha "465b303"}}}' \
		-X org.corfield.new/app :name "$name" :target-dir . :overwrite true; then
		echo "Error: deps-new did not scaffold the project. Aborting setup." >&2
		exit 1
	fi
fi

# Stage files so nix can see them (nix reads only git-tracked files)
if [[ -d ".git" ]]; then
	echo "Adding files to git..."
	git add flake.nix
	[[ -f deps.edn ]] && git add deps.edn
	[[ -d .claude ]] && git add .claude
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
