# Global Options
trix_matrix_functions="matrix_"
trix_env_functions="env_"
trix_env_filter=".*"
trix_matrix_filter=".*"
trix_steps='setup script clean'

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

		. "$target_file"

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
		command_options="--matrix $matrix_entry --env \"\$TRIX_ENV\""

		cat <<-TRAVISYML
			# A courtesy of trix, a Mosai Workshop tool.
			# Generated from the $matrix_entry on $target_file

			install:
			  - $0 --steps="setup" $command_options run $target_file
			script:
			  - $0 --steps="script" $command_options run $target_file
			after_script:
			  - $0 --steps="clean" $command_options run $target_file
			matrix:
			  include:
		TRAVISYML

		. "$target_file"

		include () ( trix_spawn "" "$environments" "$@" )
		exclude () ( trix_spawn "" "$environments" "$@" )

		$matrix_entry | sort | uniq |
			while read entry; do
				trix_travis_entry "$entry"
			done

		break
	done
}

trix_travis_entry ()
{
	entry="$1"
	os=""
	vars_line=""


	var () ( trix_parsevar "" "$@" )

	for env_entry in $entry; do
		vars="$(${env_entry})"
		is_os_var="$(echo "$vars" | sed -n /TRAVIS_/p | wc -l)"

		if [ $is_os_var != 0 ]; then
			os="$(echo "$vars" | sed 's/TRAVIS_OS=//;s/"//g')"
		else
			vars_line="${vars_line}${vars}"
		fi

	done

	echo "    # Result environment:$vars_line"
	echo "    - env: TRIX_ENV=\"$entry\""
	echo "      os: $os"
	echo ""
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
	done |
	sed -n "/$trix_env_filter/p"
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
	excluded="$(echo "$entries" | grep "^-	" | sed "s/^[-]	//")"
	all_entries="$(echo "$entries" | sed "s/^[-+]	//")"

	echo "$all_entries" |
		trix_iterate_entries "$matrix_entry" "$excluded"
}

trix_iterate_entries ()
{
	matrix_entry="$1"
	excluded="$2"
	success_count=0
	total_count=0

	while read entry; do
		total_count=$((total_count+1))
		is_excluded="$(echo "$excluded" | sed -n "/$entry/p" | wc -l)"

		if [ $is_excluded -gt 0 ]; then
			continue
		fi

		previous_errmode="$(set +o | grep errexit)"
		set +e

		trix_process_entry "$matrix_entry" "$entry"

		if [ $? = 0 ]; then
			success_count=$((success_count+1))
		fi

		# Restore previous error mode
		$previous_errmode
	done

	printf \\n%s\\n "Totals: $success_count/$total_count envs passed."

	if [ $total_count != $success_count ]; then
		return 1
	fi
}

trix_process_entry ()
{
	matrix_entry="$1"
	TRIX_ENV="$2"
	script_passed=0

	include () ( : )
	exclude () ( : )
	setup   () ( : )
	script  () ( : )
	clean   () ( : )
	var     () ( trix_parsevar "export " "$@" )

	for env_setting in $TRIX_ENV; do
		eval "$($env_setting)"
	done

	$matrix_entry

	case $trix_steps in *"setup"*  ) : | setup  1>&2 ;; esac

	case $trix_steps in *"script"* )
		: | script
		script_passed=$?
		;;
	esac

	case $trix_steps in *"clean"*  ) : | clean  1>&2 ;; esac

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
	add_quotes="s/\(^[a-zA-Z0-9_]*=\)\(.*\)$/\1\"\2\" /"

	if [ $# = 0 ]; then
		return
	fi

	while [ $# -gt 0 ]; do
		piece="$(printf %s "$1" | sed "$add_quotes")"
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

	cat "$target_file"  |
	sed -n "$signature" |
	cut -d" " -f1       |
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
	trix_probe "$trix_matrix_functions" "$@" |
		sed -n "/$trix_matrix_filter/p"
}
