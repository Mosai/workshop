# Saves the current shell command for future use
testsuite_current_shell=$(ps -o pid,comm | grep $$ | head -n1 | sed 's/.* //g')

# Fixes incomplete ps output for the busybox sh
if [ "$testsuite_current_shell" = "busybox" ];then
	testsuite_current_shell="busybox sh"
fi

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
		          spec  [path]        Run tests and display results as specs
		          list  [path]        Lists test functions in the specified path
		          exec  [file] [name] Run a single test by its file and name
		          help               Displays this message
	HELP
}

# Run tests on a specified path
testsuite_run ()
{
	target="$1"
	testsuite_list "$target" |  testsuite_process simple "$target"
}

# Run tests and display results as specs
testsuite_spec ()
{
	target="$1"
	testsuite_list "$target" |  testsuite_process spec "$target"
}

# Run tests from STDIN list
testsuite_process ()
{
	report_mode="$1"
	target="$2"
	passed_count=0
	total_count=0
	last_file=""
	current_file=""

	while read test_parameters; do
		current_file="$(echo "$test_parameters" | sed 's/ .*//')"

		if [ "$current_file" != "$last_file" ]; then
			testsuite_file_report_$report_mode "$current_file"
		fi

		total_count=$((total_count+1))

		results="$(testsuite_exec $test_parameters 2>&1 >/dev/null)"
		returned=$?

		testsuite_unit_report_$report_mode $test_parameters "$returned" "$results"

		if [ $returned = 0 ];then
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

testsuite_unit_report_spec ()
{
	test_file="$1"
	test_function="$2"
	returned="$3"
	results="$4"
	test_status="[ ]"
		
	if [ $returned = 0 ];then
		test_status="[x]"
	fi

	cat <<-NAME | tr '_' ' '
		  $test_status $test_function
	NAME

	testsuite_unit_stack "$returned" "$results"
}

testsuite_unit_stack ()
{
	returned="$1"
	results="$2"

	if [ $returned != 0 ];then
		echo "$results"   |
		      sed '1d;$d' |
		      awk 'BEGIN{FS=OFS="\t"}{ printf "   %-4s %-20s %-30s\n", $1, $2, $3}'
	fi
}

testsuite_file_report_simple () ( : )
testsuite_file_report_spec ()
{
	cat <<-FILEHEADER

		$current_file
	FILEHEADER
}

testsuite_unit_report_simple ()
{
	test_file="$1"
	test_function="$2"
	returned="$3"
	results="$4"
		
	if [ $returned = 0 ];then
		echo -n "."
	else
		echo -n "E"
	fi
}

# Executes a test on a test function
testsuite_exec ()
{
	test_file="$1"
	test_function="$2"

	# Loads the test file and executes the test in another shell instance

	testsuite_external "$test_file"
	returned=$? # Return code for the test, saved for later

	# Removes the 'test_' from the start of the name
	test_function=${test_function#test_}

	return $returned
}

testsuite_external ()
{
	test_file="$1"

	if [ z"$BASH_VERSION" != z ]; then
		trace_command='+	$(basename "${BASH_SOURCE}"):${LINENO}	'
	elif [ "$testsuite_current_shell" = "pdksh" ]; then
		trace_command="+	\${LINENO}	"
	elif [ z"$KSH_VERSION" != z ]; then
		trace_command='+	$(basename "${.sh.file}"):${LINENO}	'
	elif [ z"$ZSH_VERSION" != z ]; then
		trace_command='+	$(basename ${(%):-%x:%I})	'
	else
		trace_command="+	\${LINENO}	"
	fi

	$testsuite_current_shell <<-EXTERNAL
		. "$test_file"
		command -v setup 2>&1 >/dev/null && setup "$test_file"
		command -v setopt 2>&1 >/dev/null &&setopt PROMPT_SUBST
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
