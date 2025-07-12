{
  description = "A collection of templates from FalconProgrammer - Jonathan Boyle";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-precommit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-precommit-hooks,
    ...
  }:
    {
      templates = {
        python-pdm = {
          path = ./python-pdm;
          description = "A template for a python project using pdm";
        };

        python-shell = {
          path = ./python-shell;
          description = "A template to create a python shell with certain packages";
        };

        python-poetry2nix = {
          path = ./python-poetry2nix;
          description = "A template for a python project using poetry2nix";
        };

        default-package-flake = {
          path = ./default-package-flake;
          description = "A basic flake for building a default.nix package";
        };

        rust-bevy = {
          path = ./rust-bevy;
          description = "A NixOS development flake for Bevy development.";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      pre-commit-check = nix-precommit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          trim-trailing-whitespace.enable = true;
          end-of-file-fixer.enable = true;
        };
      };
    in {
      devShells.default = pkgs.mkShell {
        inherit (pre-commit-check) shellHook;
        buildInputs = with pkgs; [
          alejandra
          nixfmt-rfc-style
        ];
      };
    });
}
