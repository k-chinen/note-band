#!/usr/bin/perl

use strict;
use Getopt::Std;

my %opt;
getopts('hsvnf' => \%opt);

my $thispgn = $0;
#print STDERR $thispgn."\n";

my $printfilename = 0;
if($opt{'f'}) {
    $printfilename = 1;
}

my $verbose = 0;
if($opt{'v'}) {
    $verbose = 1;
}

my $noaction = 0;
if($opt{'n'}) {
    $noaction = 1;
}

if($opt{'h'}) {
    print <<EOM;
usage: $0 [options]
usage: $0 [options] -s [files]
options:
    -h      print this message
    -s      scan specified files
    -v      verbose mode
    -n      no action; print only

  debug
    -f      print filename

example:
    $0 -s u1.pl

EOM
    exit 0;
}


sub scanprogram {
    my(@ar) = @_;
    my $f;
    my @oar;
    @oar = ();
    foreach $f (@ar) {
        open(F, "<$f");
        while(<F>) {
            if(/DBM::Deep',\s*'([^']*)'\s*;/) {
                if($printfilename) {
                    print "$f ";
                }
                print "$1\n";
                push(@oar, $1);
            }
        }
        close(F);
    }
    return @oar;
}

sub removefiles {
    my(@ar) = @_;
    my $f;
    my $s;
    my $c;

    $s = 0;
    foreach $f (@ar) {
        if($f =~ /\.db$/ || $f =~ /\.hdb$/) {
        }
        else {
            print "skip file $f\n";
            next;
        }

        if($verbose) {
            print STDERR "target $f\n";
        }
        if(!$noaction) {
            $c = unlink($f);
            if($c) {
                print "  success unlink <$c>\n";
            }
            else {
                print "  fail    unlink <$c>\n";
            }
        }
    }
}


my @targets;

@targets = ();

if($opt{'s'}) {
    @targets = &scanprogram(@ARGV);
}
else {
    @targets = ('pfs.db', 'dfs.db', 'dfn.db', 'doc.db', 'noc.db',
                'grp.db', 'ar.db');
}


&removefiles(@targets);



