#load "src/main.jai";

#run {
	#import("Compiler");
	#import("File");

	make_directory_if_it_does_not_exist("bin/");
	
	set_build_options_dc(.{
		output_path = "bin/",
		output_executable_name = "bunnymark"
	});
}