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
	setup  () ( vagrant up   $MACHINE )
	clean  () ( vagrant halt $MACHINE )
	script () 
	{
		posit_opt=" --shell \"$TARGET_SHELL\" --report tiny"
		posit_cmd="$TARGET_SHELL bin/posit $posit_opt run test/"

		vagrant ssh $MACHINE -c "cd /vagrant; $posit_cmd"
	}

	include deb_* common_*
	include deb_* shell_*

	include rpm_* common_*
	include rpm_* shell_zsh
	include rpm_* shell_ksh
	exclude rpm_centos5 common_busybox_sh
	exclude rpm_centos5 common_dash
}

# Travis Matrix
matrix_travis ()
{
	setup ()
	{
		if [ "yes" = "$PPA_REQUIRED" ]; then 
			sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F5751EC8
		fi

		if [ "yes" = "$PPA_REQUIRED" ]; then 
			sudo bash -c ". /etc/lsb-release; echo deb http://ppa.launchpad.net/agriffis/bashes/ubuntu \$DISTRIB_CODENAME main >> /etc/apt/sources.list"
		fi

		if [ "Linux" = "$(uname -s)" ]; then 
			sudo apt-get update -qq
		fi

		if [ "Linux" = "$(uname -s)" ]; then 
			sudo apt-get install -y $SHELL_PKG
		fi

		if [ "Darwin" = "$(uname -s)" ]; then 
			brew update
		fi

		if [ "Darwin" = "$(uname -s)" ]; then 
			if [ ! -z "$SHELL_PKG" ]; then 
				brew install $SHELL_PKG
			fi
		fi
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

# Environment List

env_travis_linux () ( var TRAVIS_OS="linux" )
env_travis_osx   () ( var TRAVIS_OS="osx"   )

env_deb_precise64     () ( var MACHINE="precise64"  )
env_deb_trusty64      () ( var MACHINE="trusty64"   )
env_deb_lucid64       () ( var MACHINE="lucid64"    )
env_deb_debian7464    () ( var MACHINE="debian7464" )
env_deb_debian6064    () ( var MACHINE="debian6064" )
env_rpm_fedora2064    () ( var MACHINE="fedora2064" )
env_rpm_fedora1964    () ( var MACHINE="fedora1964" )
env_rpm_centos6464    () ( var MACHINE="centos6464" )
env_rpm_centos5       () ( var MACHINE="centos5"    )

env_common_busybox_sh () ( var TARGET_SHELL="busybox sh" SHELL_PKG="busybox" )
env_common_dash       () ( var TARGET_SHELL="dash"       SHELL_PKG="dash"    )
env_common_bash       () ( var TARGET_SHELL="bash"       SHELL_PKG="bash"    )

env_extras_bash2_05b  () ( var TARGET_SHELL="bash2.05b"  SHELL_PKG="bash2.05b"  PPA_REQUIRED="yes" )
env_extras_bash3_0_16 () ( var TARGET_SHELL="bash3.0.16" SHELL_PKG="bash3.0.16" PPA_REQUIRED="yes" )
env_extras_bash3_2_48 () ( var TARGET_SHELL="bash3.2.48" SHELL_PKG="bash3.2.48" PPA_REQUIRED="yes" )
env_extras_bash4_2_45 () ( var TARGET_SHELL="bash4.2.45" SHELL_PKG="bash4.2.45" PPA_REQUIRED="yes" )
env_extras_zsh_beta   () ( var TARGET_SHELL="zsh-beta"   SHELL_PKG="zsh-beta" )

env_shell_zsh         () ( var TARGET_SHELL="zsh"   SHELL_PKG="zsh"   )
env_shell_ksh         () ( var TARGET_SHELL="ksh"   SHELL_PKG="ksh"   )
env_shell_pdksh       () ( var TARGET_SHELL="pdksh" SHELL_PKG="pdksh" )
env_shell_mksh        () ( var TARGET_SHELL="mksh"  SHELL_PKG="mksh"  )