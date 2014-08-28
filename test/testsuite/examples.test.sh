test_this_test_should_always_pass ()
{
	true
}

test_tr_can_replace_fancy_chars ()
{
	translated="$(echo 'Foo' | tr 'o' 'a')"

	[ "$translated" = "Faa" ]
}

test_arithmetic_sum ()
{
	num1=2
	num2=3
	sum=$((num1+num2))

	[ $sum = 5 ]
}