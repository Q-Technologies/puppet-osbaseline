# Class: osbaseline
class osbaseline::repos (
  # Class parameters are populated from module hiera data
  String $yum_conf_path,
  String $yum_repos_d,
  String $yum_log,

  # Class parameters are populated from External(hiera)/Defaults/Fail
  Data      $yum_defaults    = {},
  Data      $zypper_defaults = {},
  Boolean   $purge_repos = $::osbaseline::purge_repos,
  String    $proxy_url   = $::osbaseline::proxy_url,
) {

  $yum_all_repos  = hiera_hash('osbaseline::repos::all_yum', {})
  $this_os             = downcase( $facts['os']['name'] )
  $yum_os_repos   = hiera_hash("osbaseline::repos::${this_os}_yum", {})
  $yum_repos      = merge( $yum_all_repos, $yum_os_repos )
  $zypper_repos   = hiera_hash('osbaseline::repos::zypper',{})
  $repos_to_purge = hiera_array('osbaseline::repos::purge',[])

  file { $repos_to_purge:
    ensure => absent,
  }

  if $facts['os']['family'] =~ /RedHat|AIX|Suse/ {
    if $facts['os']['family'] == 'AIX' {
      file { '/etc/yum.conf' :
        ensure => link,
        target => $yum_conf_path,
      }
    }
    file { $yum_repos_d :
      ensure  => directory,
      recurse => $purge_repos,
      purge   => $purge_repos,
      mode    => '0755',
    }

    file { $yum_conf_path:
      ensure  => file,
      mode    => '0644',
      content => epp('osbaseline/yum.conf.epp', { yum_proxy_url => $proxy_url,
                                                  yum_repos_d   => $yum_repos_d,
                                                  os            => $this_os,
                                                  yum_log       => $yum_log,
                                                }),
    }

    create_resources('yumrepo', $yum_repos, $yum_defaults)

    if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
      service { 'choose_repo':
        ensure => stopped,
        enable => false,
      }
    }

  } elsif $::osfamily == 'Suse' {
    #notify { "$zypper_repos": }
    create_resources('zypprepo', $zypper_repos, $zypper_defaults)
    # Purging doesn't work by the moethod below - the zypprepo module will need to support it
    #file { '/etc/zypp/repos.d/':
    #ensure  => 'directory',
    #recurse => true,
    #purge   => true,
    #} 
  } else {
      fail("Wrong OS Family, should be RedHat, AIX or Suse, not ${::osfamily}")
  }


}
