setup ()
{
	. "$POSIT_DIR/../../lib/dispatch.sh"
	. "$POSIT_DIR/../../lib/depur.sh"
}

test_depur_empty_call_dispatch ()
{
	empty_call="$(depur)"
	
	[ "$empty_call" = "No command provided. Try 'depur --help'" ]
}

test_depur_empty_invalid_dispatch ()
{
	invalid_call="$(depur foobarbaz)"
	
	[ "$invalid_call" = "Call 'depur foobarbaz' invalid. Try 'depur --help'" ]
}

test_depur_option_flag_dispatch ()
{
	# Stub all flag handlers
	depur_option_f     () ( true )
	depur_option_full  () ( true )
	depur_option_short () ( true )
	depur_option_s     () ( true )
	depur_option_shell () ( true )

	# All calls should touch the handlers and return true
	depur -f      &&
	depur --full  &&
	depur --short &&
	depur -s      &&
	depur --shell
}

test_depur_option_flag_redispatch ()
{
	# Stubs a command that should be called after options are set
	depur_command_mockpass () ( true )

	# All calls should touch the handlers and return true
	depur -f      mockpass &&
	depur --full  mockpass &&
	depur --short mockpass &&
	depur -s      mockpass &&
	depur --shell sh mockpass
}

test_depur_coverage_counts_lines_properly ()
{
	posit_files=".fixture.sh"
	
	output () 
	{
		cat <<-INPUT
			$POSIT_DIR/../posit/resources/posit_postcov.fixture.sh	4
			$POSIT_DIR/../posit/resources/posit_postcov.fixture.sh	9
			$POSIT_DIR/../posit/resources/posit_postcov.fixture.sh	9
			$POSIT_DIR/../posit/resources/posit_postcov2.fixture.sh	9
		INPUT
	}

	depur_clean () ( cat )

	check ()
	{
		output="$(cat | cat)"
		skipped_lines="$(echo "$output" | grep "^> \`-\`" | wc -l)"
		zeroed_lines="$(echo "$output" | grep "^> \`0\`	" | wc -l)"
		covered="$(echo "$output" | grep "^> \`1\`	" | wc -l)"
		doubled="$(echo "$output" | grep "^> \`2\`	" | wc -l)"

		[ $skipped_lines = 16 ] &&
		[ $zeroed_lines = 1 ] &&
		[ $covered = 2 ] &&
		[ $doubled = 1 ]

		exit $?
	}

	output | depur_command_coverage | check
}

test_depur_clean ()
{
	unit_results_mock ()
	{
		cat <<-RESULTS

			This line should be removed
			+	somefile.sh:2	This line stays!

			This line should be removed

			+	somefile.sh:3	This line stays!			
			++	somefile.sh:4	This line stays!			
			++  :3				This line should be removed
		RESULTS
	}
	line_count="$(unit_results_mock | depur_clean | wc -l )"

	[ $line_count = 3 ]
}
