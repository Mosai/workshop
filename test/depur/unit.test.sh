setup ()
{
	. "$POSIT_DIR/../../lib/common.sh"
	. "$POSIT_DIR/../../lib/depur.sh"
}

test_depur_realpath_should_solve_relative_file_paths_to_absolute_ones ()
{
	real_file="/usr/bin/env"
	relative_file="/usr/bin/../bin/env"

	output="$(depur_realpath "$relative_file")"

	[ "$output" = "$real_file" ]
}

test_depur_clean_should_extract_files_and_lines_from_a_stack ()
{
	# Mocks the depur_realpath function to prevent filesystem interaction
	depur_realpath () ( echo "$1" )

	# Stubs a stack trace
	stack_stub ()
	{
		cat <<-STUBBED_STACK_TRACE
			This line should be removed. All Stack lines start
			with a +[TAB].
			+	/usr/bin/env:4	some command
			+	/usr/bin/env:9	some command

			Misc non-stack lines can appear at any point

			The line below is a stack line without a file, it
			should also be removed:
			+	:0	some_command

			+	/usr/bin/env:9	some command
			+	/etc/passwd:9	some command
		STUBBED_STACK_TRACE
	}

	# Prints out the expected stack trace used for assertion
	expected_stack ()
	{
		cat <<-EXPECTED_CLEAN_STACK
			/usr/bin/env	4
			/usr/bin/env	9
			/usr/bin/env	9
			/etc/passwd	9
		EXPECTED_CLEAN_STACK
	}

	expected="$(expected_stack | cat)"
	output="$(stack_stub | depur_clean)"

	[ "$output" = "$expected" ]
}

test_depur_profile_should_count_and_order_line_executions ()
{
	resource_prefix="+	$POSIT_DIR/../posit/resources/posit_post"
	# Mocks the depur_realpath function to prevent filesystem interaction
	depur_realpath () ( echo "$1" )

	# Stubs a stack trace
	stack_stub ()
	{
		cat <<-STUBBED_STACK_TRACE
			${resource_prefix}cov.fixture.sh:4 some command 4cov
			${resource_prefix}cov.fixture.sh:9 some command 9cov
			${resource_prefix}cov.fixture.sh:9 some command 9cov
			${resource_prefix}cov2.fixture.sh:9 some command 9cov2
		STUBBED_STACK_TRACE
	}

	# Prints out the expected stack trace used for assertion
	expected_stack ()
	{
		cat <<-EXPECTED_PROFILE_INFO
			2	posit_postcov.fixture.sh:9		true
			1	posit_postcov.fixture.sh:4		true
			1	posit_postcov2.fixture.sh:9		true
		EXPECTED_PROFILE_INFO
	}

	expected="$(expected_stack | cat)"
	output="$(stack_stub | depur_command_profile)"

	[ "$output" = "$expected" ]
}


# This is a sort of functional test, it should be rewritten as unit.
test_depur_coverage_should_count_lines_from_a_clean_stack ()
{
	# Gets the resources directory for this test suite
	resources_dir="$POSIT_DIR/../posit/resources"

	# Mocks the interal call to depur_clean to do nothing but output
	depur_clean () ( cat )

	# Stubs an output that depur_clean should actually do
	# using resources from the test folder
	clean_stub ()
	{
		cat <<-STUBBED_STACK_TRACE
			$resources_dir/posit_postcov.fixture.sh	4
			$resources_dir/posit_postcov.fixture.sh	9
			$resources_dir/posit_postcov.fixture.sh	9
			$resources_dir/posit_postcov2.fixture.sh	9
		STUBBED_STACK_TRACE
	}

	check ()
	{
		output="$(cat)"
		skipped_lines="$(echo "$output" | grep "^> \`-\`" | wc -l)"
		zeroed_lines="$(echo "$output" | grep "^> \`0\`	" | wc -l)"
		covered="$(echo "$output" | grep "^> \`1\`	" | wc -l)"
		doubled="$(echo "$output" | grep "^> \`2\`	" | wc -l)"

		# Variables are unquoted to avoid wc whitespace output
		[ $skipped_lines = 16 ] &&
		[ $zeroed_lines = 1 ] &&
		[ $covered = 2 ] &&
		[ $doubled = 1 ]

		exit $?
	}

	clean_stub | depur_command_coverage | check
}

test_depur_run_should_invoke_a_shell_with_stack_settings ()
{
	# Depur uses this variable to look for the shell
	depur_shell="shell_mock"

	# Mocks the shell to just print what its arguments and the
	# mocked PS4
	shell_mock           () ( echo "$@ $PS4" )

	# Mocks the function tracer with fake PS4 information
	depur_command_tracer () ( echo "! PS4_MOCK" )

	oldPS4="$PS4"
	PS4='' # Disables the real posit PS4
	set +x # Disables the real posit debugging
	output="$(depur_command_run "some_file.sh")"
	set -x # Re-enables
	PS4="$oldPS4"

	# Now we can expect a clean call without posit interference
	expected="-x some_file.sh ! PS4_MOCK"

	[ "$output" = "$expected" ]
}

test_depur_command_tracer_should_get_a_tracer_if_none_is_set ()
{
	# Mocks the function that generates the tracer
	depur_get_tracer () ( echo "tracer mock" )

	# Keeps the old trace command (from posit)
	old_depur_trace_command="$depur_trace_command"

	# Cleans, so the tracer will be called
	export depur_trace_command=''

	# Calls the command_tracer twice
	output="$(depur_command_tracer "foo")"

	# Restores the posit tracer
	depur_trace_command="$old_depur_trace_command"

	[ "$output" = "tracer mock" ]
}


test_depur_command_tracer_should_reuse_a_previously_set_tracer ()
{
	# Mocks the function that generates the tracer
	depur_get_tracer () ( echo "fail! this should not be called" )

	# Keeps the old trace command (from posit)
	old_depur_trace_command="$depur_trace_command"

	# Cleans, so the tracer will be called
	export depur_trace_command='tracer mock'

	# Calls the command_tracer twice
	output="$(depur_command_tracer "foo")"

	# Restores the posit tracer
	depur_trace_command="$old_depur_trace_command"

	[ "$output" = "tracer mock" ]
}

test_depur_format_should_print_formatted_columns ()
{
	input="+	/s:4	some command"
	expected="        +    /s:4                 some command                  "
	output="$(echo "$input" | depur_command_format)"

	[ "$output" = "$expected" ]
}
