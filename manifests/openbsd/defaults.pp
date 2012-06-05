# manifests/openbsd/defaults.pp 

class user::openbsd::defaults {
  # we need this somehow to mange it
  user::managed{root: 
    name => 'root', 
    name_comment => 'Charlie &',
    uid => '0', 
    gid => '0', 
    homedir => '/root', 
    homedir_mode => '0700', 
  }
}

