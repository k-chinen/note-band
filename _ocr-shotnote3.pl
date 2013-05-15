#!/usr/bin/perl -w

use strict;
use Image::Magick;

my %ca;

#
# this program seprate charactor area into 7 sub-areas
# for line detection.
#
# 1166      3333
# 1166      3333
# 1166      4444
# 2277      4444
# 2277      5555
# 2277      5555
#
#

$ca{"0000000"} = "0";
$ca{"1110111"} = "0";
$ca{"0000011"} = "1";
$ca{"0111110"} = "2";
$ca{"0011111"} = "3";
$ca{"1001011"} = "4";
$ca{"1011101"} = "5";
$ca{"1111101"} = "6";
$ca{"1010011"} = "7";
$ca{"1111111"} = "8";
$ca{"1011111"} = "9";

my $_hlthre = 45;
my $_vlthre = 45;
my $_err_letter = '@';
my $_sep_letter = ',';
my $_spc_letter = 'w';

my $Lck_debug = 0;
my $Lck_algo  = 0;


sub Ldump {
    my($cw, $ch, $nar) = @_;
    my $hhh;
    my $vvv;
    my $ppp;
    my $ggg;
    my $mm;
    my $lno;

    print STDERR "---\n";
        $ggg = ''; 
        for($vvv=0;$vvv<$cw;$vvv++) {
            $ggg .= sprintf("%d", $vvv%10);
        }
        print STDERR " .. . $ggg\n";
    for($hhh=0;$hhh<$ch;$hhh++) {
        $lno = sprintf("%2d", $hhh);
        $ggg = ''; 
        for($vvv=0;$vvv<$cw;$vvv++) {
            $ppp = $hhh*$cw + $vvv;
            $ggg .= @$nar[$ppp];
        }
        $mm = ' ';
        if($hhh== int($ch/4) || $hhh== int($ch*3/4)) {
            $mm = '.';
        }
        elsif($hhh== int($ch/3) || $hhh== int($ch*2/3)) {
            $mm = '-';
        }
        elsif($hhh== int($ch/2)) {
            $mm = '=';
        }
        print STDERR " $lno $mm $ggg\n";
    }   
}

sub LdumpD {
    my($cw, $ch, $nar) = @_;
    my $hhh;
    my $vvv;
    my $ppp;
    my $ggg;
    my $mm;
    my $lno;

    print STDERR "---\n";
        $ggg = ''; 
        for($vvv=0;$vvv<$cw;$vvv++) {
            $ggg .= sprintf("%d", $vvv%10);
        }
        print STDERR " .. . $ggg\n";
    for($hhh=0;$hhh<$ch;$hhh++) {
        $lno = sprintf("%2d", $hhh);
        $ggg = ''; 
        for($vvv=0;$vvv<$cw;$vvv++) {
            $ppp = $hhh*$cw + $vvv;
            $ggg .= @$nar[$ppp];
        }
        $ggg =~ s/0/./g;
        $mm = ' ';
        if($hhh== int($ch/4) || $hhh== int($ch*3/4)) {
            $mm = '.';
        }
        elsif($hhh== int($ch/3) || $hhh== int($ch*2/3)) {
            $mm = '-';
        }
        elsif($hhh== int($ch/2)) {
            $mm = '=';
        }
        print STDERR " $lno $mm $ggg\n";
    }   
        $ggg = ''; 
        for($vvv=0;$vvv<$cw;$vvv++) {
            $ggg .= sprintf("%d", $vvv%10);
        }
        print STDERR " .. . $ggg\n";
}

#
# BoundingBox check
# 
sub BBck {
    my($cw, $ch, $sx1, $sy1, $sx2, $sy2, $nar) = @_;
#   my($dx1, $dy1, $dx2, $dy2) = (
    my($xmin, $xmax, $ymin, $ymax) = (100000, -1, 100000, -1);
    my($x,$y);
    my($p);

    for($y=$sy1;$y<$sy2;$y++) {
        for($x=$sx1;$x<$sx2;$x++) {
            $p = $y*$cw+$x;
            if(@$nar[$p]>0) {
                if($x<$xmin) {  $xmin = $x;}
                if($x>$xmax) {  $xmax = $x;}
                if($y<$ymin) {  $ymin = $y;}
                if($y>$ymax) {  $ymax = $y;}
            }
        }
    }

#    if($Lck_debug) {
#        print STDERR "BB $xmin, $ymin, $xmax, $ymax\n";
#    }
    return ($xmin, $ymin, $xmax, $ymax);
}

