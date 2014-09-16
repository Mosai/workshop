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

	trix_probe_matrix "$target_file" | trix_iterate_matrix
}

trix_iterate_matrix ()
{
	run_passed=0

	while read matrix_entry; do
		trix_process "$target_file" "$matrix_entry"
		
		if [ $? != 0 ]; then
			run_passed=1
		fi
	done

	return $run_passed
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

trix_command_travis ()
{
	target_file="$1"
	environments="$(trix_probe_env "$target_file")"

	trix_probe_matrix "$target_file" | 
		while read matrix_entry; do

			cat <<-TRAVISYML
				# A courtesy of trix, a Mosai Workshop tool.
				# Generated from the $matrix_entry on $target_file

				script: 
				  - $0 --matrix $matrix_entry --env "\$TRIX_ENV" run $target_file
				matrix:
				  include:
			TRAVISYML

			. $target_file

			include () ( trix_spawn "" "$environments" "$@" )
			exclude () ( trix_spawn "" "$environments" "$@" )
			var     () ( trix_parsevar "" "$@" )

			$matrix_entry | sort | uniq | 
				while read entry; do
					os=""
					entry_vars_line=""

					for env_entry in $entry; do
						env_entry_vars="$(${env_entry})"
						env_is_travis="$(echo "$env_entry_vars" | sed -n /TRAVIS_/p | wc -l)"

						if [ $env_is_travis != 0 ]; then
							os="$(echo "$env_entry_vars" | sed 's/TRAVIS_OS=//; s/"//g')"
						else
							entry_vars_line="${entry_vars_line}${env_entry_vars}"
						fi

					done

					echo "    # Result environment:$entry_vars_line"
					echo "    - env: TRIX_ENV=\"$entry\""
					echo "      os: $os"
					echo ""

				done

			break
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

	echo "$all_entries" | trix_iterate_entries "$matrix_entry" "$exclusions"
}

trix_iterate_entries ()
{
	matrix_entry="$1"
	exclusions="$2"
	process_passed=0

	while read entry; do
		was_excluded="$(echo "$exclusions" | sed -n "/$entry/p" | wc -l)"

		if [ $was_excluded -gt 0 ]; then
			continue
		fi

		trix_process_entry "$matrix_entry" "$entry"

		if [ $? != 0 ]; then
			process_passed=1
		fi
	done

	return $process_passed
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
	var     () ( trix_parsevar "export " "$@" )

	for env_setting in $entry; do
		eval "$($env_setting)"
	done

	echo "### $matrix_entry: $entry"
	$matrix_entry
	: | setup
	: | script
	script_passed=$?
	: | clean

	unset -f include
	unset -f exclude
	unset -f setup
	unset -f script
	unset -f clean

	return $script_passed
}

trix_parsevar ()
{
	prefix="$1"
	shift
	parsedvar="${prefix} "
	
	if [ $# = 0 ]; then
		return
	fi

	while [ $# -gt 0 ]; do
		piece="$(printf %s "$1" | sed "s/\(^[a-zA-Z0-9_]*=\)\(.*\)$/\1\"\2\" /")"
		parsedvar="${parsedvar}${piece}"
		shift
	done

	echo "$parsedvar"
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