setup ()
{
	. "$POSIT_DIR/../../lib/common.sh"
	. "$POSIT_DIR/../../lib/dispatch.sh"
	. "$POSIT_DIR/../../lib/posit/cov.sh"
	. "$POSIT_DIR/../../lib/posit/spec.sh"
	. "$POSIT_DIR/../../lib/posit/tiny.sh"
	. "$POSIT_DIR/../../lib/posit.sh"
}

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


test_posit_option_flag_dispatch ()
{
	# Stub all flag handlers
	posit_option_report  () ( true )
	posit_option_shell   () ( true )
	posit_option_files   () ( true )
	posit_option_funcs   () ( true )
	posit_option_timeout () ( true )
	posit_option_fast    () ( true )
	posit_option_silent  () ( true )
	posit_option_f       () ( true )
	posit_option_s       () ( true )

	# All calls should touch the handlers and return true
	posit --report  &&
	posit --shell   &&
	posit --files   &&
	posit --funcs   &&
	posit --timeout &&
	posit --fast    &&
	posit --silent  &&
	posit -f        &&
	posit -s
}

test_posit_option_flag_redispatch ()
{
	# Stubs a command that should be called after options are set
	posit_command_mockpass () ( true )
	posit_unit_foo () ( true )

	# All calls should touch the handlers and return true
	posit --report  foo mockpass &&
	posit --shell   foo mockpass &&
	posit --files   foo mockpass &&
	posit --funcs   foo mockpass &&
	posit --timeout foo mockpass &&
	posit --fast    mockpass &&
	posit --silent  mockpass &&
	posit -f        mockpass &&
	posit -s        mockpass
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
	posit_process "$POSIT_DIR/resources/" |
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
