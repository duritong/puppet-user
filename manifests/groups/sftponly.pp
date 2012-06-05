# manifests/groups/sftponly.pp

class user::groups::sftponly {
  group{'sftponly':
    ensure => present,
    gid => 10000,
  }
}
