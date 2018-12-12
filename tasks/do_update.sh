#!/bin/bash

if [[ -f /etc/redhat-release ]]; then
    command='/usr/bin/yum distro-sync --assumeyes --disablerepo=\* --enablerepo=\*osbaseline\*'
elif [[ -f /etc/SuSE-release ]]; then
    command='zypper dup -y'
elif [[ -f /etc/os-release ]]; then
    if [[ $(grep -ci suse /etc/os-release) -gt 0 ]]; then
        command='zypper dup -y'
    else
        (>&2 echo "Unsupported OS")
        exit 1
    fi
#elif [[ $(uname -s) = "AIX" ]]; then
else
    (>&2 echo "Unsupported OS")
    exit 1
fi

echo Performing upgrade now...
$command
