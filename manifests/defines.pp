# manifests/defines.pp

# ssh:_key have to be handed over as the classname
# containing the ssh_keys
define user::define_user(
	$name_comment = 'absent',
	$uid = 'absent',
	$gid = 'absent',
    $groups = [],
    $membership = 'minimum',
	$homedir = 'absent',
    $managehome = 'true',
    $homedir_mode = '0750',
	$sshkey = 'absent',
	$shell = 'absent'
){

    $real_homedir = $homedir ? {
        'absent' => "/home/$name",
        default => $homedir
    }

    $real_name_comment = $name_comment ? {
        'absent' => $name,
        default => $name_comment,
    }

    $real_shell = $shell ? {
        'absent' =>  $operatingsystem ? {
                          openbsd => "/usr/local/bin/bash",
                          default => "/bin/bash",
                    },
        default => $shell,
    }

    user { $name:
        allowdupe => false,
        comment => "$real_name_comment",
        ensure => present,
        home => $real_homedir,
        managehome => $managehome,
        shell => $real_shell,
        groups => $groups,
        membership => $membership,
    }

    
    case $managehome {
        'true': {
            file{"$real_homedir":
                ensure => directory,
                require => User[$name],
                owner => $name, mode => $homedir_mode;
            } 
            case $gid {
                'absent': { 
                    File[$real_homedir]{
                        group => $name,
                    }
                }
                default: { 
                    File[$real_homedir]{
                        group => $gid,
                    }
                }
            }
        }
    }

    case $uid {
        'absent': { info("Not defining a uid for user $name") }
        default: {
            User[$name]{
                uid => $uid,
            }
        }
    }

    case $gid {
        'absent': { info("Not defining a gid for user $name") }
        default: {
            User[$name]{
                gid => $gid,
            }
        }
    }

	case $name {
		root: {}
		default: {
			group { $name:
 				allowdupe => false,
				ensure => present,
                require => User[$name],
			}
            case $gid {
                'absent': { info("not defining a gid for group $name") }
                default: {
                    Group[$name]{
                        gid => $gid,
                    }
                }
		    }
	    }
    }

	case $sshkey {
		'absent': { info("no sshkey to manage for user $name") }
		default: {
            User[$name]{
                before => Class[$sshkey],
            }
			include $sshkey
		}
	}
}


define user::sftp_only(

) {
    include user::groups::sftponly
    user::define_user{"${name}":
        name_comment => "SFTP-only user: ${name}",
        groups => [ 'sftponly' ],        
        managehome => 'false',        
        shell => $operatingsystem ? {
            debian => '/usr/sbin/nologin',
            ubuntu => '/usr/sbin/nologin',
            default => '/sbin/nologin'
        },
        require => Group['sftponly'],
    }
}
