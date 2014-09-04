. "$POSIT_DIR/../../lib/posit.sh"

test_posit_empty_call ()
{
	# Stubs an illustrative posit_* function
	posit_demo () ( echo "OK $@" )

	dispatched="$(posit demo 1 2 3)"

	[ "$dispatched" = "OK 1 2 3" ]
}

test_posit_help ()
{
	help_call="$(posit help | cat)"
	returned_code=$?

	[ ! -z "$help_call" ] &&
	[ $returned_code = 0 ]
}

test_posit_list_using_files ()
{
	posit_listfile () ( echo "$1 OK" )

	expected_list="$(posit list /usr/bin/env)"
	
	[ "$expected_list" = "/usr/bin/env OK" ]
}

test_posit_list_using_directories ()
{
	posit_listdir () ( echo "$1 OK" )

	expected_list="$(posit list /usr)"
	
	[ "$expected_list" = "/usr OK" ]
}

test_posit_list_without_parameters ()
{
	posit_listfile () ( echo "should not be called" )
	posit_listdir  () ( echo "should not be called" )

	expected_list="$(posit list)"
}

template_posit_runner ()
{
	reporting_mode="$1"
	target_command="$2"

	posit_list    () ( echo -n "list_called $@ " )
	posit_process () ( cat; echo -n "process_called $@ " )

	used_path="/path.sh"
	called="$(posit $target_command "$POSIT_CMD" $used_path)"
	expected="list_called $used_path process_called $reporting_mode $POSIT_CMD $used_path "

	[ "$called" = "$expected" ]
}

test_posit_run ()
{
	template_posit_runner "run" "run"
}

test_posit_spec ()
{
	template_posit_runner "spec" "spec"
}

test_posit_cov ()
{
	posit_post_cov () ( cat )

	template_posit_runner "cov" "cov"
}

test_posit_postcov_counts_lines_properly ()
{
	posit_file_pattern=".fixture.sh"
	
	output () 
	{
		cat <<-INPUT
			$POSIT_DIR/resources/posit_postcov.fixture.sh	4
			$POSIT_DIR/resources/posit_postcov.fixture.sh	9
			$POSIT_DIR/resources/posit_postcov.fixture.sh	9
			$POSIT_DIR/resources/posit_postcov2.fixture.sh	9
		INPUT
	}

	check ()
	{
		output="$(cat | cat)"
		traced_lines="$(echo "$output" | grep "^    -" | wc -l)"
		zeroed_lines="$(echo "$output" | grep "^    0" | wc -l)"
		covered="$(echo "$output" | grep "^    1" | wc -l)"
		doubled="$(echo "$output" | grep "^    2" | wc -l)"

		[ $traced_lines = 16 ] &&
		[ $zeroed_lines = 1 ] &&
		[ $covered = 2 ] &&
		[ $doubled = 1 ]

		exit $?
	}

	output | posit_post_cov | check
}

test_posit_process_with_single_test ()
{
	posit_file_pattern=".fixture.sh"
	file_mock_location="$(dirname

	 $POSIT_FILE)/resources/posit_postcov.fixture.sh test_should_always_pass"
	posit_exec_mock () ( echo "exec mock called" )
	posit_file_report_mock () ( echo "file_report_mock called" )
	posit_unit_report_mock () ( echo "unit_report_mock called" )

	check () 
	{
		result="$(cat)"
		file_report_results="$(echo "$result" | grep "^file_report_mock called")"
		unit_report_results="$(echo "$result" | grep "^unit_report_mock called")"
		last_line="$(echo "$result" | tail -n 1)"

		[ "$file_report_results" = "file_report_mock called" ] &&
		[ "$unit_report_results" = "unit_report_mock called" ] &&
		[ "$last_line" = "1 tests out of 1 passed." ]

		exit $?
	}

	echo $file_mock_location | 
	posit_process "mock" "$POSIT_DIR/re

	sources/" |
	check
}


test_posit_process_with_multiple_tests ()
{
	posit_file_pattern=".fixture.sh"
	posit_exec_mock () ( echo "exec mock called" )
	posit_file_report_mock () ( echo "file_report_mock called" )
	posit_unit_report_mock () ( echo "unit_report_mock called" )

	mocklist ()
	{
		cat <<-LIST
			$POSIT_DIR/resources/posit_postcov.fixture.sh test_should_always_pass
			$POSIT_DIR/resources/posit_postcov.fixture.sh test_should_always_pass2
			$POSIT_DIR/resources/posit_postcov2.fixture.sh test_should_always_pass
			$POSIT_DIR/resources/posit_postcov2.fixture.sh test_should_always_pass2
		LIST
	}

	check () 
	{
		result="$(cat)"
		file_report_results="$(echo "$result" | grep "^file_report_mock called" | wc -l)"
		unit_report_results="$(echo "$result" | grep "^unit_report_mock called" | wc -l)"
		last_line="$(echo "$result" | tail -n 1)"

		[ $file_report_results = 2 ] &&
		[ $unit_report_results = 4 ] &&
		[ "$last_line" = "4 tests out of 4 passed." ]

		exit $?
	}

	mocklist | 
		posit_process "mock" "$POSIT_DIR/resources/" |
		check
}

test_posit_process_with_no_tests ()
{
	posit_exec_mock () ( echo "exec_mock called $@" )
	posit_file_report_mock () ( echo "file_report_mock called $@" )
	posit_unit_report_mock () ( echo "unit_report_mock called $@" )
	mocklist () ( true )

	result="$(mocklist | posit_process "$POSIT_CMD" "mock" "$POSIT_DIR/resources/")"

	[ "$result" = "No tests found on $POSIT_DIR/resources/" ]
}

template_posit_unit_report ()
{
	expected_mode="$1"
	expected_code="$2"
	expected_string="$3"	

	result="$(posit_unit_report_$expected_mode "/foo/bar" "test_foo_bar" $expected_code "")"
	pass_results="$(echo "$result" | grep "$expected_string" | wc -l)"

	[ $pass_results = 1 ]
}

test_posit_unit_report_spec_success ()
{
	posit_stack_format () ( : )
	template_posit_unit_report spec 0 "pass:"
}

test_posit_unit_report_spec_fail ()
{
	posit_stack_format () ( : )
	template_posit_unit_report spec 1 "fail:"
}

test_posit_unit_report_run_fail ()
{
	template_posit_unit_report run 1 "F"
}

test_posit_unit_report_run_success ()
{
	template_posit_unit_report run 0 "\."
}

template_posit_exec ()
{
	mode="$1"
	expected="$2"
	posit_stack_collect () ( echo "collect called $@" )

	check ()
	{
		result="$(cat)"

		[ "$result" = "collect called /foo/bar foo_bar  $expected" ]
		exit $?
	}

	posit_exec_$mode "/foo/bar" "foo_bar" | check
}

test_posit_exec_spec ()
{
	template_posit_exec spec "basename"
}

test_posit_exec_run ()
{
	template_posit_exec run "basename"
}

test_posit_exec_cov ()
{
	template_posit_exec cov "echo"
}

test_posit_file_report_spec ()
{
	result="$(posit_file_report_spec "/foo/bar" | sed '1d;$d')"

	[ "$result" = "### /foo/bar" ]
}

test_posit_unit_report_cov ()
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
	unit_results=$(unit_results_mock | cat)

	result="$(posit_unit_report_cov "/foo/bar" "test_foo_bar" 0 "$unit_results")"
	line_count="$(echo "$result" |  grep somefile.sh | wc -l )"

	[ $line_count = 3 ]
}
