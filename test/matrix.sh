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

# Environment List

env_deb_precise64     () ( var MACHINE="precise64"  )
env_deb_trusty64      () ( var MACHINE="trusty64"   )
env_deb_lucid64       () ( var MACHINE="lucid64"    )
env_deb_debian7464    () ( var MACHINE="debian7464" )
env_deb_debian6064    () ( var MACHINE="debian6064" )
env_rpm_fedora2064    () ( var MACHINE="fedora2064" )
env_rpm_fedora1964    () ( var MACHINE="fedora1964" )
env_rpm_centos6464    () ( var MACHINE="centos6464" )
env_rpm_centos5       () ( var MACHINE="centos5"    )

env_common_busybox_sh () ( var TARGET_SHELL="busybox sh" )
env_common_dash       () ( var TARGET_SHELL="dash"       )
env_common_bash       () ( var TARGET_SHELL="bash"       )

env_extras_bash2_05b  () ( var TARGET_SHELL="bash2.05b"  )
env_extras_bash3_0_16 () ( var TARGET_SHELL="bash3.0.16" )
env_extras_bash3_2_48 () ( var TARGET_SHELL="bash3.2.48" )
env_extras_bash4_2_45 () ( var TARGET_SHELL="bash4.2.45" )
env_extras_zsh_beta   () ( var TARGET_SHELL="zsh-beta"   )

env_shell_zsh         () ( var TARGET_SHELL="zsh"        )
env_shell_ksh         () ( var TARGET_SHELL="ksh"        )
env_shell_pdksh       () ( var TARGET_SHELL="pdksh"      )
env_shell_mksh        () ( var TARGET_SHELL="mksh"       )