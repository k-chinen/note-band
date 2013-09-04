#!/usr/bin/perl
#

use strict;
use DBM::Deep;
use Time::Local;
use POSIX 'strftime';
use Tk;
use Tk::Balloon;
use Tk::Photo;
use Tk::JPEG;


sub mkdateoffset {
    my($rdv,$doff) = @_;
    my ($xy,$xm,$xd);
    $xy = substr($rdv, 0, 2);
    $xm = substr($rdv, 2, 2);
    $xd = substr($rdv, 4, 2);
    my $epoch = timelocal(0,0,0,$xd, $xm-1, $xy+2000-1900);
    my $d = strftime("%y%m%d", localtime($epoch+$doff*86400));
    return $d;
}

#              20130401
my $maxdate = '99999999';

my $lowcolor  = "#999";
my $mark_mid  = 7;
my $midcolor  = "#fcc";
my $mark_high = 3;
my $highcolor = "#f66";
my $negcolor = "#66f";


my $refdate = strftime("%y%m%d", localtime());
my $jmpdate = strftime("%y%m%d", localtime());

my %date2color;
my $datecolorstyle=0;

sub update_datecolor {
    my $ut=time();
    my ($xy,$xm,$xd);
    $xy = substr($refdate, 0, 2);
    $xm = substr($refdate, 2, 2);
    $xd = substr($refdate, 4, 2);
    my $epoch = timelocal(0,0,0,$xd, $xm-1, $xy+2000-1900);
    print "$xy $xm $xd\n";
    print "epoch $epoch vs $ut -> ".($ut-$epoch)."\n";

    undef %date2color;

    if($datecolorstyle==0) {
        my $d;
        my $i;
        for($i=0;$i<7;$i++) {
            $d = strftime("%y%m%d", localtime($epoch-$i*86400));
            $date2color{$d} = $midcolor;
        }
        for($i=0;$i<3;$i++) {
            $d = strftime("%y%m%d", localtime($epoch-$i*86400));
            $date2color{$d} = $highcolor;
        }
    }
    elsif($datecolorstyle==1) {
        my $d;
        my $i;
        for($i=0;$i<31;$i++) {
            $d = strftime("%y%m%d", localtime($epoch-$i*86400));
            $date2color{$d} = $midcolor;
        }
        for($i=0;$i<7;$i++) {
            $d = strftime("%y%m%d", localtime($epoch-$i*86400));
            $date2color{$d} = $highcolor;
        }
    }

 if(0) {
    my $d;
    foreach $d (sort keys %date2color) {
        print "$d $date2color{$d}\n";
    }
 }

}

sub uniqpush {
    my($nar,$nm) = @_;
    my @same;

#   print "--- $nm\n";
#   print "before ".(scalar(@$nar))." ".(join("/",@$nar))."\n";
    
    @same = ();
    @same = grep(/^$nm$/, @$nar);
#   print "same? $#same\n";
    if($#same>=0) {
#       print "NOCHANG\n"
    }
    else {
        push(@$nar, $nm);
    }
#   print "after  ".(scalar(@$nar))." ".(join("/",@$nar))."\n";
}


sub arpos {
    my($nar,$v) = @_;
    my $i;
    my $c;
    my $r;
    $r = -1;
    $i = 0;
    foreach $c (@$nar) {
        if($c eq $v) {
            $r = $i;
            last;
        }
        $i++;
    }
    return $r;
}
sub arposvalue {
    my($nar,$v) = @_;
    my $i;
    my $r;
    $r = -1;
    foreach $i (@$nar) {
        if($i eq $v) {
            $r = $i;
            last;
        }
    }
    return $r;
}


my $jumploose=3;

my %pfs;
my $db_pfs = tie %pfs, 'DBM::Deep', 'pfs.db'; 

my %dfs;
my $db_dfs = tie %dfs, 'DBM::Deep', 'dfs.db'; 
my %dfn;
my $db_dfn = tie %dfn, 'DBM::Deep', 'dfn.db'; 
my %doc;
my $db_doc = tie %doc, 'DBM::Deep', 'doc.db'; 
my %noc;
my $db_noc = tie %noc, 'DBM::Deep', 'noc.db'; 
my %grp;
my $db_grp = tie %grp, 'DBM::Deep', 'grp.db'; 

### XXX
my %dah;
my $db_dah = tie %dah, 'DBM::Deep', 'dah.db'; 


my @ar;
my $db_ar = tie @ar, 'DBM::Deep', 'ar.db';

#$db_ar->clear();
#@ar = keys %pfs;


sub dbimport {
    print "dbimport:\n";
}

my $dbexport_fname="note-band.export";
my $dbexport_dir=".";
my $dbexport_perfix="";

sub export_dah {
    my($t) = @_;
    print "export_dah:\n";
    my $fname;
    my $k;

    my $ext       = strftime "%Y%m%d%H%M%S", localtime($t);
    my $heredate  = strftime "%Y/%m/%d %H:%M:%S", localtime($t);
    my $theredate = strftime "%Y/%m/%d %H:%M:%S", gmtime($t);

    $fname = $dbexport_dir . "/" . "dah" .  "_" . $ext;

    open(F, ">$fname");
    print F "# Host  ".`hostname`;
    print F "# Local $heredate\n";
    print F "# UTC   $theredate"."Z\n";
    foreach $k (keys %dah) {
        print F "$k|$dah{$k}\n";
    }
    close(F);
}

sub dbexport {
    print "dbexport:\n";
    my $t;
    $t = time();

    &export_dah($t);

    print "dbexport: done\n";
}

sub ar_print {
    my $k;
    foreach $k (@ar) {
        print "$k $dfn{$k}\n";
    }
}

sub data_verify {
    my $k;
    foreach $k (@ar) {
        if(!defined $dfn{$k}) {
            $dfn{$k} = $maxdate;
        }
    }
#   &ar_print;
}

sub ar_init {
    $db_ar->clear();
    if(0){
    my $k;
        $k = 'MD5:1';
#       $k = 'MD5:225d803e418946e7c24f5fe18cf5227a';
        push(@ar, $k);
        $dfn{$k} = '20130401';

        $k = 'MD5:2';
#        $k = 'MD5:48e3743bc885ee073b6d2ea23a216085';
        push(@ar, $k);
        $dfn{$k} = '20130402';

        $k = 'MD5:3';
#        $k = 'MD5:e74602901e2c7fa89d583a4bc053f95f';
        push(@ar, $k);
        $dfn{$k} = '20130403';

        $k = 'MD5:4';
#       $k = 'MD5:e3878b74354d592ad4d54f38345802a5';
        push(@ar, $k);
        $dfn{$k} = '20130404';

        $k = 'MD5:5';
#       $k = 'MD5:114dc22484b3962247a2d3b2b53bb980';
        push(@ar, $k);
        $dfn{$k} = '20130405';
    }
}

my $imgwd = 240;
my $imght = int($imgwd*4/3);
my $imggp = 20;

my $imgaj = 3;
my $imglm = 5;

my %imgocache;
my %imgscache;

my $iltmargin = 30;
my $illmargin = 30;
my $ilrmargin = 30;
my $ilgap     = 30;

my @imgstack = ();


my $shttmin = -1;
my $shttmax = -1;

my $shtht_default = 150;
my $shtht   = 150;
my $shtwd   = 75;
my $shtdp   = 50;
my $shttd   = 20;
my $shtvg   = 14;
my $shtga   = 25;
my $shtct   = 20;
my $shtaj   = 3;
my $shtlm   = 5;
my $shtqw   = 10;
my $shtmw   = 5;

my $vbug=0;

my $mw = MainWindow->new();
my $base = $mw->Frame->pack(-fill=>"both", -expand=>1);

