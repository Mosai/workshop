test_this_test_should_always_pass ()
{
	true
}

test_this_test_should_always_fail ()
{
	false
}

test_this_test_should_always_pass_2 ()
{
	true
}

test_tr_can_replace_fancy_chars ()
{
	translated="$(echo 'Foo' | tr 'o' 'a')"

	[ "$translated" = "Faa" ]
}