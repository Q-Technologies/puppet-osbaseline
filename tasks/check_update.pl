#!/usr/bin/env perl

use strict;
use YAML;
use 5.10.0;

chomp( my @installed = `rpm -qa --qf '%{NAME}.%{ARCH} %{VERSION}-%{RELEASE}\n'` );
my $packages = {};
for my $pkg ( @installed ){
    my ( $name, $version ) = split /\s+/, $pkg;
    $packages->{$name} = $version;
}

#chomp( my @updates = `yum -q check-update --disablerepo=\* --enablerepo=\*osbaseline\*` );
chomp( my @updates = `yum distro-sync --assumeno --disablerepo=\* --enablerepo=\*osbaseline\*` );

for( @updates ){
    say $_;
}
exit 0;

# Structured data not working for all scenarios - so not active for now

for(my $i=0; $i<@updates; $i++) {
    # delete any blank or heading lines
    if( $updates[$i] =~ /(^$)|Obsoleting/ ) {
        splice @updates, $i, 1;
        $i--;
        next;
    }
    # If we only have a package on this line, append the next line, then delete it
    if( $updates[$i] =~ /^\S+$/ ){
        splice @updates, $i, 1, $updates[$i].' '.$updates[$i+1];
        splice @updates, $i+1, 1;
    }
    # treat any lines lines that start with whitespace as actually belonging to the previous line and merge the data
    $updates[$i] =~ s/^\s+/supercedes:/;
    if( $updates[$i] =~ /supercedes/ ){
        # delete previous lines and adjust $i accordingly
        $i--;
        my $previous = splice @updates, ($i), 1;
        # we're back on our original line
        my ( $pkg_s, $version_s, $repo_s ) = split /\s+/, $updates[$i];
        $pkg_s =~ s/supercedes://g;
        my $pkg_info = { new_name => $previous->{name}, current => $version_s, target => $previous->{current}, name => $pkg_s };
        splice @updates, $i, 1, $pkg_info;
    } else {
        my ( $pkg, $version, $repo ) = split /\s+/, $updates[$i];
        my $pkg_info = { current => $version, target => $packages->{$pkg}, name => $pkg };
        splice @updates, $i, 1, $pkg_info;
    }
}

my $output = {};

for my $pkg_info ( @updates ){
    $output->{$pkg_info->{name}} = { current => $pkg_info->{current}, target => $pkg_info->{target} };
    $output->{$pkg_info->{name}}{new_name} = $pkg_info->{new_name} if $pkg_info->{new_name};
}
say Dump( $output );
