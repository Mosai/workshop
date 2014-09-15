setup () 
{
	. "$POSIT_DIR/../../lib/dispatch.sh"
	. "$POSIT_DIR/../../lib/trix.sh"
}

test_trix_empty_call_dispatch ()
{
	empty_call="$(trix)"
	
	[ "$empty_call" = "No command provided. Try 'trix --help'" ]
}

test_trix_empty_invalid_dispatch ()
{
	invalid_call="$(trix foobarbaz)"
	
	[ "$invalid_call" = "Call 'trix foobarbaz' invalid. Try 'trix --help'" ]
}

test_trix_parsevar_with_one_variable ()
{
	parsed="$(trix_parsevar FOO=bar)"

	[ "$parsed" = 'export FOO="bar" ' ]
}

test_trix_parsevar_with_more_variables ()
{
	parsed="$(trix_parsevar FOO=bar BAR=baz)"

	[ "$parsed" = 'export FOO="bar" BAR="baz" ' ]
}

test_trix_parsevar_with_quoted_variables ()
{
	parsed="$(trix_parsevar FOO="bar zoo" BAR="baz ZAZ")"

	[ "$parsed" = 'export FOO="bar zoo" BAR="baz ZAZ" ' ]
}

test_trix_parsevar_with_mixed_equal_signs ()
{
	parsed="$(trix_parsevar FOO="bar=zoo" BAR="baz ZAZ")"

	[ "$parsed" = 'export FOO="bar=zoo" BAR="baz ZAZ" ' ]
}

test_trix_probe_with_results ()
{
	real_cat="$(which cat)"
	nl="
"
	cat () 
	{
		$real_cat <<-PROBED
			sample_foo () 
			{
				:
			}
			sample_bar () 
			{
				:
			}
		PROBED
	}

	parsed="$(trix_probe sample_ /mocked/file)"

	[ "$parsed" = "sample_foo${nl}sample_bar" ]
}

test_trix_probe_with_no_results ()
{
	real_cat="$(which cat)"
	nl="
"
	cat () ( : )

	parsed="$(trix_probe sample_ /mocked/file)"

	[ "$parsed" = "" ]
}