my $cline = $base->Frame(-relief=>'raise',-bd=>1)->pack(-side=>'top',-fill=>'x');
my $bquit = $cline->Button(-text=>"EXIT", -command=>\&exit)->pack(-side=>'left');
#my $bnop = $cline->Button(-text=>"NOP")->pack(-side=>'left');
#my $binit = $cline->Button(-text=>"INIT", -command=>\&init_redraw)->pack(-side=>'left');

my $jline = $base->Frame(-relief=>'raise',-bd=>1)->pack(-side=>'top',-fill=>'x');
my $bhead = $jline->Button(-text=>"|<", -command=>\&poshead)->pack(-side=>'left');
my $bprev = $jline->Button(-text=>"<<",  -command=>\&posprevw)->pack(-side=>'left');
my $bprev = $jline->Button(-text=>"<",  -command=>\&posprev)->pack(-side=>'left');
my $bsucc = $jline->Button(-text=>">",  -command=>\&possucc)->pack(-side=>'left');
my $bsucc = $jline->Button(-text=>">>",  -command=>\&possuccw)->pack(-side=>'left');
my $btail = $jline->Button(-text=>">|", -command=>\&postail)->pack(-side=>'left');

my $dmy = $jline->Label(-text=>'jump.date')->pack(-side=>'left');
my $dmy = $jline->Entry(-textvariable=>\$jmpdate)->pack(-side=>'left');
my $dmy = $jline->Button(-text=>'<',
            -command=>\&jumpprev)->pack(-side=>'left');
my $dmy = $jline->Button(-text=>'>',
            -command=>\&jumpnext)->pack(-side=>'left');
my $dmy = $jline->Checkbutton(-text=>'strict',-variable=>\$jumploose,
    -onvalue=>'0')->pack(-side=>'left');
my $dmy = $jline->Checkbutton(-text=>'loose',-variable=>\$jumploose,
    -onvalue=>'3')->pack(-side=>'left');
my $dmy = $jline->Checkbutton(-text=>'veryloose',-variable=>\$jumploose,
    -onvalue=>'7')->pack(-side=>'left');

#my $ljmsg  = $jline->Label(-width=>20,-text=>'',
#   -anchor=>'w',-bg=>'lightcyan')->pack(-side=>'left');


#my $brebuild = $cline->Button(-text=>"rebuild", -command=>\&rebuild)->pack(-side=>'left');
my $bscan = $cline->Button(-text=>"scan", -command=>\&scan)->pack(-side=>'left');
my $bimportbyfs = $cline->Button(-text=>"import by fs", -command=>\&import_byfs)->pack(-side=>'left');
my $bsortbyah = $cline->Button(-text=>"sort by ah", -command=>\&sort_byah)->pack(-side=>'left');
#my $bsortbyahnd = $cline->Button(-text=>"sort by ah no-date", -command=>\&sort_byahnd)->pack(-side=>'left');
#my $bsortbyahdn = $cline->Button(-text=>"sort by ah date-no", -command=>\&sort_byahdn)->pack(-side=>'left');
my $bsortbyfn = $cline->Button(-text=>"sort by fn", -command=>\&sort_byfn)->pack(-side=>'left');
#my $bsortbyocdn = $cline->Button(-text=>"sort by date-no of ocr", -command=>\&sort_byocdn)->pack(-side=>'left');
#my $bsortbyocnd = $cline->Button(-text=>"sort by no-date of ocr", -command=>\&sort_byocnd)->pack(-side=>'left');
my $bsortbyoc = $cline->Button(-text=>"sort by ocr", -command=>\&sort_byoc)->pack(-side=>'left');

my $qvbug  = $cline->Checkbutton(-text=>'debug',-variable=>\$vbug,-command=>[\&tgv,\$vbug], -relief=>'sunken')->pack(-side=>'right');
my $qexport = $cline->Button(-text=>'export',-command=>[\&dbexport])->pack(-side=>'right');
my $qimport = $cline->Button(-text=>'import',-command=>[\&dbimport])->pack(-side=>'right');


my $dline = $base->Frame->pack(-side=>'top',-fill=>'x');
my $dmy = $dline->Label(-text=>'ref.date')->pack(-side=>'left');
my $dmy = $dline->Entry(-textvariable=>\$refdate,
    -validatecommand=> sub {$_[1] =~ /\d{6}/})->pack(-side=>'left');
my $dmy = $dline->Label(-text=>'past',     -bg=>$lowcolor)->pack(-side=>'left');
my $dmy = $dline->Label(-text=>'recent',   -bg=>$midcolor)->pack(-side=>'left');
my $dmy = $dline->Label(-text=>'hot',      -bg=>$highcolor)->pack(-side=>'left');
my $dmy = $dline->Label(-text=>'future',   -bg=>$negcolor, -fg=>'white')->pack(-side=>'left');

my $dmy = $dline->Checkbutton(-text=>'7d/3d',-variable=>\$datecolorstyle,
    -onvalue=>'0',
    -command=>[\&datecolorchange])->pack(-side=>'left');
my $dmy = $dline->Checkbutton(-text=>'1m/7d',-variable=>\$datecolorstyle,
    -onvalue=>'1',
    -command=>[\&datecolorchange])->pack(-side=>'left');

my $datepriority=1;

my $vfnd=1;
my $vfnt=0;
my $vfsd=0;
my $vfst=0;
my $vocd=1;
my $vocn=1;

my $vsline = $base->Frame->pack(-side=>'top', -fill=>'x');
my $dmy    = $vsline->Label(-width=>7, -text=>'meta')->pack(-side=>'left');
my $qvfnd  = $vsline->Checkbutton(-text=>'FND',-variable=>\$vfnd,-command=>[\&tgv,\$vfnd])->pack(-side=>'left');
my $qvfnt  = $vsline->Checkbutton(-text=>'FNT',-variable=>\$vfnt,-command=>[\&tgv,\$vfnt])->pack(-side=>'left');
my $qvfsd  = $vsline->Checkbutton(-text=>'FSD',-variable=>\$vfsd,-command=>[\&tgv,\$vfsd])->pack(-side=>'left');
my $qvfst  = $vsline->Checkbutton(-text=>'FST',-variable=>\$vfst,-command=>[\&tgv,\$vfst])->pack(-side=>'left');
my $qvocd  = $vsline->Checkbutton(-text=>'OCD',-variable=>\$vocd,-command=>[\&tgv,\$vocd])->pack(-side=>'left');
my $qvocn  = $vsline->Checkbutton(-text=>'OCN',-variable=>\$vocn,-command=>[\&tgv,\$vocn])->pack(-side=>'left');


#my $vpline = $base->Frame->pack(-side=>'top', -fill=>'x');
my $vpline = $vsline;
my $dmy    = $vpline->Label(-width=>7, -text=>'')->pack(-side=>'left');
my $dmy    = $vpline->Label(-width=>7, -text=>'priority')->pack(-side=>'left');
my $qvpriority_no    = $vpline->Radiobutton(-text=>'no-date',-variable=>\$datepriority,-value=>0,-command=>[\&redraw])->pack(-side=>'left');
my $qvpriority_date  = $vpline->Radiobutton(-text=>'date-no',-variable=>\$datepriority,-value=>1,-command=>[\&redraw])->pack(-side=>'left');



my $dmy = $jline->Button(-text=>"redraw",   -command=>\&redrawR)->pack(-side=>'right');


