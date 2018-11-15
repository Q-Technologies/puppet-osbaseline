# Class: osbaseline
class osbaseline::repos (
  # Class parameters are populated from module hiera data
  String $yum_conf_path,
  String $yum_repos_d,
  String $yum_log,

  # Class parameters are populated from External(hiera)/Defaults/Fail
  Data      $yum_defaults    = $::osbaseline::yum_defaults,
  Data      $zypper_defaults = $::osbaseline::zypper_defaults,
  Boolean   $purge_repos     = $::osbaseline::purge_repos,
  String    $proxy_url       = $::osbaseline::proxy_url,
  Boolean   $do_update       = false,
) {

  include stdlib

  $yum_all_repos  = lookup('osbaseline::repos::all_yum', Data, 'deep', {})
  $this_os        = downcase( $facts['os']['name'] )
  $yum_os_repos   = lookup("osbaseline::repos::${this_os}_yum", Data, 'deep', {})
  $yum_repos      = merge( $yum_all_repos, $yum_os_repos )
  $zypper_repos   = lookup('osbaseline::repos::zypper', Data, 'deep', {})
  $repos_to_purge = lookup('osbaseline::repos::purge', Collection, 'unique', [])

  file { $repos_to_purge:
    ensure => absent,
  }

  if $facts['os']['family'] =~ /RedHat|AIX/ {
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

    # Create the repositories based on the yum repo data found in hiera. If an osbaseline one is specified
    # and updates are turned on, then run the yum update.  For all other repos, just run a yum clean all.
    # Yum update will be notified and because it is refresh only, it will only run if the baseline has changed.

    $yum_repos.each | $name, $data | {
      $data2 = deep_merge( { 'name' => $name, descr => $name }, $yum_defaults, $data )
      if $name =~ /osbaseline/ and $::osbaseline_date and $::osbaseline_date =~ /^\d{4}\-\d{2}\-\d{2}$/ and $do_update {
        $execs = [ Exec['yum clean'], Exec['queue yum update' ] ]
      }
      else {
        $execs = [ Exec['yum clean'] ]
      }
      if !empty( $data ) and
          ( ( $name =~ /osbaseline/ and $::osbaseline_date and $::osbaseline_date =~ /^\d{4}\-\d{2}\-\d{2}$/ )
            or $name !~ /osbaseline/ ){
        file { "${yum_repos_d}/${name}.repo":
          ensure  => file,
          mode    => '0444',
          notify  => $execs,
          content => inline_epp(@(END), { name => $name, data => $data2 })
            [<%= $name %>]
            <% $data.each | $key, $value | { -%>
            <%= $key %>=<%= $value %>
            <% } -%>
            | END
        }
      }
    }

    exec { 'yum clean':
      command     => '/usr/bin/yum clean all',
      path        => '/bin:/usr/bin',
      refreshonly => true,
    }

    exec { 'queue yum update':
      command     => 'touch /tmp/need_yum_update',
      path        => '/bin:/usr/bin',
      notify      => Exec['yum update' ],
      refreshonly => true,
    }

    exec { 'yum update':
      command => '/usr/bin/yum distro-sync --assumeyes --disablerepo=\* --enablerepo=\*osbaseline\* && rm -f /tmp/need_yum_update',
      path    => '/bin:/usr/bin',
      onlyif  => 'bash -c "[[ -e /tmp/need_yum_update ]]"',
    }

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
