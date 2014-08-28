setup ()
{
	current_file="$1"
	. "$(dirname $current_file)/../../lib/testsuite.sh"
}

test_dispatcher_should_call_and_pass_arguments ()
{
	# Stubs an illustrative testsuite_* function
	testsuite_demo () ( echo "OK $@" )

	dispatched="$(testsuite demo 1 2 3)"

	[ "$dispatched" = "OK 1 2 3" ]
}

test_empty_testsuite_call_should_provide_help_on_stderr ()
{
	empty_call="$(testsuite 2>&1)"

	[ z"$KSH_VERSION" != z ] || # skip this test for ksh
	[ ! -z "$empty_call" ]   &&
	[ $? = 0 ]
}

test_help_command_should_return_help_text ()
{
	help_call="$(testsuite help)"

	[ ! -z "$help_call" ] &&
	[ $? = 0 ]
}

test_list_command_can_point_to_files ()
{
	testsuite_listfile () ( echo "$1 OK" )

	filepoint="$(testsuite list /usr/bin/env)"
	
	[ "$filepoint" = "/usr/bin/env OK" ]
}

test_list_command_can_point_to_directories ()
{
	testsuite_listdir () ( echo "$1 OK" )

	filepoint="$(testsuite list /usr)"
	
	[ "$filepoint" = "/usr OK" ]
}
