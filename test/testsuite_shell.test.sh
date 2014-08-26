test_arithmetic_sum ()
{
	num1=2
	num2=3
	sum=$((num1+num2))

	[ $sum = 5 ]
}