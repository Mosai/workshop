setup ()
{
	. "$POSIT_DIR/../../lib/common.sh"
	. "$POSIT_DIR/../../lib/dispatch.sh"
	. "$POSIT_DIR/../../lib/trix.sh"
}

test_trix_parsevar_with_one_variable ()
{
	parsed="$(trix_parsevar "export" FOO=bar)"

	[ "$parsed" = 'export FOO="bar" ' ]
}

test_trix_parsevar_with_more_variables ()
{
	parsed="$(trix_parsevar "export" FOO=bar BAR=baz)"

	[ "$parsed" = 'export FOO="bar" BAR="baz" ' ]
}

test_trix_parsevar_with_quoted_variables ()
{
	parsed="$(trix_parsevar "export" FOO="bar zoo" BAR="baz ZAZ")"

	[ "$parsed" = 'export FOO="bar zoo" BAR="baz ZAZ" ' ]
}

test_trix_parsevar_with_mixed_equal_signs ()
{
	parsed="$(trix_parsevar "export" FOO="bar=zoo" BAR="baz ZAZ")"

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

	probed="$(trix_probe sample_ /mocked/file)"

	[ "$probed" = "sample_foo${nl}sample_bar" ]
}

test_trix_probe_with_no_results ()
{
	real_cat="$(which cat)"
	nl="
"
	cat () ( : )

	probed="$(trix_probe sample_ /mocked/file)"

	[ "$probed" = "" ]
}

test_trix_spawn ()
{
	nl="
"
	tab="	"
	mock_environments="env_mock_foo${nl}env_mock_bar${nl}env_mock_baz"
	spawned="$(trix_spawn "mock_mode" "$mock_environments" "mock_*")"

	[ "$spawned" = "mock_mode${tab}env_mock_foo${nl}mock_mode${tab}env_mock_bar${nl}mock_mode${tab}env_mock_baz" ]
}

test_trix_spawn_with_env_filter ()
{
	nl="
"
	tab="	"
	mock_environments="env_mock_foo${nl}env_mock_foo_also${nl}env_mock_baz"
	trix_env_filter="foo"
	spawned="$(trix_spawn "mock_mode" "$mock_environments" "mock_*")"

	[ "$spawned" = "mock_mode${tab}env_mock_foo${nl}mock_mode${tab}env_mock_foo_also" ]
}

test_trix_probe_matrix_with_filter ()
{

	real_cat="$(which cat)"
	cat ()
	{
		$real_cat <<-PROBED
			matrix_foo ()
			{
				:
			}
			matrix_bar ()
			{
				:
			}
		PROBED
	}

	trix_matrix_filter="foo"
	probed="$(trix_probe_matrix /mocked/file)"

	[ "$probed" = "matrix_foo" ]
}
