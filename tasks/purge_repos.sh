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
        else
            echo "Unsupported OS"
            exit 1
        fi
    elif [[ $(uname -s) = "AIX" ]]; then
        PT_repo_dir=/opt/freeware/etc/yum/yum.conf
    else
        echo "Unsupported OS"
        exit 1
    fi
fi

if [[ ! -d ${PT_repo_dir} ]]; then
    echo The expected directory was not found
    exit 1
elif [[ $(echo ${PT_repo_dir} | perl -ne 's/(^\/*|\/*$)//g; print int split( /\//, $_);') -lt 2 ]]; then
    echo "The path looks too short, aborting"
    exit
else
    rm -rf ${PT_repo_dir}/*
fi


