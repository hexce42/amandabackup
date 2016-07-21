class backup::client (
	$conf = '',
	$amandahost = '',
	$auth = '',
	$client_user = '',
	$client_port = '',
	$client_private_key = '',
	$server_public_key = '',
) inherits backup::client::params {
	
	$config = $conf
	if  client_private_key != '' {
		$ssh_key="/etc/amanda/${config}/${client_private_key}"
	} else {
		$ssh_key=''
	}

	package { $backup::client::params::basic_packages:
		ensure => present,
	}

	file { "amanda_config_dir":
        path => "/etc/amanda",
        ensure => directory,
        owner => $dumpuser,
        require => Package[ $backup::client::params::basic_packages ],
    }
	
	file { "amanda_config_dir_$config":
		path => "/etc/amanda/$config",
		ensure => directory,
		owner => $dumpuser,
		require => File[ "amanda_config_dir" ],
	}

	file {"amanda_client_config_file_$config":
		path => "/etc/amanda/$config/amanda-client.conf",
		ensure => present,
		owner => $backup::client::params::dumpuser,
		mode => "0660",
		content => template("${module_name}/amanda-client.conf.erb"),
		require => File["amanda_config_dir_$config"]
	}

	if client_private_key != '' {

		file { "amanda_ssh_private_key_$config":
		path => $ssh_key,
		ensure	=> present,
		owner => $backup::client::params::dumpuser,
		mode => "0600",
		source => "puppet:///modules/${module_name}/${client_private_key}",
		require => File["amanda_config_dir_$config"],
		}
	}

	if server_public_key !='' {

		file {"amanda_ssh_dir_$config":
		path => "${backup::client::params::amandahome}/.ssh",
		ensure => directory,
		owner => $backup::client::params::dumpuser,
		group => $backup::client::params::dumpgroup,
		mode => "0700",
		}
		
		file { "amanda_ssh_authorized_keys_$config":
		path => "${backup::client::params::amandahome}/.ssh/authorized_keys",
		ensure => present,
		owner => $backup::client::params::dumpuser,
		group => $backup::client::params::dumpgroup,
		mode => "0600",
		require => File["amanda_ssh_dir_$config"]
		}

		file { "amanda_ssh_known_hosts_$config":
        path => "${backup::client::params::amandahome}/.ssh/known_hosts",
        ensure => present,
        owner => $backup::client::params::dumpuser,
        group => $backup::client::params::dumpgroup,
        mode => "0600",
        require => File["amanda_ssh_dir_$config"]
        }


		exec { "ammanda_add_server_public_key_$config":
			path => ['/bin','/usr/bin'],
			command => "echo \'$server_public_key\' >> ${backup::client::params::amandahome}/.ssh/authorized_keys",
			unless => "grep \"Backup Server\" ${backup::client::params::amandahome}/.ssh/authorized_keys",
			require => File["amanda_ssh_authorized_keys_$config"],
		}

#		exec { "ammanda_add_server_public_key_$config":
#           path => ['/bin','/usr/bin'],
#           command => "echo \"\" > ${backup::client::params::amandahome}/.ssh/authorized_keys", 
#           require => File["amanda_ssh_authorized_keys_$config"],
#       }


		 exec { "ammanda_add_server_host_key_$config":
			path => ['/bin','/usr/bin'],
            command => "su - ${backup::client::params::dumpuser} -c \'ssh-keyscan -t rsa -p $client_port $amandahost >> ${backup::client::params::amandahome}/.ssh/known_hosts\'",
            unless => "grep $amandahost ${backup::client::params::amandahome}/.ssh/known_hosts",
			require => File["amanda_ssh_known_hosts_$config"],
        }
	
		
	}

	if $::osfamily == 'Debian' {
		file { "amanda_interop_dir" :
            path => "/usr/lib64",
            ensure => directory,
			require => Package[ $backup::client::params::basic_packages ],	
        }
		file { "amanda_interop_link" :
			path => "/usr/lib64/amanda",
			ensure => link,
			target => "/usr/lib/amanda",
			require => File["amanda_interop_dir"]
		}
		exec { "amanda_backup_user_shell" :
			path => ['/bin','/usr/bin'],
			unless => "grep $backup::client::params::dumpuser /etc/passwd | grep bash",
			command => "chsh -s /bin/bash $backup::client::params::dumpuser"
		}
	}

	if $::osfamily == 'RedHat' {
		if $::operatingsystemmajrelease == '5' {
			file { "amanda_centos5_dir" :
            	path => "/usr/lib64",
            	ensure => directory,
            	require => Package[ $backup::client::params::basic_packages ],
        	}
        	file { "amanda_centos5_link" :
            	path => "/usr/lib64/amanda/amandad",
            	ensure => link,
            	target => "/usr/libexec/amanda/amandad",
            	require => File["amanda_centos5_dir"]
        	}

		}	
	}

	
}
