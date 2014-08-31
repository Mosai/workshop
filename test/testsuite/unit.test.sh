setup ()
{
	current_file="$1"
	. "$(dirname $current_file)/../../lib/testsuite.sh"
}

test_testsuite_empty_call ()
{
	# Stubs an illustrative testsuite_* function
	testsuite_demo () ( echo "OK $@" )

	dispatched="$(testsuite demo 1 2 3)"

	[ "$dispatched" = "OK 1 2 3" ]
}

test_testsuite_help ()
{
	help_call="$(testsuite help)"

	[ ! -z "$help_call" ] &&
	[ $? = 0 ]
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
	template_testsuite_runner "simple" "run"
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

