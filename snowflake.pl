#!/usr/bin/perl -w

use strict;
use Getopt::Std;
use Term::ANSIColor qw(:pushpop);;

use vars qw/ %opt /;

our $CONFIG_FILE="$ENV{'HOME'}/.config/pep8";

$| = 1;

&main;

sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub run_flake8() {
    if ($_[0] eq "") {
        return;
    } 

    open LESS, '| less -R' or die $!;
    select LESS;

    print LESS BOLD GREEN ON_BLACK "################# FLAKE8 OUTPUT FOR FILE $_[0] ################\n\n";

    my $output = "";

    if ($opt{c}) {
        $output = `flake8 --config=$CONFIG_FILE $_[0] | grep $opt{c}`;
    } else {
        $output = `flake8 --config=$CONFIG_FILE $_[0]`;
    }

    foreach my $line (split(/\n/, $output)) {
        my ($filename, $line, $column, $error) = split(/:/, $line);
        
        print LESS BLUE "$filename ";

        if (defined($line)) {
            print LESS GREEN "$line:$column";
        }

        if (defined($error)) {
            print LESS RED ON_BLACK "$error";
        }
        print LESS BLUE "\n";
    }

    select STDOUT;
    close LESS;
}

sub check_env() {
    my $flake8 = `which flake8`;
    if ($flake8 eq "") {
        print "ERROR: could not find flake8, try activating a virtualenv.\n";
        exit 0;
    }
}

sub usage() {
    print STDERR << "USAGE";

Will run flake8 on all files in a mercurial changset.

usage: $0 [-r revision]
     -r        : a mercurial revision changeset number
     -f        : check files that match this name
     -c        : specify a flake8 code to match

USAGE

    exit;

}

sub main() {

    &check_env();

    getopts("r:f:c:", \%opt ) or &usage();
    
    if (not defined($opt{r})) {
        &usage();
    }

    my $revision = $opt{r};
    my @files = split(/:/, `hg log -r $revision | grep files`);
    my $filelist = &trim($files[1]);

    foreach my $file (split(/\s/, $filelist)) {
        if (defined($opt{f})) {
            if ($file =~ $opt{f}) {
                &run_flake8($file);
            }
        } else {
            &run_flake8($file);
        }
    }
}