sub verify_ht {
    my $y;
    $y = 1;
    $y += 3;    # XXX
    if($vfnd) {  $y++; }
    if($vfnt) {  $y++; }
    if($vfsd || $vfst) {     $y++; }
    if($vfsd) {  $y++; }
    if($vfst) {  $y++; }
    if($vocd || $vocn) {     $y++; }
#    if($vocd) {  $y++; }
#    if($vocn) {  $y++; }
    if($vocd) {  $y+=2; }

    print "verify_ht: y $y\n";
    $shtht = $shttd + $y*$shtvg + $shtct;
}

sub reset_ht {
    $shtht = $shtht_default;
}

my $iscale = 1;

#my $viline = $base->Frame->pack(-side=>'top', -fill=>'x');
my $viline = $vsline;
my $dmy    = $viline->Label(-width=>7, -text=>'')->pack(-side=>'left');

my $dmy    = $viline->Label(-width=>7, -text=>'image')->pack(-side=>'left');
my $qismall  = $viline->Checkbutton(-text=>'S',-variable=>\$iscale,
    -onvalue=>'0',
    -command=>[\&iscalechange,0])->pack(-side=>'left');
my $qimedium  = $viline->Checkbutton(-text=>'M',-variable=>\$iscale,
    -onvalue=>'1',
    -command=>[\&iscalechange,1])->pack(-side=>'left');
my $qilarge  = $viline->Checkbutton(-text=>'L',-variable=>\$iscale,
    -onvalue=>'2',
    -command=>[\&iscalechange,2])->pack(-side=>'left');
my $qidlarge  = $viline->Checkbutton(-text=>'LL',-variable=>\$iscale,
   -onvalue=>'3',
   -command=>[\&iscalechange,3])->pack(-side=>'left');



my $canvas = $base->Canvas(-width=>720, -height=>480, -bg=>"snow")->pack(-fill=>'both',-expand=>1);
my $sbar = $base->Label(-anchor=>'w')->pack(-side=>'bottom',-fill=>'x');

$b = $mw->Balloon(-statusbar=>$sbar);

$b->attach($bquit, -balloonmsg =>"destroy this program", -statusmsg=>"exit this");
#$b->attach($binit, -balloonmsg =>"init", -statusmsg=>"clear and add dummy data");
#$b->attach($bnop, -msg =>"dummy this program");


