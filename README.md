Mosai Workshop 
==============

A set of quality shell script automation tools.

  - Written in POSIX Shell and common utilities like `sed` and `tr`.
  - Tested against bash, dash/ash, ksh/pdksh, zsh and busybox sh.
  - Works out of the box without any dependency in most distros, OS X and MinGW.

*This is a work in progress. This document represents the current version, but 
more features and tools are planned.*

[![Build Status](https://travis-ci.org/Mosai/workshop.svg?branch=master)](https://travis-ci.org/Mosai/workshop)

Installation
------------

Linux and OS X:

  1. Clone or [download](https://github.com/Mosai/workshop/archive/master.zip) the project.

Windows:

  1. [Download git](http://git-scm.com/download/win) to get the git bash.
  2. Clone or [download](https://github.com/Mosai/workshop/archive/master.zip) the project.

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

#### Test Runner

You can run tests using the `$ bin/testsuite` tool from this package. This is 
how the runner output is presented:

```
$ bin/testsuite run test/
### test/testsuite/unit.test.sh
  - pass: testsuite empty call
  - pass: testsuite help
  - pass: testsuite list using files
  - pass: testsuite list using directories
  - pass: testsuite list without parameters
  - pass: testsuite run
  - pass: testsuite spec
  - pass: testsuite cov
  - pass: testsuite postcov counts lines properly

9 tests out of 9 passed.
```

Output from test functions is not displayed on the test runner unless any errors occour, 
so you don't need to redirect it to `/dev/null` by yourself.

#### Stack Traces

When an error is returned from a test function, testsuite displays a handy stack trace
for the test (available on zsh, bash and ksh):

```
### test/testsuite/unit.test.sh
  - fail: testsuite empty call
   +    unit.test.sh:12      dispatched=+                  
   +    testsuite.sh:18      testsuite_demo 1 2 3          
   +    :3                   echo 'OK 1' 2 3               
   +    unit.test.sh:12      dispatched='OK 1 2 3'         
   +    unit.test.sh:14      [ 'OK 1 2 3' '=' 'OK 1 2 ' ']'
   +    zsh:9                has_passed=1                  
  - pass: testsuite help
  - pass: testsuite list using files
  - pass: testsuite list using directories
  - pass: testsuite list without parameters
  - pass: testsuite run
  - pass: testsuite spec
  - pass: testsuite cov
  - pass: testsuite postcov counts lines properly

8 tests out of 9 passed.

```

For dash and busybox, a simpler trace is still displayed without the files and 
line numbers.

#### Code Coverage

Experimental code coverage reports are available for shells
that support the rich stack traces. 

This is an excerpt from the `$ bin/testsuite cov test/` output:

```
-	testsuite_run ()
-	{
1		target="$1"
2		testsuite_list "$target" | testsuite_process simple "$target"
-	}
	
-	# Run tests and display results as specs
-	testsuite_spec ()
1	{
1		target="$1"
2		testsuite_list "$target" | testsuite_process spec "$target"
-	}


``` 

The number on the left is the number of passes that 
each specific line had. 