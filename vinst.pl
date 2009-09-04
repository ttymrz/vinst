#!/usr/bin/perl
#-----------------------------------------------------------------------------#
# vinst.pl
# generate instance from verilog rtl.
#
# author: Tetsuya Morizumi
# created: 200x-xx-xx
# $Id$
#-----------------------------------------------------------------------------#
use strict;

#-----------------------------------------------------------------------------#
# global environment
#-----------------------------------------------------------------------------#
my $indent = "    ";
my $ts = 16;            # tabstop
#my $inst_px = "U_";    # instance prefix
my $inst_px = "";

#-----------------------------------------------------------------------------#
# main
#-----------------------------------------------------------------------------#
if($#ARGV < 0){
    print "$0 [-e] <verilog file>\n";
    exit;
}

my $fill_flag = 1;
my $file = $ARGV[0];
if($ARGV[0] eq "-e")
{
    $fill_flag = 0;
    $file = $ARGV[1];
}

open(VFILE, $file) or die "cannot open file: $file\n";

my $rtl = "";
while(my $in = <VFILE>){
    chop($in);
    # strip comment //
    $in =~ s/\/\/.*//go;
    $rtl .= $in;
}

close(VFILE);

# strip comment /* */
$rtl =~ s/\/\*[\w\W.]*?\*\///go;

# parse module
if($rtl =~ /module/o and $rtl =~ /endmodule/o)
{
    my @modules = split(/endmodule/, $rtl);

    foreach my $m (@modules)
    {
        $m =~ s/(^\s+|\s+$)//o;
        if($m ne "")
        {
            &print_instance($m);
        }
    }
}

exit;

#-----------------------------------------------------------------------------#
# print instance
#-----------------------------------------------------------------------------#
sub print_instance()
{
    my $m = shift;

    # get module name and ports
    my $module = "";
    my $ports = "";

    if($m =~ /module\s+(\w+)\s*\(([\s\w,]+)\)\s*;/o)
    {
        $module = $1;
        $ports = $2;
    }
    else
    {
        return;
    }

    $ports =~ s/\s+//go;
    my @port = split(/,/, $ports);

    print "$module $inst_px$module\n(\n";

    my $format;
    if($fill_flag)
    {
        $format = sprintf "$indent.%%-%ds(%%-%ds)", $ts-1, $ts-1;
    }
    else
    {
        $format = sprintf "$indent.%%-%ds()", $ts-1;
    }
    
    my $i = 0;
    foreach my $p (@port)
    {
        if($fill_flag)
        {
            printf $format, $p ,$p;
        }
        else
        {
            printf $format, $p;
        }
        if($i == $#port)
        {
            print "\n";
        }
        else
        {
            print ",\n";
        }
        $i++;
    }
    print ");\n";
}

