define backup::server::dumptypes (
	$config = '',
	$dumpuser = '',
) {
	
	if $config=="" {
        $config_name=$name
    } else {
        $config_name=$config
    }

	concat { "amanda_dumptypes_$config_name":
		path =>"/etc/amanda/$config_name/dumptypes.conf",
		ensure => present,
		owner => $dumpuser,
		order => numeric,
     }

	concat::fragment { "amanda_dumptype_header_$config_name":
		target => "amanda_dumptypes_$config_name",
		content => "#File maintained through puppet. DO NOT EDIT \n",
		order => 1,
		
	}
}

define backup::server::dumptypes::type (
	$config='',
	$comment='',
	$inherit='',
	$dumptype='',
	$auth='',
	$amanda_path='',
	$client_username='',
	$client_port='',
	$bumpsize='',
	$bumppercent='',
	$bumpmult='',
	$bumpdays='',
	$compress='',
	$compress_type='',
	$compress_program='',
	$dumpcycle='',
	$encrypt='',
	$encrypt_program='',
	$encrypt_option_string='',
	$estimate='',
	$exclude='',
	$exclude_files=[''],
	$exclude_list='',
	$holdingdisk='',
	$ignore='',
	$include='',
    $include_files=[''],
    $include_list='',
    $holdingdisk='',
	$ignore='',
	$index='',
	$kencrypt='',
	$maxdumps='',
	$maxpromoteday='',
	$max_warnings='',
	$priority='',
	$program='',
	$application='',
	$script='',
	$property=[],
	$record='',
	$skip_full='',
	$skip_incr='',
	$ssh_keys='',
	$starttime='',
	$strategy='',
	$allow_split='',
	$tape_splitsize='',
	$split_diskbuffer='',
	$fallback_splitsize='',
	$recovery_limit='',
	$dump_limit='',
	) {
	
	if $dumptype=="" {
		$dump_name=$name
	} else {
		$dump_name=$dumptype
	}

	
	concat::fragment {"amanda_dumptypes_entry_${config}_${dump_name}":
		target => "amanda_dumptypes_$config",
		content => template("${module_name}/dumptypes_entry.erb")
	}
}
		
