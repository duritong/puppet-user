# manifests/defines.pp

# sshkey:           have to be handed over as the classname
#                   containing the ssh_keys
# password:         the password in cleartext or as crypted string
#                   which should be set. Default: absent -> no password is set.
#                   To create an encrypted password, you can use:
#                   /usr/bin/mkpasswd -H md5 -S $salt $password
#                   Note: On OpenBSD systems we can only manage crypted passwords.
#                         Therefor the password_crypted option doesn't have any effect.
#                         You'll find a python script in ${module}/password/openbsd/genpwd.py
#                         Which will help you to create such a password
# password_crypted: if the supplied password is crypted or not. 
#                   Default: true
#                   Note: If you'd like to use unencrypted passwords, you have to set a variable
#                         $password_salt to an 8 character long salt, being used for the password.  
# gid:              define the gid of the group
#                   absent: let the system take a gid (*default*)
#                   uid: take the same as the uid has if it isn't absent
#                   <value>: take this gid
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
    $password = 'absent',
    $password_crypted = 'true',
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
            case $gid {
                'uid': {
                    case $uid {
                        'absent': { info("Not defining a gid for user $name as uid is absent") }
                        default: {
                            $real_gid = $uid
                        }
                    }
                }
                default: {
                    $real_gid = $gid
                }
            }
            if $real_gid {
                User[$name]{
                    gid => $real_gid,
                }
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

    case $password {
        'absent': { info("not managing the password for user $name") }
        default: {
            case $operatingsystem {
                openbsd: { 
                    exec { "setpass ${name}":
                        unless => "grep -q '^${name}:${password}:' /etc/master.passwd",
                        command => "usermod -p '${password}' ${name}",
                        require => User["${name}"],
                    }   
                }
                default: {
                    include ruby-libshadow
                    if $password_crypted {
                        $real_password = $password
                    } else {
                        case $password_salt {
                            '': { fail("To use unencrypted passwords you have to define a variable \$password_salt to an 8 character salt for passwords!") }
                            default: {
                                $real_password = mkpasswd($password,$password_salt)
                            }
                        }
                    }
                    User[$name]{
                        password => $real_password,
                        require => Package['ruby-libshadow'],
                    }
                }
            }
        }
    }
}


# gid:  by default it will take the same as the uid
define user::sftp_only(
    $managehome = 'false',
    $uid = 'absent',
    $gid = 'uid',
    $homedir_mode = '0750',
    $password = 'absent',
    $password_crypted = 'true'
) {
    include user::groups::sftponly
    user::define_user{"${name}":
        uid => $uid,
        gid => $gid,
        name_comment => "SFTP-only_user_${name}",
        groups => [ 'sftponly' ],        
        managehome => $managehome,
        homedir_mode => $homedir_mode,
        shell => $operatingsystem ? {
            debian => '/usr/sbin/nologin',
            ubuntu => '/usr/sbin/nologin',
            default => '/sbin/nologin'
        },
        password => $password,
        password_crypted => $password_crypted,
        require => Group['sftponly'],
    }
}
