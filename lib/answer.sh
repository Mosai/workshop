answer_cr=$(printf '\r')
answer_esc=$(printf '\33')
answer_oldterm=''
answer_focused=-1
answer_total=0

answer () ( dispatch answer "$@" )

# Provides help
answer_command_help ()
{
	cat <<-HELP
	   Usage: answer [option_list...] [command]
	          answer help, -h, --help [command] Displays help for command.

	Commands: get  [spec] Gets an answer from a specification list

	Spec: A spec is a string containing elements separated by a pipe "|".
	      Buttons are enclosed by square brackets '[ A Button ]'
	      Labels are just plain text.

	Examples: answer get 'Continue?|[ yes ]|[ no ]'

	HELP
}

# Options
answer_option_help () ( answer_command_help )
answer_option_h    () ( answer_command_help )

# Gets an answer from a input specification list
answer_command_get ()
{
	question="$1"
	shift

	# Gets each widget on a line
	widgets="$(answer_widgets "$question")"
	# Total number of elements
	answer_total="$(echo "$widgets" | wc -l)"

	# Saves old terminal settings and start receiving raw keyboard input
	answer_oldterm="$(stty -g)"
	stty raw -echo || exit

	# Restore old terminal settings if the script ends
	trap "answer_end; exit" 1 2 15

	# Starts the focus process
	answer_focus "$widgets" 0

	k="K["       # Marker used to identify escape sequences
	keybuffer='' # This buffer holds escape sequences for special keys
	while true; do
		# Gets a single byte from stdin, probably the keyboard
		byte="$(dd bs=1 count=1 2>/dev/null)"
		keypressed="$byte"

		case "$keypressed" in
			# Starts to buffer an escape sequence
			$answer_esc )
				keybuffer="K" # Stores the marker prefix
				keypressed=''
				;;
			# Ends the escape sequence buffer using common
			# characters
			"" | [a-zA-NP-Z~^\$@$answer_esc] )
				if [ ! -z "$keybuffer" ]; then
					keypressed="${keybuffer}${keypressed}"
					keybuffer=''
				fi
				;;
			# Buffers additional characters in the escape sequence
			* )
				if [ ! -z "$keybuffer" ]; then
					keybuffer="${keybuffer}${keypressed}"
					keypressed=''
				fi
				;;
		esac

		# Chooses what to do with the key pressed
		case "$keypressed" in
			"${k}C" | "${k}OC" ) # RIGHT
				answer_focus "$widgets" $((answer_focused+1))
				;;
			"${k}D" | "${k}OD" ) # LEFT
				answer_focus "$widgets" $((answer_focused-1))
				;;
			"$answer_cr"       ) # ENTER
				answer_choose "$widgets" "$answer_focused"
				;;
			"$byte"            ) # CHAR

				;;
			*                  ) # UNKNOWN

				;;
		esac

	done

	# Clears the raw terminal settings and return
	answer_end
}

# Gets widgets from a spec one in each line
answer_widgets ()
{
	answer="$1"
	# Needs an unindented line in order to work on OS X sed :(
	echo "$answer" |
	sed 's/|/\
'$answer_cr'/g'
}

# Restores old terminal settings and prints a new line
answer_end () ( stty "$answer_oldterm"; printf %s\\n )

# Prints a line of widgets and focus one of them by its id.
answer_focus ()
{
	widgets="$1"
	chosen_focus="$2"

	# Loops until a widget is focusable
	is_focusable=''
	while :; do

		# Widgets start on 1, so we skip 0
		if [ "$chosen_focus" -gt 0 ]; then
			is_focusable="$(echo "$widgets"   |
			     sed -n "${chosen_focus}p" |
			     tr -d "$answer_cr"        |
			     sed -n '
				/^ *\[/p
			     ')"
		fi

		# Stops if the widget found is focusable
		if [ ! -z "$is_focusable" ]; then
			break
		fi

		# Finds if this widget is before or after the last focused
		# in order to properly skip unfocusable widgets in the
		# right order
		if [ "$chosen_focus" -gt "$answer_focused" ]; then
			chosen_focus=$((chosen_focus+1))
		elif [ "$chosen_focus" -lt "$answer_focused" ]; then
			chosen_focus=$((chosen_focus-1))
		fi

		# Finds if we reached the end of the widget list
		if [ "$chosen_focus" -gt $((answer_total+1)) ] ||
		   [ "$chosen_focus" -lt 1 ]; then
		   break
		fi
	done

	# Ends if no focusable widget is found
	if [ "$chosen_focus" -gt $((answer_total)) ] &&
	   [ "$answer_focused" = -1 ];then
		answer_end; exit
	fi

	# If the focus is the same, does nothing
	if [ "$chosen_focus" = "$answer_focused" ] ||
	   [ -z "$is_focusable" ]; then
		return
	fi

	answer_focused="$chosen_focus"

	# Erases the entire line
	printf '\033[2K\r'
	# Prints the new line
	echo "$widgets" | answer_focus_render "$chosen_focus"


}

# Renders the actual widgets from answer_focus
answer_focus_render ()
{
	current_focus="$1"
	rendering=0 # Current widget id

	# Loops through widgets from stdin
	while read widget; do
		rendering=$((rendering+1))

		# Focused widget
		if [ "$current_focus" = "$rendering" ]; then
			printf "\033[7m ${widget} \033[0m" | tr -d "$answer_cr"
		# Unfocused
		else
			printf " ${widget} " | tr -d "$answer_cr"
		fi
	done
}

# Prints the output answer for a widget and ends
answer_choose ()
{
	widgets="$1"
	answer_focused="$2"

	# Erases the entire line
	printf '\033[2K\r'

	printf "$widgets"           |
	sed -n "${answer_focused}p" | # Finds the current widget
	sed 's/\[ \(.*\) \]/\1/g'     # Removes decorations from answer

	answer_end; exit              # Resets terminal and ends
}
