setup ()
{
	lib_path="$POSIT_DIR/../../lib/workshop"

	. "$lib_path/common.sh"
	. "$lib_path/dispatch.sh"
}

test_dispatch_with_empty_placeholder ()
{
	expected_string="Called empty placeholder"

	example  () ( dispatch example "${@:-}" )
	example_ () ( echo "$expected_string" )

	OLDPS4="$PS4" # Prevent debugger from changing the output on MinGW
	set +e        # We care only about the output on this test
	help_call="$(: | dispatch example)"
	set -e
	PS4="$OLDPS4"

	[ "$expected_string" = "$help_call" ]
}

test_dispatch_with_call_placeholder ()
{
	expected_string="Called empty command placeholder"

	example       () ( dispatch example "$@" )
	example_call_ () ( echo "$expected_string $@" )

	OLDPS4="$PS4" # Prevent debugger from changing the output on MinGW
	set +e        # We care only about the output on this test
	help_call="$(: | dispatch example foaks)"
	set -e
	PS4="$OLDPS4"

	[ "$expected_string example foaks" = "$help_call" ]
}

test_dispatch_command ()
{
	expected_string="Called command"

	example             () ( dispatch example "$@" )
	example_command_foo () ( echo "$expected_string $@")

	OLDPS4="$PS4" # Prevent debugger from changing the output on MinGW
	set +e        # We care only about the output on this test
	command_call="$(: | dispatch example foo bar baz)"
	set -e
	PS4="$OLDPS4"

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
	example_command_foo () ( printf %s "Command $expected_string" )
	example_option_f    ()
	{
		printf %s "Option $expected_string $@"
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
	example_command_foo () ( printf %s "Command $expected_string $@" )
	example_option_fanz ()
	{
		printf %s "Option $expected_string $@"
		dispatch example "$@"
	}

	short_repassing_call="$(: | example --fanz foo)"

	[ "Option ${expected_string} fooCommand ${expected_string} " = "$short_repassing_call" ]
}


test_dispatch_option_long_with_equal_sign ()
{
	expected_string="Called option"

	example             () ( dispatch example "$@" )
	example_option_fanz () ( echo "$expected_string $@"; shift )

	long_call="$(: | example --fanz=bar baz)"

	[ "$expected_string bar baz" = "$long_call" ]
}


test_dispatch_option_long_with_equal_sign_and_quotes ()
{
	expected_string="Called option"

	example             () ( dispatch example "$@" )
	example_option_fanz () ( echo "$expected_string $@"; shift )

	long_call="$(: | example --fanz="bar baz")"

	[ "$expected_string bar baz " = "$long_call" ]
}


test_dispatch_option_long_with_equal_sign_quotes_and_equal_value ()
{
	expected_string="Called option"

	example             () ( dispatch example "$@" )
	example_option_fanz () ( echo "$expected_string $@"; shift )

	long_call="$(: | example --fanz="bar=baz")"

	[ "$expected_string bar=baz " = "$long_call" ]
}

test_dispatch_option_long_repassing_with_equal_sign ()
{
	expected_string="Called!"

	example             () ( dispatch example "$@" )
	example_command_foo () ( printf %s "Command $expected_string $@" )
	example_option_fanz ()
	{
		printf %s "Option $expected_string $@"
		shift
		dispatch example "$@"
	}

	long_repassing_call="$(: | example --fanz="bla bar" foo)"

	[ "Option ${expected_string} bla barfooCommand ${expected_string} " = "$long_repassing_call" ]
}