#
# Reagion check
# returns
#   horizontal line 'H'
#   veritical line  'V'
#   otherwise       'E'
#
sub Rck {
    my($cw, $ch, $sx1, $sy1, $sx2, $sy2, $nar) = @_;
    my @bb;
    my ($w, $h, $a);
    my ($c, $m, $r);
    my ($x, $y, $p);
    my $rv='E';

    if($Lck_debug) {
#        print STDERR "R $cw x $ch ; $sx1 $sy1 $sx2 $sy2\n";
        print STDERR "seg $sx1 $sy1 $sx2 $sy2\n";
    }

    @bb = BBck($cw, $ch, $sx1, $sy1, $sx2, $sy2, $nar);

    if($bb[2]<0 || $bb[3]<0) {
        return $rv;
    }

    $w = $bb[2] - $bb[0] + 1;
    $h = $bb[3] - $bb[1] + 1;
    $m = $w*$h;
    $c = 0;
    $r = -1;
    $a = -1;

    if($h>0 && $w>0) {
        for($y=$bb[1];$y<=$bb[3];$y++) {
            for($x=$bb[0];$x<=$bb[2];$x++) {
                $p = $y*$cw + $x;
                if(@$nar[$p]>0) {
                    $c++;
                }
            }   
        }
        $r = $c*100/$m;

        # reject sparse BB
        if($r>=30) {
            $a = $w/$h;

            # width larger than height -> horizontal
            if($a>1) {
                if($w>$cw/3) {
                    $rv = 'H';
                }
            }
            else {
                if($h>$ch/5) {
                    $rv = 'V';
                }
            }
        }
    }

    if($Lck_debug) {
        printf STDERR 
        "  size %2d, %2d / %4.1f,%4.1f (area %3d / %3d) %5.1f%% aspect %5.2f -> %s\n",
            $w, $h, $cw/3, $ch/5, $c, $m, $r, $a, $rv;
    }

    return $rv;
}


# removevlines($cw, $ch, $nar)
sub removevlines {
    my($cw, $ch, $nar) = @_;

    my $vvv;
    my $hhh;
    my $ppp;
    my $ppp2;
    my $ggg;
    my $ggg2;
    my $mm;
    my $qqq;
    my $nx;
    my $ny;
    my $cx;
    my $cy;

Y:  for($hhh=0;$hhh<$ch-1;$hhh++) {
X:      for($vvv=0;$vvv<$cw-1;$vvv++) {
            $ppp  = $hhh*$cw + $vvv;
            $ggg  = @$nar[$ppp];
            if($ggg>0) {
                $nx = $vvv;
                $ny = $hhh;
                
                while(1) {
                    $ppp2 = $ny*$cw + $nx;
                    $ggg2 = @$nar[$ppp2];
                    if($ggg2>0 && $nx<$cw-1) {
                        $nx++;
                    }
                    else {
                        last;
                    }
                }
                
#                if($Lck_debug) {
#                    print STDERR "hhh $hhh vvv $vvv nx $nx\n";
#                }
                if($nx-$vvv<$cw/4) {
#                    if($Lck_debug) {
#                        print STDERR "    CLEAR\n";
#                    }
                    for($cx=$vvv;$cx<$nx;$cx++) {
                        $ppp2 = $ny*$cw + $cx;
                        @$nar[$ppp2] = '0';
                    }
                }

                $vvv = $nx;
            }
        }
    }
#    if($Lck_debug) {
#        &LdumpD($cw, $ch, $nar);
#    }
}


