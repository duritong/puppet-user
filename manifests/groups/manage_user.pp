# manage a user in a group
define user::groups::manage_user(
  $ensure = 'present',
  $group,
  $user = $name,
){
  augeas{"manage_${user}_in_group_${group}":
    context => '/files/etc/group',
  }
  if ($ensure == 'present'){
    Augeas["manage_${user}_in_group_${group}"]{
      changes => [ "set ${group}/user[last()+1] ${user}" ],
      onlyif => "match ${group}/*[../user='${user}'] size == 0"
    }
  } else {
    Augeas["manage_${user}_in_group_${group}"]{
      changes => "rm ${group}/user[.='${user}']",
    }
  }
}

