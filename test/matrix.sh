#
# Mosai Workshop Test Matrix
#

# Main tested shells
env_common_busybox  () ( var TARGET_SHELL="busybox sh" SHELL_PKG="busybox" )
env_common_dash     () ( var TARGET_SHELL="dash"       SHELL_PKG="dash"    )
env_common_bash     () ( var TARGET_SHELL="bash"       SHELL_PKG="bash"    )
env_shell_zsh       () ( var TARGET_SHELL="zsh"        SHELL_PKG="zsh"     )
env_shell_ksh       () ( var TARGET_SHELL="ksh"        SHELL_PKG="ksh"     )
env_shell_pdksh     () ( var TARGET_SHELL="pdksh"      SHELL_PKG="pdksh"   )
env_shell_mksh      () ( var TARGET_SHELL="mksh"       SHELL_PKG="mksh"    )
env_shell_yash      () ( var TARGET_SHELL="yash"       SHELL_PKG="yash"    )
env_shell_posh      () ( var TARGET_SHELL="posh"       SHELL_PKG="posh"    )

# Extra shells for Ubuntu versions higher than 11.
env_extras_bash2_0  () ( var TARGET_SHELL="bash2.05b"  SHELL_PKG="bash2.05b"\
	                     PPA_REQUIRED="agriffis/bashes precise F5751EC8" )
env_extras_bash3_0  () ( var TARGET_SHELL="bash3.0.16" SHELL_PKG="bash3.0.16"\
	                     PPA_REQUIRED="agriffis/bashes precise F5751EC8" )
env_extras_bash3_2  () ( var TARGET_SHELL="bash3.2.48" SHELL_PKG="bash3.2.48"\
	                     PPA_REQUIRED="agriffis/bashes precise F5751EC8" )
env_extras_bash4_2  () ( var TARGET_SHELL="bash4.2.45" SHELL_PKG="bash4.2.45"\
                             PPA_REQUIRED="agriffis/bashes precise F5751EC8" )
env_extras_zsh_beta () ( var TARGET_SHELL="zsh-beta"   SHELL_PKG="zsh-beta" )

# Environments for Travis CI
env_travis_linux () ( var TRAVIS_OS="linux" )
env_travis_osx   () ( var TRAVIS_OS="osx"   )

# deb/rpm environment machines for vagrant
env_deb_precise64   () ( var VAGRANT_MACHINE="precise64"  )
env_deb_trusty64    () ( var VAGRANT_MACHINE="trusty64"   )
env_deb_debian7464  () ( var VAGRANT_MACHINE="debian7464" )
env_deb_debian6064  () ( var VAGRANT_MACHINE="debian6064" )
env_rpm_fedora2064  () ( var VAGRANT_MACHINE="fedora2064" )
env_rpm_fedora1964  () ( var VAGRANT_MACHINE="fedora1964" )
env_rpm_centos6464  () ( var VAGRANT_MACHINE="centos6464" )


# Local Test Matrix
matrix_local ()
{
	setup  ()
	{
		provision_chooser
		shell_version "$TARGET_SHELL" "$TRIX_ENV"
	}

	script ()
	{
		$TARGET_SHELL bin/posit --shell "$TARGET_SHELL"\
					--silent --fast\
					--report tiny run "test/"
	}

	include "common_*"
	include "shell_*"
	include "extras_*"

}
# Runs the local matrix on remote machines
# Faster than matrix_virtual but not as isolated
matrix_remote ()
{
	setup  () ( vagrant up   "$VAGRANT_MACHINE" )
	clean  () ( vagrant halt "$VAGRANT_MACHINE" )
	script ()
	{
		trix_cmd="bin/trix --matrix=local run test/matrix.sh"

		vagrant ssh "$VAGRANT_MACHINE" -c "cd /vagrant; $trix_cmd"
	}

	include "deb_*"
	include "rpm_*"
}

