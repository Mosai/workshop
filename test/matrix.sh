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
	setup  () ( provision_chooser )
	script ()
	{
		shell_version "$TARGET_SHELL"
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
	printf %s " > SHELL_VERSION: "
	case "$1" in
		busybox* )
			busybox --help 2>&1 | head -n1
			;;
		dash     )
			echo "Dash can't know its version."
			;;
		bash*    )
			$1 --version 2>&1 | head -n1
			;;
		zsh      )
			zsh --version 2>&1 | head -n1
			;;
		*ksh     )
			$1 -c 'echo $KSH_VERSION'
			;;
		yash     )
			yash --version  2>&1 | head -n1
			;;
		posh     )
			posh -c 'echo $POSH_VERSION'
			;;
	esac
}
