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

require '_ocr-shotnote3.pl';


my %pfs;
my $db = tie %pfs, 'DBM::Deep', 'pfs.db'; 

my %dfn;
my $db = tie %dfn, 'DBM::Deep', 'dfn.db'; 
my %doc;
my $db = tie %doc, 'DBM::Deep', 'doc.db'; 
my %noc;
my $db = tie %noc, 'DBM::Deep', 'noc.db'; 
my %grp;
my $db = tie %grp, 'DBM::Deep', 'grp.db'; 


my ($xdy, $xdm, $xdd, $xdH, $xdM, $xdS);
my @ps;
my $xdfn;
my $xdfnD;
my $k;
my $xndoc;
my $xnoc;
my $xdoc;
my $dmy;
my $i;
my $tbegin;
my $tend;
my $c_s;
my $c_d;
my $msg;

$tbegin = time();
$i = 0;
$c_s = 0;
$c_d = 0;
foreach $k (keys %pfs) {
    if($i%100==0) {
        print STDERR "; progress $i\n";
    }

    if(defined $dfn{$k}) {
        $xdfn = $dfn{$k};
    }
    else {
        @ps = split(/:/, $pfs{$k});
        if($ps[0] =~ /\/.*_(\d+)-(\d+)-(\d+) (\d+)_(\d+)_(\d+).jpe?g/i) {
#            $xdy = $1;
            $xdy = $1-2000;
            $xdm = $2;
            $xdd = $3;
            $xdH = $4;
            $xdM = $5;
            $xdS = $6;
            $xdfn = "$xdy$xdm$xdd"."_$xdH$xdM$xdS";

            $dfn{$k} = $xdfn;

        }
        else {
            $xdfn = "ERR";
            next;
        }
    }
    ($xdfnD,$dmy) = split(/_/, $xdfn);

    if(defined $doc{$k}) {
print "PASS A\n";
#        $xnoc = $noc{$k};
#        $xdoc = $doc{$k};
#        $xndoc = $noc{$k}.",".$doc{$k};
        $xndoc = $doc{$k};
    }
    else {
print "PASS B\n";
        if($ps[0] ne '') {
print "PASS B1\n";
            $xndoc = &ap($ps[0], 100);
            $xndoc =~ s/w/0/g;

#           ($xnoc, $xdoc) = split(/,/,  $xndoc);
#	    $doc{$k} = $xdoc;
#	    $noc{$k} = $xnoc;
           ($xnoc, $xdoc) = split(/,/,  $xndoc);
	    $doc{$k} = $xndoc;
        }
	else {
print "PASS B2\n";
	my $oqk='';
	    if(defined $noc{$k}) {
		$oqk .= 'N';
	    }
	    else {
		$oqk .= " ";
	    }
	    if(defined $doc{$k}) {
		$oqk .= 'D';
	    }
	    else {
		$oqk .= " ";
	    }
print "     $oqk\n";
	}
    }

    $msg = '';
    if($xdfnD eq "20".$xdoc) {
        $msg = "SAME";
        $c_s++;
    }
    else {
        $c_d++;
    }

    print "$i $k $xdfn $xndoc $msg\n";

    $i++;
}

$tend = time();
printf "; same %d %7.1f%%, diff %d %7.1f%%\n",
        $c_s, $c_s*100/$i, $c_d, $c_d*100/$i;
printf "; begin %12d\n", $tbegin;
printf "; end   %12d\n", $tend;
printf "; diff  %12d\n", $tend-$tbegin;
printf "; %d items, %f sec\n", $i, ($tend-$tbegin)/$i;
printf ";    + %f sec\n", ($tend-$tbegin-2)/$i;
printf ";    - %f sec\n", ($tend-$tbegin+2)/$i;

