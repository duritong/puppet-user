# manifests/defines.pp

# sshkey:           have to be handed over as the classname
#                   containing the ssh_keys
# password:         the password in cleartext or as crypted string
#                   which should be set. Default: absent -> no password is set.
#                   To create an encrypted password, you can use:
#                   /usr/bin/mkpasswd -H md5 --salt=$salt $password
#                   where $salt is 8 bytes long
#                   Note: On OpenBSD systems we can only manage crypted
#                         passwords.
#                         Therefor the password_crypted option doesn't have any
#                         effect.
#                         You'll find a python script in
#                         ${module}/password/openbsd/genpwd.py
#                         Which will help you to create such a password
# password_crypted: if the supplied password is crypted or not.
#                   Default: true
#                   Note: If you'd like to use unencrypted passwords, you have
#                         to set a variable $password_salt to an 8 character
#                         long salt, being used for the password.
# gid:              define the gid of the group
#                   absent: let the system take a gid
#                   uid: take the same as the uid has if it isn't absent
#                        (*default*)
#                   <value>: take this gid
# manage_group:     Wether we should add a group with the same name as well,
#                   this works only if you supply a uid.
#                   Default: true
define user::managed (
  Enum['present','absent']
  $ensure         = present,
  $name_comment     = 'absent',
  $uid              = 'absent',
  $gid              = 'uid',
  $groups           = [],
  $manage_group     = true,
  $membership       = 'minimum',
  $homedir          = 'absent',
  $managehome       = true,
  $homedir_mode     = '0750',
  $sshkey           = 'absent',
  $purge_ssh_keys   = false,
  $password         = 'absent',
  $password_salt    = false,
  $password_crypted = true,
  $allowdupe        = false,
  $shell            = 'absent'
) {
  $real_homedir = $homedir ? {
    'absent' => "/home/${name}",
    default  => $homedir
  }

  $real_name_comment = $name_comment ? {
    'absent' => $name,
    default  => $name_comment,
  }

  $real_shell = $shell ? {
    'absent' => '/bin/bash',
    default  => $shell,
  }

  if size($name) > 32 {
    fail("Usernames can't be longer than 32 characters. ${name} is too long!")
  }

  user { $name:
    ensure     => $ensure,
    allowdupe  => $allowdupe,
    comment    => $real_name_comment,
    home       => $real_homedir,
    managehome => $managehome,
    shell      => $real_shell,
    groups     => $groups,
    membership => $membership,
  }
  if $ensure != 'absent' {
    User[$name] {
      purge_ssh_keys => $purge_ssh_keys,
    }
  } else {
    # ensure all remaining processes are killed before removing
    exec { "pkill -u ${name}":
      onlyif => "bash -c \"test $(ps -u ${name} | grep -v PID | wc -l) -gt 0\"",
      before => User[$name],
    }
  }

  if $managehome {
    file { $real_homedir: }
    if $ensure == 'absent' {
      File[$real_homedir] {
        ensure  => absent,
        purge   => true,
        force   => true,
        recurse => true,
      }
    } else {
      File[$real_homedir] {
        ensure  => directory,
        require => User[$name],
        owner   => $name,
        mode    => $homedir_mode,
      }
      case $gid {
        'absent','uid': {
          File[$real_homedir] {
            group => $name,
          }
        }
        default: {
          File[$real_homedir] {
            group => $gid,
          }
        }
      }
    }
  }

  if $uid != 'absent' {
    User[$name] {
      uid => $uid,
    }
  }

  if $gid != 'absent' {
    if $gid == 'uid' {
      if $uid != 'absent' {
        $real_gid = $uid
      } else {
        $real_gid = false
      }
    } else {
      $real_gid = $gid
    }
    if $real_gid {
      User[$name] {
        gid => String($real_gid),
      }
    }
  }

  if $name != 'root' {
    if $uid != 'absent' and $ensure == 'present' {
      # unless not yet present, we want to add a subuid space for the user
      # this should be done before adding the user.
      # since we calculate the space using the max 65536 subuid space, we have
      # a stable distribution based on the uid/gid of a user
      if 'uids' in $facts['subids'] and !($name in $facts['subids']['uids']) {
        $subuid_start = String($uid * 65536)
        file_line {
          "${name}_subuid":
            ensure  => $ensure,
            line    => "${name}:${subuid_start}:65536",
            path    => '/etc/subuid',
            match   => "^${regexpescape($name)}:",
            require => User[$name];
        }
      }
      if $real_gid {
        if 'gids' in $facts['subids'] and !($name in $facts['subids']['gids']) {
          $subgid_start = String($real_gid * 65536)
          file_line {
            "${name}_subgid":
              ensure => $ensure,
              line   => "${name}:${subgid_start}:65536",
              path   => '/etc/subgid',
              match  => "^${regexpescape($name)}:",
          } -> Group<| title == $name |>
        }
      }
    }

    if $uid == 'absent' {
      if $manage_group and ($ensure == 'absent') {
        group { $name:
          ensure  => absent,
          require => User[$name],
        }
      }
    } else {
      if $manage_group {
        group { $name:
          ensure    => $ensure,
          allowdupe => false,
        }
        if $real_gid {
          Group[$name] {
            gid => String($real_gid),
          }
        }
        if $ensure == 'absent' {
          Group[$name] {
            require => User[$name],
          }
        } else {
          Group[$name] {
            before => User[$name],
          }
        }
      }
    }
  }
  if $ensure == 'present' {
    if $sshkey != 'absent' {
      User[$name] {
        before => Class[$sshkey],
      }
      include $sshkey
    }

    if $password != 'absent' {
      if $password_crypted {
        $real_password = $password
      } else {
        if $password_salt {
          $real_password = mkpasswd($password,$password_salt)
        } else {
          fail("To use unencrypted passwords for ${name} you have to define a variable \$password_salt to an 8 character salt for passwords!")
        }
      }
      User[$name] {
        password => $real_password,
      }
    }
  }
}
