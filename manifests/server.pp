class backup::server (
	$config = '',
	$org = '',
	$mailto = '',
	$dumpcycle = '1week',
	$runspercycle = '7',
	$tapecycle = '35',
	$tapelength = '20480 mbytes',
	$runtapes = '1',
	$vtapes_dir ='/backup',
	$dtimeout = '1800',
	$ctimeout ='30',
	$etimeout = '300',
	$ssh_key ='',
	$holding_drive='/tmp/holding',
	$inparallel='4',
	$dumporder = 'sssS',
	$taperalgo = 'first',
	$displayunit ='m',
	$netusage= '4000',
	$bumpsize= '20',
	$bumppercent ='20',
	$bumpdays ='1',
	$usetimestamps ='yes',
	$maxdumpsize ='-1',
	$bumpmult = '4',
	$amrecover_changer = 'changer',
	$autoflush = 'no',
	$client_public_key ='',
) inherits backup::server::params {

	package { $backup::server::params::basic_packages:
		ensure => present,
	}

	puppet::agent::customfacts { "backup_server":
        custom_facts => [
            "ssh_ignore=1",
			"backupserver=1"
        ]
    }
	
	file { "amanda_debian_interop_link":
        path => "/usr/lib/amanda",
        ensure => link,
		target => "/usr/lib64/amanda",
        require => Package[ $backup::server::params::basic_packages ],
    }
	
	file { "amanda_config_dir":
        path => "/etc/amanda",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
        require => Package[ $backup::server::params::basic_packages ],
    }


	file { "amanda_config_dir_$config":
		path => "/etc/amanda/$config",
		ensure => directory,
		owner => $backup::server::params::dumpuser,
		require => File[ "amanda_config_dir" ],
	}

	file { "amanda_backup_dir_$config":
        path => "$vtapes_dir/$config",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
    }


	file { "amanda_vtapes_dir_$config":
        path => "$vtapes_dir/$config/vtapes",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
		require => File["amanda_backup_dir_$config"]
    }

	file { "amanda_state_dir_$config":
        path => "$vtapes_dir/$config/state",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
		require => File["amanda_backup_dir_$config"]
    }

	file { "amanda_curinfo_dir_$config":
        path => "$vtapes_dir/$config/state/curinfo",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
        require => File["amanda_backup_dir_$config"]
    }

	file { "amanda_index_dir_$config":
        path => "$vtapes_dir/$config/state/index",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
        require => File["amanda_backup_dir_$config"]
    }

	file { "amanda_log_dig_$config":
        path => "$vtapes_dir/$config/state/log",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
        require => File["amanda_backup_dir_$config"]
    }


	file {"amanda_main_config_file_$config":
		path => "/etc/amanda/$config/amanda.conf",
		ensure => present,
		owner => $backup::server::params::dumpuser,
		mode => "0660",
		content => template("${module_name}/amanda.conf.erb"),
		require => File["amanda_config_dir_$config"]
	}

	file {"amanda_advanced_config_file_$config":
        path => "/etc/amanda/$config/advanced.conf",
        ensure => present,
        owner => $backup::server::params::dumpuser,
        mode => "0660",
        content => template("${module_name}/advanced.conf.erb"),
        require => File["amanda_config_dir_$config"]
    }

	if ssh_key != '' {
		file { "amanda_ssh_private_key_$config":
		path => "/etc/amanda/$config/$ssh_key",
		ensure	=> present,
		owner => $backup::server::params::dumpuser,
		mode => "0600",
		source => "puppet:///modules/${module_name}/${ssh_key}",
		require => File["amanda_config_dir_$config"],
		}
	}

	file { "amanda_holding_drive_$config":
        path => "$holding_drive",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
        require => File["amanda_backup_dir_$config"]
    }

	exec { "amanda_set_tape_labels_$config":
		command => "/bin/su - amandabackup bash -c \"for i in {1..$tapecycle} ; do amlabel ${config} ${config}-\\\$i slot \\\$i ; done\"",
		onlyif => "/bin/su - amandabackup bash -c \"amcheck $config\" | grep \"ERROR: No acceptable volumes found\"",
		require => File["amanda_advanced_config_file_$config","amanda_vtapes_dir_$config"],
	}

	backup::server::dumptypes { $config:
        dumpuser =>  $backup::server::params::dumpuser,
    }

	backup::server::disklist { $config:
         dumpuser => $backup::server::params::dumpuser,
    }

	File["amanda_config_dir_$config"] -> backup::server::dumptypes[$config] ->  backup::server::disklist[$config]

	if client_public_key !='' {

        file {"amanda_ssh_dir_$config":
        path => "${backup::server::params::amandahome}/.ssh",
        ensure => directory,
        owner => $backup::server::params::dumpuser,
        group => $backup::server::params::dumpgroup,
        mode => "0700",
        }

        file { "amanda_ssh_authorized_keys_$config":
        path => "${backup::server::params::amandahome}/.ssh/authorized_keys",
        ensure => present,
        owner => $backup::server::params::dumpuser,
        group => $backup::server::params::dumpgroup,
        mode => "0600",
        require => File["amanda_ssh_dir_$config"]
        }

        exec { "ammanda_add_client_public_key_$config":
            command => "/bin/echo '$client_public_key' >> ${backup::server::params::amandahome}/.ssh/authorized_keys",
            unless => "/bin/grep \"$client_public_key\" ${backup::server::params::amandahome}/.ssh/authorized_keys",
			require => File["amanda_ssh_authorized_keys_$config"],
        }
	}

	cron::job{
          'amanda-server-dump':
            minute      => '0',
            hour        => '2',
            date        => '*',
            month       => '*',
            weekday     => '*',
            user        => 'amandabackup',
            command     => "/usr/sbin/amdump ${config}",
        }


}
