Mosai Workshop
==============

A set of quality shell script automation tools.

  - Written in POSIX Shell and common utilities like `sed` and `tr`.
  - Tested against bash, dash, ksh and zsh. 
  - Works out of the box without any dependency in most distros, OS X and MinGW.

*This is a work in progress. This document represents the current version, but 
more features and tools are planned.*

The Tools
---------

### testsuite

Testsuite can run tests written as shell functions. A test look likes this:

```sh
test_tr_can_replace_fancy_chars ()
{
	translated="$(echo 'Foo' | tr 'o' 'a')"

	[ "$translated" = "Faa" ]
}
```

Each one of these functions runs in its own process to prevent contamination. A test
passes when its function returns a successful code.


You can run tests using the `$ bin/testsuite` tool from this package. This is 
how the runner output is presented:

```
$ bin/testsuite file test/testsuite_basics.sh 
[x] this test should always pass
[ ] this test should always fail
[x] tr can replace fancy chars

2 tests out of 3 passed.
```

Output from test functions is not displayed on the test runner, so you don't need
to redirect it to `/dev/null` by yourself.