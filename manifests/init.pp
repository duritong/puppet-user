# modules/user/manifests/init.pp - manage user stuff
# Copyright (C) 2007 admin@immerda.ch
#

modules_dir { "user": }

class user {

}


define user::define_user(
	$name,
	$uid,
	$gid,
	$home_dir = '',
	$ssh_key = ''
	$shell = ''
	){

	$real_ssh_key = $ssh_key ? {
		'' => $name,
		default => $ssh_key,
	}
	
	$real_home_dir = $home_dir ? {
		'' => "/home/$name",
		default => $home_dir
	}

	$real_name_comment = $name_comment ? {
		'' => $name,
		default => $name_comment,	
	}

	$real_shell = $shell ? {
		'' =>  $operatingsystem ? {
                       	  openbsd => "/usr/local/bin/bash",
                          default => "/bin/bash",
                	},
		default => $shell,
	}

	user { $name:
		allowdupe => false,
                comment => "$real_name_comment",
                ensure => present,
                gid => $gid,
		home => $real_home_dir,
		shell => $real_shell,
		uid => $uid,
	}

	group { $name:
 		allowdupe => false,
		ensure => present,
		gid => $gid
	}

	file {$real_home_dir:
  			ensure => directory,
			mode => 0750, owner => $name, group => $name;
	}

	ssh::deploy_auth_key{$name: source => $real_ssh_key, user => $name, target_dir => '', group => $name}
}
