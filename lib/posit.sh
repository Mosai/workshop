# File name pattern for test files
posit_file_pattern="*.test.sh"	

# Dispatches commands to other posit_ functions
posit () ( posit_"$@" )

# Placeholder for empty calls
posit_ () ( echo "No command provided. Try 'posit help'" 1>&2; return 1 )

# Provides help
posit_help ()
{
	cat <<-HELP
		Usage: posit [command]

		Commands: run   [path]        Run tests for the specified path
		          spec  [path]        Run tests and display results as specs
		          cov   [path]        Displays the code coverage for files used
		          list  [path]        Lists test functions in the specified path
		          exec  [file] [name] Run a single test by its file and name
		          help                Displays this message
	HELP
}

# Main function for the `posit run` report
posit_run ()
{
	target="$1"
	posit_list "$target" | posit_process run "$target"
}
# Executes a single test
posit_exec_run () ( posit_stack_collect "$1" "$2" "basename" )
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
	target="$1"
	posit_list "$target" | posit_process spec "$target"
}
# Executes a single test
posit_exec_spec () ( posit_stack_collect "$1" "$2" "basename" )
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
	posit_stack_format "$returned" "$results"
}

# Main function for the `posit cov` report
posit_cov ()
{
	target="$1"
	posit_list "$target" | posit_process cov "$target" |
	posit_post_cov
}
# Executes a single test
posit_exec_cov () ( posit_stack_collect "$1" "$2" "echo" )
# Reports a test file
posit_file_report_cov () ( : )
# Reports a single unit
posit_unit_report_cov ()
{
	results="$4"

	echo "$results"    |
		# Remove non-stack lines (stack lines start with +) 
		sed '/^[^+]/d' |
		# Gets only the file:lineno column
		cut -d"	" -f2  | 
		# Removes empty lines and lines without file names,
		# change the : into a tab.
		sed '/^:/d;   /^\s*$/d;   s/:/	/' 
}
# Post-processes unit stacks into coverage info
posit_post_cov ()
{
	# Should contain a list of files and lines covered
	unsorted="$(cat)"
	# Gets an unique list of files
	covered_files="$(echo "$unsorted" | cut -d"	" -f1 | sort | uniq)"

	for file in $covered_files; do
		if [ -f $file ]; then

			# Gets lines only for this file
			thisfile="$(echo "$unsorted" | grep "^$file")"

			IFS='' 					# Read line by line, not separator
			sed '/./=' $file     |  # Number lines on file
			sed '/./N; s/\n/ /'  |  # Format numbered lines
			while read file_line; do
				# Current line number
				lineno="$(echo "$file_line" | cut -d" " -f1)"
				# Full line text
				pureline="$(echo "$file_line" | cut -d" " -f2-)"
				# Number of matches on this line
				matched="$(echo "$thisfile" | sed -n "/	$lineno$/p" | wc -l | sed "s/[	 ]*//")"
				# Formatted number of matched lines <tab> the file line
				posit_post_cov_line "$lineno" "$pureline" "$matched" "$file"
			done
			IFS= # Restore separator
		fi
	done
}

posit_post_cov_line ()
{
	lineno="$1"
	pureline="$2"
	matched=$3
	file="$4"

	# Ignore comment lines
	if [ -z "$(echo "$pureline" | sed '/^[	 ]*#/d')" ]        ||
	# Ignore lines with only a '{'
	   [ -z "$(echo "$pureline" | sed '/^[	 ]*{[	 ]*$/d')" ]    ||
	# Ignore lines with only a '}'
	   [ -z "$(echo "$pureline" | sed '/^[	 ]*}[	 ]*$/d')" ]    ||
	# Ignore lines with only a 'fi'
	   [ -z "$(echo "$pureline" | sed '/^[	 ]*fi[	 ]*$/d')" ]   ||
	# Ignore lines with only a 'done'
	   [ -z "$(echo "$pureline" | sed '/^[	 ]*done[	 ]*$/d')" ] ||
	# Ignore lines with only a 'else'
	   [ -z "$(echo "$pureline" | sed '/^[	 ]*else[	 ]*$/d')" ] ||
	# Ignore lines with only a function declaration
	   [ -z "$(echo "$pureline" | sed '/^[	 ]*[a-zA-Z0-9_]*[	 ]*()$/d')" ] ||
	# Ignore blank lines
	   [ -z "$(echo "$pureline" | sed '/^[	 ]*$/d')" ]; then
		echo "-	$(basename $file)	$pureline"
		return
	fi

	echo "$matched	$(basename $file)	$pureline"
}

