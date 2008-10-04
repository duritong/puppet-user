# manifests/openbsd/defaults.pp 

class user::openbsd::defaults {
    # we need this somehow to mange it
    user::define_user{root: 
        name => 'root', 
        name_comment => 'Charlie &',
        uid => '0', 
        gid => '0', 
        home_dir => '/root/', 
        home_dir_mode = '0700', 
    }
}