# removehlines($cw, $ch, $nar)
sub removehlines {
    my($cw, $ch, $nar) = @_;

    my $vvv;
    my $hhh;
    my $ppp;
    my $ppp2;
    my $ggg;
    my $ggg2;
    my $mm;
    my $qqq;
    my $nx;
    my $ny;
    my $cx;
    my $cy;

X:  for($vvv=0;$vvv<$cw-1;$vvv++) {
Y:      for($hhh=0;$hhh<$ch-1;$hhh++) {
            $ppp  = $hhh*$cw + $vvv;
            $ggg  = @$nar[$ppp];
            if($ggg>0) {
                $nx = $vvv;
                $ny = $hhh;
                
                while(1) {
                    $ppp2 = $ny*$cw + $nx;
                    $ggg2 = @$nar[$ppp2];
                    if($ggg2>0 && $ny<$ch-1) {
                        $ny++;
                    }
                    else {
                        last;
                    }
                }

#                if($Lck_debug) {
#                    print STDERR "hhh $hhh vvv $vvv ny $ny\n";
#                }
                if($ny-$hhh<$cw/4) {
#                    if($Lck_debug) {
#                        print STDERR "    CLEAR\n";
#                    }
                    for($cy=$hhh;$cy<$ny;$cy++) {
                        $ppp2 = $cy*$cw + $nx;
                        @$nar[$ppp2] = '0';
                    }
                }

                $hhh = $ny;
            }
        }
    }
#    if($Lck_debug) {
#        &LdumpD($cw, $ch, $nar);
#    }
}

#
# trim right and bottom line
#
sub trimRB {
    my($cw, $ch, $nar) = @_;
    my($x, $y, $p);
    for($y=0;$y<$ch;$y++) {
        $x = $cw-1;
        $p = $y*$cw+$x;
        @$nar[$p] = 0;
    }
    for($x=0;$x<$cw;$x++) {
        $y = $ch-1;
        $p = $y*$cw+$x;
        @$nar[$p] = 0;
    }
}

sub guessvthre {
    my ($nq) = @_;
    my %freq;
    my $fsum;
    my $fsumra;
    my $hh;
    my $vmin;
    my $vmax;
    my $_t33;
    my $_t50;    
    my $p;
    my $len;

#print STDERR "guessvthre:\n";
    $len = scalar(@$nq)."\n";

    $p = 0;
    foreach (@$nq) {
        if($p%3==0) {
            $freq{$_}++;
        }
        $p++;
    }
    $fsum = 0;
    $_t33 = -1;
    $_t50 = -1;
    foreach $p (sort {$a<=>$b} keys %freq) {
        if($fsum==0) {
            $vmin = $p;
        }
        $fsum += $freq{$p};
        $fsumra = $fsum*100/($len/3);
        if($Lck_debug) {
            $hh = '*'x(int($fsumra/2));
            printf STDOUT "%5d %5d %6d %5.1f %s\n",
                $p, $freq{$p}, $fsum, $fsumra, $hh;
        }
        if($_t50<0 && $fsumra >= 10) {
            $_t50 = $p;
        }
        if($_t33<0 && $fsumra >= 5) {
            $_t33 = $p;
        }
        $vmax = $p;
    }
    if($Lck_debug) {
        print STDERR "vmin $vmin vmax $vmax _t33 $_t33 _t50 $_t50\n";
    }
    return ($vmin, $vmax, $_t33, $_t50);
}

sub grow {
    my ($cw, $ch, $dst, $src) = @_;

    ### grow 3x3 '+' letter shape
    my $vvv;
    my $hhh;
    my $ppp;
    my $ggg;
    my $mm;
    my $qqq;
    for($hhh=0+1;$hhh<$ch-1;$hhh++) {
        for($vvv=0+1;$vvv<$cw-1;$vvv++) {
            $ppp = $hhh*$cw + $vvv;
            $ggg = @$src[$ppp];
            if($ggg>0) {
                $qqq = $hhh*$cw + ($vvv-1); @$dst[$qqq] = 1;
                $qqq = $hhh*$cw + ($vvv+1); @$dst[$qqq] = 1;
                $qqq = ($hhh-1)*$cw + $vvv; @$dst[$qqq] = 1;
                $qqq = ($hhh+1)*$cw + $vvv; @$dst[$qqq] = 1;
            }
        }
    }
}


