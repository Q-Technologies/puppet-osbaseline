# osbaseline

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with osbaseline](#setup)
    * [What osbaseline affects](#what-osbaseline-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with osbaseline](#beginning-with-osbaseline)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module provides the ability to easily manage Operating System baseline levels.  It does 
this by setting up the package repositories (YUM for RedHat/AIX and Zypper for Suse).  It can 
be used to manage any repositories, but it's designed to work smoothly with https://github.com/Q-Technologies/lobm (the 
Linux OS Baseline Maker) - which basically uses symbolic links to snapshot repositories by date, ensuring all systems
have exacting the same patches (package versions) installed.

## Setup

### What osbaseline affects

It manages the package repositories a client is pointing to.

### Setup Requirements

It requires hiera data to drive the configuration and a set of groups in the classifier (setting an appropriate variable).

### Beginning with osbaseline

Simply include or call the class:
```
include osbaseline
```

or
```
class { 'osbaseline': }`
```

## Usage

If you just want to use it to manage generic repositories, set **enforce_baseline** to false in heira or when calling the class:
```
class { 'osbaseline':
  enforce_baseline = false
}`
```
Otherwise it will fail a Puppet run saying the baseline variable is not set.

To use in baseline mode, create a group in the Classifier that matches all the nodes you want to manage and set up a variable the date of the 
baseline, e.g.: `::osbaseline_date = 2017-09-30`.  This can also be acheived by setting a fact, but is harder to manage.  

Create additional groups with different dates and move hosts between them as desired.  The repository URIs will be updated accordingly
on the next Puppet runs.

## Limitations

Only tested on AIX, EL and Suse systems.  It is not designed for Debian based systems.

## Development

If you would like to contribute to or comment on this module, please do so at it's Github repository.  Thanks.

