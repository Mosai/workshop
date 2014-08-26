# Dispatches commands to other testsuite_ functions
testsuite () ( testsuite_"$@" )

# Placeholder for empty calls
testsuite_ () ( echo "No command provided. Try 'testsuite help'" 1>&2 )

# Provides help
testsuite_help ()
{
	cat <<-HELP 1>&2
		Usage: testsuite [command]

		Commands: file [path] Run tests for the specified .sh file only
		          list [path] Lists test functions in the specified path
		          help        Displays this message
	HELP
}

# Run tests on a single test file
testsuite_file ()
{
	test_file="$1"
	test_list="$(testsuite_list "$test_file")"
	passed_count=0
	total_count=0

	if [ -z "$test_list" ]
	then
		echo "No tests found on $test_file" 1>&2
	fi

	for test_function in $test_list; do
		total_count=$((total_count+1))
		testsuite_exec "$test_file" "$test_function"
		if [ $? = 0 ]
		then
			passed_count=$((passed_count+1))
		fi
	done

	cat <<-RESULT

		$passed_count tests out of $total_count passed.
	RESULT
}

# Executes a test on a test function
testsuite_exec ()
{
	test_file="$1"
	test_function="$2"
	test_status="[ ]"
	current_shell=$(ps -p $$ | tail -1 | sed 's/.* //g')

	# Loads the test file and executes the test in another shell instance
	$current_shell <<-EXTERNAL
		. "$test_file" 1>&2 2>/dev/null                 
		$test_function 1>&2 2>/dev/null
	EXTERNAL

	returned=$? # Return code for the test, saved for later

	if [ $returned = 0 ]
	then
		test_status="[x]"
	fi

	# Removes the 'test_' from the start of the name
	test_function=${test_function#test_}

	cat <<-NAME | tr '_' ' '
		$test_status $test_function
	NAME

	return $returned
}

# Lists test functions in a single file
testsuite_list ()
{
	target="$1"
	signature="s/^\(test_[a-zA-Z0-9_]*\)\s*()$/\1/p"

	cat "$target" | sed -n "$signature"
}