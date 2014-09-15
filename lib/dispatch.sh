# Dispatches calls of commands and arguments
dispatch ()
{
	namespace="$1"     # Namespace to be dispatched
	arg="$2"           # First argument
	short="${arg#*-}"  # First argument without trailing -
	long="${short#*-}" # First argument without trailing --

	# Exit and warn if no first argument is found
	if [ -z "$arg" ]; then 
		${namespace}_ # Call empty call placeholder
		return 1
	fi

	shift 2 # Remove namespace and first argument from $@

	# Detects if a command, --long or -short option was called
	if [ "$arg" = "--$long" ];then
		main_call=${namespace}_option_${long}
	elif [ "$arg" = "-$short" ];then
		main_call=${namespace}_option_${short}
	else
		main_call=${namespace}_command_${long}
	fi

	# Warn if dispatched function not found
	if ! command -v "$main_call" 1>/dev/null 2>/dev/null; then
		${namespace}_call_ $namespace $arg # Empty call placeholder
		return 1
	fi

	$main_call "$@"
}