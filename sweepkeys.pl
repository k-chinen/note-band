#!/usr/bin/perl

use strict;
use DBM::Deep;
use Getopt::Std;

BEGIN {
    eval {
        require Digest::MD5;
        import Digest::MD5 'md5_hex'
    };
    if ($@) { # ups, no Digest::MD5
        require Digest::Perl::MD5;
        import Digest::Perl::MD5 'md5_hex'
    }     
}

my %pfs;
my $db = tie %pfs, 'DBM::Deep', 'pfs.db'; 

my $cn_n = 0;
my $cn_a = 0;
my $cn_s = 0;

sub process_file {
    my($fn) = @_;
    my $cnt;
    my $rk;
    my $k;
    
    $cnt = '';
    open(F, "$fn");
    while(<F>) {
        $cnt .= $_;
    }
    close(F);
    
    $rk = md5_hex($cnt);
    $k = "MD5:".$rk;

#   print "$rk  $fn\n";
#   print "$k  $fn\n";

    if(defined $pfs{$k}) {
        if($pfs{$k} ne $fn) {
            $pfs{$k} .= ":".$fn;
            $cn_a++;
        }
        else {
            $cn_s++;
        }
    }
    else {
        $pfs{$k} = $fn;
            $cn_n++;
    }
}


sub addadj_path {
    my($pre,$body) = @_;
    my $p;
    $p = $pre. "/". $body;
    $p =~ s#/./#/#g;
    $p =~ s#//#/#g;
    return $p;
}

sub process_dir {
    my($dn) = @_;
    my @fs;
    my $f;
    my $p;
print "DIR $dn\n";
    opendir(DIR, "$dn");
    @fs = readdir(DIR);
    foreach $f (@fs) {
        $p = addadj_path($dn, $f);
        if( $f eq '.' || $f eq '..') {
            next;
        }
        if(-d $p) {
            &process_dir($p);
        }
        elsif(-f $p) {
            &process_file($p);
        }
        else {
print "UNKNOWN $p\n";
        }
    }
    closedir(DIR);
}

my $f;
foreach $f (@ARGV) {
    if( -d $f) {
        &process_dir($f);
    }
    elsif( -f $f) {
        &process_file($f);
    }
    else {
        
    }
}

print "# new $cn_n, append $cn_a, same $cn_s\n"; 


