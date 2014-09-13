. "$POSIT_DIR/../../lib/dispatch.sh"
. "$POSIT_DIR/../../lib/posit.sh"

test_posit_empty_call_dispatch ()
{
	empty_call="$(posit)"
	
	[ "$empty_call" = "No command provided. Try 'posit --help'" ]
}

test_posit_empty_invalid_dispatch ()
{
	invalid_call="$(posit foobarbaz)"
	
	[ "$invalid_call" = "Call 'posit foobarbaz' invalid. Try 'posit --help'" ]
}

test_posit_list_using_files ()
{
	posit_listfile () ( echo "$1 OK" )

	expected_list="$(posit_command_list /usr/bin/env)"
	
	[ "$expected_list" = "/usr/bin/env OK" ]
}

test_posit_list_using_directories ()
{
	posit_listdir () ( echo "$1 OK" )

	expected_list="$(posit_command_list /usr)"
	
	[ "$expected_list" = "/usr OK" ]
}

test_posit_list_without_parameters ()
{
	posit_listfile () ( echo "should not be called" )
	posit_listdir  () ( echo "should not be called" )

	expected_list="$(posit_command_list)"

	[ "$expected_list" = "" ]
}

template_posit_runner ()
{
	reporting_mode="$1"

	posit_command_list () ( echo -n "list_called $@ " )
	posit_process () ( cat; echo -n "process_called $@ " )

	used_path="/path.sh"
	called="$(posit --report $reporting_mode run "$used_path")"
	expected="list_called $used_path process_called $used_path "

	[ "$called" = "$expected" ]
}

test_posit_tiny ()
{
	template_posit_runner "tiny"
}

test_posit_spec ()
{
	template_posit_runner "spec"
}

test_posit_cov ()
{
	depur () ( cat )

	template_posit_runner "cov"
}


test_posit_process_with_single_test ()
{
	posit_file_pattern=".fixture.sh"
	file_mock_location="$POSIT_DIR/resources/posit_postcov.fixture.sh test_should_always_pass"
	posit_count_mock () ( echo "$1...$2" )
	posit_exec_mock () ( echo "exec mock called" )
	posit_head_mock () ( echo "head_mock called" )
	posit_unit_mock () ( echo "unit_mock called" )
	posit_all_mock () ( cat )

	check () 
	{
		result="$(cat)"
		head_results="$(echo "$result" | grep "^head_mock called")"
		unit_results="$(echo "$result" | grep "^unit_mock called")"
		last_line="$(echo "$result" | tail -n 1)"

		[ "$head_results" = "head_mock called" ] &&
		[ "$unit_results" = "unit_mock called" ] &&
		[ "$last_line" = "1...1" ]

		exit $?
	}

	posit_mode="mock"
	echo $file_mock_location | 
	posit_process "$POSIT_DIR/re

	sources/" |
	check
}


test_posit_process_with_multiple_tests ()
{
	posit_file_pattern=".fixture.sh"
	posit_exec_mock () ( echo "exec mock called" )
	posit_head_mock () ( echo "head_mock called" )
	posit_unit_mock () ( echo "unit_mock called" )
	posit_count_mock () ( echo "$1...$2" )
	posit_all_mock () ( cat )

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
		head_results="$(echo "$result" | grep "^head_mock called" | wc -l)"
		unit_results="$(echo "$result" | grep "^unit_mock called" | wc -l)"
		last_line="$(echo "$result" | tail -n 1)"

		[ $head_results = 2 ] &&
		[ $unit_results = 4 ] &&
		[ "$last_line" = "4...4" ]

		exit $?
	}

	posit_mode="mock"
	mocklist | 
		posit_process "$POSIT_DIR/resources/" |
		check
}

test_posit_process_with_no_tests ()
{
	posit_exec_mock ()  ( echo "exec_mock called $@" )
	posit_head_mock ()  ( echo "head_mock called $@" )
	posit_unit_mock ()  ( echo "unit_mock called $@" )
	posit_count_mock () ( echo "$@" )
	mocklist () ( true )

	posit_mode="mock"
	result="$(mocklist | posit_process "$POSIT_DIR/resources/")"

	[ "$result" = "0 0 0" ]
}

template_posit_unit ()
{
	expected_mode="$1"
	expected_code="$2"
	expected_string="$3"	

	result="$(posit_unit_$expected_mode "/foo/bar" "test_foo_bar" $expected_code "")"
	pass_results="$(echo "$result" | grep "$expected_string" | wc -l)"

	[ $pass_results = 1 ]
}

test_posit_unit_spec_success ()
{
	posit_stack_format () ( : )
	template_posit_unit spec 0 "pass:"
}

test_posit_unit_spec_fail ()
{
	posit_stack_format () ( : )
	template_posit_unit spec 1 "fail:"
}

test_posit_unit_tiny_fail ()
{
	template_posit_unit tiny 1 "F"
}

test_posit_unit_tiny_success ()
{
	template_posit_unit tiny 0 "\."
}

template_posit_exec ()
{
	mode="$1"
	expected="$2"
	args="$3"
	posit_external () ( echo "external called $@" )

	check ()
	{
		result="$(cat | tail -n 1)"

		[ "$result" = "external called /foo/bar foo_bar $expected" ]
		exit $?
	}

	posit_exec_$mode "/foo/bar" "foo_bar" | check
}

test_posit_exec_spec ()
{
	template_posit_exec spec "--short"
}

test_posit_exec_tiny ()
{
	template_posit_exec tiny "--short"
}

test_posit_exec_cov ()
{
	template_posit_exec cov "--full"
}

test_posit_head_spec ()
{
	result="$(posit_head_spec "/foo/bar" | sed '1d;$d')"

	[ "$result" = "### /foo/bar" ]
}

test_posit_unit_cov ()
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

	result="$(posit_unit_cov "/foo/bar" "test_foo_bar" 0 "$unit_results")"
	line_count="$(echo "$result" |  grep somefile.sh | wc -l )"

	[ $line_count = 3 ]
}