# Virtual Test Matrix
matrix_virtual ()
{
	setup  ()
	{
		 vagrant up "$VAGRANT_MACHINE"
		 provision_chooser
	}
	clean  () ( vagrant halt "$VAGRANT_MACHINE" )
	script ()
	{
		posit_opt=" --shell \"$TARGET_SHELL\" --report spec"
		posit_cmd="$TARGET_SHELL bin/posit $posit_opt run test/"

		vagrant ssh "$VAGRANT_MACHINE" -c "cd /vagrant; $posit_cmd"
	}

	include "deb_*" "common_*"
	include "deb_*" "shell_*"

	include "rpm_*" "common_*"
	include "rpm_*" shell_zsh
	include "rpm_*" shell_ksh
}

# Travis Matrix
matrix_travis ()
{
	setup  ()
	{
		echo "Setting up build for '$TARGET_SHELL' on '$TRAVIS_OS'..."

		provision_chooser
		shell_version "$TARGET_SHELL" "$TRIX_ENV"
	}

	script ()
	{
		$TARGET_SHELL bin/posit --shell "$TARGET_SHELL"\
					--report spec run "test/"
	}

	include travis_linux "common_*"
	include travis_linux "shell_*"
	include travis_linux "extras_*"

	include travis_osx shell_ksh
	include travis_osx shell_mksh
	include travis_osx shell_zsh
	include travis_osx common_bash
}

#
# Provisioning Helper Functions (not actually part of the matrix)
#

# Chooses if new packages are needed and sets up them
provision_chooser ()
{
	main_shell_command="$(echo "$TARGET_SHELL" | cut -d" " -f1)"
	# No setup if environment has no packages
	[ -z "${SHELL_PKG-}" ] && return

	# No setup if shell already present
	command -v "$main_shell_command" 2>/dev/null 1>/dev/null && return

	# Install PPA if required
	[ ! -z "${PPA_REQUIRED-}" ]  && provision_ppa $PPA_REQUIRED

	provision_package "$SHELL_PKG"
}

# Sets up a single package for apt, yum or brew
provision_package ()
{
	package="$1"

	# Install packages for debian-based linuxes
	command -v apt-get 2>/dev/null 1>/dev/null && provision_apt "$package"

	# Install packages for debian-based linuxes
	command -v yum     2>/dev/null 1>/dev/null && provision_yum "$package"

	# Install packages for OS X
	command -v brew    2>/dev/null 1>/dev/null && provision_brew "$package"
}

# Helper function to add a ppa to the apt sources
provision_ppa ()
{
	ppa_name="$1"
	dist="$2"
	keys="$3"
	keyserver="keyserver.ubuntu.com"
	sources_file="/etc/apt/sources.list"
	address="http://ppa.launchpad.net/$ppa_name/ubuntu"
	has_ppa="$(grep "^deb.*$ppa_name" "$sources_file" | wc -l)"

	[ $has_ppa -gt 0 ] && return

	echo "A PPA is required for this environment. Installing..."

	sudo apt-key adv --keyserver $keyserver --recv-keys "$keys" |
	sed 's/^/ > /'

	echo "deb $address $dist main" | sudo tee -a "$sources_file"
}

# Helper function to install apt packages
provision_apt ()
{
	pkgspec="$1"

	echo "Packages from apt are required. Installing..."

	sudo apt-get update -qq -y       | sed 's/^/ > /'
	sudo apt-get install -y $pkgspec | sed 's/^/ > /'
}

# Helper function to install yum packages
provision_yum ()
{
	pkgspec="$1"

	echo "Packages from yum are required. Installing..."

	sudo yum check-update        | sed 's/^/ > /'
	sudo yum install -y $pkgspec | sed 's/^/ > /'
}

# Helper function to install brew packages
provision_brew ()
{
	pkgspec="$1"

	echo "Packages from brew are required. Installing..."

	brew update           | sed 's/^/ > /'
	brew install $pkgspec | sed 's/^/ > /'
}

