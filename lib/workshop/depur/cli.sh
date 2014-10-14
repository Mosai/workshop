
# Dispatches commands to other depur_ functions
depur () ( dispatch depur "${@:-}" )

# Provides help
depur_command_help ()
{
	cat <<-HELP
	   Usage: depur [option_list...] [command]
	          depur help, -h, --help [command]  Displays help for command.

	Commands: run    [script]  Runs and traces the given script.
	          tracer           Gets a tracer command for a shell.
	          format           Formats a stack trace from stdin.
	          coverage         Formats a trace from stdin into code coverage.
	          profile          Formats a trace from stdin into profile info.

	 Options: --shell  [shell]   Changes the shell used for debugging.
	          --ignore [pattern] Don't report files matching this pattern.
	          --short, -s        Displays only the basename for paths.
	          --full,  -f        Displays complete paths for the trace.
	HELP
}

# Options
depur_option_help   () ( depur_command_help )
depur_option_h      () ( depur_command_help )
depur_option_f      () ( depur_filter="echo";      dispatch depur "${@:-}" )
depur_option_full   () ( depur_filter="echo";      dispatch depur "${@:-}" )
depur_option_s      () ( depur_filter="basename";  dispatch depur "${@:-}" )
depur_option_short  () ( depur_filter="basename";  dispatch depur "${@:-}" )
depur_option_shell  () ( depur_shell="$1";  shift; dispatch depur "${@:-}" )
depur_option_ignore () ( depur_ignore="$1"; shift; dispatch depur "${@:-}" )

depur_      () ( echo "No command provided. Try 'depur --help'"; return 1 )
depur_call_ () ( echo "Call '$*' invalid. Try 'depur --help'"; return 1)

