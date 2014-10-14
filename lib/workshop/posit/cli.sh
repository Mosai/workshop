# Dispatches commands to other posit_(command|option) functions
posit () ( dispatch posit "${@:-}" )

# Displays help
posit_command_help ()
{
	cat <<-HELP
	   Usage: posit [option_list...] [command]
	          posit help, -h, --help [command]  Displays help for command.

	Commands: run  [path]  Runs tests on the specified path.
	          list [path]  Lists the tests on the specified path.

	 Options: --report  [mode]    Changes the output mode.
	          --shell   [shell]   Changes the shell used for tests.
	          --files   [pattern] Inclusion pattern for test file lookup
	          --funcs   [pattern] Inclusion pattern for test function lookup
	          --timeout [seconds] Timeout for each single test
	          --fast,   -f        Stops on the first failed test.
	          --silent, -s        Don't collect stacks, just run them.

	   Modes: tiny   Uses a single line for the results.
	          spec   A complete report with the test names and statuses.
	          trace  The spec report including stack staces of failures.
	          cov    A code coverage report for the tests.

	HELP
}

# Option handlers
posit_option_help    () ( posit_command_help )
posit_option_h       () ( posit_command_help )
posit_option_f       () ( posit_fast="1";            dispatch posit "${@:-}" )
posit_option_fast    () ( posit_fast="1";            dispatch posit "${@:-}" )
posit_option_s       () ( posit_silent="1";          dispatch posit "${@:-}" )
posit_option_silent  () ( posit_silent="1";          dispatch posit "${@:-}" )
posit_option_shell   () ( posit_shell="$1";   shift; dispatch posit "${@:-}" )
posit_option_files   () ( posit_files="$1";   shift; dispatch posit "${@:-}" )
posit_option_timeout () ( posit_timeout="$1"; shift; dispatch posit "${@:-}" )
posit_option_report  () ( posit_mode="$1";    shift; dispatch posit "${@:-}" )
posit_option_funcs   ()
{
	posit_functions="$1"
	shift
	dispatch posit "${@:-}"
}

posit_      () ( echo "No command provided. Try 'posit --help'";return 1 )
posit_call_ () ( echo "Call '$*' invalid. Try 'posit --help'"; return 1)
