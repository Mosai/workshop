posit_filter_spec () ( echo "basename" )
# Executes a single test
posit_exec_spec () ( posit_external "$1" "$2" 2>&1 || false )
posit_count_spec () ( echo ""; printf %s "Totals:"; posit_count_tiny "$@" )
posit_all_spec () ( posit_process "$1" )
# Reports a test file
posit_head_spec ()
{
	cat <<-FILEHEADER

		### $1

	FILEHEADER
}
# Reports a single unit
posit_unit_spec ()
{
	test_function="$2"
	test_returned="$3"
	results="$4"
	test_status="fail:"

	if [ "$test_returned" = "0" ]; then
		test_status="pass:"
	elif [ "$test_returned" = "3" ]; then
		test_status="skip:"
	else
		test_returned=1
	fi

	# Removes the 'test_' from the start of the name
	test_function=${test_function#test_}

	# Displays the test status and humanized test name
	# replacing _ to spaces
	echo "  - $test_status $test_function" | tr '_' ' '

	# Formats a stack trace with the test results
	if [ $test_returned = 1 ] && [ "$posit_silent" = "-1" ]; then
		echo "$results" | depur_command_format
	fi
}

