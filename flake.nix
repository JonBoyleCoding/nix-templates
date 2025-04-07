{
  description = "A collection of templates from FalconProgrammer - Jonathan Boyle";

  outputs = {self}: {
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
  };
}