sub vprint {
    my($cv,$sx,$sy,$ch,$num) = @_;
    my $y;
    my $i;
    my $lab;
    my @rg;
    my $id;

    @rg = ();

    $y = 0;
    $b = 1;

print "vprint $num\n";
    foreach $i (split(//, $num)) {
print "  i $i\n";
        $id = $cv->create('text', $sx,$sy-$ch*$y, -text=>$i);
        push(@rg, $id);
        $y++;
    }

    return @rg;
}

sub numvprint {
    my($cv,$sx,$sy,$ch,$pz,$num) = @_;
    my $y;
#    my $x;
    my $i;
    my $lab;
    my $v;
    my $b;

    $v = $num;
    $y = 0;
    $b = 1;

    for($i=0;$i<4;$i++) {
        if($pz && $v<=$b) {
            last;
        }
        $lab = sprintf("%d", ($v/$b)%10);
        $cv->create('text', $sx,$sy-$ch*$y, -text=>$lab);
        $y++;
        $b = $b*10;
    }
}


sub OLDnumvprint {
    my($cv,$sx,$sy,$ch,$pz,$num) = @_;
    my $y;
    my $x;
    my $i;
    my $lab;

    $lab = sprintf("%d", $num%10);
    my $id = $cv->create('text', $sx,$sy-$ch*0, -text=>$lab);

    $lab = sprintf("%d", ($num/10)%10);
    if($pz || $lab ne '0') {
        my $id = $cv->create('text', $sx,$sy-$ch*1, -text=>$lab);
    }

    $lab = sprintf("%d", ($num/100)%10);
    if($pz || $lab ne '0') {
        my $id = $cv->create('text', $sx,$sy-$ch*2, -text=>$lab);
    }

    $lab = sprintf("%d", ($num/1000)%10);
    if($pz || $lab ne '0') {
        my $id = $cv->create('text', $sx,$sy-$ch*3, -text=>$lab);
    }
}


my $__ix;
my $__iy;

sub sent { 
    my($id,$cv,$k,$x,$y) = @_;
#    print "sent $k\n";
    $sbar->configure(-text=>$k);
}
sub slev { 
    my($id,$cv,$k,$x,$y) = @_;
#    print "slev $k\n";
}


sub conv_CLah {
    my($k) = @_;
    print "CLah $k\n";
    if(!defined $dfn{$k}) {
        print "ignore key\n";
        return -1;
    }
    undef $dah{$k};
}

sub conv_fn2ah {
    my($k) = @_;
    print "fn2ah $k\n";
    my $tmpd;

    if(!defined $dfn{$k}) {
        print "ignore key\n";
        return -1;
    }
#   $dah{$k} = $dfn{$k};
#   $dah{$k} =~ s/_/,/g;
    
    ($tmpd) = split(/_/, $dfn{$k});
    $dah{$k} = "9999,".$tmpd;
    
}

sub conv_oc2ah {
    my($k) = @_;
    print "oc2ah $k\n";

    if(!defined $doc{$k}) {
        print "ignore key\n";
        return -1;
    }
    $dah{$k} = $doc{$k};
}

sub markfn2ah {
    my($id,$cv,$k,$x,$y) = @_;

    &conv_fn2ah($k);
}

sub markoc2ah {
    my($id,$cv,$k,$x,$y) = @_;

    &conv_oc2ah($k);
}


my $aim;


sub spick {
    my($id,$cv,$k,$x,$y) = @_;
    my @co;
    my @bb;
    my $r=$shtlm*3;
    print "spick $k\n";
    print "aim $aim\n";

#   foreach my $i ($cv->itemcget($k, -members)) {
#       print "  i $i\n";
#   }

    @co = $cv->coords($k);
    print "co $co[0], $co[1], $co[2], $co[3]\n";
    print "x $x, y $y\n";
    @bb = $cv->bbox($k);
    print "bb $bb[0], $bb[1], $bb[2], $bb[3]\n";

    $__ix = $x-$bb[0];
    $__iy = $y-$bb[1];
    print "ix $__ix iy $__iy\n";

    {

#        my $dmy= $cv->create('rectangle',$x-$r,$y-$r,$x+$r,$y+$r,
#                -tag=>"brange");
#        $cv->raise("brange");


        my @qidlist = $cv->find('closest', $x,$y);
        my $qid;
        my @qtaglist;
        my $qtag;
        my @nearlist;
        my $qc;
        my $rr;
        $rr = $r*$r;
        $qc=0;
        @nearlist = ();
        foreach $qid (@qidlist) {
            print "qid closest $qid\n";
            @qtaglist = $cv->gettags($qid);
            print "\ttag ".(join("|",@qtaglist))."\n";

            my %dist;

            foreach $qtag (@qtaglist) {
                undef %dist;

                if($qtag eq 'current') {
                    next;
                }

                my $mid;
                my @memlist;
                @memlist = $cv->itemcget($qtag, -members);
                foreach $mid (@memlist) {
                    my($llx, $lly, $urx, $ury) = $cv->coords($mid);
                    my($gx,$gy) = ( ($llx+$urx)/2, ($lly+$ury)/2);
                    my $dd;
                    $dd = ($gx-$x)*($gx-$x) + ($gy-$y)*($gy-$y);
                    if($dd<=$rr) {
                        $dist{$mid} = $dd;
                    }
                }

                my @dorder = sort {$dist{$a}<=>$dist{$b}} keys %dist;
                my $chg = 0;

                print "- - -\n";
                foreach $mid (@dorder) {
                    my @mtaglist;
                    my $mtag;

                    print "mid $mid dist $dist{$mid}\n";

                    @mtaglist = $cv->gettags($mid);
                    print "\t\ttag ".(join("/",@mtaglist))."\n";

                    foreach $mtag (@mtaglist) {
                        if($mtag eq 'CLah') {
                            &conv_CLah($qtag);
                            $chg++;
                        }
                        if($mtag eq 'fn2ah') {
                            &conv_fn2ah($qtag);
                            $chg++;
                        }
                        if($mtag eq 'oc2ah') {
                            &conv_oc2ah($qtag);
                            $chg++;
                        }

                        if($mtag eq 'noapp') {
                            &imgpush($id,$cv,$k,$x,$y);
                            $chg++;
                        }
                        if($mtag eq 'app') {
                            &imgremove($id,$cv,$k,$x,$y);
                            $chg++;
                        }
                    }

                    if($chg>0) {
                        &redraw;
                    }
                }

            }
            $qc++;

        }
        if($qc==0) {
            print "no item(s)\n";
        }

    }
    

    $cv->create('rectangle', $bb[0], $bb[1], $bb[2], $bb[3],
            -fill=>'gray75', -outline=>'gray75', -tag=>"imark");
    $cv->raise('imark');
    $cv->raise($k);

    $aim = $k;
}



sub smove {
    my($id,$cv,$k,$x,$y) = @_;
    print "smove $k x $x y $y\n";
    print "aim $aim\n";

    if($aim eq '') {
        return;
    }

    my $nx;
    my $ny;

    $nx = $x-$__ix;
    $ny = $y-$__iy;

    print "nx $nx ny $ny\n";
    $cv->coords($k, $nx, $ny);
}

sub closeleft {
    my($cv,$ig,$sw,$x,$y,$srw,$srh) = @_;
    my @rawitems;
    my @items;
    my $i;
    my $ck;
    my $maxx;
    my $maxi;
    my @co;
    my @tgs;
#print "closeleft sw $sw x $x y $y srw $srw srh $srh\n";

    @rawitems = $cv->find('enclosed', $x-$srw, $y-$srh, $x+$sw, $y+$srh);
#   print "# of rawitems $#rawitems\n";
#   print join(":", @rawitems)."\n";

    foreach $i (@rawitems) {
        @tgs = $cv->gettags($i);
#       print " tags ".join("/",@tgs)."\n";
        $ck = $tgs[0];
#       print "   ck $ck\n";

        if($ck eq '') {
            next;
        }
        if($ck eq 'imark') {
            next;
        }
        if($ck ne $ig) {
#            push(@items, $i);
            if(defined $dfn{$ck}) {
                push(@items, $i);
            }
        }   
    }
#       print "# of items $#items\n";
#       print join(":", @items)."\n";
    
    $maxx = -1;
    $maxi = '';
    foreach $i (@items) {
        @co = $cv->coords($i);
        print "$i coords ".(join(":",@co))."\n";
        if($co[0]>$maxx) {
            $maxx = $co[0];
            $maxi = $i;
        }
    }

#    print "maxi $maxi\n";

    if($maxi eq '') {
        return "";
    }
    else {
        return ($cv->gettags($maxi))[0];
    }
}

sub closeright {
    my($cv,$ig,$sw,$x,$y,$srw,$srh) = @_;
    my @rawitems;
    my @items;
    my $i;
    my $ck;
    my $minx;
    my $mini;
    my @co;
    my @tgs;

#print "closeright sw $sw x $x y $y srw $srw srh $srh\n";

    @rawitems = $cv->find('enclosed', $x-$sw, $y-$srh, $x+$srw, $y+$srh);
    foreach $i (@rawitems) {
        @tgs = $cv->gettags($i);
        $ck = $tgs[0];
        if($ck eq '') {
            next;
        }
        if($ck eq 'imark') {
            next;
        }
        if($ck ne $ig) {
            push(@items, $i);
        }   
    }
#   print "# of items $#items\n";
#   print join(":", @items)."\n";
    
    $minx = 99999;
    $mini = '';
    foreach $i (@items) {
        @co = $cv->coords($i);
#       print "$i coords ".(join(":",@co))."\n";
        if($co[0]<$minx) {
            $minx = $co[0];
            $mini = $i;
        }
    }

#    print "mini $mini\n";

    if($mini eq '') {
        return "";
    }
    else {
        return ($cv->gettags($mini))[0];
    }
}


sub srele {
    my($id,$cv,$k,$x,$y) = @_;
    print "srele $k\n";
    print "aim $aim\n";
    print "  x $x y $y\n";
    if($aim eq '') {
        return;
    }
    my ($cx, $cy);  # center of sheet
    my @bb;
    my @nearitems;
    my @litems;
    my @ritems;
    my $i;
    my $srw;
    my $srh;
    my $lk; # left key
    my $rk; # right key
    my $li; # left index
    my $ri; # right index
    my $si; # self index
    my @co;
    my $cook=0;

#    print "before ".join(",",@ar)."\n";

    $srw = $shtwd*10;
    $srh = $shtht*3;

    $cv->delete('imark');

    @bb = $cv->bbox($k);
    $cx = ($bb[0]+$bb[2])/2;
    $cy = ($bb[1]+$bb[3])/2;

    print "cx $cx cy $cy\n";

#    $lk = &closeleft($cv,$k,$shtwd,$cx,$cy,$srw,$srh);
#    $rk = &closeright($cv,$k,$shtwd,$cx,$cy,$srw,$srh);
    $lk =  &closeleft($cv,$k,0,$cx,$cy,$srw,$srh);
    $rk = &closeright($cv,$k,0,$cx,$cy,$srw,$srh);
    print "lk $lk rk $rk\n";

    $si = -1;
    $ri = -1;
    $li = -1;
    for($i=0;$i<=$#ar;$i++) {
        if($ar[$i] eq $k) {
            $si = $i;
        }
        if($ar[$i] eq $lk) {
            $li = $i;
        }
        if($ar[$i] eq $rk) {
            $ri = $i;
        }
    }

    print "si $si li $li ri $ri\n";

    if($si==-1) {
        print "strange 0--\n";
        goto ENDPROC;
    }
    if($li==-1 && $ri==-1) {
        print "strange -00\n";
        goto ENDPROC;
    }


    splice(@ar, $si, 1);    # remove self

    $ri = -1;
    $li = -1;
    for($i=0;$i<=$#ar;$i++) {
        if($ar[$i] eq $lk) {
            $li = $i;
        }
        if($ar[$i] eq $rk) {
            $ri = $i;
        }
    }

    print "li $li ri $ri\n";

    if($li==-1) {
#print "A\n";
        splice(@ar, $ri, 0, $k);
        my $cook=1;
    }
    elsif($ri==-1) {
#print "B\n";
        splice(@ar, $li+1, 0, $k);
        my $cook=1;
    }
    else {
#print "C\n";
        splice(@ar, $li+1, 0, $k);
        my $cook=1;
    }

#    print "after  ".join(",",@ar)."\n";

ENDPROC:
{
    if($cook==0) {
        @co = $cv->coords('imark');
        $cv->coords($k,@co);
    }

    &redraw;

}

}


sub shead {
    my($id,$cv,$k,$x,$y) = @_;
    print "shead k |$k| x $x y $y\n";
}
sub stail {
    my($id,$cv,$k,$x,$y) = @_;
    print "stail \n";
}


sub verify_time {
    my($xd) = @_;
    if($xd =~ /^[0-2][0-9][0-5][0-9][0-5][0-9]$/) {
        return 1;
    }
    return 0;
}

sub verify_date {
    my($xd) = @_;
    if($xd =~ /^[1][0-9][01][0-9][0-3][0-9]$/) {
        return 1;
    }
    return 0;
}

sub verify_no {
    my($xd) = @_;
    if($xd =~ /\d{4}/) {
        return 1;
    }
    return 0;
}

sub marktime {
    my($cv, $x, $y, $r, $xd, $nar) = @_;
    my $id;
    my $ck;

    $ck = &verify_time($xd);

    if($ck==1) {
        $id = $cv->create('oval', $x, $y, $x+$r, $y+$r,
                -fill=>'#fff', -outline=>'#fff');
    }
    else {
        $id = $cv->create('oval', $x, $y, $x+$r, $y+$r,
                -fill=>'#f00', -outline=>'#f00');
    }
    push(@$nar, $id);
}

sub markdate {
    my($cv, $x, $y, $r, $xd, $nar) = @_;
    my $id;
    my $ck;

    $ck = &verify_date($xd);

    if($ck==1) {
        $id = $cv->create('oval', $x, $y, $x+$r, $y+$r,
                -fill=>'#fff', -outline=>'#fff');
    }
    else {
        $id = $cv->create('oval', $x, $y, $x+$r, $y+$r,
                -fill=>'#f00', -outline=>'#f00');
    }
    push(@$nar, $id);
}

sub markno {
    my($cv, $x, $y, $r, $xd, $nar) = @_;
    my $id;
    my $ck;

    $ck = &verify_no($xd);

    if($ck==1) {
        $id = $cv->create('oval', $x, $y, $x+$r, $y+$r,
                -fill=>'#fff', -outline=>'#fff');
    }
    else {
        $id = $cv->create('oval', $x, $y, $x+$r, $y+$r,
                -fill=>'#f00', -outline=>'#f00');
    }
    push(@$nar, $id);
}

sub mkcrosssym {
    my($refar, $cv, $k, $x, $y, $w, $h, $xtag) = @_;
    my $id1;
    $id1 = $cv->create('rectangle',
            $x,    $y+$h/3,
            $x+$w, $y-$h*2/3,
            -fill=>'white', -outline=>'black', -tag=>$xtag);
    $cv->raise($id1);
    push(@{$refar}, $id1);

    $id1 = $cv->create('line',
            $x,    $y+$h/3,
            $x+$w, $y-$h*2/3);
    $cv->raise($id1);
    push(@{$refar}, $id1);

    $id1 = $cv->create('line',
            $x,    $y-$h*2/3,
            $x+$w, $y+$h/3);
    $cv->raise($id1);
    push(@{$refar}, $id1);
}

sub mkupsym {
    my($refar, $cv, $k, $x, $y, $w, $h, $xtag) = @_;
    my $id1;
    $id1 = $cv->create('rectangle',
            $x,    $y+$h/3,
            $x+$w, $y-$h*2/3,
            -fill=>'white', -outline=>'black', -tag=>$xtag);
    $cv->raise($id1);
    push(@{$refar}, $id1);

    $id1 = $cv->create('line',
            $x+$w/2, $y+$h/3,
            $x+$w/2, $y-$h*2/3);
    $cv->raise($id1);
    push(@{$refar}, $id1);

    $id1 = $cv->create('line',
            $x,      $y+$h/3-$h/2,
            $x+$w/2, $y-$h*2/3,
            $x+$w,   $y+$h/3-$h/2
            );
    $cv->raise($id1);
    push(@{$refar}, $id1);
}



my $__n;

sub decide_color {
    my($rd,$gd) = @_;
    my $r;
    my $ddiff;

    $r = $lowcolor;
    $ddiff = $rd-$gd;
    if($ddiff<0) {
        $r = $negcolor;
    }
    elsif(defined $date2color{$gd}) {
        $r = $date2color{$gd};
    }
    return $r;
}

sub mkshtsym {
    my($cv,$x,$y,$k,$rdv) = @_;
    my $crbody;
    my $cr2body;
    my $cdv;
    my $cid;
    my @labids;
    my @grs;
    my $ly;
    my $ddiff;
    my $dfnD;
    my $dmy;

    $__n++;
#    print "n $__n $x $y\n";

    my ($xfnd, $xfnt, $xfsd, $xfst, $xocd, $xocn);
    ($xfnd, $xfnt) = split(/_/, $dfn{$k});
    ($xfsd, $xfst) = split(/_/, $dfs{$k});
    ($xocn, $xocd) = split(/,/, $doc{$k});

    my ($xahd, $xahn) = ("noDate", "noNo");
    if(defined $dah{$k})  {
        ($xahn, $xahd) = split(/,/, $dah{$k});
    }

#    print "xfnd, xfnt, xfsd, xfst, xocd, xocn\n";
#    print "$xfnd, $xfnt, $xfsd, $xfst, $xocd, $xocn\n";

    $crbody = $lowcolor;
    $cr2body = $lowcolor;

    if(defined $dfn{$k}) {
        $cr2body = &decide_color($rdv, $xfnd);
    }
    if(defined $dah{$k}) {
        $crbody = &decide_color($rdv, $xahd);
    }


    my $body = $cv->create('rectangle',
                    $x,$y-$shtht+$shttd,$x+$shtwd,$y,
                    -fill=>'white', -outline=>'#ccc');
    my $cmark = $cv->create('rectangle',
                    $x,$y-$shtht,$x+$shtwd-$shttd,$y-$shtht+$shttd,
                    -fill=>$crbody, -outline=>$crbody);
    my $cmark2 = $cv->create('rectangle',
                    $x+$shtwd-$shttd,$y-$shtht,$x+$shtwd,$y-$shtht+$shttd,
                    -fill=>$cr2body, -outline=>$crbody);
    @grs = ($body,$cmark,$cmark2);

    if($vbug) {
        my $id1 = $cv->create('text', $x+$shtwd/2,$y+$shtvg,
                    -text=>$k, -fill=>'black');
        push(@grs, $id1);
        my $id2 = $cv->create('text', $x+$shtwd/2, $y+$shtvg*2,
                    -text=>$dfn{$k});
        push(@grs, $id2);
    }

    if($xocd>0 && $xfnd>0) {
        my $diff = $xocd - $xfnd;
        if($diff<0) {
            $diff = - $diff;
        }
        if($diff>100) {
            my $mistery = $cv->create('oval',
                $x+$shttd/4,$y-$shtht+$shttd*1/4,
                $x+$shttd*3/4,$y-$shtht+$shttd*3/4,
                -fill=>'black', outline=>'black');
            push(@grs, $mistery);
        }
        if(0) {
            my $id1 = $cv->create('text', $x+$shtwd/2,$y+$shtvg,
                        -text=>$diff, -fill=>'black');
            push(@grs, $id1);
        }
    }


    $ly = 1;

    if(defined $dfn{$k}) {
        my $qx;
        my $mx;
        my $lx;
        my $id1;
        my $id2;
#       $shtqw = $shtvg;
        $qx = $x+$shtlm;
        $mx = $x+$shtlm+$shtqw+2;
        $lx = $x+$shtlm+$shtqw+2+$shtmw+2;

        my $gg = -$shtvg/2;

    {
        &mkcrosssym(\@grs, $cv, $k,
            $qx, $y-$shtht+$shttd+$shtvg*$ly, $shtqw, $shtvg, "CLah");

      if($datepriority==0) {

        $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                -text=>$xahn, -anchor=>'w');
        push(@grs, $id1);
&markno($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xahn, \@grs);
        $ly++;

        $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                -text=>$xahd, -anchor=>'w');
        push(@grs, $id1);
&markdate($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xahd, \@grs);
        $ly++;

      }
    
      if($datepriority==1) {

        $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                -text=>$xahd, -anchor=>'w');
        push(@grs, $id1);
&markdate($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xahd, \@grs);
        $ly++;

        $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                -text=>$xahn, -anchor=>'w');
        push(@grs, $id1);
&markno($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xahn, \@grs);
        $ly++;

      }

    }

        {
            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>' = = = = ', -anchor=>'w');
            push(@grs, $id1);
            $ly++;
        }
        if($vfnd) {

            &mkupsym(\@grs, $cv, $k,
                $qx, $y-$shtht+$shttd+$shtvg*$ly, $shtqw, $shtvg, "fn2ah");

            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xfnd, -anchor=>'w');
            push(@grs, $id1);
    &markdate($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xfnd, \@grs);
            $ly++;
        }
        if($vfnt) {
            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xfnt, -anchor=>'w');
            push(@grs, $id1);
    &marktime($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xfnt, \@grs);
            $ly++;
        }
        if($vfsd || $vfst) {
            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>"---", -anchor=>'w');
            push(@grs, $id1);
            $ly++;
        }
        if($vfsd) {
            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xfsd, -anchor=>'w');
            push(@grs, $id1);
            $ly++;
        }
        if($vfst) {
            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xfst, -anchor=>'w');
            push(@grs, $id1);
            $ly++;
        }
        if($vocd || $vocn) {
            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>"---", -anchor=>'w');
            push(@grs, $id1);
            $ly++;
        }
        if($vocd) {
    if($datepriority==0) {
            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xocn, -anchor=>"w");
            push(@grs, $id1);
    &markno($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xocn, \@grs);
            $ly++;

            &mkupsym(\@grs, $cv, $k,
                $qx, $y-$shtht+$shttd+$shtvg*$ly, $shtqw, $shtvg, "oc2ah");

            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xocd, -anchor=>'w');
            push(@grs, $id1);
    &markdate($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xocd, \@grs);
            $ly++;


    }

    if($datepriority==1) {
            &mkupsym(\@grs, $cv, $k,
                $qx, $y-$shtht+$shttd+$shtvg*$ly, $shtqw, $shtvg, "oc2ah");

            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xocd, -anchor=>'w');
            push(@grs, $id1);
    &markdate($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xocd, \@grs);
            $ly++;


            $id1 = $cv->create('text', $lx, $y-$shtht+$shttd+$shtvg*$ly,
                    -text=>$xocn, -anchor=>"w");
            push(@grs, $id1);
    &markno($cv, $mx, $y-$shtht+$shttd+$shtvg*$ly+$gg, $shtmw, $xocn, \@grs);
            $ly++;
    }


        }

    }

    my $id;
    my $p = arpos(\@imgstack, $k);

    if($p>=0) {
#print "APP\n";
        $id = $cv->create('polygon',
                $x+$shtlm+0*$shtaj,$y-2*$shtaj,
                $x+$shtlm+1*$shtaj,$y-1*$shtaj,
                $x+$shtlm+3*$shtaj,$y-3*$shtaj,
                $x+$shtlm+5*$shtaj,$y-1*$shtaj,
                $x+$shtlm+6*$shtaj,$y-2*$shtaj,
                $x+$shtlm+3*$shtaj,$y-5*$shtaj,
                -fill=>'black', -outline=>'black', -tag=>"app");

    }
    else {
#print "NOT APP\n";
        $id = $cv->create('polygon',
                $x+$shtlm+0*$shtaj,$y-4*$shtaj,
                $x+$shtlm+1*$shtaj,$y-5*$shtaj,
                $x+$shtlm+3*$shtaj,$y-3*$shtaj,
                $x+$shtlm+5*$shtaj,$y-5*$shtaj,
                $x+$shtlm+6*$shtaj,$y-4*$shtaj,
                $x+$shtlm+3*$shtaj,$y-1*$shtaj,
                -fill=>'black', -outline=>'black', -tag=>"noapp");

    }

    $cv->raise($id);
    push(@grs, $id);

