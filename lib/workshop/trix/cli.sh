
# Dispatches commands to other trix_ functions
trix () ( dispatch trix "${@:-}" )

# Provides help
trix_command_help ()
{
	cat <<-HELP
	   Usage: trix [option_list...] [command]
	          trix help, -h, --help [command]  Displays help for command.

	Commands: run    [file]  Runs the target matrix file
	          list   [file]  Lists all tested environments

	 Options: --env    [name]  Runs only the selected environment
	          --matrix [name]  Runs only the selected matrix
	          --steps  [name]  Runs only the selected steps

	   Steps: setup   Runs before the actual environment starts
	          script  The actual script for the env
	          clean   Runs after the environment has completed its job

	HELP
}

trix_option_help   () ( trix_command_help )
trix_option_h      () ( trix_command_help )
trix_option_env    () ( trix_env_filter="$1"; shift; dispatch trix "${@:-}" )
trix_option_steps  () ( trix_steps="$1";       shift; dispatch trix "${@:-}" )
trix_option_matrix ()
{
	trix_matrix_filter="$1"
	shift
	dispatch trix "${@:-}"
}

trix_      () ( echo "No command provided. Try 'trix --help'"; return 1 )
trix_call_ () ( echo "Call '$*' invalid. Try 'trix --help'";   return 1 )


