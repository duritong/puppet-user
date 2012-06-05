define user::groups::manage_user(
  $ensure = 'present',
  $group,
  $user = 'absent'
){

  if ($user != 'absent'){
    $real_user = $user
  } else {
    $real_user = $name
  }

  augeas{"manage_${real_user}_in_group_${group}":
    context => '/files/etc/group',
  }
  if ($ensure == 'present'){
    Augeas["manage_${real_user}_in_group_${group}"]{
      changes => [ "set ${group}/user[last()+1] ${real_user}" ],
      onlyif => "match ${group}/*[../user='${real_user}'] size == 0"
    }
  } else {
    Augeas["manage_${real_user}_in_group_${group}"]{
      changes => "rm ${group}/user[.='${real_user}']",
    }
  }
}