#   print "grs ".(join("/", @grs))."\n";

    
    my $id = $cv->createGroup([$x, $y-$shtht],
                -members=>\@grs,
                -tag=>$k);

    $cv->bind($k, "<ButtonPress-1>"   => [\&spick,$cv,$k,Ev('x'),Ev('y')]);
    $cv->bind($k, "<B1-Motion>"       => [\&smove,$cv,$k,Ev('x'),Ev('y')]);
    $cv->bind($k, "<ButtonRelease-1>" => [\&srele,$cv,$k,Ev('x'),Ev('y')]);
    $cv->bind($k, "<Enter>" =>           [\&sent,$cv,$k,Ev('x'),Ev('y')]);
    $cv->bind($k, "<Leave>" =>           [\&slev,$cv,$k,Ev('x'),Ev('y')]);
#   $cv->bind($k, "<Key>h" =>            [\&shead,$cv,$k,Ev('x'),Ev('y')]);
#   $cv->bind($k, "<Key>t" =>            [\&stail,$cv,$k,Ev('x'),Ev('y')]);

}

my $sltmargin = 30;
my $sllmargin = 30;
my $slrmargin = 30;

sub decotline {
    my($cv,$ox,$oy,$nar,$nl,$refdate) = @_;
    my $x;
    my $dice;
    my $w;
    my $gw;
    my $lab;
    my $i;
    my $maxi;
    my $ch;
    my $len;
    my $left;
    my $rdv;
    my $cdv;
    my $k;
    my $gy;

    my $sx;
    my $sy;
    my $haverest=0;


    $sx = $ox;
    $sy = $oy;


    $rdv = $refdate+0;
#    print "rdv $rdv\n";

    $len = scalar(@$nar);

#    print "nl $$nl, len $len\n";
#   foreach $i (@$nar) {
#       print "$i $dfn{$i}\n";
#   }


    $left = $$nl;
    if($left<0 && $len>0) {
print "FIRST\n";
        $left = 0;
        $$nl = 0;
    }


if(0) {

print "size ";
print $cv->width();
print " x ";
print $cv->height();
print "\n";

print "req  ";
print $cv->reqwidth();
print " x ";
print $cv->reqheight();
print "\n";

print "pos  ";
print $cv->x();
print " x ";
print $cv->y();
print "\n";
}

    if($cv->width==1 && $cv->reqwidth>0) {
        $gw = $cv->reqwidth;
#        $gw = $cv->reqwidth*3/4;
    }
    else {
        $gw = $cv->width;
#        $gw = $cv->width*3/4;
    }

    $w = $gw - $ox - $sllmargin - $slrmargin;

 if(0) {
    $cv->create('line', $ox, $oy-30, $ox, $oy+260, -fill=>'tan');
    $cv->create('line', $ox+$sllmargin, $oy-30, $ox+$sllmargin, $oy+260, -fill=>'tan');
    $cv->create('line', $ox+$sllmargin+$w, $oy-30, $ox+$sllmargin+$w, $oy+260, -fill=>'tan');
    $cv->create('line', $ox+$sllmargin+$w+$slrmargin, $oy-30, $ox+$sllmargin+$w+$slrmargin, $oy+260, -fill=>'tan');

 }

    $sx = $ox + $sllmargin;
    $sy = $oy + $sltmargin + $shtht;

    $cv->create('line', $sx, $sy, $sx+$w, $sy);

    if($len<=0) {
        print "NODATA\n";
        return;
    }

    $gy = $oy+$sltmargin/2;

    my $msg = sprintf("%d/%d", $left+1, $len);

    $cv->create('text', $ox+$sllmargin+$shtwd/2, $gy, -text=>$msg);


#print "left $left\n";
    if($left!=0) {
        $cv->create('polygon', $ox+$sllmargin/3, $gy,
                            $ox+$sllmargin*2/3, $gy-$sllmargin/6,
                            $ox+$sllmargin*2/3, $gy+$sllmargin/6,
                            -fill=>'black');
    }


    $x = 0;
    for($i=$left;$i<$len;$i++) {
        if($x+$shtwd>$w) {
            last;
        }
        $k = @$nar[$i];

        &mkshtsym($cv,$sx+$x,$sy,$k,$rdv);

        my $p = arpos(\@imgstack, $k);
#       print "p $p\n";
        if($p>=0) {
            $cv->create('line', $sx+$x, $sy,
                $illmargin+$p*($imgwd+$ilgap),250,
                -fill=>'blue', -width=>3);
        }

        $x += $shtwd;
        $x += $shtga;
        $maxi = $i;
        if($x>$w) {
            last;
        }
    }

#print "left $left maxi $maxi len $len\n";

    if($maxi!=$len-1) {
        $cv->create('polygon', $sx+$w+$sllmargin*2/3, $gy,
                            $sx+$w+$sllmargin/3, $gy-$sllmargin/6,
                            $sx+$w+$sllmargin/3, $gy+$sllmargin/6,
                            -fill=>'black');
    }


 if(0) {

    foreach $i ($cv->find('all')) {
        my @ts;
        @ts = $cv->gettags($i);
        if($#ts>=0) {
            $k = $ts[0];
            print "$i $k $dfn{$k}\n";
        }
        else {
            print "$i - -\n";
        }
    }
 }

    $shttmin = $left;
    $shttmax = $maxi;

}



