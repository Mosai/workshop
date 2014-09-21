answer_cr=$(printf '\r')
answer_esc=$(printf '\33')
answer_oldterm=''
answer_focused=-1
answer_total=0

answer_widgets ()
{
	answer="$1"
	echo "$answer" |
	sed 's/|/\
'$answer_cr'/g'
}

answer_end () ( stty "$answer_oldterm"; printf %s\\n )

answer_focus ()
{
	widgets="$1"
	chosen_focus="$2"

	focusable=''
	while :; do

		if [ "$chosen_focus" -gt 0 ];then
			focusable="$(echo "$widgets"   |
			     sed -n "${chosen_focus}p" |
			     tr -d "$answer_cr"        |
			     sed -n '
				/^ *\[/p
			     ')"
		fi

		if [ ! -z "$focusable" ]; then
			break
		fi

		if [ "$chosen_focus" -gt "$answer_focused" ]; then
			chosen_focus=$((chosen_focus+1))
		elif [ "$chosen_focus" -lt "$answer_focused" ]; then
			chosen_focus=$((chosen_focus-1))
		fi

		if [ "$chosen_focus" -gt $((answer_total+1)) ] ||
		   [ "$chosen_focus" -lt 1 ]; then
		   break
		fi
	done


	if [ "$chosen_focus" -gt $((answer_total)) ] &&
	   [ "$answer_focused" = -1 ];then
		answer_end; exit
	fi

	if [ "$chosen_focus" = "$answer_focused" ] ||
	   [ -z "$focusable" ]; then
		return
	fi

	answer_focused="$chosen_focus"

	printf '\033[2K\r'
	echo "$widgets" | answer_focus_render "$chosen_focus"


}

answer_focus_render ()
{
	current_focus=$1
	rendering=0

	while read widget; do
		rendering=$((rendering+1))

		if [ "$current_focus" = "$rendering" ]; then
			printf "\033[7m ${widget} \033[0m" | tr -d "$answer_cr"
		else
			printf " ${widget} " | tr -d "$answer_cr"
		fi
	done
}

answer_choose ()
{
	widgets="$1"
	answer_focused="$2"

	printf '\033[2K\r'
	printf "$widgets"           |
	sed -n "${answer_focused}p" |
	sed 's/\[ \(.*\) \]/\1/g'
	answer_end; exit
}

answer ()
{
	answer_oldterm="$(stty -g)"
	question="$1"
	widgets="$(answer_widgets "$question")"
	answer_total="$(echo "$widgets" | wc -l)"
	shift

	stty raw -echo || exit
	trap "answer_end; exit" 1 2 15

	answer_focus "$widgets" 0

	keybuffer=''
	while true; do
		byte="$(dd bs=1 count=1 2>/dev/null)"
		keypressed="$byte"
		k="K["

		case "$keypressed" in
			$answer_esc )
				keybuffer="K"
				keypressed=''
				;;
			"" | [a-zA-NP-Z~^\$@$answer_esc] )
				if [ ! -z "$keybuffer" ]; then
					keypressed="${keybuffer}${keypressed}"
					keybuffer=''
				fi
				;;
			* )
				if [ ! -z "$keybuffer" ]; then
					keybuffer="${keybuffer}${keypressed}"
					keypressed=''
				fi
				;;
		esac

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

	answer_end
}
