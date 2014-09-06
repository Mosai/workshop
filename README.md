Mosai Workshop 
==============

A set of quality shell script automation tools.

  - Written in POSIX Shell and common utilities like `sed` and `tr`.
  - Tested against bash, dash/ash, ksh/pdksh, zsh and busybox sh.
  - Works out of the box without any dependency in most distros, OS X and MinGW.

*This is a work in progress. This document represents the current version, but 
more features and tools are planned.*

[![Build Status](https://travis-ci.org/Mosai/workshop.svg?branch=master)](https://travis-ci.org/Mosai/workshop)

Instructions
------------

  1. `$ git clone git@github.com:Mosai/workshop.git` or [download and unzip](https://github.com/Mosai/workshop/archive/master.zip) the project.
  2. `$ cd /path/to/project/workshop` (use your real path)
  3. `$ bin/posit help`

If you're on Windows, [download git](http://git-scm.com/download/win) before anything else. 
Git already includes the Git Bash.

The Tools
---------

### posit

posit can run tests written as shell functions. A test should be named "*.test.sh" and
look likes this:

```sh
test_tr_can_replace_fancy_chars ()
{
	translated="$(echo 'Foo' | tr 'o' 'a')"

	[ "$translated" = "Faa" ]
}
```

Tests on posit are isolated, so you can mock other commands and functions:

```sh

test_posit_list_using_files ()
{
  # Mocks the posit_listfile function that should be called
  posit_listfile () ( echo "$1 OK" )

  # Run the test
  expected_list="$(posit list /usr/bin/env)"
  
  # Checks if the mock command was called
  [ "$expected_list" = "/usr/bin/env OK" ]
}
```

Each one of these functions runs in its own process to prevent contamination. A test
passes when its function returns a successful code.

The following variables are available for each test:


  - `$POSIT_FILE` has the relative path to the current test.
  - `$POSIT_DIR` has the relative directory to the current test.
  - `$POSIT_FUNCTION` has the function name for the test
  - `$POSIT_CMD` has the command line to invoke the current shell


#### Test Runner

You can run tests using the `$ bin/posit` tool from this package. This is 
how the runner output is presented:

```
$ bin/posit run test/
............................ 28/28 passed.
```

More report modes are available:

```
$ bin/posit --report=spec run test/dispatch/

### test/dispatch/unit.test.sh

  - pass: dispatch with empty placeholder
  - pass: dispatch with call placeholder
  - pass: dispatch command
  - pass: dispatch option short
  - pass: dispatch option short repassing
  - pass: dispatch option long
  - pass: dispatch option long repassing
  - pass: dispatch option long value and repassing

Totals: 8/8 passed.

```

#### Flags

Output from test functions is not displayed on the test runner unless any errors occour, 
so you don't need to redirect it to `/dev/null` by yourself. You can ommit this behavior
by setting `$ posit -s` or `$ posit --silent` before any command.

Even if a test fails, posit will continue running the others. You can instruct posit to
fail fast using `$ posit -f` or `$posit --fast`.

You can tell posit to use any shell for the tests by using `$ posit --shell=ksh`, for
example.

See more flags on `$ posit help`.

#### Stack Traces

When an error is returned from a test function, posit displays a handy stack trace
for the test (available on zsh, bash and ksh):

```
### test/posit/unit.test.sh
  - fail: posit empty call
   +    unit.test.sh:12      dispatched=+                  
   +    posit.sh:18      posit_demo 1 2 3          
   +    :3                   echo 'OK 1' 2 3               
   +    unit.test.sh:12      dispatched='OK 1 2 3'         
   +    unit.test.sh:14      [ 'OK 1 2 3' '=' 'OK 1 2 ' ']'
   +    zsh:9                has_passed=1                  
  - pass: posit help
  - pass: posit list using files
  - pass: posit list using directories
  - pass: posit list without parameters
  - pass: posit run
  - pass: posit spec
  - pass: posit cov
  - pass: posit postcov counts lines properly

8 tests out of 9 passed.

```

You can ommit the stack by setting `$ posit -s` or `$ posit --silent` before the
run command

For dash and busybox, a simpler trace is still displayed without the files and 
line numbers.

#### Code Coverage

Experimental code coverage reports are available for shells
that support the rich stack traces. 

This is an excerpt from the `$ bash bin/posit --spec=cov --shell=bash test/dispatch` output:

```
> `-    # Detects if a command, --long or -short option was called`  
> `10   if [ "$arg" = "--$long" ];then`
> `-      # Allows --long-options-with=values`  
> `9      set -- ${namespace}_option_$(echo "$long" | tr '=' ' ') $@`
> `7    elif [ "$arg" = "-$short" ];then`
> `2      set -- ${namespace}_option_${short} $@`
> `-    else`  
> `5      set -- ${namespace}_command_${long} $@`
> `-    fi` 

``` 

The number on the left is the number of passes that each specific line had. 

Testing
-------

Workshop is tested in a large number of distros. We provide our Vagrantfile with
the machines needed. To test in a specific machine:

```sh
$ cd /my/path/to/workshop/
$ vagrant up lucid64 # Look for machine names in the Vagrantfile
> vagrant running...
$ vagrant ssh
> vagrant running...
> Hello...
$ cd /vagrant
$ bin/posit --shell=bash run test/
```

Distros tested:

  - **Unknown OS X** from the Travis CI.
  - **Ubuntu 12.04** from the Travis CI and Vagrantfile.
  - **Ubuntu 10.04** from the Vagrantfile.
  - **Ubuntu 14.04** from the Vagrantfile.
  - **Debian 7.4** from the Vagrantfile.
  - **Debian 6.0.9** from the Vagrantfile.
  - **Fedora 20** from the Vagrantfile.
  - **Fedora 19** from the Vagrantfile.
  - **CentOS 6.5** from the Vagrantfile.
  - **CentOS 5** from the Vagrantfile.
  - **OpenSUSE 13** from the Vagrantfile.
  - **OpenSUSE 12** from the Vagrantfile.
  - **FreeBSD 10.0** from the Vagrantfile.
  - **Current ArchLinux** from the Vagrantfile.

The list of shells tested is available in the provisioning
inliners inside the Vagrantfile.