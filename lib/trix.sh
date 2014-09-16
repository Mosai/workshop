# Dispatches commands to other trix_ functions
trix () ( dispatch trix "$@" )

trix_matrix_functions="matrix_"
trix_env_functions="env_"
trix_env_filter=".*"
trix_matrix_filter=".*"

# Provides help
trix_command_help ()
{
	cat <<-HELP
	   Usage: trix [option_list...] [command]
	          trix help, -h, --help [command]  Displays help for command.

	Commands: run    [file]  Runs the target matrix file
	          list   [file]  Lists all tested environments

	 Options: --env    [name]  Runs only the selected environment
	          --matrix [name]  Runs only the selected matrix

	HELP
}

trix_option_help   () ( trix_command_help )
trix_option_h      () ( trix_command_help )
trix_option_env    () ( trix_env_filter="$1";    shift && dispatch trix "$@" )
trix_option_matrix () ( trix_matrix_filter="$1"; shift && dispatch trix "$@" )

trix_      () ( echo "No command provided. Try 'trix --help'"; return 1 )
trix_call_ () ( echo "Call '$@' invalid. Try 'trix --help'";   return 1 )

trix_command_run ()
{
	target_file="$1"
	environments="$(trix_probe_env "$target_file")"

	trix_probe_matrix "$target_file" | 
		while read matrix_entry; do
			trix_process "$target_file" "$matrix_entry"
		done
}

trix_command_list ()
{
	target_file="$1"
	environments="$(trix_probe_env "$target_file")"

	trix_probe_matrix "$target_file" | 
		while read matrix_entry; do

			. $target_file

			include () ( trix_spawn "run" "$environments" "$@" )
			exclude () ( trix_spawn "skip" "$environments" "$@" )

			$matrix_entry | sort | uniq

		done
}

trix_spawn ()
{
	mode="$1"
	environments="$2"
	spawned=""
	shift 2

	for spawn_entry in $@; do
		grouped="$(echo "$environments" | grep "$spawn_entry")"
		if [ -z "$spawned" ]; then
			spawned="$grouped"
		else
			spawned="$(trix_spawn_merge "$spawned" $grouped)"
		fi
	done 

	echo "$spawned" |
		while read full_entry; do
			echo "$mode	$full_entry"
		done | sed -n "/$trix_env_filter/p"
}

trix_spawn_merge ()
{
	spawned="$1"
	shift

	echo "$spawned" |
		while read spawned_line; do
			for grouped_entry in $@; do
				echo "$spawned_line $grouped_entry"
			done
		done
}

trix_process ()
{
	target_file="$1"
	matrix_entry="$2"

	. $target_file

	include () ( trix_spawn "+" "$environments" "$@" )
	exclude () ( trix_spawn "-" "$environments" "$@" )

	entries="$($matrix_entry | sort | uniq)"
	exclusions="$(echo "$entries" | grep "^-	" | sed "s/^[-]	//")"
	all_entries="$(echo "$entries" | sed "s/^[-+]	//")"

	echo "$all_entries" |
		while read entry; do

			was_excluded="$(echo "$exclusions" | sed -n "/$entry/p" | wc -l)"

			if [ $was_excluded -gt 0 ]; then
				continue
			fi

			trix_process_entry "$matrix_entry" "$entry"
		done
}

trix_process_entry ()
{
	matrix_entry="$1"
	entry="$2"

	include () ( : )
	exclude () ( : )
	setup   () ( : )
	script  () ( : )
	clean   () ( : )
	var     () ( trix_parsevar "$@" )

	for env_setting in $entry; do
		eval "$($env_setting)"
	done

	echo "### $matrix_entry: $entry"
	$matrix_entry
	: | setup
	: | script
	: | clean

	unset -f include
	unset -f exclude
	unset -f setup
	unset -f script
	unset -f clean
}

trix_parsevar ()
{
	if [ $# -gt 0 ]; then
		echo -n "export "
	fi
	while [ $# -gt 0 ]; do
		echo -n "$1" | sed "s/\(^[a-zA-Z0-9_]*=\)\(.*\)$/\1\"\2\" /"
		shift
	done
}

trix_probe ()
{
	identifier="$1"
	target_file="$2"
	signature="/^\(\(${identifier}\)[a-zA-Z0-9_]*\)[	 ]*/p"

	cat "$target_file" | sed -n "$signature" | cut -d" " -f1 |
		while read line; do
			echo "$line"
		done
}

trix_probe_env () 
{
	trix_probe "$trix_env_functions" "$@" 
}

trix_probe_matrix () 
{
	trix_probe "$trix_matrix_functions" "$@"| sed -n "/$trix_matrix_filter/p"
}