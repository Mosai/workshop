
# Single execution for the "tiny" report
posit_exec_tiny () ( posit_external "$1" "$2" "--short" 2>/dev/null )
# Filter for the overall test output on mode "tiny"
posit_all_tiny  () ( posit_process "$1" )
# Header for each file report on mode "tiny"
posit_head_tiny () ( : )
# Report for each unit on mode "tiny"
posit_unit_tiny ()
{
	returned_code="$3"

	([ "$returned_code" = 0 ] && echo -n "." ) || # . for pass
	([ "$returned_code" = 3 ] && echo -n "S" ) || # S for skip
	echo -n "F"                                   # F for failure
}
# Count report for the "tiny" mode
posit_count_tiny ()
{
	passed="$1"
	total="$2"
	skipped="$3"

	([ "$total"   -gt 0 ] && echo -n " $passed/$total passed.") ||
	echo -n "No tests found."

	([ "$skipped" -gt 0 ] && echo -n " $skipped/$total skipped.")
	echo ""
}

