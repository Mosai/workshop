test_this_test_should_always_pass ()
{
	true
}

test_tr_can_replace_fancy_chars ()
{
	translated="$(echo 'Foo' | tr 'o' 'a')"

	[ "$translated" = "Faa" ]
}