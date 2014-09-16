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

# Extra shells for Debian-based distros provided by a PPA
# See the setup_ppa helper function
env_extras_bash2_0  () ( var TARGET_SHELL="bash2.05b"  SHELL_PKG="bash2.05b"\
	                     PPA_REQUIRED="agriffis/bashes F5751EC8" )
env_extras_bash3_0  () ( var TARGET_SHELL="bash3.0.16" SHELL_PKG="bash3.0.16"\
	                     PPA_REQUIRED="agriffis/bashes F5751EC8" )
env_extras_bash3_2  () ( var TARGET_SHELL="bash3.2.48" SHELL_PKG="bash3.2.48"\
	                     PPA_REQUIRED="agriffis/bashes F5751EC8" )
env_extras_bash4_2  () ( var TARGET_SHELL="bash4.2.45" SHELL_PKG="bash4.2.45"\
                             PPA_REQUIRED="agriffis/bashes F5751EC8" )
env_extras_zsh_beta () ( var TARGET_SHELL="zsh-beta"   SHELL_PKG="zsh-beta" )

# Environments for Travis CI
env_travis_linux () ( var TRAVIS_OS="linux" )
env_travis_osx   () ( var TRAVIS_OS="osx"   )

# deb/rpm environment machines for vagrant
env_deb_precise64   () ( var VAGRANT_MACHINE="precise64"  )
env_deb_trusty64    () ( var VAGRANT_MACHINE="trusty64"   )
env_deb_lucid64     () ( var VAGRANT_MACHINE="lucid64"    )
env_deb_debian7464  () ( var VAGRANT_MACHINE="debian7464" )
env_deb_debian6064  () ( var VAGRANT_MACHINE="debian6064" )
env_rpm_fedora2064  () ( var VAGRANT_MACHINE="fedora2064" )
env_rpm_fedora1964  () ( var VAGRANT_MACHINE="fedora1964" )
env_rpm_centos6464  () ( var VAGRANT_MACHINE="centos6464" )
env_rpm_centos5     () ( var VAGRANT_MACHINE="centos5"    )


# Local Test Matrix
matrix_local ()
{
	script () ( $TARGET_SHELL bin/posit --shell "$TARGET_SHELL" --report tiny run test/ )

	include common_*
	include shell_*
	include extras_*
}

# Virtual Test Matrix
matrix_virtual ()
{
	setup  () ( vagrant up   $VAGRANT_MACHINE )
	clean  () ( vagrant halt $VAGRANT_MACHINE )
	script () 
	{
		posit_opt=" --shell \"$TARGET_SHELL\" --report tiny"
		posit_cmd="$TARGET_SHELL bin/posit $posit_opt run test/"

		vagrant ssh $VAGRANT_MACHINE -c "cd /vagrant; $posit_cmd"
	}

	include deb_* common_*
	include deb_* shell_*

	include rpm_* common_*
	include rpm_* shell_zsh
	include rpm_* shell_ksh
	exclude rpm_centos5 common_busybox
	exclude rpm_centos5 common_dash
}

# Travis Matrix
matrix_travis ()
{
	setup ()
	{
		echo "Setting up build for '$TARGET_SHELL' on '$TRAVIS_OS'..."

		# No setup if environment has no packages
		[ -z "$SHELL_PKG" ] && return

		# Install PPA if required
		[ ! -z "$PPA_REQUIRED" ] && setup_ppa $PPA_REQUIRED

		# Install packages for linux
		[ "Linux" = "$(uname -s)" ]  && setup_apt "$SHELL_PKG"

		# Install packages for OS X
		[ "Darwin" = "$(uname -s)" ] && setup_brew "$SHELL_PKG"
	}

	script ()
	{
		$TARGET_SHELL bin/posit --shell "$TARGET_SHELL" --report spec run test/
	}

	include travis_linux common_*
	include travis_linux shell_*
	include travis_linux extras_*

	include travis_osx shell_ksh
	include travis_osx shell_mksh
	include travis_osx shell_zsh
	include travis_osx common_bash
}

# Helper function to add a ppa to the apt sources
setup_ppa ()
{
	address="$1"
	keys="$2"

	echo "A PPA is required for this environment. Installing..."

	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$keys" | sed 's/^/ > /'
	sudo bash -c ". /etc/lsb-release; echo deb http://ppa.launchpad.net/$address/ubuntu \$DISTRIB_CODENAME main >> /etc/apt/sources.list"
}

# Helper function to install apt packages
setup_apt ()
{
	pkgspec="$1"

	echo "Packages from apt are required for this environment. Installing..."

	sudo apt-get update -qq | sed 's/^/ > /'
	sudo apt-get install -y $pkgspec | sed 's/^/ > /'
}

# Helper function to install brew packages
setup_brew ()
{
	pkgspec="$1"

	echo "Packages from brew are required for this environment. Installing..."

	brew update | sed 's/^/ > /'
	brew install $pkgspec | sed 's/^/ > /'
}