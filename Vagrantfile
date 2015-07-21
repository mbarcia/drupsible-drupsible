# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile for Drupsible

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Minimum Vagrant version required
Vagrant.require_version ">= 1.7.2"

# Use rbconfig to determine if we're on a windows host or not.
require 'rbconfig'
is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
if is_windows
  install_windows_param = 'is_windows'
end

# Install required plugins if not present.
required_plugins = %w(vagrant-cachier vagrant-hostsupdater)
required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end

#
# Customize as needed
#

# Virtualbox (Debian Jessie 8.0)
BOX               = 'Debian-jessie-amd64-netboot'
BOX_URL           = 'https://github.com/holms/vagrant-jessie-box/releases/download/Jessie-v0.1/Debian-jessie-amd64-netboot.box'

# VMWare Fusion (Ubuntu 12.04)
#BOX               = 'hashicorp/precise64'

# Parallels (Ubuntu 14.04)
#BOX               = 'parallels/ubuntu-14.04'

# Default box parameters
RAM               = 1024   # Default memory size in MB
GUI               = false # Enable/Disable GUI

# Default Virtualbox parameters
PAE               = 'on'
ACPI              = 'on'
IOAPIC            = 'on'
CHIPSET           = 'ich9'

# Network configuration
DOMAIN            = ".drupsible.org"
NETWORK           = "192.168.70."
NETMASK           = "255.255.255.0"

# These hosts must match your Ansible inventory
HOSTS = {
   "local" => [NETWORK+"10", 2048, false, BOX, BOX_URL, PAE, ACPI, IOAPIC, CHIPSET],
}

#
# Vagrant configuration main
#
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  HOSTS.each do | (name, cfg) |
    ipaddr, ram, gui, box, box_url, pae, acpi, ioapic, chipset = cfg

    config.vm.define name do |machine|
      machine.vm.box     = box
      machine.vm.box_url = box_url
      machine.vm.guest = :debian

      # Virtualbox
      machine.vm.provider "virtualbox" do |vb|
        vb.gui    = gui
        vb.memory = ram
        # Configure misc settings
        vb.customize ['modifyvm', :id,
        '--rtcuseutc', 'on',
        '--natdnshostresolver1', 'on',
        '--nictype1', 'virtio',
        '--nictype2', 'virtio']
        vb.customize ["modifyvm", :id, "--pae", pae]
        vb.customize ["modifyvm", :id, "--acpi", acpi]
        vb.customize ["modifyvm", :id, "--ioapic", ioapic]
        vb.customize ["modifyvm", :id, "--chipset", chipset]
      end

      # VMWare
      machine.vm.provider "vmware_fusion" do |vmw, o|
        o.vm.box = box
        o.vm.guest = :ubuntu
        vmw.gui = gui
        vmw.vmx["memsize"] = ram
      end

      # Parallels
      machine.vm.provider "parallels" do |p, o|
        o.vm.box = box
        o.vm.guest = :ubuntu
        p.memory = ram
        p.update_guest_tools = true
      end

      machine.vm.hostname = name + DOMAIN
      machine.vm.network 'private_network', ip: ipaddr, netmask: NETMASK

      # Add aliases of each host to /etc/hosts
      config.hostsupdater.aliases = [ 'local.bak' + DOMAIN ]

      # Prevent annoying "stdin: not a tty" errors
      config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
      
      if name.eql?'local' 
        # SSH setup
        # Vagrant >= 1.7.0 defaults to using a randomly generated RSA key.
        # We need to disable this in order to pass the correct identity from host to guest.
        config.ssh.insert_key = false
    
        # Help use agent forwarding
        # Windows user: use a shell like Git Bash. 
        cmd = `ssh-add -l`
        if not $?.success?
          puts "Starting ssh-agent..."
          `ssh-agent`
          if $?.success?
            cmd = `ssh-add -l`
            if not $?.success?
              if not cmd.include? "insecure_private_key"
                `ssh-add ~/.vagrant.d/insecure_private_key`
                if $?.success?
                  puts "Your ssh-agent was started, and Vagrant's default key has been added."
                else
                  puts "Your ssh-agent was started, but Vagrant's default key could NOT be added."
                  exit 1
                end
              end
            end
          else
            puts "Your ssh-agent was NOT running, and could NOT be started."
            exit 1
          end
        else
          if not cmd.include? "insecure_private_key"
            `ssh-add ~/.vagrant.d/insecure_private_key`
            puts "Your ssh-agent was already running, and Vagrant's default key has been added."
          else
            # ssh-agent is running, with Vagrant's default key loaded.
          end
        end
        
        # Allow identities to be passed from host to guest.
        # ssh-agent must be running on the host, the private keys loaded with ssh-add
        config.ssh.forward_agent = true
          
        # No more delayed screen output from shell provisioners
        $stdout.sync = true
        $stderr.sync = true
        
        # Install Ansible only on the controller machine
        machine.vm.provision "shell" do |sh|
          sh.path = "drupsible-provision.sh"
          sh.args = ["vagrant", install_windows_param.to_s]
        end

        # Run deploy playbook
        machine.vm.provision "shell" do |sh|
          sh.path = "drupsible-deploy.sh"
          sh.args = ["/home/vagrant/ansible/inventory/vagrant_ansible_inventory", ENV['DEPLOY_ARGS'].to_s, ENV['TAGS'].to_s,  ENV['SKIP_TAGS'].to_s]
          sh.privileged = false
          keep_color = true
        end

        machine.vm.provision "shell", 
          inline: 'cat /vagrant/shortcuts.sh >> /home/vagrant/.profile'
      end 

    end

  end # HOSTS-each

  # Allow caching to be used (see the vagrant-cachier plugin)
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
    config.cache.auto_detect = false
    config.cache.enable :apt
    config.cache.enable :gem
    config.cache.enable :npm
  end
end
