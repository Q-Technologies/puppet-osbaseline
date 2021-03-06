# Class: osbaseline
class osbaseline (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Boolean $enforce_baseline = true,
  Boolean $purge_repos      = false,
  String  $proxy_url        = '',
  Data    $yum_defaults     = {},
  Data    $zypper_defaults  = {},
  Data    $multilib_policy  = 'best',
  String  $repo_server      = 'http://mirrorlist.centos.org',
) {

  if $facts['os']['family'] =~ /RedHat|Suse|AIX/ {
    # only continue if baseline_date is set and matches YYYY-MM-DD (roughly) - unless we are not enforcing baseline
    if $enforce_baseline and !( $::osbaseline_date and $::osbaseline_date =~ /^\d{4}\-\d{2}\-\d{2}$/ ) {
      fail("osbaseline module requires the 'osbaseline_date' variable to be set in YYYY-MM-DD format (got [${::osbaseline_date}])")
    } else {
      include osbaseline::repos
    }
  }

  # The following will only install things if directed to by hiera - set osbaseline::scripts::install to true for the relevant scope
  include osbaseline::scripts
}
