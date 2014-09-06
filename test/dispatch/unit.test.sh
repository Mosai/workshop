. "$POSIT_DIR/../../lib/dispatch.sh"

test_dispatch_with_empty_placeholder ()
{
	expected_string="Called empty placeholder"

	example  () ( dispatch example "$@" )
	example_ () ( echo "$expected_string" )

	help_call="$(: | example)"

	[ "$expected_string" = "$help_call" ]
}

test_dispatch_with_call_placeholder ()
{
	expected_string="Called empty command placeholder"

	example       () ( dispatch example "$@" )
	example_call_ () ( echo "$expected_string $@" )

	help_call="$(: | example foaks)"

	[ "$expected_string example foaks" = "$help_call" ]
}


test_dispatch_command ()
{
	expected_string="Called command"

	example             () ( dispatch example "$@" )
	example_command_foo () ( echo "$expected_string $@")

	command_call="$(: | example foo bar baz)"
	returned_code=$?

	[ "$expected_string bar baz" = "$command_call" ]
}

test_dispatch_option_short ()
{
	expected_string="Called option"
	
	example          () ( dispatch example "$@" )
	example_option_f () ( echo "$expected_string $@"; shift )

	short_call="$(: | example -f bar baz)"

	[ "$expected_string bar baz" = "$short_call" ]
}

test_dispatch_option_short_repassing ()
{
	expected_string="Called!"
	
	example             () ( dispatch example "$@" )
	example_command_foo () ( echo -n "Command $expected_string" )
	example_option_f    () 
	{
		echo -n "Option $expected_string $@"
		dispatch example "$@"
	}

	short_repassing_call="$(: | example -f foo)"

	[ "Option ${expected_string} fooCommand ${expected_string}" = "$short_repassing_call" ]
}

test_dispatch_option_long ()
{
	expected_string="Called option"
	
	example             () ( dispatch example "$@" )
	example_option_fanz () ( echo "$expected_string $@"; shift )

	long_call="$(: | example --fanz bar baz)"

	[ "$expected_string bar baz" = "$long_call" ]
}

test_dispatch_option_long_repassing ()
{
	expected_string="Called!"
	
	example             () ( dispatch example "$@" )
	example_command_foo () ( echo -n "Command $expected_string $@" )
	example_option_fanz () 
	{
		echo -n "Option $expected_string $@"
		dispatch example "$@"
	}

	short_repassing_call="$(: | example --fanz foo)"

	[ "Option ${expected_string} fooCommand ${expected_string} " = "$short_repassing_call" ]
}

test_dispatch_option_long_value_and_repassing ()
{
	expected_string="Called!"
	
	example             () ( dispatch example "$@" )
	example_command_foo () ( echo -n "Command $expected_string $@" )
	example_option_fanz () 
	{
		echo -n "Option $expected_string $@"
		shift
		dispatch example "$@"
	}

	short_repassing_call="$(: | example --fanz=borz foo)"

	[ "Option ${expected_string} borz fooCommand ${expected_string} " = "$short_repassing_call" ]
}
