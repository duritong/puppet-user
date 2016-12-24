# gid:  by default it will take the same as the uid
define user::sftp_only(
  $ensure           = present,
  $managehome       = false,
  $uid              = 'absent',
  $gid              = 'uid',
  $homedir          = 'absent',
  $homedir_mode     = '0750',
  $password         = 'absent',
  $password_crypted = true
) {
  require user::groups::sftponly
  $shell = $::operatingsystem ? {
    'Debian' => '/usr/sbin/nologin',
    'Ubuntu' => '/usr/sbin/nologin',
    default  => '/sbin/nologin'
  }
  user::managed{$name:
    ensure           => $ensure,
    uid              => $uid,
    gid              => $gid,
    name_comment     => "SFTP-only_user_${name}",
    groups           => [ 'sftponly' ],
    managehome       => $managehome,
    homedir          => $homedir,
    homedir_mode     => $homedir_mode,
    shell            => $shell,
    password         => $password,
    password_crypted => $password_crypted;
  }
}
