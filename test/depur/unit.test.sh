setup ()
{
	. "$POSIT_DIR/../../lib/dispatch.sh"
	. "$POSIT_DIR/../../lib/depur.sh"
}

test_depur_empty_call_should_print_no_command_notice ()
{
	output="$(depur)"

	[ "$output" = "No command provided. Try 'depur --help'" ]
}

test_depur_empty_call_should_return_status_code_1 ()
{
	depur

	[ $? = 1 ]
}

test_depur_invalid_call_should_print_notice ()
{
	call="this_call_does_not_exist"
	output="$(depur $call)"

	[ "$output" = "Call 'depur $call' invalid. Try 'depur --help'" ]
}

test_depur_all_options_should_call_their_respective_functions ()
{
	# Replace actual flags by stubs that should be called
	depur_option_f      () ( true )
	depur_option_full   () ( true )
	depur_option_short  () ( true )
	depur_option_s      () ( true )
	depur_option_shell  () ( true )
	depur_option_ignore () ( true )

	# All calls should touch the handlers and return true
	depur -f      &&
	depur --full  &&
	depur --short &&
	depur -s      &&
	depur --shell &&
	depur --ignore
}

test_depur_all_options_should_redispatch_after_being_set ()
{
	# Stubs a command that should be called after options are set
	depur_command_commandstub () ( true )

	# All calls should touch the handlers and return true
	depur -f            commandstub &&
	depur --full        commandstub &&
	depur --short       commandstub &&
	depur -s            commandstub &&
	depur --shell  "sh" commandstub &&  # This option uses an argument
	depur --ignore "sh" commandstub     # This option uses an argument
}

test_depur_realpath_should_solve_relative_file_paths_to_absolute_ones ()
{
	# Gets the first real directory path on the current filesystem
	for real_dir in /*; do [ -d "$real_dir" ] && break; done

	# Gets the first real file path on the first real directory
	for real_file in $real_dir/*; do [ -f "$real_file" ] && break; done

	# Gets only the file name for the first real file found
	basename_file=$(basename "$real_file")

	# The first dir should be a first-level one, make it relative
	# For example, /bin/ash will be /bin../bin/ash
	relative_file="$real_dir/..$real_dir/$basename_file"

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
			+	/usr/bin/env:4	some command
			+	/usr/bin/env:9	some command
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


test_depur_coverage ()
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

		[ "$skipped_lines" = 16 ] &&
		[ "$zeroed_lines" = 1 ] &&
		[ "$covered" = 2 ] &&
		[ "$doubled" = 1 ]

		exit $?
	}

	clean_stub | depur_command_coverage | check
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
			++  :3			This line should be removed
		RESULTS
	}
	line_count="$(unit_results_mock | depur_clean | wc -l )"

	[ $line_count = 3 ]
}
