# Global option defaults
posit_files=".test.sh"  # File name pattern for test files
posit_functions="test_"
posit_mode="tiny"        # Reporting mode to be used
posit_shell="sh"         # Shell used to tiny the isolated tests
posit_fast="-1"          # Fails fast. Use -1 to turn off
posit_silent="-1"        # Displays full stacks. Use -1 to turn off
posit_timeout="3"        # Timeout for each test
posit_timer=''
posit_tracer=''

# Lists tests in the specified target path
posit_command_list ()
{
	([ -f "$1" ] && posit_listfile "$1") ||
	([ -d "$1" ] && posit_listdir  "$1")
}

# Run tests for the specified target path
posit_command_run ()
{
	posit_command_list "$1"      | # Lists all tests for the path
	"posit_all_${posit_mode}" "$1"   # Processes the tests
}

# Run tests from a STDIN list
posit_process ()
{
	mode="$posit_mode"
	passed_count=0
	total_count=0
	last_file=""
	skipped_count="0"
	# Stores the previous error mode
	previous_errmode="$(set +o | grep errexit)"
	filter="$(posit_filter_$mode)"

	# If not silent
	if [ "$posit_silent" = "-1" ]; then
		posit_tracer="$(depur_filter="$filter" "depur_command_tracer"\
			"$posit_shell")"
	fi
	# If timeout command is present, use it
	if [ "$posit_timeout" != 0 ]; then
		posit_timer="$(posit_get_timer)"
	fi

	# Each line should have a file and a test function on that file
	while read test_parameters; do
		test_file="$(echo "$test_parameters" | cut -d " " -f1)"
		test_func="$(echo "$test_parameters" | cut -d " " -f2)"
		total_count=$((total_count+1))
		results='' # Resets the results variable
		skipped_return=3

		# Detects when tests should skip
		if [ "$skipped_count" -gt "0" ]; then
			skipped_count=$((skipped_count+1))
			"posit_unit_$mode" "$test_file" "$test_func"\
					   "$skipped_return" "$results"
			continue
		fi

		# Don't exit on errors
		set +e
		# Runs a test and stores results
		results="$(: | "posit_exec_$mode" "$test_file" "$test_func")"
		# Stores the returned code
		returned=$?
		# Restore previous error mode
		$previous_errmode

		# Displays a header when the file changes
		[ "$test_file" != "$last_file" ] &&
		"posit_head_$mode" "$test_file"

		# Run the customized report
		"posit_unit_$mode" "$test_file" "$test_func"\
				   "$returned" "$results"

		if [ $returned = 0 ]; then
			passed_count=$((passed_count+1))
		elif [ "$posit_fast" = "1" ];then
			# Starts skipping if fail fast was enabled
			skipped_count=1
		fi

		last_file="$test_file"
	done

	# Display results counter
	"posit_count_$mode" $passed_count $total_count $skipped_count

	if [ "$passed_count" != "$total_count" ]; then
		return 1
	fi
}

posit_get_timer ()
{
	if [ -z "$posit_timer" ] &&
	   command -v timeout 2>/dev/null 1>/dev/null; then

		# Checks if this timeout version uses -t for duration
		if [ z"$(timeout -t0 printf %s 2>&1)" != z"" ]; then
			posit_timer="timeout $posit_timeout"
		else
			posit_timer="timeout -t $posit_timeout"
		fi
	fi

	echo "$posit_timer"
}

# Executes a file on a function using an external shell process
posit_external ()
{
	test_file="$1"
	test_func="$2"
	test_dir="$(dirname "$1")"
	shell="$posit_shell"
	test_command="$posit_timer $posit_shell"

	# If not silent
	if [ "$posit_silent" = "-1" ]; then
		test_command="$test_command -x"
	fi

	# Declares env variables and executes the test in
	# another environment.
	PS4="$posit_tracer"             \
	POSIT_CMD="$shell"              \
	POSIT_FILE="$test_file"         \
	POSIT_DIR="$test_dir"           \
	POSIT_FUNCTION="$test_func"     \
	$test_command <<-EXTERNAL
		# Compat options for zsh
		setopt PROMPT_SUBST SH_WORD_SPLIT >/dev/null 2>&1 || :

		setup    () ( : )   # Placeholder setup function
		teardown () ( : )   # Placeholder teardown function
		. "\$POSIT_FILE"    # Loads the tested file
		setup               # Calls the setup function
		\$POSIT_FUNCTION && # Calls the tested function
		has_passed=\$?   || # Stores the result from the test
		has_passed=\$?
		teardown            # Calls the teardown function
		exit \$has_passed   # Exits with the test status
	EXTERNAL
}

# Lists test functions for a specified dir
posit_listdir ()
{
	target_dir="$1"

	find "$target_dir" -type f |
	grep "$posit_files"        |
	while read test_file; do
		posit_listfile "$test_file"
	done
}

# Lists test functions in a single file
posit_listfile ()
{
	target_file="$1"
	signature="/^\(${posit_functions}[a-zA-Z0-9_]*\)[	 ]*/p"

	cat "$target_file"  |
	sed -n "$signature" |
	cut -d" " -f1       |
	while read line; do
		echo "$target_file $line"
	done
}

