posit_filter_cov () ( echo "echo" )
posit_exec_cov   () ( posit_external "$1" "$2" 2>&1 )
posit_all_cov    ()
{
	posit_process "$1" |
	depur_ignore="$posit_files" depur_command_coverage
}
posit_head_cov   () ( : )
posit_unit_cov   () ( echo "$4" )
posit_count_cov  () ( posit_count_spec "$@" )
