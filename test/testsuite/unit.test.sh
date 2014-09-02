. "$(dirname $current_file)/../../lib/testsuite.sh"

test_testsuite_empty_call ()
{
	# Stubs an illustrative testsuite_* function
	testsuite_demo () ( echo "OK $@" )

	dispatched="$(testsuite demo 1 2 3)"

	[ "$dispatched" = "OK 1 2 3" ]
}

test_testsuite_help ()
{
	help_call="$(testsuite help | cat)"
	returned_code=$?

	[ ! -z "$help_call" ] &&
	[ $returned_code = 0 ]
}

test_testsuite_list_using_files ()
{
	testsuite_listfile () ( echo "$1 OK" )

	expected_list="$(testsuite list /usr/bin/env)"
	
	[ "$expected_list" = "/usr/bin/env OK" ]
}

test_testsuite_list_using_directories ()
{
	testsuite_listdir () ( echo "$1 OK" )

	expected_list="$(testsuite list /usr)"
	
	[ "$expected_list" = "/usr OK" ]
}

test_testsuite_list_without_parameters ()
{
	testsuite_listfile () ( echo "should not be called" )
	testsuite_listdir  () ( echo "should not be called" )

	expected_list="$(testsuite list)"
}

template_testsuite_runner ()
{
	reporting_mode="$1"
	target_command="$2"

	testsuite_list    () ( echo -n "list_called $@ " )
	testsuite_process () ( cat; echo -n "process_called $@ " )

	used_path="/path.sh"
	called="$(testsuite $target_command $used_path)"
	expected="list_called $used_path process_called $reporting_mode $used_path "

	[ "$called" = "$expected" ]
}

test_testsuite_run ()
{
	template_testsuite_runner "run" "run"
}

test_testsuite_spec ()
{
	template_testsuite_runner "spec" "spec"
}

test_testsuite_cov ()
{
	testsuite_post_cov () ( cat )

	template_testsuite_runner "cov" "cov"
}

test_testsuite_postcov_counts_lines_properly ()
{
	testsuite_file_pattern=".fixture.sh"
	
	output () 
	{
		cat <<-INPUT
			$(dirname $current_file)/resources/testsuite_postcov.fixture.sh	4
			$(dirname $current_file)/resources/testsuite_postcov.fixture.sh	9
			$(dirname $current_file)/resources/testsuite_postcov.fixture.sh	9
			$(dirname $current_file)/resources/testsuite_postcov2.fixture.sh	9
		INPUT
	}

	check ()
	{
		output="$(cat | cat)"
		traced_lines="$(echo "$output" | grep "^-" | wc -l)"
		zeroed_lines="$(echo "$output" | grep "^0" | wc -l)"
		covered="$(echo "$output" | grep "^1" | wc -l)"
		doubled="$(echo "$output" | grep "^2" | wc -l)"

		[ $traced_lines = 16 ] &&
		[ $zeroed_lines = 1 ] &&
		[ $covered = 2 ] &&
		[ $doubled = 1 ]

		exit $?
	}

	output | testsuite_post_cov | check
}

test_testsuite_process_with_single_test ()
{
	testsuite_file_pattern=".fixture.sh"
	file_mock_location="$(dirname $current_file)/resources/testsuite_postcov.fixture.sh test_should_always_pass"
	testsuite_exec_mock () ( echo "exec mock called" )
	testsuite_file_report_mock () ( echo "file_report_mock called" )
	testsuite_unit_report_mock () ( echo "unit_report_mock called" )

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
	testsuite_process "mock" "$(dirname $current_file)/resources/" |
	check
}