# XLck($image, $cw, $ch, $xo, $yo)
sub XLck {
    my ($xi, $cw, $ch, $xo, $yo) = @_;
    my @ximg;
    my $rv = '@';
    my ($gw, $gh) = ($cw, int($ch*1.1+0.5));

    my $x;
    my $y;
    my $p;
    my $dx;
    my $dy;
    my $q;
    my $tv;
    my $wd;
    my $ht;
    $wd = $xi->Get('columns');
    $ht = $xi->Get('rows');

    if($Lck_debug) {
        print STDERR ";;; === debug $Lck_debug algo $Lck_algo\n";
        print STDERR 
    "XLck: wd $wd, ht $ht, cw $cw, ch $ch, gw $gw, gh $gh, xo $xo, yo $yo\n";
    }

    # clip target area (no and date)
    my @px;
    @px = $xi->GetPixels(map=>'RGB', x=>$xo, y=>$yo, width=>$gw, height=>$gh);

    my $vthre = 40000;
    my $_cv = -1;
    my $vmin;
    my $vmax;
    my $xvthre;
    my $xvmed;

    ($vmin, $vmax, $xvthre, $xvmed) = &guessvthre(\@px);
#print STDERR "xvthe $xvthre xvmed $xvmed\n";

    if($_cv>0) {
        $vthre = $_cv;
    }
    if($Lck_debug) {
        printf STDERR "\t\t\tck0 vmin %5d, vmax %5d, vthre %5d\n",
            $vmin, $vmax, $vthre;
    }

$vthre=45000;   # XXX
    if($Lck_debug) {
        printf STDERR "\t\t\tck1 vmin %5d, vmax %5d, vthre %5d\n",
            $vmin, $vmax, $vthre;
    }

    if($vmin>=$vmax/2) {
        if($Lck_debug) {
            printf STDERR ";;;\t\t\tskip white; vmin %5d, vmax %5d vs %5d\n",
                $vmin, $vmax, $vthre;
        }
        $rv = $_spc_letter;
        if($Lck_debug) {
            print ";;; char $rv\n";
        }
        return $rv;
    }

    $p = 0;
    foreach (@px) {
        if($p%3==0) {
#               push(@ximg, $_> 0 ? 0 : 1);
#               push(@ximg, $_< 50000 ? 1 : 0);
            push(@ximg, $_< $vthre ? 1 : 0);
        }
        $p++;
    }

    if($Lck_debug) {
        &Ldump($gw, $gh, \@ximg);
    }

    my @nimg;

    if(1) {
        # generate same size with 0
        foreach (@ximg) {
            push(@nimg, 0);
        }   

        &grow($gw, $gh, \@nimg, \@ximg);
        &trimRB($gw, $gh, \@nimg);
        if($Lck_debug) {
            &Ldump($gw, $gh, \@nimg);
        }
    }
    else {
        # copy
        foreach (@ximg) {
            push(@nimg, $_);
        }   
        &trimRB($gw, $gh, \@nimg);
        if($Lck_debug) {
            &Ldump($gw, $gh, \@nimg);
        }
    }

    my @Lbb = &BBck($gw, $gh, 0,       0, $gw, $gh,      \@nimg);

    if($Lbb[2]<0 || $Lbb[3]<0) {
        if($Lck_debug) {
            print STDERR ";;; no BB; empty\n";
        }
        return $_err_letter;
    }

    my ($v1, $v2, $v3, $v4, $v5, $v6, $v7);
    my ($sig);

#   undef @himg;
#   undef @vimg;
    # copy
    my @himg;
    foreach (@nimg) {
        push(@himg, $_);
    }   
    # copy
    my @vimg;
    foreach (@nimg) {
        push(@vimg, $_);
    }   

    &removevlines($gw, $gh, \@himg);
    if($Lck_debug) {
        &LdumpD($gw, $gh, \@himg);
    }

    &removehlines($gw, $gh, \@vimg);
    if($Lck_debug) {
        &LdumpD($gw, $gh, \@vimg);
    }

    if($Lck_debug) {
        print STDERR "letter size $cw $ch, BB $Lbb[0] $Lbb[1] $Lbb[2] $Lbb[3]\n";
    }
 
    if($Lck_algo==0) {

        $v3 = &Rck($gw, $gh, 0, 0,            $gw, int($gh/3),  \@himg);
        $v5 = &Rck($gw, $gh, 0, int($gh*2/3), $gw, $gh,         \@himg);
        $v4 = &Rck($gw, $gh, 0, int($gh/4),   $gw, int($gh*3/4),\@himg);

        $v1 = &Rck($gw, $gh, 0, 0, int($gw/2), int($gh/2),     \@vimg);
        $v2 = &Rck($gw, $gh, 0, int($gh/2), int($gw/2), $gh,   \@vimg);
        $v6 = &Rck($gw, $gh, int($gw/2), 0, $gw, int($gh/2),   \@vimg);
        $v7 = &Rck($gw, $gh, int($gw/2), int($gh/2), $gw, $gh, \@vimg);

        if($Lck_debug) {
            printf STDERR ";; values $v1 $v2 $v3 $v4 $v5 $v6 $v7\n";
        }
        if($Lck_debug) {
            printf STDERR ";; .  %s  .\n", $v3 eq "H" ? "---" : "   ";
            printf STDERR ";; . %s   %s .\n", 
                                $v1 eq "V" ? "|" : " ", $v6 eq "V" ? "|": " ";
#            printf STDERR ";; . %s   %s .\n", 
#                                $v1 eq "V" ? "|" : " ", $v6 eq "V" ? "|": " ";
            printf STDERR ";; .  %s  .\n", $v4 eq "H" ? "---" : "   ";
            printf STDERR ";; . %s   %s .\n", 
                                $v2 eq "V" ? "|" : " ", $v7 eq "V" ? "|": " ";
#            printf STDERR ";; . %s   %s .\n", 
#                                $v2 eq "V" ? "|" : " ", $v7 eq "V" ? "|": " ";
            printf STDERR ";; .  %s  .\n", $v5 eq "H" ? "---" : "   ";
        }

        $sig = ($v1 eq 'V' ? "1": "0").($v2 eq 'V' ? "1": "0").
            ($v3 eq 'H' ? "1": "0").($v4 eq 'H' ? "1": "0").
            ($v5 eq 'H' ? "1": "0").
            ($v6 eq 'V' ? "1": "0").($v7 eq 'V' ? "1": "0");

        if(defined $ca{$sig}) { $rv = $ca{$sig}; }
        else { $rv = $_err_letter; }

        if($Lck_debug) {
            print STDERR ";;; sig $sig -> rv $rv normal\n";
        }

    }
    elsif($Lck_algo==1) {
        my($dhh, $dhl);
        my $hw=int($cw/2);

    if(0) {
        $dhh=int(($Lbb[3]-$Lbb[1])/3   + $Lbb[1]);
        $dhl=int(($Lbb[3]-$Lbb[1])*2/3 + $Lbb[1]);
        $v3 = &Rck($cw, $ch, 0, $Lbb[1],   $cw, $dhh,      \@himg);
        $v5 = &Rck($cw, $ch, 0, $dhl,       $cw, $Lbb[3],  \@himg);

        $dhh=int(($Lbb[3]-$Lbb[1])/4   + $Lbb[1]);
        $dhl=int(($Lbb[3]-$Lbb[1])*3/4 + $Lbb[1]);
        $v4 = &Rck($cw, $ch, 0, $dhh,   $cw, $dhl,  \@himg);
    }

        $dhh=int(($Lbb[3]-$Lbb[1])/4   + $Lbb[1]);
        $dhl=int(($Lbb[3]-$Lbb[1])*3/4 + $Lbb[1]);
        $v3 = &Rck($cw, $ch, 0, $Lbb[1],   $cw, $dhh,      \@himg);
        $v5 = &Rck($cw, $ch, 0, $dhl,       $cw, $Lbb[3],  \@himg);
        $v4 = &Rck($cw, $ch, 0, $dhh,       $cw, $dhl,      \@himg);

        $dhh=int(($Lbb[3]-$Lbb[1])*.45   + $Lbb[1]);
        $dhl=int(($Lbb[3]-$Lbb[1])*.55   + $Lbb[1]);
        $v1 = &Rck($cw, $ch, 0,   0,    $hw, $dhh,      \@vimg);
        $v2 = &Rck($cw, $ch, 0,   $dhl, $hw, $Lbb[3],   \@vimg);
        $v6 = &Rck($cw, $ch, $hw, 0,    $cw, $dhh,      \@vimg);
        $v7 = &Rck($cw, $ch, $hw, $dhl, $cw, $Lbb[3],   \@vimg);

        if($Lck_debug) {
            printf STDERR ";; values $v1 $v2 $v3 $v4 $v5 $v6 $v7\n";
        }
        if($Lck_debug) {
            printf STDERR ";; .  %s  .\n", $v3 eq "H" ? "---" : "   ";
            printf STDERR ";; . %s   %s .\n", 
                                $v1 eq "V" ? "|" : " ", $v6 eq "V" ? "|": " ";
#            printf STDERR ";; . %s   %s .\n", 
#                                $v1 eq "V" ? "|" : " ", $v6 eq "V" ? "|": " ";
            printf STDERR ";; .  %s  .\n", $v4 eq "H" ? "---" : "   ";
            printf STDERR ";; . %s   %s .\n", 
                                $v2 eq "V" ? "|" : " ", $v7 eq "V" ? "|": " ";
#            printf STDERR ";; . %s   %s .\n", 
#                                $v2 eq "V" ? "|" : " ", $v7 eq "V" ? "|": " ";
            printf STDERR ";; .  %s  .\n", $v5 eq "H" ? "---" : "   ";
        }

        $sig = ($v1 eq 'V' ? "1": "0").($v2 eq 'V' ? "1": "0").
            ($v3 eq 'H' ? "1": "0").($v4 eq 'H' ? "1": "0").
            ($v5 eq 'H' ? "1": "0").
            ($v6 eq 'V' ? "1": "0").($v7 eq 'V' ? "1": "0");

        if(defined $ca{$sig}) { $rv = $ca{$sig}; }
        else { $rv = $_err_letter; }

        if($Lck_debug) {
            print STDERR ";;; sig $sig -> rv $rv BB-shift\n";
        }
    }

    if($Lck_debug) {
        print ";;; char $rv\n";
    }
    return $rv;
}