sub imgpush {
    my($id,$cv,$k,$x,$y) = @_;
    my @co;
    my @bb;
    print "imgpush $k\n";

    @co = $cv->coords($k);
    print "co $co[0], $co[1], $co[2], $co[3]\n";
    print "x $x, y $y\n";
    @bb = $cv->bbox($k);
    print "bb $bb[0], $bb[1], $bb[2], $bb[3]\n";

    $__ix = $x-$bb[0];
    $__iy = $y-$bb[1];
    print "ix $__ix iy $__iy\n";

#   print "imgstack ".(join("/",@imgstack))."\n";
    &uniqpush(\@imgstack, $k);
    print "imgstack ".(join("/",@imgstack))."\n";

    &redraw;
}

sub imgremove {
    my($id,$cv,$k,$x,$y) = @_;
    my $pos;
    print "imgremove $k\n";
    $pos = &arpos(\@imgstack,$k);
    if($pos>=0) {
        splice(@imgstack,$pos,1);
    }
    &redraw;
}

sub imgpick {
    my($id,$cv,$k,$x,$y) = @_;
    my @co;
    my @bb;
    print "imgpick $k\n";

#   foreach my $i ($cv->itemcget($k, -members)) {
#       print "  i $i\n";
#   }

    @co = $cv->coords($k);
    print "co $co[0], $co[1], $co[2], $co[3]\n";
    print "x $x, y $y\n";
    @bb = $cv->bbox($k);
    print "bb $bb[0], $bb[1], $bb[2], $bb[3]\n";

    $__ix = $x-$bb[0];
    $__iy = $y-$bb[1];
    print "ix $__ix iy $__iy\n";

    &imgremove($id,$cv,$k,$x,$y);

#    if($__iy>=$shtht-$shtct&&$__iy<=$shtht) {
#        print "remove?\n";
#        &imgremove($id,$cv,$k,$x,$y);
#        return;
#    }

}

