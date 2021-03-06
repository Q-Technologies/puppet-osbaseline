#!/bin/bash
repo_dir=${PT_repo_dir}

if [[ -z ${PT_repo_dir} ]]; then
    if [[ -f /etc/redhat-release ]]; then
        PT_repo_dir=/etc/yum.repos.d
    elif [[ -f /etc/SuSE-release ]]; then
        PT_repo_dir=/etc/zypp/repos.d
    elif [[ -f /etc/os-release ]]; then
        if [[ $(grep -ci suse /etc/os-release) -gt 0 ]]; then
            PT_repo_dir=/etc/zypp/repos.d
        elif [[ $(grep -ci redhat /etc/os-release) -gt 0 ]]; then
            PT_repo_dir=/etc/yum.conf
        else
            (>&2 echo "Unsupported OS")
            exit 1
        fi
    elif [[ $(uname -s) = "AIX" ]]; then
        PT_repo_dir=/opt/freeware/etc/yum/yum.conf
    else
        (>&2 echo "Unsupported OS")
        exit 1
    fi
fi

if [[ ! -d ${PT_repo_dir} ]]; then
    (>&2 echo "The expected directory was not found")
    exit 1
elif [[ $(echo ${PT_repo_dir} | perl -ne 's/(^\/*|\/*$)//g; print int split( /\//, $_);') -lt 2 ]]; then
    (>&2 echo "The path looks too short, aborting")
    exit 1
else
    echo "Defined repositories:"
    if [[ -f /etc/SuSE-release ]]; then
        zypper -D ${PT_repo_dir} lr -d
    elif [[ -f /etc/os-release ]]; then
        if [[ $(grep -ci suse /etc/os-release) -gt 0 ]]; then
            zypper -D ${PT_repo_dir} lr -d
        elif [[ $(grep -ci redhat /etc/os-release) -gt 0 ]]; then
            yum -c ${PT_repo_dir} repoinfo
        else
            (>&2 echo "Unsupported OS")
            exit 1
        fi
    elif [[ $(uname -s) = "AIX" ]]; then
        yum -c ${PT_repo_dir} repoinfo
    else
        (>&2 echo "Unsupported OS")
        exit 1
    fi
fi


