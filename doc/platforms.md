Supported Platforms
===================

Workshop is tested in a large number of distros and shells. It uses only POSIX Shell Scripts, so it is also architecture independent. For a quick overview of supported environments check our [Travis](https://travis-ci.org/Mosai/workshop) and [AppVeyor](https://ci.appveyor.com/project/alganet/workshop/branch/master) builds.

Distros Tested
--------------

  - **Unknown OS X** from Travis CI.
  - **Ubuntu 12.04** from Travis CI and test matrix.
  - **Ubuntu 14.04** from test matrix.
  - **Debian 7.4** from test matrix.
  - **Debian 6.0.9** from test matrix.
  - **Fedora 20** from test matrix.
  - **Fedora 19** from test matrix.
  - **CentOS 6.5** from test matrix.
  - **Windows Server 2012** from AppVeyor.

Previous versions were tested on OpenSuse, Arch Linux, FreeBSD and older versions of Ubuntu and CentOS. Although they're not in our matrix, Workshop should work just fine on them.

Shells Tested
-------------

Mosai Workshop has been proved portable by real testing. These are the shells and versions we targeted on our test matrix:

  - **bash** - _Bourne Again Shell_. Probably the most popular shell around.
    - 2.05b
    - 3.0.16
    - 3.2.48
    - 4.1.5
    - 4.2.24
    - 4.2.37
    - 4.2.45
    - 4.3.11
  - **busybox sh** - Busybox uses the _Alquemist Shell_ (ash) which does not have a way to report its own version, these are busybox versions:
    - 1.15.1
    - 1.17.1
    - 1.18.5
    - 1.19.4
    - 1.20.2
    - 1.21.1
  - **dash** - The default non-user shell on Ubuntu.
    - (dash does not have a way to find its own version, we tested in all distros available)
  - **ksh** - _The Korn Shell_. A classic.
    - JM 93u 2011-02-08
    - JM 93u+ 2012-02-29
    - AJM 93u+ 2012-08-01
  - **mksh** - _MirOS Korn Shell_. A clone based on ksh88.
    - R39 2009/08/01
    - R39 2010/07/25
    - R40 2012/07/20
    - R40 2012/02/11
    - R46 2013/05/02
    - R50 2014/06/29
  - **pdksh** - _Public Domain Korn Shell_. A clone based on ksh88.
    - 5.2.14 99/07/13.2
    - R40 2012/07/20
    - R46 2013/05/02
  - **posh** - _Policy-Compliant Ordinary Shell_. Lightweight, very POSIX compliant shell.
    - (unknown version on Debian 6 before `$POSH_VERSION` was available)
    - 0.10.2
    - 0.12.3
  - **yash** - _Yet Another Shell_, a very lighweight one.
    - 2.30
    - 2.29
    - 2.35
    - 2.36
  - **zsh** - _The Z Shell_. Another popular shell.
    - 4.3.10
    - 4.3.10-dev-1-cvs0720
    - 4.3.17-dev-0-cvs0621
    - 4.3.12-dev-1-cvs
    - 5.0.2
    - 5.0.6

Check for Yourself
------------------

If you want to run tests in your own machine, you can run our test matrix:

```sh
bin/trix --matrix=local run test/matrix.sh
```

You can also run these tests in virtual machines. The following command
runs all shells available one machine per time:

```sh
bin/trix --matrix=remote run test/matrix.sh
```

And if you want, you can run one shell per time, which is really slow but far more isolated:

```sh
bin/trix --matrix=virtual run test/matrix.sh
```
