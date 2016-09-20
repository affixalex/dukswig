# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "hypoalex/alpine34"
  config.ssh.shell = "/bin/sh"
  config.vm.network :private_network, ip: "172.168.65.2"
  config.vm.synced_folder ".", "/dukswig", type: "nfs"

  config.vm.provision "shell", inline: <<-SHELL
    sudo apk update && sudo apk upgrade
    sudo apk add alpine-sdk
    sudo apk add autoconf
    sudo apk add automake
		sudo apk add libpcre32
    sudo apk add git
    sudo apk add vim
    cd ~vagrant && git clone https://github.com/hypoalex/swig.git
    cd swig && ./autogen.sh
    
  SHELL
end
