
# Executes a single test
posit_exec_spec () ( posit_external "$1" "$2" "--short" 2>&1 )
posit_count_spec () ( echo ""; echo -n "Totals:"; posit_count_tiny "$@" )
posit_all_spec () ( cat )
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
	test_file="$1"
	test_function="$2"
	returned="$3"
	results="$4"
	test_status="fail:"
		
	if [ $returned = 0 ]; then
		test_status="pass:"
	elif [ $returned = 3 ]; then
		test_status="skip:"
	else
		returned=1
	fi

	# Removes the 'test_' from the start of the name
	test_function=${test_function#test_}

	# Displays the test status and humanized test name
	# replacing _ to spaces
	echo "  - $test_status $test_function" | tr '_' ' '

	# Formats a stack trace with the test results
	if [ $returned = 1 ] && [ "$posit_silent" = "-1" ]; then
		echo "$results" | depur format
	fi
}

