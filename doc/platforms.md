Supported Platforms
===================

Workshop is tested in a large number of distros and shells. It uses only
POSIX Shell Scripts, so it is also architecture independent. For a quick
overview of supported environments check our [Travis Builds](https://travis-ci.org/Mosai/workshop).

If you want to run tests in your own machine, you can run our test matrix:

```sh
bin/trix run test/matrix.sh
```

Vagrant is currently required to run the matrix.

Distros Tested
--------------

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

Although not automated yet, tests pass on OpenSuse, Arch and FreeBSD as well.

Shells Tested
-------------

  - **bash**, default from each distro. Versions bash2.05b, bash3.0.16
    bash3.2.48 and bash4.2.45 from PPA. Current brew bash on Travis.
  - **zsh** and **zsh-beta** when available (Debian-based distros mostly.)
  - **ksh** and **pdksh**, **mksh** when available.
  - **dash** when available.
  - **busybox sh** when available.

Manual testing is also done on the [git bash](http://git-scm.com/download/win).