# Run tests from a STDIN list
posit_process ()
{
	report_mode="$1"
	target="$2"
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
		results="$(posit_exec_$report_mode $test_parameters)"
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

# Formats a stack to be displayed
posit_stack_format ()
{
	returned="$1"
	results="$2"

	if [ $returned != 0 ]; then
		echo "$results"   |
			  # Removes the first and last lines
		      sed '1d;$d' | 
		      # Displays the stack in aligned columns
		      awk 'BEGIN{FS=OFS="\t"}{ printf "   %-4s %-20s %-30s\n", $1, $2, $3}'
	fi
}

# Executes a test passing a filter to the stack
posit_stack_collect ()
{
	test_file="$1"
	test_function="$2"
	file_filter="$3"

	posit_external "$test_file" "$test_function" "$file_filter" 2>&1
	
	return $?
}

# Executes a file on a function using an external shell process
posit_external ()
{
	test_file="$1"
	test_function="$2"
	file_filter="$3"

	posit_find_current_shell

	# Find out command to get file/line information on PS4 for
	# each shell
	if [ z"$BASH_VERSION" != z ]; then
		trace_command="+	\$($file_filter \"\${BASH_SOURCE}\"):\${LINENO}	"
	elif [ "$posit_current_shell" = "pdksh" ]; then
		trace_command="+	[unknown]:\${LINENO}	"
	elif [ "$posit_current_shell" = "mksh" ]; then
		trace_command="+	[unknown]:\${LINENO}	"
	elif [ z"$KSH_VERSION" != z ]; then
		trace_command="+	\$($file_filter \"\${.sh.file}\"):\${LINENO}	"
	elif [ z"$ZSH_VERSION" != z ]; then
		trace_command="+	\$($file_filter \${(%):-%x:%I})	"
	else
		trace_command="+	[unknown]:\${LINENO}	" # Fallback
	fi

	# Executes the shell in a separate process
	$posit_current_shell <<-EXTERNAL
		# Enables compatibility options when needed
		command -v setopt 2>/dev/null >/dev/null && setopt PROMPT_SUBST SH_WORD_SPLIT

		current_file="$test_file" # Stores the current file
		PS4='$trace_command'      # Injects the debug prompt
		set -x                    # Enables debugging
		. "$test_file"            # Loads the file
		$test_function            # Executes the function
		has_passed=\$?            # Stores the returned code
		set +x                    # Disables debugging
		exit \$has_passed         # Exits with the test results

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

posit_find_current_shell () 
{
	if [ -z "$posit_current_shell" ]; then
		# File name pattern for test files
		posit_file_pattern="*.test.sh"
		# Saves the current shell command for future use
		posit_current_shell=$(ps -o pid,comm 2>/dev/null | grep $$ | head -n1 | sed 's/.* //g')
		# Some shells are reported with a dash 
		posit_current_shell="${posit_current_shell#-}"

		# Falls back to $SHELL when no valid command found
		if [ -z "$(command -v "$posit_current_shell")" ]; then
			posit_current_shell="$SHELL"
		fi

		# Fixes incomplete ps output for the busybox sh
		if [ "$posit_current_shell" = "busybox" ]; then
			posit_current_shell="busybox sh"
		fi

		export posit_current_shell="$posit_current_shell"
	fi
}
