dispatch
========

A full command line argument dispatcher in 50 lines of portable shell script.

Download the [standalone version](https://github.com/Mosai/workshop/blob/master/lib/dispatch.sh) or use the full [Mosai Workshop](https://github.com/Mosai/workshop).

Usage
-----

Unlike many argument parsers, **dispatch** is not designed to be used inside case/esac control structures. It behaves like a router for shell script functions.

Let's create a command line tool called `dexample` to explore the dispatch features:

### Dispatching Commands

Our first command will be `dsample hello`, a command to print the string "Hello World".

Create a file called `dsample` with the following contents:

```sh
# Loads the dispatch library
. "/path/to/dispatch.sh"

# The hello command
dsample_command_hello () ( echo "Hello World" )

# Dispatch the arguments
dispatch dsample "$@"
```

You should replace `/path/to/dispatch.sh` with the proper path to the library and make the file executable by running `$ chmod +x dsample`.

Now, when you run it you should see the string "Hello World":

```sh
$ ./dsample hello
Hello World
```

### Command Arguments

dispatch will repass remaining arguments to your command:

```sh
dsample_command_greet () ( echo "Hello $1" )

dispatch dsample "$@"
```

```sh
$ ./dsample greet "Alexandre"
Hello Alexandre
```

### Empty Call Placeholder

You might have experimented with the sample and tried to run it without any arguments. Whenever dispatch is called without arguments, it routes to a placeholder function:

```sh
dsample_ () ( echo "No arguments provided." )

dispatch dsample "$@"
```

You can execute whatever you want on the empty call placeholder, but in this sample we will just print a message saying that no arguments were provided:

```sh
$ ./dsample
No arguments provided.
```

### Not Found Calls

If dispatch can't find any route, it will fall back to a default one passing the entire command line called:

```sh
dsample_call_ () ( echo "Invalid call '$@'" )

dispatch dsample "$@"
```

Calling any invalid command or option will now display an error message:

```sh
$ ./dsample foobarbaz
Invalid call 'dsample foobarbaz'.
```

### Simple Options

Support for short and long options is available. 

```sh
dsample_option_v    () ( echo "Version: 0.0" )
dsample_option_help () ( echo "Usage: dsample [options] [command]" )

dispatch dsample "$@"
```

The result should be:

```sh
$ ./dsample --help
Usage: dsample [options] [command]
$ ./dsample -v
Version: 0.0
```

These options will end the dispatch process, but if you want you can
dispatch the arguments again. The following sample introduces the `--short`
option which changes the _Hello_ to _Hi_ if passed.

```sh
dsample_short=0
dsample_command_hello ()
{
	if [ $dsample_short = 0 ]; then
		echo "Hello World"
	else
		echo "Hi World"
	fi	
}
dsample_option_short () ( dsample_short=1; dispatch dsample "$@" )

dispatch dsample "$@"
```

And now it is possible to call commands with options:

```sh
$ ./dsample hello
Hello World
$ ./dsample --short hello
Hi World
```

### Options and Values

If you need options with values, you'll need to shift them:

```sh
dsample_message="Hello"
dsample_command_greet () ( echo "$dsample_message $1" )
dsample_option_message () ( dsample_message="$1"; shift; dispatch dsample "$@" )

dispatch dsample "$@"
```

Long option values can be quoted and the equal sign `=` is optional:

```sh
$ ./dsample --message Welcome greet Alexandre
Welcome Alexandre
$ ./dsample --message=Welcome greet Alexandre
Welcome Alexandre
$ ./dsample --message="Welcome to dispatch, " greet Alexandre
Welcome to dispatch, Alexandre
```

### Full Sample

Here is our full sample in a single file:

```sh
# Loads the dispatch library
. "/path/to/dispatch.sh"

# Variables and flags
dsample_short=0
dsample_message="Hello"

# Placeholder calls
dsample_               () ( echo "No arguments provided." )
dsample_call_          () ( echo "Invalid call '$@'." )

# Options
dsample_option_v       () ( echo "Version: 0.0" )
dsample_option_help    () ( echo "Usage: dsample [options] [command]" )
dsample_option_short   () ( dsample_short=1; dispatch dsample "$@" )
dsample_option_message () ( dsample_message="$1"; shift; dispatch dsample "$@" )

# Commands
dsample_command_greet  () ( echo "$dsample_message $1" )
dsample_command_hello ()
{
	if [ $dsample_short = 0 ]; then
		echo "Hello World"
	else
		echo "Hi World"
	fi	
}

# Dispatch the arguments
dispatch dsample "$@"
```