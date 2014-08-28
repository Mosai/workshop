# Saves the current shell command for future use
testsuite_current_shell=$(ps -p $$ | tail -1 | sed 's/.* //g')

# Dispatches commands to other testsuite_ functions
testsuite () ( testsuite_"$@" )

# Placeholder for empty calls
testsuite_ () ( echo "No command provided. Try 'testsuite help'" 1>&2 )

# Provides help
testsuite_help ()
{
	cat <<-HELP
		Usage: testsuite [command]

		Commands: run   [path]        Run tests for the specified path
		          list  [path]        Lists test functions in the specified path
		          exec  [file] [name] Run a single test by its file and name
		          help               Displays this message
	HELP
}

# Run tests on a specified path
testsuite_run ()
{
	target="$1"
	testsuite_list "$target" |  testsuite_process "$target"
}

# Run tests from STDIN list
testsuite_process ()
{
	target="$1"
	passed_count=0
	total_count=0
	last_file=""
	current_file=""

	while read test_parameters; do
		current_file="$(echo "$test_parameters" | sed 's/ .*//')"

		if [ "$current_file" != "$last_file" ]; then
			cat <<-FILEHEADER

				$current_file
			FILEHEADER
		fi

		total_count=$((total_count+1))
		testsuite_exec $test_parameters  # Expand line as parameters

		if [ $? = 0 ];then
			passed_count=$((passed_count+1))
		fi

		last_file="$current_file"
	done

	if [ $total_count = 0 ];then
		echo "No tests found on $target" 1>&2
		return 0
	fi

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

	# Loads the test file and executes the test in another shell instance

	results="$(testsuite_external "$test_file" 2>&1 >/dev/null)"
	returned=$? # Return code for the test, saved for later

	if [ $returned = 0 ];then
		test_status="[x]"
	fi

	# Removes the 'test_' from the start of the name
	test_function=${test_function#test_}

	cat <<-NAME | tr '_' ' '
		  $test_status $test_function
	NAME

	if [ $returned != 0 ];then
		echo "$results" |
		      tail -n+2 | 
		      head -n-2 | 
		      awk 'BEGIN{FS=OFS="\t"}{ printf "   %-4s %-20s %-30s\n", $1, $2, $3}'
	fi

	return $returned
}

testsuite_external ()
{
	test_file="$1"

	if [ z"$BASH_VERSION" != z ]; then
		trace_command='+	$(basename "${BASH_SOURCE}"):${LINENO}	'
	elif [ z"$KSH_VERSION" != z ]; then
		trace_command='+	$(basename "${.sh.file}"):${LINENO}	'
	elif [ z"$ZSH_VERSION" != z ]; then
		trace_command='+	%x:%I	'
	else
		trace_command="+	${LINENO}"
	fi


	$testsuite_current_shell <<-EXTERNAL
		. "$test_file"
		command -v setup 2>&1 >/dev/null && setup "$test_file"
		PS4='$trace_command'
		set -x
		$test_function "$test_file"
		has_passed="\$?"
		set +x
		command -v teardown 2>&1 >/dev/null && teardown "$test_file"
		exit \$has_passed
	EXTERNAL
}

# Lists test functions in the specified path
testsuite_list ()
{
	target="$1"

	if   [ -f "$target" ];then
		testsuite_listfile "$target"
	elif [ -d "$target" ];then
		testsuite_listdir "$target"
	fi
}

# Lists test functions for a specified dir
testsuite_listdir ()
{
	target_dir="$1"

	find "$target_dir" -type f -name "*.test.sh" |
	grep -v "\.example\." |
	while read test_file; do
		testsuite_listfile "$test_file"
	done
}

# Lists test functions in a single file
testsuite_listfile ()
{
	target_file="$1"
	signature="s/^\(test_[a-zA-Z0-9_]*\)\s*()$/\1/p"

	cat "$target_file" | sed -n "$signature" |
		while read line; do
			echo "$target_file $line"
		done
}
