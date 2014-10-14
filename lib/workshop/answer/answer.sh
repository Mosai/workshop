# Global Options
answer_cr=$(printf '\r')   # A plain carriage return
answer_esc=$(printf '\33') # A plain ESC character
answer_oldterm=''          # Contains the previous terminal state when changed
answer_tryfocus=-1         # Current widget trying to be focused
answer_total=0             # Total number of widgets
answer_chosen=''           # Text for the chosen widget
answer_length=50           # Line length

# Gets an answer from a input specification list
answer_command_get ()
{
	answer_tryfocus=-1
	answer_total=0
	answer_chosen=''
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
				answer_focus "$widgets" $((answer_tryfocus+1))
				;;
			"${k}D" | "${k}OD" ) # LEFT
				answer_focus "$widgets" $((answer_tryfocus-1))
				;;
			"$answer_cr"       ) # ENTER
				answer_choose "$widgets" "$answer_tryfocus"
				return
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
answer_end () ( stty "$answer_oldterm" )

# Prints a line of widgets and focus one of them by its id.
answer_focus ()
{
	widgets="$1"
	chosen_focus="$2"
	answer_length="$(stty size <&2 | cut -d" " -f2)"

	# Loops until a widget is focusable
	is_focusable=''
	while :; do

		# Widgets start on 1, so we skip 0
		if [ "$chosen_focus" -gt 0 ]; then
			is_focusable="$(echo "$widgets" |
			     sed -n "${chosen_focus}p"  |
			     tr -d "$answer_cr"         |
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
		if [ "$chosen_focus" -gt "$answer_tryfocus" ]; then
			chosen_focus=$((chosen_focus+1))
		elif [ "$chosen_focus" -lt "$answer_tryfocus" ]; then
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
	   [ "$answer_tryfocus" = -1 ];then
		answer_end; return
	fi

	# If the focus is the same, does nothing
	if [ "$chosen_focus" = "$answer_tryfocus" ] ||
	   [ -z "$is_focusable" ]; then
		return
	fi

	answer_tryfocus="$chosen_focus"

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
	widgets_length=0

	# Loops through widgets from stdin
	while read widget; do
		widget="$(printf %s "${widget}" | tr -d "$answer_cr")"
		widget_length="${#widget}"
		widgets_length=$((widgets_length+widget_length+1))

		if [ $widgets_length -gt $((answer_length)) ]; then
			if [ "$current_focus" -gt $((rendering)) ]; then
				widgets_length=$((widget_length+2))
				printf '\033[2K\r'
				printf %s "< "
			else
				widgets_length=$((widgets_length-widget_length+2))
				printf %s " >"
				break
			fi
		fi

		rendering=$((rendering+1))

		# Focused widget
		if [ "$current_focus" = "$rendering" ]; then
			printf "\033[7m${widget}\033[0m "
		# Unfocused
		else
			printf "${widget} "
		fi
	done
}

# Prints the output answer for a widget and ends
answer_choose ()
{
	widgets="$1"
	answer_tryfocus="$2"

	printf '\033[2K\r'

	export answer_chosen="$(printf "$widgets" |
		sed -n "${answer_tryfocus}p"          | # Finds current widget
		sed 's/\[ \(.*\) \]/\1/g'            | # Removes decorations
		tr -d "$answer_cr"
	)"

	printf %s\\r\\n  "$answer_chosen"

	answer_end; return            # Resets terminal and ends
}

answer_command_menu ()
{
	menu_answer="$1:"
	menu_entries="Exit	exit"
	nl="
"

	while read menu_entry; do
		menu_button="$(echo "$menu_entry" | cut -d "	" -f1)"
		menu_answer="${menu_answer}|[ $menu_button ]"
		menu_entries="${menu_entries}${nl}${menu_entry}"
	done

	while :; do
		answer_command_get "$menu_answer|[ Exit ]" < /dev/tty
		answer_match="$(echo "$menu_entries" | sed -n "/^${answer_chosen}/p" | cut -d"	" -f2)"
		if [ "$answer_match" = "exit" ]; then
			break
		fi

		if [ ! -z "$answer_match" ]; then
			$answer_match
			break
		fi
	done
}
