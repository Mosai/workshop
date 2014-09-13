. "$POSIT_DIR/../../lib/dispatch.sh"
. "$POSIT_DIR/../../lib/depur.sh"

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


