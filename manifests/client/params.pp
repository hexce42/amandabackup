class backup::client::params {
	case $::operatingsystem {
		'CentOS','OracleLinux' : {
			case $::operatingsystemmajrelease {
				'7' : {
					$basic_packages=['amanda-client','amanda','amanda-libs']
					$dumpuser='amandabackup'
					$dumpgroup='disk'
					$amandahome='/var/lib/amanda'
				}
				 '6' : {
                    $basic_packages=['amanda-client','amanda','glib2']
                    $dumpuser='amandabackup'
                    $dumpgroup='disk'
                    $amandahome='/var/lib/amanda'
                }
				'5' : {
					$basic_packages=['amanda-backup_client']
                    $dumpuser='amandabackup'
                    $dumpgroup='disk'
                    $amandahome='/var/lib/amanda'
                }

				default : { fail("${::hostname}: Module ${::module_name} does not support operatingsystem ${::operatingsystem} ${::operatingsystemmajrelease}") }
			}
		}
		'Debian','Ubuntu' : {
			$basic_packages=['amanda-client','amanda-common']
			$dumpuser='backup'
			$dumpgroup='backup'
			$amandahome='/var/backups'
		}
		
		default : { fail("${::hostname}: Module ${::module_name} does not support operatingsystem ${::operatingsystem} ${::operatingsystemmajrelease}") }
	}
}
