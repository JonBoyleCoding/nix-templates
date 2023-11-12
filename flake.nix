{
	description = "A collection of templates from FalconProgrammer - Jonathan Boyle";

	outputs = {self}: {
		templates = {

			python-pdm = {
				path = ./python-pdm;
				description = "A template for a python project using pdm";
			};

		};
	};
}
