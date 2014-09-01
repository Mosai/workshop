# File name pattern for test files
testsuite_file_pattern="*.test.sh"
# Saves the current shell command for future use
testsuite_current_shell=$(ps -o pid,comm 2>/dev/null | grep $$ | head -n1 | sed 's/.* //g')
# Some shells are reported with a dash 
testsuite_current_shell="${testsuite_current_shell#-}"

# Falls back to $SHELL when no valid command found
if [ -z "$(command -v "$testsuite_current_shell")" ]; then
	testsuite_current_shell="$SHELL"
fi

# Fixes incomplete ps output for the busybox sh
if [ "$testsuite_current_shell" = "busybox" ]; then
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
		          cov   [path]        Displays the code coverage for files used
		          list  [path]        Lists test functions in the specified path
		          exec  [file] [name] Run a single test by its file and name
		          help                Displays this message
	HELP
}

# Main function for the `testsuite run` report
testsuite_run ()
{
	target="$1"
	testsuite_list "$target" | testsuite_process run "$target"
}
# Executes a single test
testsuite_exec_run () ( testsuite_stack_collect "$1" "$2" "basename" )
# Reports a test file
testsuite_file_report_run () ( : )
# Reports a single unit
testsuite_unit_report_run ()
{
	test_file="$1"
	test_function="$2"
	returned="$3"
	results="$4"
		
	if [ $returned = 0 ]; then
		echo -n "."
	else
		echo -n "E"
	fi
}

# Main function for the `testsuite spec` report
testsuite_spec ()
{
	target="$1"
	testsuite_list "$target" | testsuite_process spec "$target"
}
# Executes a single test
testsuite_exec_spec () ( testsuite_stack_collect "$1" "$2" "basename" )
# Reports a test file
testsuite_file_report_spec ()
{
	cat <<-FILEHEADER

		### $current_file
	FILEHEADER
}
# Reports a single unit
testsuite_unit_report_spec ()
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

	cat <<-NAME | tr '_' ' '
		  - $test_status $test_function
	NAME

	testsuite_stack_format "$returned" "$results"
}

# Main function for the `testsuite cov` report
testsuite_cov ()
{
	target="$1"
	testsuite_list "$target" | testsuite_process cov "$target" |
	testsuite_post_cov
}
# Executes a single test
testsuite_exec_cov () ( testsuite_stack_collect "$1" "$2" "echo" )
# Reports a test file
testsuite_file_report_cov () ( : )
# Reports a single unit
testsuite_unit_report_cov ()
{
	test_file="$1"
	test_function="$2"
	returned="$3"
	results="$4"

	echo "$results"    | 
		sed '/^[^+]/d' |
		cut -d"	" -f2  |
		sed '/^:/d;/^\s*$/d;s/:/	/g'
}
# Post-processes unit stacks into coverage info
testsuite_post_cov ()
{
	unsorted="$(cat)"
	covered_files="$(echo "$unsorted" | cut -d"	" -f1 | sort | uniq)"

	for file in $covered_files; do
		if [ -f $file ]; then

			thisfile="$(echo "$unsorted" | grep "^$file")"

			IFS='' 
			sed '/./=' $file     | 
			sed '/./N; s/\n/ /'  | 
			while read file_line; do
				lineno="$(echo "$file_line" | cut -d" " -f1)"
				pureline="$(echo "$file_line" | cut -d" " -f2-)"
				matched="$(echo "$thisfile" | sed -n "/	$lineno$/p" | wc -l)"
				echo "$matched	$pureline"
			done
			IFS=
		fi
	done
}

# Run tests from a STDIN list
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

		results="$(testsuite_exec_$report_mode $test_parameters)"
		returned=$?

		testsuite_unit_report_$report_mode $test_parameters "$returned" "$results"

		if [ $returned = 0 ]; then
			passed_count=$((passed_count+1))
		fi

		last_file="$current_file"
	done

	if [ $total_count = 0 ]; then
		echo "No tests found on $target" 1>&2
		return 0
	fi

	cat <<-RESULT

		$passed_count tests out of $total_count passed.
	RESULT

	if [ "$passed_count" != "$total_count" ]; then
		return 1
	fi
}

# Formats a stack to be displayed
testsuite_stack_format ()
{
	returned="$1"
	results="$2"

	if [ $returned != 0 ]; then
		echo "$results"   |
		      sed '1d;$d' |
		      awk 'BEGIN{FS=OFS="\t"}{ printf "   %-4s %-20s %-30s\n", $1, $2, $3}'
	fi
}

# Executes a test passing a filter to the stack
testsuite_stack_collect ()
{
	test_file="$1"
	test_function="$2"
	file_filter="$3"

	# Loads the test file and executes the test in another shell instance

	testsuite_external "$test_file" "$test_function" "$file_filter" 2>&1 >/dev/null
	returned=$? # Return code for the test, saved for later

	return $returned
}

# Executes a file on a function using an external shell process
testsuite_external ()
{
	test_file="$1"
	test_function="$2"
	file_filter="$3"

	if [ z"$BASH_VERSION" != z ]; then
		trace_command="+	\$($file_filter \"\${BASH_SOURCE}\"):\${LINENO}	"
	elif [ "$testsuite_current_shell" = "pdksh" ]; then
		trace_command="+	\${LINENO}	"
	elif [ z"$KSH_VERSION" != z ]; then
		trace_command="+	\$($file_filter \"\${.sh.file}\"):\${LINENO}	"
	elif [ z"$ZSH_VERSION" != z ]; then
		trace_command="+	\$($file_filter \${(%):-%x:%I})	"
	else
		trace_command="+	\${LINENO}	"
	fi

	$testsuite_current_shell <<-EXTERNAL
		. "$test_file"
		current_file="$test_file"
		command -v setopt 2>&1 >/dev/null && setopt SH_WORD_SPLIT
		command -v setup 2>&1 >/dev/null  && setup "$test_file"
		command -v setopt 2>&1 >/dev/null && setopt PROMPT_SUBST
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

	if   [ -f "$target" ]; then
		testsuite_listfile "$target"
	elif [ -d "$target" ]; then
		testsuite_listdir "$target"
	fi
}

# Lists test functions for a specified dir
testsuite_listdir ()
{
	target_dir="$1"

	find "$target_dir" -type f -name "$testsuite_file_pattern" |
	grep -v "\.example\." |
	while read test_file; do
		testsuite_listfile "$test_file"
	done
}

# Lists test functions in a single file
testsuite_listfile ()
{
	target_file="$1"
	signature="/^\(test_[a-zA-Z0-9_]*\)\s*/p"

	cat "$target_file" | sed -n "$signature" | cut -d" " -f1 |
		while read line; do
			echo "$target_file $line"
		done
}
