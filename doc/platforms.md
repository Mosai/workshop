Supported Platforms
===================

Workshop is tested in a large number of distros and shells. It uses only POSIX Shell Scripts, so it is also architecture independent. For a quick overview of supported environments check our [Travis](https://travis-ci.org/Mosai/workshop) and [AppVeyor](https://ci.appveyor.com/project/alganet/workshop/branch/master) builds.

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

  - **bash**, default from each distro. Versions bash2.05b, bash3.0.16
    bash3.2.48 and bash4.2.45 from PPA.
  - **zsh** and also **zsh-beta**.
  - **ksh**
  - **pdksh**
  - **mksh**
  - **yash**
  - **dash**
  - **busybox sh**
  - **git bash** (on Windows).
