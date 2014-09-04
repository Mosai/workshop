depur_trace_function=
depur_exclude_file_pattern="\.test\.sh$"

# Dispatches commands to other depur_ functions
depur () ( depur_"$@" )

# Placeholder for empty calls
depur_ () ( echo "No command provided. Try 'depur help'" 1>&2 )

# Provides help
depur_help ()
{
	cat <<-HELP
		Usage: depur [command] [args...]
	HELP
}

depur_run ()
{
	interpreter="$1"
	shift
	cmdline="$@"

	PS4="$(depur_tracer "$interpreter" basename)" $interpreter -x $cmdline 2>&1
}

depur_full ()
{
	interpreter="$1"
	shift
	cmdline="$@"

	PS4="$(depur_tracer "$interpreter" echo)" $interpreter -x $cmdline 2>&1
}

depur_cov ()
{
	depur_full "$@" | depur_coverage
}

depur_tracer ()
{
	interpreter="$1"
	filter="$2"

	if [ -z "$depur_trace_function"]; then
		export depur_trace_function="$(depur_get_tracer "$interpreter" "$filter")"
	fi

	echo "$depur_trace_function"
}

depur_clean ()
{
	# Remove non-stack lines (stack lines start with +) 
	sed '/^[^+]/d'  |
	# Gets only the file:lineno column
	cut -d"	" -f2   | 
	# Removes empty lines and lines without file names,
	# change the : into a tab.
	sed '/^:/d;   /^[	 ]*$/d;   s/:/	/' 
}

depur_coverage ()
{
	# Should contain a list of files and lines covered
	unsorted="$(depur_clean)"
	# Gets an unique list of files
	covered_files="$(echo "$unsorted" | cut -d"	" -f1 | sort | uniq)"

	for file in $covered_files; do

		file="$(echo "$file" | sed "/$depur_exclude_file_pattern/d")"
		if [ ! -z "$file" ] && [ -f $file ]; then

			cat <<-FILEHEADER

				### $file

			FILEHEADER

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
				depur_covline "$lineno" "$pureline" "$matched" "$file"
			done
			IFS= # Restore separator
		fi
	done
}


depur_covline ()
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
		echo "    -	$pureline"
		return
	fi

	echo "    $matched	$pureline"
}


depur_get_tracer ()
{
	interpreter="$1"
	filter="${2:-basename}"

	$interpreter <<-EXTERNAL 
		if [ z"\$BASH_VERSION" != z ]; then
			echo "+	\\\$($filter \"\\\${BASH_SOURCE}\"):\\\${LINENO:-0}	"
		elif [ z"\$(echo "\$KSH_VERSION" | sed -n '/93/p')" != z ]; then
			echo "+	\\\$($filter \"\\\${.sh.file}\"):\\\${LINENO:-0}	"
		elif [ z"\$ZSH_VERSION" != z ]; then
			echo "+	\\\$($filter \\\${(%):-%x:%I})	"
		else
			echo "+	:\\\${LINENO:-0}	" # Fallback
		fi
	EXTERNAL
}

depur_format ()
{
	echo ""
	# Removes the first line
	sed '1d' | 
	# Displays the stack in aligned columns
	awk 'BEGIN{FS=OFS="\t"}{ printf "        %-4s %-20s %-30s\n", $1, $2, $3}'
	echo ""
}

