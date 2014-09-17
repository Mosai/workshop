# Testing machines for the entire Workshop build

Vagrant.configure("2") do |config|

  config.vm.define "precise64", autostart: false do |machine|
    machine.vm.box = "hashicorp/precise64"
  end

  config.vm.define "trusty64", autostart: false do |machine|
    machine.vm.box = "ubuntu/trusty64"
  end

  config.vm.define "debian7464", autostart: false do |machine|
    machine.vm.box = "chef/debian-7.4"
  end

  config.vm.define "debian6064", autostart: false do |machine|
    machine.vm.box = "puppetlabs/debian-6.0.9-64-nocm"
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
  end

  config.vm.define "fedora2064", autostart: false do |machine|
    machine.vm.box = "chef/fedora-20"
    machine.ssh.pty = true
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
  end

  config.vm.define "fedora1964", autostart: false do |machine|
    machine.vm.box = "chef/fedora-19"
    machine.ssh.pty = true
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
  end

  config.vm.define "centos6464", autostart: false do |machine|
    machine.vm.box = "chef/centos-6.5"
    machine.ssh.pty = true
    machine.vm.synced_folder './', '/vagrant', type: 'rsync'
  end


end
