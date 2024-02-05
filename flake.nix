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

		};
	};
}
