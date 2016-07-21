class backup::server::params {
	case $::operatingsystem {
		'CentOS' : {
			case $::operatingsystemmajrelease {
				'7' : {
					$basic_packages=['amanda-server','amanda','amanda-libs']
					$dumpuser='amandabackup'
					$dumpgroup='disk'
					$amandahome='/var/lib/amanda'
				}
				'6' : {
					$basic_packages=['amanda-server','amanda','amanda-libs']
					$dumpuser='amandabackup'
                    $dumpgroup='disk'
                    $amandahome='/var/lib/amanda'
				}
				default : { fail("${::hostname}: Module ${::module_name} does not support operatingsystem ${::operatingsystem} ${::operatingsystemmajrelease}") }
			}
		}
		default : { fail("${::hostname}: Module ${::module_name} does not support operatingsystem ${::operatingsystem} ${::operatingsystemmajrelease}") }
	}
}
