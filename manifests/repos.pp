# Class: osbaseline
class osbaseline::repos (
  # Class parameters are populated from module hiera data
  String $yum_conf_path,
  String $yum_repos_d,
  String $yum_log,

  # Class parameters are populated from External(hiera)/Defaults/Fail
  Data      $yum_defaults     = $::osbaseline::yum_defaults,
  Data      $zypper_defaults  = $::osbaseline::zypper_defaults,
  Boolean   $purge_repos      = $::osbaseline::purge_repos,
  String    $proxy_url        = $::osbaseline::proxy_url,
  String    $multilib_policy  = $::osbaseline::multilib_policy,
  Boolean   $do_reboot        = false,
  Boolean   $do_update        = false,
  Boolean   $constant_enforce = false,
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

    # Turn off RedHat subscription if we are also purging the repos
    if $facts['os']['name'] == 'RedHat' and lookup('osbaseline::purge_repos', Boolean, 'first', true) {
      exec { 'remove RHEL subscriptions':
        command  => '/usr/sbin/subscription-manager remove --all && /usr/sbin/subscription-manager config --rhsm.auto_enable_yum_plugins=0',
        path     => '/usr/bin:/usr/sbin:/bin',
        provider => shell,
        unless   => "/usr/sbin/subscription-manager status | perl -nE 'exit 1 if /Overall Status: Current/'",
        before   => Class['osbaseline'],
      }
      if $facts['os']['release']['major'] == '6' {
        ini_setting { 'rhn subscription':
          ensure  => present,
          path    => '/etc/yum/pluginconf.d/subscription-manager.conf',
          section => 'main',
          setting => 'enabled',
          value   => 0,
          require => Exec['rhsm auto_enable_yum_plugins'],
        }
      }
      #if $facts['os']['release']['major'] == '7' {
      exec { 'rhsm auto_enable_yum_plugins':
        command  => '/usr/sbin/subscription-manager config --rhsm.auto_enable_yum_plugins=0',
        onlyif   => '/usr/sbin/subscription-manager config | grep -q "auto_enable_yum_plugins = \[1\]"',
        path     => '/usr/bin:/usr/sbin:/bin',
        provider => shell,
        before   => Class['osbaseline'],
      }
      #}
      exec { 'rhsm manage_repos':
        command  => '/usr/sbin/subscription-manager config --rhsm.manage_repos=0',
        onlyif   => '/usr/sbin/subscription-manager config | grep -q "manage_repos = \[1\]"',
        path     => '/usr/bin:/usr/sbin:/bin',
        provider => shell,
        before   => Class['osbaseline'],
      }
    }

    file { $yum_conf_path:
      ensure  => file,
      mode    => '0644',
      content => epp('osbaseline/yum.conf.epp', {
                                                  yum_proxy_url   => $proxy_url,
                                                  yum_repos_d     => $yum_repos_d,
                                                  os              => $this_os,
                                                  yum_log         => $yum_log,
                                                  multilib_policy => $multilib_policy,
                                                }),
    }

    # Create the repositories based on the yum repo data found in hiera. If an osbaseline one is specified
    # and updates are turned on, then run the yum distro-sync.  For all other repos, just run a yum clean all.
    # Yum distro-sync will be notified and because it is refresh only, it will only run if the baseline has changed.

    # Currently the yum distro-sync is only triggered on a repo change (i.e. data change), an enhancement will be to
    # always check whether a distro-sync needs to be done

    $yum_repos.each | $name, $data | {
      $data2 = deep_merge( { 'name' => $name, descr => $name }, $yum_defaults, $data )
      if $name =~ /osbaseline/ and $::osbaseline_date and $::osbaseline_date =~ /^\d{4}\-\d{2}\-\d{2}$/ and
          $do_update and !$constant_enforce {
        $execs = [ Exec['yum clean'], Exec['queue yum distro-sync' ] ]
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

    exec { 'queue yum distro-sync':
      command     => 'touch /tmp/need_yum_update',
      path        => '/bin:/usr/bin',
      notify      => Exec['yum distro-sync' ],
      refreshonly => true,
    }

    if $constant_enforce {
      $onlyif = '! yum distro-sync --assumeno'
    } else {
      $onlyif = 'bash -c "[[ -e /tmp/need_yum_update ]]"'
    }

    exec { 'yum distro-sync':
      command => '/usr/bin/yum distro-sync --assumeyes --disablerepo=\* --enablerepo=\*osbaseline\* && rm -f /tmp/need_yum_update',
      path    => '/bin:/usr/bin',
      onlyif  => $onlyif,
    }
    if $do_reboot {
      reboot { 'reboot after yum distro-sync':
        subscribe => Exec['yum distro-sync'],
        apply     => finished,
      }
    }

    if $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '7' {
      service { 'choose_repo':
        ensure => stopped,
        enable => false,
      }
    }

  } elsif $facts['os']['family'] == 'Suse' {
    #notify { "$zypper_repos": }
    create_resources('zypprepo', $zypper_repos, $zypper_defaults)
    # Purging doesn't work by the moethod below - the zypprepo module will need to support it - 
    # or purge with a puppet task included in this module
    #file { '/etc/zypp/repos.d/':
    #ensure  => 'directory',
    #recurse => true,
    #purge   => true,
    #} 
  } else {
      fail("Wrong OS Family, should be RedHat, AIX or Suse, not ${facts['os']['family']}")
  }


}