# Finds the version for a given shell
shell_version ()
{
	printf %s "Env '$TRIX_ENV': "
	$1 <<-'WHATSHELL'

		: 'This script aims at recognizing all Bourne compatible shells.
		   Emphasis is on shells without any version variables.
		   Comments to mascheck@in-ulm.de'
		: '$Id: whatshell.sh,v 1.17 2012/04/23 21:59:02 xmascheck Exp xmascheck $'
		: 'fixes are tracked on www.in-ulm.de/~mascheck/various/whatshell/'

		LC_ALL=C export LC_ALL
		: 'trivial cases first, yet parseable for historic shells'
		case $BASH_VERSION in *.*) { echo "bash $BASH_VERSION";exit;};;esac
		case $ZSH_VERSION  in *.*) { echo "zsh $ZSH_VERSION";exit;};;esac
		case "$VERSION" in *zsh*) { echo "$VERSION";exit;};;esac
		case  "$SH_VERSION" in *PD*|*MIRBSD*) { echo  "$SH_VERSION";exit;};;esac
		case "$KSH_VERSION" in *PD*|*MIRBSD*) { echo "$KSH_VERSION";exit;};;esac
		case "$POSH_VERSION" in 0.[1234]*) \
		     { echo "posh $POSH_VERSION, possibly slightly newer, yet<0.5";exit;}
		  ;; *.*|*POSH*) { echo "posh $POSH_VERSION";exit;};; esac
		case $YASH_VERSION in *.*) { echo "yash $YASH_VERSION";exit;};;esac

		myex(){ echo "$@";exit;} # "exec echo" might call the external command

		# Almquist shell aka ash
		(typeset -i var) 2>/dev/null || {
		  case $SHELLVERS in "ash 0.2") myex 'original ash';;esac
		  test "$1" = "debug" && debug=1
		  n=1; case `(! :) 2>&1` in *not*) n=0;;esac
		  b=1; case `echo \`:\` ` in '`:`') b=0;;esac
		  g=0; { set -- -x; getopts x: var
		         case $OPTIND in 2) g=1;;esac;} >/dev/null 2>&1
		  p=0; (eval ': ${var#value}') 2>/dev/null && p=1
		  r=0; ( (read</dev/null)) 2>/dev/null; case $? in 0|1|2)
			  var=`(read</dev/null)2>&1`; case $var in *arg*) r=1;;esac
			;;esac
		  v=1; set x; case $10 in x0) v=0;;esac
		  t=0; (PATH=;type :) >/dev/null 2>&1 && t=1
		  test -z "$debug" || echo debug '$n$b$g$p$r$v$t: ' $n$b$g$p$r$v$t
		  case $n$b$g$p$r$v$t in
		     00*) myex 'early ash (4.3BSD, 386BSD 0.0-p0.2.3/NetBSD 0.8)'
		  ;; 010*) myex 'early ash (ash-0.2 port, Slackware 2.1-8.0,'\
			'386BSD p0.2.4, NetBSD 0.9)'
		  ;; 1110100) myex 'early ash (Minix 2.x-3.1.2)'
		  ;; 1000000) myex 'early ash (4.4BSD Alpha)'
		  ;; 1100000) myex 'early ash (4.4BSD)'
		  ;; 11001*) myex 'early ash (4.4BSD Lite, early NetBSD 1.x, BSD/OS 2.x)'
		  ;; 1101100) myex 'early ash (4.4BSD Lite2, BSD/OS 3 ff)'
		  ;; 1101101) myex 'ash (FreeBSD, Cygwin pre-1.7, Minix 3.1.3 ff)'
		  ;; esac
		  e=0; case `(PATH=;exp 0)2>&1` in 0) e=1;;esac
		  n=0; case y in [^x]) n=1;;esac
		  r=1; case `(PATH=;noexist 2>/dev/null) 2>&1` in
		        *not*) r=0 ;; *file*) r=2 ;;esac
		  f=0; case `eval 'for i in x;{ echo $i;}' 2>/dev/null` in x) f=1;;esac
		  test -z "$debug" || echo debug '$e$n$r$a$f: ' $e$n$r$a$f
		  case $e$n$r$f in
		     1100) myex 'ash (dash 0.3.8-30 - 0.4.6)'
		  ;; 1110) myex 'ash (dash 0.4.7 - 0.4.25)'
		  ;; 1010) myex 'ash (dash 0.4.26 - 0.5.2)'
		  ;; 0120|1120|0100) myex 'ash (Busybox 0.x)'
		  ;; 0110) myex 'ash (Busybox 1.x)'
		  ;;esac
		  a=0; case `eval 'x=1;(echo $((x)) )2>/dev/null'` in 1) a=1;;esac
		  x=0; case `f(){ echo $?;};false;f` in 1) x=1;;esac
		  c=0; case `echo -e '\x'` in *\\x) c=1;;esac
		  test -z "$debug" || echo debug '$e$n$r$f$a$x$c: ' $e$n$r$f$a$x$c
		  case $e$n$r$f$a$x$c in
		     1001010) myex 'ash (Slackware 8.1 ff, dash 0.3.7-11 - 0.3.7-14)'
		  ;; 10010??) myex 'ash (dash 0.3-1 - 0.3.7-10, NetBSD 1.2 - 3.1/4.0)'
		  ;; 10011*)  myex 'ash (NetBSD 3.1/4.0 ff)'
		  ;; 00101*)  myex 'ash (dash 0.5.5.1 ff)'
		  ;; 00100*)  myex 'ash (dash 0.5.3-0.5.5)'
		  ;;      *)  myex 'unknown ash'
		  ;;esac
		}

		savedbg=$! # save unused $! for a later check

		# Korn shell ksh93, $KSH_VERSION not implemented before 93t'
		# protected: fatal substitution error in non-ksh
		( eval 'test "x${.sh.version}" != x' ) 2>/dev/null &
		wait $! && { eval 'myex "ksh93 ${.sh.version}"' ; }

		# Korn shell ksh86/88
		_XPG=1;test "`typeset -Z2 x=0; echo $x`" = '00' && {
		  case `print -- 2>&1` in *"bad option"*)
		    myex 'ksh86 Version 06/03/86(/a)';; esac
		  test "$savedbg" = '0'&& myex 'ksh88 Version (..-)11/16/88 (1st release)'
		  test ${x-"{a}"b} = '{ab}' && myex 'ksh88 Version (..-)11/16/88a'
		  case "`for i in . .; do echo ${i[@]} ;done 2>&1`" in
		    "subscript out of range"*)
		    myex 'ksh88 Version (..-)11/16/88b or c' ;; esac
		  test "`whence -v true`" = 'true is an exported alias for :' &&
		    myex 'ksh88 Version (..-)11/16/88d'
		  test "`(cd /dev/null 2>/dev/null; echo $?)`" != '1' &&
		    myex 'ksh88 Version (..-)11/16/88e'
		  test "`(: $(</file/notexistent); echo x) 2>/dev/null`" = '' &&
		    myex 'ksh88 Version (..-)11/16/88f'
		   case `([[ "-b" > "-a" ]]) 2>&1` in *"bad number"*) \
		    myex 'ksh88 Version (..-)11/16/88g';;esac # fixed in OSR5euc
		  test "`cd /dev;cd -P ..;pwd 2>&1`" != '/' &&
		    myex 'ksh88 Version (..-)11/16/88g' # fixed in OSR5euc
		  test "`f(){ typeset REPLY;echo|read;}; echo dummy|read; f;
		     echo $REPLY`" = "" && myex 'ksh88 Version (..-)11/16/88h'
		  test $(( 010 )) = 8 &&
		    myex 'ksh88 Version (..-)11/16/88i (posix octal base)'
		  myex 'ksh88 Version (..-)11/16/88i'
		}

		echo 'oh dear, unknown shell'
	WHATSHELL
}