sub ap {
    my($fname, $optflag) = @_;

    my $ti = Image::Magick->new;
    my $xxx;

#   print STDERR "; ap $fname, opt $optflag\n";

    $xxx = $ti->Read($fname);

    my $wd;
    my $ht;
    $wd = $ti->Get('columns');
    $ht = $ti->Get('rows');

    my ($x1,$x2,$x3,$x4,$x5,$x6,$x7,$x8,$x9,$xa);
    my ($y1,$y2,$y3,$y4,$y5,$y6,$y7,$y8,$y9);
    my ($u1,$u2);
    my ($v1,$v2);
    my ($v3,$v4);
    my ($lw,$lh,$l0,$l1,$l2,$l3,$l4,$l5,$l6,$l7,$l8,$l9);

    $x1=$wd*0.018;
    $x2=$wd*0.065;
    $x3=$wd*0.935;
    $x4=$wd*0.982;
    $y1=$ht*0.0137;
    $y2=$ht*0.049;
    $y3=$ht*0.951;
    $y4=$ht*0.986;

    $x5=$wd*.0966;
    $x6=$wd*.338;
    $y5=$ht*.9568;
    $y6=$ht*.9806;

    $x7=$wd*.412;
    $x8=$wd*.565;
    $x9=$wd*.664;
    $xa=$wd*.906;

    $u1=$wd*.341;
    $u2=$wd*.926;
    $v1=0;
    $v2=$ht*.065;
    $v3=$ht*.011;
    $v4=$ht*.05;

    $lw=$wd*(.0266+0.014);
    $lh=$ht*.045;
#   $lh=$ht*.05;
    $l0=$wd*(.4125-0.007);
    $l1=$wd*(.4533-0.007);
    $l2=$wd*(.4933-0.007);
    $l3=$wd*(.5341-0.007);
    $l4=$wd*(.6633-0.007);
    $l5=$wd*(.7050-0.007);
    $l6=$wd*(.7516-0.007);
    $l7=$wd*(.7925-0.007);
    $l8=$wd*(.8391-0.007);
    $l9=$wd*(.8800-0.007);

 if(0) {
    my $ndarea;
    $ndarea = $ti->Clone();
    $ndarea->Crop(geometry=> ''.$u2-$u1.'x'.$v2.'+'.$u1.'+'.$v1);
 }

    my $oq = '';
    my $v;

    $Lck_debug = $optflag % 100;
    $Lck_algo  = int($optflag / 100);

#   $ti->Set(monochrome=>"True");

    $v = &XLck($ti, int($lw), int($lh), int($l0), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l1), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l2), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l3), int($v3));
    $oq .= $v;
    $oq .= $_sep_letter;
    $v = &XLck($ti, int($lw), int($lh), int($l4), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l5), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l6), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l7), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l8), int($v3));
    $oq .= $v;
    $v = &XLck($ti, int($lw), int($lh), int($l9), int($v3));
    $oq .= $v;

    return $oq;
}

1;
