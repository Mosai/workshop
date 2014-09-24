setup ()
{
	. "$POSIT_DIR/../../lib/common.sh"
	. "$POSIT_DIR/../../lib/posit/cov.sh"
	. "$POSIT_DIR/../../lib/posit/spec.sh"
	. "$POSIT_DIR/../../lib/posit/tiny.sh"
	. "$POSIT_DIR/../../lib/posit.sh"
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
	posit_filter_mock ()  ( : )
	posit_exec_mock () ( echo "exec mock called" )
	posit_head_mock () ( echo "head_mock called" )
	posit_unit_mock () ( echo "unit_mock called" )
	posit_all_mock () ( cat )
	depur_command_tracer () ( : )

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



	echo $file_mock_location |
	posit_mode="mock" posit_timer="" posit_process "$POSIT_DIR/resources/" |
	check
}


test_posit_process_with_multiple_tests ()
{
	posit_file_pattern=".fixture.sh"
	posit_filter_mock ()  ( : )
	posit_exec_mock () ( echo "exec mock called" )
	posit_head_mock () ( echo "head_mock called" )
	posit_unit_mock () ( echo "unit_mock called" )
	posit_count_mock () ( echo "$1...$2" )
	posit_all_mock () ( cat )
	depur_command_tracer () ( : )

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


	mocklist |
	posit_timer=""	posit_mode="mock" posit_process "$POSIT_DIR/resources/" |
	check
}

test_posit_process_with_no_tests ()
{
	posit_filter_mock ()  ( : )
	posit_exec_mock ()  ( echo "exec_mock called $@" )
	posit_head_mock ()  ( echo "head_mock called $@" )
	posit_unit_mock ()  ( echo "unit_mock called $@" )
	posit_count_mock () ( echo "$@" )
	mocklist () ( true )
	depur_command_tracer () ( : )

	posit_timer=""
	posit_mode="mock"
	result="$(mocklist | posit_process "$POSIT_DIR/resources/")"

	[ "$result" = "0 0 0" ]
}

template_posit_unit ()
{
	expected_mode="$1"
	expected_code="$2"
	expected_string="$3"

	OLDPS4="$PS4" # Prevent debugger from changing the output on MinGW
	set +e        # We care only about the output on this test
	result="$(posit_unit_$expected_mode "/foo/bar" "test_foo_bar" $expected_code "")"
	set -e
	PS4="$OLDPS4"

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

test_posit_unit_spec_skip ()
{
	posit_stack_format () ( : )
	template_posit_unit spec 3 "skip:"
}

test_posit_unit_tiny_fail ()
{
	template_posit_unit tiny 1 "F"
}

test_posit_unit_tiny_success ()
{
	template_posit_unit tiny 0 "\."
}

test_posit_unit_tiny_skip ()
{
	template_posit_unit tiny 3 "S"
}


template_posit_exec ()
{
	mode="$1"
	posit_external () ( echo "external called $@" )

	check ()
	{
		result="$(cat | tail -n 1)"

		[ "$result" = "external called /foo/bar foo_bar" ]
		exit $?
	}

	posit_exec_$mode "/foo/bar" "foo_bar" | check
}

test_posit_exec_spec ()
{
	template_posit_exec spec
}

test_posit_exec_tiny ()
{
	template_posit_exec tiny
}

test_posit_exec_cov ()
{
	template_posit_exec cov
}

test_posit_head_spec ()
{
	result="$(posit_head_spec "/foo/bar" | sed '1d;$d')"

	[ "$result" = "### /foo/bar" ]
}
