# Core64-5.2

## Description

* [Core Pure 64 v5.2](http://tinycorelinux.net/ports.html)
* custom isolinux.cfg for Vagrant
  * timeout 2
  * home=sda1
  * opt=sda1
* iso booting
* sda1(/home, /opt and /tce)

## Original Packages

This box include original packages for Vagrant.

* vagrant.tcz
* vboxadd.tcz

## Build Box

download

	$ git clone https://github.com/gnue/packer-core64.git
	$ cd packer-core64

build CoreCustom64-5.2.iso

	$ pushd custom-iso
	$ vagrant up
	$ vagrant ssh -c /vagrant/custom-iso.sh
	$ vagrant destroy
	$ popd

build vboxadd64-KERNEL.tcz

	$ pushd packages
	$ vagrant up
	$ vagrant ssh -c /vagrant/pkg-vboxadd.sh
	$ vagrant destroy
	$ popd

build core64-5.2_virtualbox.box on OS X

	$ brew tap homebrew/binary
	$ brew install packer
	$ brew install squashfs

	$ build-box.sh