sub iscalechange {
    my($v) = @_;
    print "iscalechange $v\n";
    print "iscale $iscale\n";

    if($iscale==0) {
        $imgwd = 128;
    }
    elsif($iscale==1) {
#       $imgwd = 256;
        $imgwd = 192;
    }
    elsif($iscale==2) {
        $imgwd = 384;
    }
    elsif($iscale==3) {
        $imgwd = 512;
    }
    $imght = $imgwd*4/3;

    undef %imgscache;

    &redraw;
}

sub imgline {
    my($cv, $ox, $oy) = @_;
    my $i;
    my $k;
    my $x;
    my $y;
    my $id;
    my $oimg;
    my $simg;
    my $scale;
    my $aspect;
    
    $x = $ox+$illmargin;
    $y = $oy+$iltmargin;
    $i = 0;
    foreach $k (@imgstack) {
        $id = $cv->create('rectangle', $x, $y, $x+$imgwd, $y+$imght);
        $cv->raise($id);

        if($vbug) {
#       $id = $cv->create('text', $x+$imgwd/2, $y+$imght/2, -text=>$k);
        $id = $cv->create('text', $x+$imgwd/2, $y-$iltmargin/2, -text=>$k);
        }

#        my $fn = "img".($i+1).".jpg";
#print " fn |$fn|\n";
        my $fn = $pfs{$k};

        if(-f $fn) {
            my ($swd, $sht);

            if(defined $imgocache{$k}) {
                $oimg = $imgocache{$k};
            }
            else {
                $oimg = $mw->Photo(-file=>$fn);
                $imgocache{$k} = $oimg;
            }

            if(defined $imgscache{$k}) {
                $simg = $imgscache{$k};
            }
            else {
#                print " size ".($oimg->width)." x ".($oimg->height)."\n";
                $scale = $oimg->width/$imgwd;
                $aspect = $oimg->height/$oimg->width;
#                print " scale $scale; aspect $aspect\n";
                $simg = $mw->Photo();
                $simg->copy($oimg, -shrink, -subsample=>$scale);
                $imgscache{$k} = $simg;
            }

            $swd = $simg->width;
            $sht = $simg->height;
#            print " small image $swd x $sht\n";

            $cv->create('image', $x+$swd/2, $y+$sht/2, -image=>$simg);
        }

        my $id = $cv->create('rectangle',
                    $x+$imglm+0*$imgaj,$y+0*$imgaj,
                    $x+$imglm+8*$imgaj,$y+6*$imgaj,
                    -fill=>'white', -outline=>'white',
                    -stipple=>'gray50');
        $cv->raise($id);

        my $id = $cv->create('polygon',
                    $x+$imglm+1*$imgaj,$y+4*$imgaj,
                    $x+$imglm+2*$imgaj,$y+5*$imgaj,
                    $x+$imglm+4*$imgaj,$y+3*$imgaj,
                    $x+$imglm+6*$imgaj,$y+5*$imgaj,
                    $x+$imglm+7*$imgaj,$y+4*$imgaj,
                    $x+$imglm+4*$imgaj,$y+1*$imgaj,
                    -fill=>'#009', -outline=>'#009');
        $cv->raise($id);

#     $cv->bind($k, "<ButtonPress-1>"   => [\&spick,$cv,$k,Ev('x'),Ev('y')]);
        $cv->bind($id,"<ButtonPress-1>" => [\&imgpick,$cv,$k,Ev('x'),Ev('y')]);


        $x += $imgwd;
        $x += $ilgap;
        $i++;
    }
    
}



my $crr = 50;
my $ledge=-1;





sub redraw {
#print "redraw\n";
    $canvas->delete('all');
    &decotline($canvas, 0, 0, \@ar, \$ledge, $refdate);
    &imgline($canvas, 0, 250);
}

sub draw {
#print "draw\n";
    &redraw;
}

sub init_redraw {
#print "init_redraw\n";
    &ar_init;
    &redraw;
}

sub posprev {
#    print "posprev before $ledge\n";
    $ledge--;
    if($ledge<0) {
        $ledge = 0;
    }
#    print "        after  $ledge\n";
    &redraw;
}

sub possucc {
#    print "possucc before $ledge\n";
    $ledge++;
    if($ledge>$#ar) {
        $ledge = $#ar;
    }
#    print "        after  $ledge\n";
    &redraw;
}


