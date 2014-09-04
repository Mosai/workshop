# File name pattern for test files
posit_file_pattern="*.test.sh"	
posit_trace_function=

# Dispatches commands to other posit_ functions
posit () ( posit_"$@" )

# Placeholder for empty calls
posit_ () ( echo "No command provided. Try 'posit help'" 1>&2; return 1 )

# Provides help
posit_help ()
{
	cat <<-HELP
		Usage: posit [command]

		Commands: run   [cmd] [path]  Run tests for the specified path
		          spec  [cmd] [path]  Run tests and display results as specs
		          cov   [cmd] [path]  Displays the code coverage for files used
		          list  [cmd] [path]  Lists test functions in the specified path
		          help                Displays this message
	HELP
}

# Main function for the `posit run` report
posit_run ()
{
	target_cmd="$1"
	target="$2"
	posit_list "$target" | posit_process run "$target_cmd" "$target"
}
# Executes a single test
posit_exec_run () ( posit_stack_collect "$1" "$2" "$3" "basename" )
# Reports a test file
posit_file_report_run () ( : )
# Reports a single unit
posit_unit_report_run ()
{
	test_file="$1"
	test_function="$2"
	returned="$3"
	results="$4"
		
	if [ $returned = 0 ]; then
		echo -n "."
	else
		echo -n "F"
	fi
}

# Main function for the `posit spec` report
posit_spec ()
{
	target_cmd="$1"
	target="$2"
	posit_list "$target" | posit_process spec "$target_cmd" "$target"
}
# Executes a single test
posit_exec_spec () ( posit_stack_collect "$1" "$2" "$3" "basename" )
# Reports a test file
posit_file_report_spec ()
{
	current_file="$1"

	cat <<-FILEHEADER

		### $current_file

	FILEHEADER
}
# Reports a single unit
posit_unit_report_spec ()
{
	test_file="$1"
	test_function="$2"
	returned="$3"
	results="$4"
	test_status="fail:"
		
	if [ $returned = 0 ]; then
		test_status="pass:"
	fi

	# Removes the 'test_' from the start of the name
	test_function=${test_function#test_}

	# Displays the test status and humanized test name
	# replacing _ to spaces
	cat <<-NAME | tr '_' ' '
		  - $test_status $test_function
	NAME

	# Formats a stack trace with the test results
	if [ $returned != 0 ]; then
		echo "$results" | depur format
	fi
}

# Main function for the `posit cov` report
posit_cov ()
{
	target_cmd="$1"
	target="$2"
	posit_list "$target" | posit_process cov "$target_cmd" "$target" |
	depur coverage
}
# Executes a single test
posit_exec_cov () ( posit_stack_collect "$1" "$2" "$3" "echo" )
# Reports a test file
posit_file_report_cov () ( : )
# Reports a single unit
posit_unit_report_cov () ( echo "$4" )

# Run tests from a STDIN list
posit_process ()
{
	report_mode="$1"
	target_cmd="$2"
	target="$3"
	passed_count=0
	total_count=0
	last_file=""
	current_file=""

	# Each line should have a file and a test function on that file
	while read test_parameters; do
		current_file="$(echo "$test_parameters" | sed 's/ .*//')"

		# Displays a file report when the file changes
		if [ "$current_file" != "$last_file" ]; then
			posit_file_report_$report_mode "$current_file"
		fi

		total_count=$((total_count+1))

		# Runs a test and stores results
		results="$(posit_exec_$report_mode "$target_cmd" $test_parameters)"
		returned=$?

		# Run the customized report
		posit_unit_report_$report_mode $test_parameters "$returned" "$results"

		if [ $returned = 0 ]; then
			passed_count=$((passed_count+1))
		fi

		last_file="$current_file"
	done

	if [ "$total_count" = "0" ]; then
		echo "No tests found on $target"
		return 1
	fi

	cat <<-RESULT

		$passed_count tests out of $total_count passed.
	RESULT

	if [ "$passed_count" != "$total_count" ]; then
		return 1
	fi
}

# Executes a test passing a filter to the stack
posit_stack_collect ()
{
	target_cmd="$1"
	test_file="$2"
	test_function="$3"
	file_filter="$4"

	external_output="$(posit_external "$target_cmd" "$test_file" "$test_function" "$file_filter" 2>&1)"
	external_code=$?
	if [ $external_code != 0 ];then
		echo "$external_output"
	fi
	
	return $external_code
}

# Executes a file on a function using an external shell process
posit_external ()
{
	interpreter="$1"
	test_file="$2"
	test_dir="$(dirname "$2")"
	test_function="$3"
	filter="$4"
	depur_trace_function="$(depur tracer "$interpreter" "$filter")"
	PS4="$depur_trace_function"     \
	POSIT_CMD="$interpreter"        \
	POSIT_FILE="$test_file"         \
	POSIT_DIR="$test_dir"           \
	POSIT_FUNCTION="$test_function" \
	$interpreter <<-EXTERNAL
		command -v setopt 2>/dev/null >/dev/null && setopt PROMPT_SUBST SH_WORD_SPLIT
		set -x
		. "\$POSIT_FILE" &&
		   \$POSIT_FUNCTION
	   exit \$?
	EXTERNAL
}

# Lists test functions in the specified path
posit_list ()
{
	target="$1"

	if   [ -f "$target" ]; then
		posit_listfile "$target"
	elif [ -d "$target" ]; then
		posit_listdir "$target"
	fi
}

# Lists test functions for a specified dir
posit_listdir ()
{
	target_dir="$1"

	find "$target_dir" -type f -name "$posit_file_pattern" |
	grep -v "\.example\." |
	while read test_file; do
		posit_listfile "$test_file"
	done
}

# Lists test functions in a single file
posit_listfile ()
{
	target_file="$1"
	signature="/^\(test_[a-zA-Z0-9_]*\)[	 ]*/p"

	cat "$target_file" | sed -n "$signature" | cut -d" " -f1 |
		while read line; do
			echo "$target_file $line"
		done
}