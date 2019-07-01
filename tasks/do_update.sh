#!/bin/bash
FILE="/tmp/linux_do_update.log"
if [[ -f /etc/redhat-release ]]; then
    command='package-cleanup --oldkernels --count=1 --assumeyes && /usr/bin/yum distro-sync --assumeyes --disablerepo=* --enablerepo=*osbaseline*'
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
eval $command > ${FILE}
if [[ $? -ne 0 ]]; then
    echo "Error patching host: $(hostname -f)" >> ${FILE}
else
    mkdir -p /etc/puppetlabs/facter/facts.d/
    echo "osbaseline_update_last_run=$(date '+%Y-%m-%d %T')" > /etc/puppetlabs/facter/facts.d/osbaseline_update_last_run.txt    
fi
cat ${FILE}

