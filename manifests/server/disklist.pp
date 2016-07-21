define backup::server::disklist (
	$config = '',
	$dumpuser = '',
) {
	
	if $config=="" {
        $config_name=$name
    } else {
        $config_name=$config
    }

	concat { "amanda_disklist_$config_name":
		path =>"/etc/amanda/$config_name/disklist",
		ensure => present,
		owner => $dumpuser,
		order => numeric,
     }

	concat::fragment { "amanda_disklist_header_$config_name":
		target => "amanda_disklist_$config_name",
		content => "#File maintained through puppet. DO NOT EDIT \n",
		order => 1,
		
	}
}

define backup::server::disklist::entry (
	$config='test',
	$host = '',
	$disk = ['/etc'],
	$dumptype = 'simple-tar',
	$ssh_port = '8833',
) {
	
	if $host=="" {
		$host_entry=$name
	} else {
		$host_entry=$host
	}

	
	concat::fragment {"amanda_disklist_entry_${config}_${name}_${dumptype}_${ssh_port}":
		target => "amanda_disklist_$config",
		content => template("${module_name}/disklist_entry.erb")
	}

	exec { "ammanda_add_client_host_key_$config_${name}":
            path => ['/bin','/usr/bin'],
            command => "ssh-keyscan -p $ssh_port $host_entry >> /var/lib/amanda/.ssh/known_hosts",
            unless => "grep ${host_entry} /var/lib/amanda/.ssh/known_hosts",
        }
}
		
