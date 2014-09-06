# Testing machines for the entire Workshop build

Vagrant.configure("2") do |config|

  config.vm.define "precise64", autostart: false do |machine|
    machine.vm.box = "hashicorp/precise64"
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo apt-get -y update"
    machine.vm.provision :shell, :inline => "sudo apt-get install -y dash bash zsh ksh pdksh busybox mksh zsh-beta"
  end

  config.vm.define "trusty64", autostart: false do |machine|
    machine.vm.box = "ubuntu/trusty64"
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo apt-get -y update"
    machine.vm.provision :shell, :inline => "sudo apt-get install -y dash bash zsh ksh pdksh busybox mksh zsh-beta"
  end

  config.vm.define "lucid64", autostart: false do |machine|
    machine.vm.box = "opscode-lucid64"
    machine.vm.box_url = "http://opscode-vagrant-boxes.s3.amazonaws.com/ubuntu10.04-gems.box"
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo apt-get -y update"
    machine.vm.provision :shell, :inline => "sudo apt-get install -y dash bash zsh ksh pdksh busybox mksh zsh-beta"
  end

  config.vm.define "debian7464", autostart: false do |machine|
    machine.vm.box = "chef/debian-7.4"
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo apt-get -y update"
    machine.vm.provision :shell, :inline => "sudo apt-get install -y dash bash zsh ksh pdksh busybox mksh zsh-beta"
  end

  config.vm.define "debian6064", autostart: false do |machine|
    machine.vm.box = "puppetlabs/debian-6.0.9-64-nocm"
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo apt-get -y update"
    machine.vm.provision :shell, :inline => "sudo apt-get install -y dash bash zsh ksh pdksh busybox mksh zsh-beta"
  end

  config.vm.define "fedora2064", autostart: false do |machine|
    machine.vm.box = "chef/fedora-20"
    machine.ssh.pty= true
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo yum update -y"
    machine.vm.provision :shell, :inline => "sudo yum install -y dash bash zsh ksh busybox mksh"
  end

  config.vm.define "fedora1964", autostart: false do |machine|
    machine.vm.box = "chef/fedora-19"
    machine.ssh.pty= true
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo yum update -y"
    machine.vm.provision :shell, :inline => "sudo yum install -y dash bash zsh ksh busybox mksh"
  end

  config.vm.define "centos6464", autostart: false do |machine|
    machine.vm.box = "chef/centos-6.5"
    machine.ssh.pty= true
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo yum update -y"
    machine.vm.provision :shell, :inline => "sudo yum install -y dash bash zsh ksh busybox mksh"
  end

  config.vm.define "centos5", autostart: false do |machine|
    machine.vm.box = "opscode-centos5"
    machine.vm.box_url = "http://opscode-vagrant-boxes.s3.amazonaws.com/centos5-gems.box"
    machine.ssh.pty= true
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo yum update -y"
    machine.vm.provision :shell, :inline => "sudo yum install -y dash bash zsh ksh busybox mksh"
  end

  config.vm.define "opensuse1364", autostart: false do |machine|
    machine.vm.box = "berendt/opensuse-13.1-x86_64"
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo zypper --non-interactive refresh"
    machine.vm.provision :shell, :inline => "sudo zypper --non-interactive rsync install ksh zsh busybox pdksh dash"
  end

  config.vm.define "opensuse1264", autostart: false do |machine|
    machine.vm.box = "opensuse-12.3"
    machine.vm.box_url = "http://sourceforge.net/projects/opensusevagrant/files/12.3/opensuse-12.3-64.box/download"
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
    
    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo zypper --non-interactive refresh"
    machine.vm.provision :shell, :inline => "sudo zypper --non-interactive rsync install ksh zsh busybox pdksh dash"
  end

  config.vm.define "freebsd1064", autostart: false do |machine|
    machine.vm.box = "chef/freebsd-10.0"
    # FreeBSD does not have bash, using sh (it's fine, we're portable.)
    machine.ssh.shell = "sh"
    # FreeBSD requires a private network to...
    machine.vm.network "private_network", ip: "192.168.50.4"
    # ... be able to sync folders using NFS. Only NFS works.
    # You may need to `sudo apt-get install nfs-kernel-server nfs-common portmap`
    machine.vm.synced_folder './', '/vagrant', type: 'nfs'

    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo pkg install -y rsync dash bash pdksh mksh busybox"
  end

  config.vm.define "archlinux", autostart: false do |machine|
    machine.vm.box = "terrywang/archlinux"
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'

    # Install several shells for fun and testing.
    machine.vm.provision :shell, :inline => "sudo pacman -S --noconfirm zsh mksh dash busybox"
  end

end
