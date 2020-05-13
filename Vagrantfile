#
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Enable time logging
$out_file = File.new('debug.log', 'w')
def $stdout.write string
    log_datas=string
    if log_datas.gsub(/\r?\n/, "") != ''
        log_datas=::Time.now.strftime("%d/%m/%Y %T")+" "+log_datas.gsub(/\r\n/, "\n")
    end
    super log_datas
    $out_file.write log_datas
    $out_file.flush
end
def $stderr.write string
    log_datas=string
    if log_datas.gsub(/\r?\n/, "") != ''
        log_datas=::Time.now.strftime("%d/%m/%Y %T")+" "+log_datas.gsub(/\r\n/, "\n")
    end
    super log_datas
    $out_file.write log_datas
    $out_file.flush
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Box metadata location and box name
BOX_URL = "https://oracle.github.io/vagrant-boxes/boxes"
BOX_NAME = "oraclelinux/8"

# define hostname
NAME = "oracle-19c-ol8"

unless Vagrant.has_plugin?("vagrant-proxyconf")
  puts 'Installing vagrant-proxyconf Plugin...'
  system('vagrant plugin install vagrant-proxyconf')
end

unless Vagrant.has_plugin?("vagrant-vbguest")
  puts 'Installing vagrant-vbguest Plugin...'
  system('vagrant plugin install vagrant-vbguest')
end

# define listener and EM Express ports
LISTENER_PORT = 1521
EM_EXPRESS_PORT = 5500

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = BOX_NAME
  config.vm.box_url = "#{BOX_URL}/#{BOX_NAME}.json"
  config.vm.define NAME

  # change memory size
  config.vm.provider "virtualbox" do |v|
    v.memory = 3072
    v.cpus = 2
    v.name = NAME
  end

  # add proxy configuration from host env - optional
  if Vagrant.has_plugin?("vagrant-proxyconf")
    puts "getting Proxy Configuration from Host..."
    if ENV["http_proxy"]
      puts "http_proxy: " + ENV["http_proxy"]
      config.proxy.http     = ENV["http_proxy"]
    end
    if ENV["https_proxy"]
      puts "https_proxy: " + ENV["https_proxy"]
      config.proxy.https    = ENV["https_proxy"]
    end
    if ENV["no_proxy"]
      config.proxy.no_proxy = ENV["no_proxy"]
    end
  end

  # VM hostname
  config.vm.hostname = NAME

  # Oracle port forwarding
  config.vm.network "forwarded_port", guest: LISTENER_PORT, host: LISTENER_PORT
  config.vm.network "forwarded_port", guest: EM_EXPRESS_PORT, host: EM_EXPRESS_PORT
  # Putty access
  config.vm.network "forwarded_port", guest: 22, host: 22

  # Copy private and public keys
  config.ssh.insert_key = false
  config.ssh.private_key_path = ['common_private_key.ppk', '~/.vagrant.d/insecure_private_key']
  config.vm.provision "file", source: "common_public_key.pub", destination: "/home/vagrant/.ssh/vagrant.pub"
  config.vm.provision "shell", inline: <<-SHELL
    cat /home/vagrant/.ssh/vagrant.pub >> /home/vagrant/.ssh/authorized_keys
    SHELL


  # Provision everything on the first run # run: always - if needed
  config.vm.provision "shell", path: "scripts/install.sh", env:
    {
       "ORACLE_BASE"         => "/opt/oracle",
       "ORACLE_HOME"         => "/opt/oracle/product/19c/dbhome_1",
       "ORACLE_SID"          => "ORCLCDB",
       "ORACLE_PDB"          => "ORCLPDB1",
       "ORACLE_CHARACTERSET" => "AL32UTF8",
       "ORACLE_EDITION"      => "EE",
       "LISTENER_PORT"       => LISTENER_PORT,
       "EM_EXPRESS_PORT"     => EM_EXPRESS_PORT,
  	   "CV_ASSUME_DISTID"    => "8.2",
	   "BASE_ZIP"            => "LINUX.X64_193000_db_home.zip",
	   "PATCH_LOC"           => "/opt/oracle/release-update",
	   "PATCH_NUMBER"        => "30869156",
	   "PATCH_ZIP"           => "p30869156_190000_Linux-x86-64.zip",
	   "OPATCH_ZIP"          => "p6880880_190000_Linux-x86-64.zip"
    }

end
