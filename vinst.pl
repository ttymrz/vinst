#!/usr/bin/perl
#-----------------------------------------------------------------------------#
# vinst.pl
# generate instance from verilog rtl.
#
# author: Tetsuya Morizumi
# created: 2013-05-29
# $Id$
#-----------------------------------------------------------------------------#
use strict;
use warnings;
use Getopt::Std;
use Verilog::Netlist;

#-----------------------------------------------------------------------------#
# global environment
#-----------------------------------------------------------------------------#
my $indent = "    ";
my $ts = 4;             # tabstop
my $inst_px = "u_";     # instance prefix
#my $inst_px = "";

#-----------------------------------------------------------------------------#
# main
#-----------------------------------------------------------------------------#
my %opt = ();
getopts("hie", \%opt);

if($opt{h} or $#ARGV == -1)
{
    &help();
    exit;
}

if($opt{i})
{
    &make_io_info();
} else
{
    &make_instance();
}

exit;

#-----------------------------------------------------------------------------#
sub help()
{
    print << "__EOL__";
Usage: ${0} [OPTION] <verilog file>...
Options
    -h  help
    -i  print i/o infomation
    -e  empty port connection
__EOL__
    exit;
}

sub make_instance()
{
    my @files = @ARGV;
    my $netlist = new Verilog::Netlist;

    &read_verilog_files($netlist, \@files);

    &print_instance($netlist);
}

sub make_io_info()
{
    my @files = @ARGV;
    my $netlist = new Verilog::Netlist;

    &read_verilog_files($netlist, \@files);

    &print_io_info($netlist);
}

sub read_verilog_files()
{
    my ($netlist, $filelist) = @_;

    foreach my $file (@{$filelist})
    {
        $netlist->read_file(filename => $file);
    }

    # checkfile
    my @existfiles = $netlist->files;
    if($#existfiles == -1)
    {
        &help();
    }
    $netlist->link();   # connection resolve
}

sub get_max_portlen()
{
    my ($ports) = @_;
    my $max = 0;

    foreach my $pp (@{$ports})
    {
        my $size = length($pp->name);
        if ($max < $size) { $max = $size; }
    }

    return $max;
}

sub print_instance()
{
    my ($netlist) = @_;

    foreach my $module ($netlist->modules_sorted)
    {
        my @ports = $module->ports_ordered;
        if ($#ports == -1) { next; }

        print $module->name, " ", $inst_px, $module->name, "\n(\n";

        my $max = &get_max_portlen(\@ports);
        $max = (int($max/$ts) + 1) * $ts;

        my $format = "";

        if($opt{e})
        {
            $format = sprintf "$indent.%%-%ds()", $max-1;
        } else
        {
            $format = sprintf "$indent.%%-%ds(%%-%ds)", $max-1, $max-1;
        }

        for(my $ii = 0; $ii <= $#ports; $ii++)
        {
            printf $format, $ports[$ii]->name, $ports[$ii]->name;
            if($ii != $#ports)
            {
                print ",\n";
            } else
            {
                print "\n";
            }
        }
        print ");\n\n";
    }
}

sub print_io_info
{
    my ($netlist) = @_;

    foreach my $module ($netlist->modules_sorted)
    {
        my @ports = $module->ports_ordered;
        if($#ports == -1) { next; }

        print "// ", $module->name, "\n";

        my $max = &get_max_portlen(\@ports);
        $max = (int($max/$ts) + 1) * $ts;

        my $format = sprintf "%%-%ds", $max-1;

        foreach my $pp (@ports)
        {
            print $pp->direction , "\t";
            if(defined($pp->net->width) && $pp->net->width != 1)
            {
                print '[',$pp->net->msb, ':',$pp->net->lsb,']';
            }
            print "\t\t";
            print $pp->name;
            print "\n";
        }
        print "\n";
    }
}

