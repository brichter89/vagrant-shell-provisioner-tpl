# -*- mode: ruby -*-
# vi: set ft=ruby :

config_dist  = File.expand_path("vagrant_config.dist", __dir__)
config_local = File.expand_path("vagrant_config", __dir__)

abort("File 'vagrant_config.dist' missing!") if !File.exists?(config_dist)
FileUtils.cp(config_dist, config_local) if !File.exists?(config_local)

load config_dist if File.exists?(config_dist)
load config_local if File.exists?(config_local)

def print_name(name)
    # Create line with #{name.length} dashes plus 8 dashes for leading and
    # following spaces ("|   " and "   |")
    line = "".rjust(name.length + 8, "-")
    indent = "  "

    puts ""
    puts indent + line
    puts indent + "|   #{name}   |"
    puts indent + line
    puts ""
end

def Kernel.is_windows?
    # Detect if we are running on Windows
    processor, platform, *rest = RUBY_PLATFORM.split("-")
    platform == 'mingw32'
end

print_name $vm_name if %w[up suspend resume halt reload ssh status destroy].include? ARGV[0]

use_nfs = !Kernel.is_windows? && $use_nfs
vagrant_name = $hostname.gsub(/[^A-Za-z0-9]/, '_').downcase

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    # All Vagrant configuration is done here. The most common configuration
    # options are documented and commented below. For a complete reference,
    # please see the online documentation at vagrantup.com.

    # Display "[vmname]" before the vagrant messages instead of "[default]"
    config.vm.define vagrant_name

    # Every Vagrant virtual environment requires a box to build off of.
    config.vm.box = "ubuntu/trusty64"

    # Configure host name
    config.vm.hostname = $hostname

    # Private network IP
    config.vm.network :private_network, ip: $private_ip

    # Public network IP
    config.vm.network :public_network, ip: $public_ip if not $public_ip.to_s.empty?

    # Shared folders (use nfs on non windows hosts)
    config.vm.synced_folder $project_src, $project_root, :nfs => use_nfs


    # VirtualBox-specific configuration
    config.vm.provider "virtualbox" do |vb|
        vb.customize ["modifyvm", :id, "--memory", $vm_memory]
        vb.customize ["modifyvm", :id, "--name", $vm_name]
    end

    # Shell provisioning
    config.vm.provision "shell" do |shell|
        shell.path = File.expand_path("vagrant/provision/shell/_provisioner_.sh", __dir__)
        shell.args = [
            "--online=#{$online}",
            "--project-root=#{$project_root}"
        ]
    end
end
