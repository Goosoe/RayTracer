#import "Basic";
#import "Compiler";
#import "File";

EXECUTABLE_NAME :: "RayTracer";

#run build();

build :: () {

    // No output for the current workspace.
    set_build_options_dc(.{do_output=false});

    build_options := get_build_options();
    args := build_options.compile_time_command_line;

    missing_args := true;
    for arg: args {
        if arg == {
            case "debug";
                set_optimization(*build_options, .DEBUG, true);
                build_options.output_path = "bin/debug";
                build_options.stack_trace = true;
                build_options.backend = .X64; // Faster compilation than LLVM.
                missing_args = false;
            case "debug-optimized";
                set_optimization(*build_options, .OPTIMIZED, true);
                build_options.output_path = "bin/debug-optimized";
                build_options.stack_trace = true;
                build_options.backend = .LLVM;
                missing_args = false;
            case "release";
                set_optimization(*build_options, .VERY_OPTIMIZED, false);
                build_options.output_path = "bin/release";
                build_options.stack_trace = false;
                build_options.backend = .LLVM;
                missing_args = false;
            case;
                compiler_report(tprint("Command-line argument #%, '%', is invalid. Valid build_options are: 'debug', 'debug-optimized' and 'release'.\n", it_index+1, arg));
        }
    }

    if missing_args
        compiler_report("No build option was provided. Valid build options are 'debug', 'debug-optimized' and 'release'\n");

    make_directory_if_it_does_not_exist(build_options.output_path, true);

    build_options.output_type = .EXECUTABLE;
    build_options.output_executable_name = EXECUTABLE_NAME;

    w := compiler_create_workspace(EXECUTABLE_NAME);
    set_build_options(build_options, w);
    add_build_file("src/main.jai", w);
}