sub posprevw {
    my $w;
#    print "posprevw before $ledge\n";
#    $ledge--;
    $w = $shttmax - $shttmin;
    $ledge = $shttmin - $w - 1;
    if($ledge<0) {
        $ledge = 0;
    }
#    print "        after  $ledge\n";
    &redraw;
}

sub possuccw {
#    print "possuccw before $ledge\n";
#    $ledge++;
    $ledge = $shttmax + 1;
    if($ledge>$#ar) {
        $ledge = $#ar;
    }
#    print "        after  $ledge\n";
    &redraw;
}



sub poshead {
    $ledge = 0;
    &redraw;
}

sub postail {
    $ledge = $#ar;
    &redraw;
}

sub tgv {
    my($vn) = @_;
#   $$vn = 1 - $$vn;
    &verify_ht;
    &redraw;
}

sub import_byfs {
    $db_ar->clear();
    @ar = keys %pfs;
    &redraw;
}


sub sort_byocnd {
    @ar = sort { $doc{$a} cmp $doc{$b}; } keys %doc;
    &redraw;
}

sub sort_byocdn {
    @ar = sort {
        my ($na,$da)=split(/,/,$doc{$a});
        my ($nb,$db)=split(/,/,$doc{$b});
        if($da==$db) { return $na cmp $nb;}
        else         { return $da cmp $db;}
    } keys %doc;
    &redraw;
}

sub sort_byoc {
    if($datepriority==1) {
        &sort_byocdn;
    }
    else {
        &sort_byocnd;
    }
}

sub sort_byahnd {
    @ar = sort {$dah{$a} cmp $dah{$b}} keys %dfn;
    &redraw;
}

sub dncmp {
    my($an,$ad) = split(/,/, $dah{$a});
    my($bn,$bd) = split(/,/, $dah{$b});
    if($ad eq $bd) {
        return $an cmp $bn;
    }
    else {
        return $ad cmp $bd;
    }
}

sub sort_byahdn {
#    @ar = sort {$dah{$a} cmp $dah{$b}} keys %dfn;
    @ar = sort dncmp keys %dfn;
    &redraw;
}

sub sort_byah {
    if($datepriority==1) {
        &sort_byahdn;
    }
    else {
        &sort_byahnd;
    }
}


sub sort_byfn {
    @ar = sort {$dfn{$a} cmp $dfn{$b}} keys %dfn;
    &redraw;
}

#sub rebuild {
#   print "rebuild\n";
#}

sub scan {
    print "scan\n";
}

sub redrawR {
    &update_datecolor;
    &redraw;
}

sub datecolorchange {
    &update_datecolor;
    &redraw;
}

sub findfirst {
    my $k;
    my $xfnd;
    my $xfn;
    my $dmy;
    my $i;
    my $p;

#   $ljmsg->configure(-text=>'');

print "jumpnext: $jmpdate\n";
    $i = 0;
    $p = -1;
    foreach $k (@ar) {
        $xfn = $dfn{$k};
        ($xfnd, $dmy) = split(/_/, $xfn);
        if($xfnd eq $jmpdate) {
            print "FOUND $i $k\n";
            $p = $i;
            last;
        }
        $i++;
    }

    if($p>=0) {
#       $ljmsg->configure(-text=>"find in $p");
        $sbar->configure(-text=>"find in $p");
        $ledge = $p;
        &redraw;
    }
    else {
#       $ljmsg->configure(-text=>'not found');
        $sbar->configure(-text=>'not found');
    }
}

sub qfindprev {
    my ($rdv) = @_;
    my $k;
    my $xfnd;
    my $xfn;
    my $dmy;
    my $i;
    my $p;
print "qfundprev: $rdv\n";
    $p = -1;
    for($i=$ledge-1;$i>=0;$i--) {
        $k = $ar[$i];
        $xfn = $dfn{$k};
        ($xfnd, $dmy) = split(/_/, $xfn);
        if($xfnd eq $rdv) {
            print "FOUND $i $k\n";
            $p = $i;
            last;
        }
    }
    return $p;
}

sub qfindnext {
    my ($rdv) = @_;
    my $k;
    my $xfnd;
    my $xfn;
    my $dmy;
    my $i;
    my $p;
print "qfindnext: $rdv\n";
    $p = -1;
    for($i=$ledge+1;$i<=$#ar;$i++) {
        $k = $ar[$i];
        $xfn = $dfn{$k};
        ($xfnd, $dmy) = split(/_/, $xfn);
        if($xfnd eq $rdv) {
            print "FOUND $i $k\n";
            $p = $i;
            last;
        }
    }
    return $p;

}

#sub mkdateoffset {


sub jumpnext {
    my $k;
    my $xfnd;
    my $p;
    my $i;

print "jumpnext: $jmpdate\n";
#   $ljmsg->configure(-text=>'');

    $xfnd = $jmpdate;

    $p = &qfindnext($xfnd);

    if($p>=0) {
#       $ljmsg->configure(-text=>"found");
        $sbar->configure(-text=>"found");
        $ledge = $p;
        &redraw;
        return;
    }

    for($i=1;$i<=$jumploose;$i++) {
        $xfnd = &mkdateoffset($jmpdate, $i);
#print "i $i xfnd $xfnd\n";
        $p = &qfindnext($xfnd);
        if($p>=0) {
            last;
        }
    }

    if($p>=0) {
#       $ljmsg->configure(-text=>"find as $xfnd");
        $sbar->configure(-text=>"find as $xfnd");
        $ledge = $p;
        &redraw;
        return;
    }
    else {
#       $ljmsg->configure(-text=>'not found');
        $sbar->configure(-text=>'not found');
    }
}

sub jumpprev {
    my $k;
    my $xfnd;
    my $p;
    my $i;

print "jumpprev: $jmpdate\n";
#   $ljmsg->configure(-text=>'');

    $xfnd = $jmpdate;

    $p = &qfindprev($xfnd);

    if($p>=0) {
        $sbar->configure(-text=>"found");
        $ledge = $p;
        &redraw;
        return;
    }

    for($i=1;$i<=$jumploose;$i++) {
        $xfnd = &mkdateoffset($jmpdate, -$i);
#print "i $i xfnd $xfnd\n";
        $p = &qfindnext($xfnd);
        if($p>=0) {
            last;
        }
    }

    if($p>=0) {
#       $ljmsg->configure(-text=>"find as $xfnd");
        $sbar->configure(-text=>"find as $xfnd");
        $ledge = $p;
        &redraw;
        return;
    }
    else {
#       $ljmsg->configure(-text=>'not found');
        $sbar->configure(-text=>'not found');
    }
}


sub Xjumpprev {
    my $k;
    my $xfnd;
    my $xfn;
    my $dmy;
    my $i;
    my $p;
print "jumpprev: $jmpdate\n";
#   $ljmsg->configure(-text=>'');
    $i = 0;
    $p = -1;
    for($i=$ledge-1;$i>=0;$i--) {
        $k = $ar[$i];
        $xfn = $dfn{$k};
        ($xfnd, $dmy) = split(/_/, $xfn);
        if($xfnd eq $jmpdate) {
            print "FOUND $i $k\n";
            $p = $i;
            last;
        }
    }

    if($p>=0) {
#       $ljmsg->configure(-text=>'find in $p');
        $sbar->configure(-text=>'find in $p');
        $ledge = $p;
        &redraw;
    }
    else {
#       $ljmsg->configure(-text=>'not found');
        $sbar->configure(-text=>'not found');
    }
}

&update_datecolor;

#&data_verify;
#&ar_print();
&verify_ht;
&draw;

$mw->bind("<Configure>", \&redraw);

MainLoop();

