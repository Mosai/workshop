# Dispatches commands to other trix_ functions
trix () ( dispatch trix "$@" )

trix_matrix_functions="matrix_"
trix_env_functions="env_"

# Provides help
trix_command_help ()
{
	cat <<-HELP
	   Usage: trix run [file] Run a matrix file
	HELP
}

trix_      () ( echo "No command provided. Try 'trix --help'"; return 1 )
trix_call_ () ( echo "Call '$@' invalid. Try 'trix --help'";   return 1 )

trix_command_run ()
{
	target_file="$1"
	environments="$(trix_probe "$target_file" $trix_env_functions)"

	trix_probe $1 $trix_matrix_functions | 
		while read matrix_entry; do
			trix_process "$target_file" "$matrix_entry"
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

	echo "$spawned" | while read full_entry; do
		echo "$mode	$full_entry"
	done
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
		done
}

trix_parsevar ()
{
	while [ $# -gt 0 ]; do
		echo "$1" | sed "s/\(^[a-zA-Z0-9_]*=\)\(.*\)$/export \1\"\2\"/"
		shift
	done
}

trix_probe ()
{
	target_file="$1"
	identifier="$2"
	signature="/^\(\(${identifier}\)[a-zA-Z0-9_]*\)[	 ]*/p"

	cat "$target_file" | sed -n "$signature" | cut -d" " -f1 |
		while read line; do
			echo "$line"
		done
}