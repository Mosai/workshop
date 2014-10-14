
answer () ( dispatch answer "$@" )

# Provides help
answer_command_help ()
{
	cat <<-HELP
	   Usage: answer [option_list...] [command]
	          answer help, -h, --help [command] Displays help for command.

	Commands: get  [spec] Gets an answer from a specification list

	Spec: A spec is a string containing elements separated by a pipe "|".
	      Buttons are enclosed by square brackets '[ A Button ]'
	      Labels are just plain text.

	Examples: answer get 'Continue?|[ yes ]|[ no ]'

	HELP
}

# Options
answer_option_help () ( answer_command_help )
answer_option_h    () ( answer_command_help )