test_testsuite_process_with_multiple_tests ()
{
	testsuite_file_pattern=".fixture.sh"
	testsuite_exec_mock () ( echo "exec mock called" )
	testsuite_file_report_mock () ( echo "file_report_mock called" )
	testsuite_unit_report_mock () ( echo "unit_report_mock called" )

	mocklist ()
	{
		cat <<-LIST
			$(dirname $current_file)/resources/testsuite_postcov.fixture.sh test_should_always_pass
			$(dirname $current_file)/resources/testsuite_postcov.fixture.sh test_should_always_pass2
			$(dirname $current_file)/resources/testsuite_postcov2.fixture.sh test_should_always_pass
			$(dirname $current_file)/resources/testsuite_postcov2.fixture.sh test_should_always_pass2
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
		testsuite_process "mock" "$(dirname $current_file)/resources/" |
		check
}

test_testsuite_process_with_mixed_failures ()
{
	testsuite_file_pattern=".fixture.sh"

	testsuite_exec_mock () 
	{
		if [ "$2" = 'test_should_always_pass2' ];then
			return 1
		else
			return 0
		fi
	}
	testsuite_file_report_mock () ( echo "file_report_mock called $@" )
	testsuite_unit_report_mock () ( echo "unit_report_mock called $@" )

	mocklist ()
	{
		cat <<-LIST
			$(dirname $current_file)/resources/testsuite_postcov.fixture.sh test_should_always_pass
			$(dirname $current_file)/resources/testsuite_postcov.fixture.sh test_should_always_pass2
			$(dirname $current_file)/resources/testsuite_postcov2.fixture.sh test_should_always_pass
			$(dirname $current_file)/resources/testsuite_postcov2.fixture.sh test_should_always_pass2
		LIST
	}

	check () 
	{
		result="$(cat | cat)"
		file_report_results="$(echo "$result" | grep "^file_report_mock called" | wc -l)"
		unit_report_results="$(echo "$result" | grep "^unit_report_mock called" | wc -l)"
		last_line="$(echo "$result" | tail -n 1)"

		[ $file_report_results = 2 ] &&
		[ $unit_report_results = 4 ] &&
		[ "$last_line" = "2 tests out of 4 passed." ]

		exit $?
	}

	mocklist | 
		testsuite_process "mock" "$(dirname $current_file)/resources/" |
		check
}

test_testsuite_process_with_no_tests ()
{
	testsuite_exec_mock () ( echo "exec_mock called $@" )
	testsuite_file_report_mock () ( echo "file_report_mock called $@" )
	testsuite_unit_report_mock () ( echo "unit_report_mock called $@" )
	mocklist () ( : )

	result="$(mocklist | testsuite_process "mock" "$(dirname $current_file)/resources/")"

	[ "$result" = "No tests found on $(dirname $current_file)/resources/" ]
}

template_testsuite_unit_report ()
{
	expected_mode="$1"
	expected_code="$2"
	expected_string="$3"	

	result="$(testsuite_unit_report_$expected_mode "/foo/bar" "test_foo_bar" $expected_code "")"
	pass_results="$(echo "$result" | grep "$expected_string" | wc -l)"

	[ $pass_results = 1 ]
}

test_testsuite_unit_report_spec_success ()
{
	testsuite_stack_format () ( : )
	template_testsuite_unit_report spec 0 "pass:"
}

test_testsuite_unit_report_spec_fail ()
{
	testsuite_stack_format () ( : )
	template_testsuite_unit_report spec 1 "fail:"
}

test_testsuite_unit_report_run_fail ()
{
	template_testsuite_unit_report run 1 "F"
}

test_testsuite_unit_report_run_success ()
{
	template_testsuite_unit_report run 0 "\."
}

template_testsuite_exec ()
{
	mode="$1"
	expected="$2"
	testsuite_stack_collect () ( echo "collect called $@" )

	check ()
	{
		result="$(cat)"

		[ "$result" = "collect called /foo/bar foo_bar $expected" ]
		exit $?
	}

	testsuite_exec_$mode "/foo/bar" "foo_bar" | check
}

test_testsuite_exec_spec ()
{
	template_testsuite_exec spec "basename"
}

test_testsuite_exec_run ()
{
	template_testsuite_exec run "basename"
}

test_testsuite_exec_cov ()
{
	template_testsuite_exec cov "echo"
}

test_testsuite_file_report_spec ()
{
	result="$(testsuite_file_report_spec "/foo/bar" | tail -n 1)"

	[ "$result" = "### /foo/bar" ]
}

test_testsuite_unit_report_cov ()
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

	result="$(testsuite_unit_report_cov "/foo/bar" "test_foo_bar" 0 "$unit_results")"
	line_count="$(echo "$result" |  grep somefile.sh | wc -l )"

	[ $line_count = 3 ]
}
