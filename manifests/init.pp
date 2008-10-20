#
# user module
#
# Copyright (C) 2007 admin@immerda.ch
# Copyright 2008, Puzzle ITC
# Marcel Härry haerry+puppet(at)puzzle.ch
# Simon Josi josi+puppet(at)puzzle.ch
#
# This program is free software; you can redistribute 
# it and/or modify it under the terms of the GNU 
# General Public License version 3 as published by 
# the Free Software Foundation.

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

   file{"$real_homedir":
        ensure => directory,
        require => User[$name],
        owner => $name, group => $name, mode => $homedir_mode;
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

    case $gid {
        'absent': { info("no gid defined for user $name") }
        default: { 
            File[$real_homedir]{
                group => $gid,
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
