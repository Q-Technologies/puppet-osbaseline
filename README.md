# osbaseline

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Description](#description)
* [Setup](#setup)
  * [What osbaseline affects](#what-osbaseline-affects)
  * [Setup Requirements](#setup-requirements)
  * [Beginning with osbaseline](#beginning-with-osbaseline)
* [Usage - For Repository Users](#usage---for-repository-users)
  * [Repositories only](#repositories-only)
  * [Manage OS Baseline](#manage-os-baseline)
    * [Included Scripts to Manage Groups](#included-scripts-to-manage-groups)
      * [Bootstrapping](#bootstrapping)
    * [Script to Manage OS Baseline groups](#script-to-manage-os-baseline-groups)
      * [Examples](#examples)
        * [Initialize the groups in the Classifier](#initialize-the-groups-in-the-classifier)
        * [Add a couple of baseline groups](#add-a-couple-of-baseline-groups)
        * [Move nodes from one baseline to another](#move-nodes-from-one-baseline-to-another)
        * [See which groups certain nodes are in](#see-which-groups-certain-nodes-are-in)
        * [Remove a group even if nodes are pinned to it](#remove-a-group-even-if-nodes-are-pinned-to-it)
* [Usage - For Repository Servers](#usage---for-repository-servers)
* [Limitations](#limitations)
* [Development](#development)

<!-- vim-markdown-toc -->

## Description

This module provides the ability to easily manage Operating System baseline levels.  It does 
this by setting up the package repositories (YUM for RedHat/AIX and Zypper for Suse).  It can 
be used to manage any repositories, but it's designed to work smoothly with https://github.com/Q-Technologies/lobm (the 
Linux OS Baseline Maker) - which basically uses symbolic links to snapshot repositories by date, ensuring all systems
have exacting the same patches (package versions) installed for each baseline.

## Setup

### What osbaseline affects

The client component manages the package repositories a client is pointing to.  The server component installs scripts 
on the requested servers.

### Setup Requirements

It requires hiera data to drive the configuration and a set of groups in the classifier (setting an appropriate variable).
The groups in the classifier are populated with scripts to make it easier to bulk move clients from one baseline to another.

### Beginning with osbaseline

Simply include or call the class:
```
include osbaseline
```

or
```
class { 'osbaseline': }
```

If called on an unsupported OS, it will be ignored.

The `purge_repos` option will force all unmanaged repositories to be removed.

## Usage - For Repository Users

### Repositories only

If you just want to use it to manage generic repositories (i.e. not date based), set **enforce_baseline** to false in heira or when calling the class:
```
class { 'osbaseline':
  enforce_baseline = false
}
```
Or, in hiera, e.g. `data/os/AIX.yaml`:
```
osbaseline::enforce_baseline: false
```

Inside your Hiera you need to define the location of the repositories to be managed, e.g.:
```

osbaseline::repos::all_yum:
  'linuxutil':
    descr: 'Common Linux Utilities Repo'
    name: 'LinuxUtil'
    baseurl: "http://%{::yum_server}/apps/linuxutil/%{::operatingsystem}/%{::operatingsystemmajrelease}"
    enabled: 1
    sslverify: 0

osbaseline::repos::redhat_yum:
  'osbaseline':
    descr: "%{::operatingsystem} %{::operatingsystemmajrelease} Baseline %{::osbaseline_date}"
    name: "%{::operatingsystem}_baseline_%{::osbaseline_date}"
    baseurl: "http://%{::yum_server}/baselines/%{::operatingsystem}%{::operatingsystemmajrelease}_%{::osbaseline_date}"
    sslverify: 0

osbaseline::repos::centos_yum:
  'osbaseline':
    descr: "%{::operatingsystem} %{::operatingsystemmajrelease} Baseline %{::osbaseline_date}"
    name: "%{::operatingsystem}_baseline_%{::osbaseline_date}"
    baseurl: "http://%{::yum_server}/baselines/%{::operatingsystem}%{::operatingsystemmajrelease}_%{::osbaseline_date}"
    sslverify: 0

```

**Note: the repository that corresponds to the OS baseline must be labeled: `osbaseline` for the automated upgrading to work.**

The `all_yum` data goes to all Linux systems that understand yum (e.g. RHEL, Centos, OEL and AIX (if configured)).  The `redhat_yum` data only goes onto
redhat branded systems, likewise for `centos_yum`.  This data is found by the module by looking in Heira for a key matching the `$facts['os']['name']` + `_yum`.  This provides
 the ability to direct 
the correct repos to the different vendors of Enterprise Linux - i.e., so you don't put Red Hat patches onto Centos or vice versa.

The module does a deep merge when looking for the repository data, so that different roles or nodes can add to the repository list without having to redefine them all each time.

The `baseurl` of the repository must match whatever URLs you are serving the baselines as on your YUM server.  The `osbaseline_date` date is set according in the node classifier (described in the next section) - again, this date needs to align to the YUM repo baselines.


### Manage OS Baseline
If you want to enforce an OS Baseline as well as manage the repositories, you will need to set up some Node Classifer groups (or otherwise set
a global variable with the baseline version).  If this variable is not set it will fail a Puppet run saying the baseline variable is not set.

If using the Node Classifer, create a group that matches all the nodes you want to manage and set up a variable with the date of the 
baseline, e.g.: `osbaseline_date` = `2018-09-30`.  This can also be achieved by setting a fact, but is harder to manage.  

Create additional groups with different dates and move hosts between them as desired.  The repository URIs will be updated accordingly
on the next Puppet runs.

If `osbaseline::repos::do_update` is set to `true` in Hiera, the `yum distro-sync` operation will be run against the baseline repo only.

If `osbaseline::repos::do_reboot` is set to `true` in Hiera, the system will be rebooted after the puppet run has completed.

#### Included Scripts to Manage Groups
There are included scripts to manage the creation of the groups and to make it easier to move nodes between the groups.  The scripts are managed through hiera.

```
# The following hiera are the defaults and can be overridden
osbaseline::scripts::selection_script_path: /usr/local/bin/baseline_selection
osbaseline::scripts::selection_config_path: /usr/local/etc/baseline_selection.yaml
osbaseline::scripts::selection_config:
  puppet_classify_host: puppet
  puppet_classify_port: 4433
  puppet_classify_cert: api_access
  puppet_ssl_path: /etc/puppetlabs/puppet/ssl
  puppetdb_host: localhost
  puppetdb_port: 8080
  group_names_prefix: OS Baseline
```

```
# The following are more site specific and must be set up in the environment hiera
osbaseline::scripts::install: true
osbaseline::scripts::selection_config:
  default_osbaseline_date: '2017-08-31'
  default_group_rule: [ 'and', [ '~', ['facts','os', 'release', 'major'], '^[67]$'], [ '=', ['facts','os', 'family'], 'RedHat'] ]
```

It reality, this needs to be run on the Puppet master due to access to certificates.  If you want to run on another host, you can copy the 
access cert and the CA to another host.  Use `puppetserver ca generate --certname api_access` (or `puppet cert generate api_access` in older installations)
to create a cert, add it to `/etc/puppetlabs/console-services/rbac-certificate-whitelist`
and restart the console services.

**Note: There is no mechanism to stop a node being pinned to two groups.  If this happens, Puppet will fail, and you'll need to make sure each node is only in one group.**

##### Bootstrapping

In order to get these scripts installed using Puppet, you will need to turn off enforcae baseline to as the Puppet run will fail if the groups do 
not exist in the Classifier.  Set this in hiera in the puppet master scope:

    osbaseline::enforce_baseline: false

#### Script to Manage OS Baseline groups
```
baseline_selection -a action -g group [-f] [node1] [node2] [node3]
```

* `-a`, the script actions:
  * `init_soe` - create the default group. All nodes matched by the `default_group_rule` will go into this group and receive 
the `default_osbaseline_date`.  They will receive a different date by being in a new baseline group.
  * `add_group` - add a new baseline group
  * `remove_group` - remove the specified group
  * `add_to_group` - pin a node to a group
  * `remove_from_group` - remove the specified nodes from a group
  * `empty_group` - empty a group of the nodes pinned to it
  * `list_group` - list the nodes pinned to a group
  * `list_groups` - list all the sub groups in parent baseline group
  * `purge_old_nodes` - remove all the nodes not found in the PuppetDB
  * `show_membership_of_nodes` - show which groups nodes are members of (all nodes will be show if none are specified)
* `-g`, specify a group name
* `-f`, force, e.g force the removal of a group even if nodes are pinned to it
* the list of nodes are required when adding/removing from a group

##### Examples

###### Initialize the groups in the Classifier

    baseline_selection -a init_soe

###### Add a couple of baseline groups

    baseline_selection -a add_group -g 2018-09-30
    baseline_selection -a add_group -g 2018-10-31

###### Move nodes from one baseline to another

It will automatically unpin from any previous groups the nodes were in.
    
    cat > host.list
    node1.example.com 
    node2.example.com 
    node3.example.com
    <ctrl-d>
    baseline_selection -a add_to_group -g 2018-10-31 `cat host.list`

###### See which groups certain nodes are in

    baseline_selection -a show_membership_of_nodes node1.example.com node4.example.com
    ---
    node1.example.com: 'OS Baseline : 2018-10-31'
    node4.example.com: Not pinned to any group

###### Remove a group even if nodes are pinned to it

    baseline_selection -a remove_group -f

## Usage - For Repository Servers
Include the `osbaseline::server` class in the profile of your repository server:
```
  class { 'osbaseline::server': }
```

Create Hiera data along these lines for the server of the repositories:
```
osbaseline::server::configuration:
  baseline_dir: "/repository/baselines/"
  http_served_from: "/repository"
  http_server_uri: "http://yumrepo.example.com/repo"
  createrepo_cmd: "/usr/bin/createrepo"
  workers: 2

osbaseline::server::definitions:
  "CentOS_7_2017-08-31":
    description: Centos 7 as at the end of August 2017
    target: centos
    versions: 1 
    rpm_dirs:
      -
        dir: /repository/os/CentOS/7/base/x86_64/Packages/
        date: "2017-08-31"
      -
        dir: /repository/os/CentOS/7/updates/x86_64/Packages/
        date: "2017-08-31"
  "OracleLinux_7_2017-08-31":
    description: OracleLinux 7 as at the end of August 2017
    target: rhel
    versions: 1 
    rpm_dirs:
      -
        dir: /repository/os/OracleLinux/7/base/x86_64/Packages/
        date: "2017-08-31"
      -
        dir: /repository/os/OracleLinux/7/updates/x86_64/Packages/
        date: "2017-08-31"
```
We assume the relevant directories are exported via the Web.  NGINX config might look like this:
```
nginx::nginx_servers:
  'yum_repo':
    listen_port: 80
    server_name: ["yumrepo.example.com"]
    access_log: '/var/log/nginx/yum_repo.access.log'
    error_log: '/var/log/nginx/yum_repo.error.log'
    use_default_location: false
    locations:
      'repo_80':
        location: '/repo/'
        autoindex: 'on'
        www_root: '/repository/'
```
A cron entry could be created along these lines (depending on the module you are using):
```
cron_entries:
  'create_centos_baseline':
    command: '/usr/bin/lobm -c /etc/lobm/baselines/CentOS_7_2017-08-31.yaml -o $(date -d yesterday +''\%Y-\%m-\%d'')'
    user: 'yumrepo'
    hour: '0'
    minute: '0'
    monthday: '1'
```


## Limitations

Only tested on AIX, EL and Suse systems.  It is not designed for Debian based systems.

## Development

If you would like to contribute to or comment on this module, please do so at it's Github repository.  Thanks.

