posit
=====

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


Test Runner
-----------

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

Flags
-----

Output from test functions is not displayed on the test runner unless any errors occour,
so you don't need to redirect it to `/dev/null` by yourself. You can ommit this behavior
by setting `$ posit -s` or `$ posit --silent` before any command.

Even if a test fails, posit will continue running the others. You can instruct posit to
fail fast using `$ posit -f` or `$posit --fast`.

You can tell posit to use any shell for the tests by using `$ posit --shell=ksh`, for
example.

See more flags on `$ posit help`.

Stack Traces
------------

When an error is returned from a test function, posit displays a handy stack trace
for the test (available on zsh, bash and ksh):

```
### test/posit/unit.test.sh
  - fail: posit empty call
   +    unit.test.sh:12      dispatched=+
   +    posit.sh:18          posit_demo 1 2 3
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

Code Coverage
-------------

Experimental code coverage reports are available for shells
that support the rich stack traces.

This is an excerpt from the `$ bash bin/posit --shell=bash --report=cov run test/dispatch/` output:

```
### /home/alganet/Projects/mosai/workshop/lib/dispatch.sh

> `-` `# Changes zsh globbing patterns`
> `11`  `command -v unsetopt 2>/dev/null >/dev/null && unsetopt NO_MATCH`
> `-`
> `-` `# Dispatches calls of commands and arguments`
> `-` `dispatch ()`
> `-` `{`
> `14`  ` namespace="$1"     # Namespace to be dispatched`
> `14`  ` arg="$2"           # First argument`
> `14`  ` short="${arg#*-}"  # First argument without trailing -`
> `14`  ` long="${short#*-}" # First argument without trailing --`
> `-`
> `-` ` # Exit and warn if no first argument is found`
> `14`  ` if [ -z "$arg" ]; then`
> `1` `   "${namespace}_" # Call empty call placeholder`
> `1` `   return 1`
> `-` ` fi`
```

The number on the left is the number of passes that each specific line had.
Coverage information is subject to shell support:

  - **bash** presents the most accurate count.
  - **zsh** and **ksh** may miss some lines.
  - others have only support for stack traces without files/lines.

The standard coverage output is Markdown.
