#!/usr/bin/perl -w

use strict;
use warnings;
use Scalar::Util 'reftype';

use XML::Simple;
use Data::Dumper;
use XML::Simple;
use LWP::Simple;

our $CONFIG_FILE="$ENV{'HOME'}/.config/pep8";

$| = 1;

&main;

sub hash_walk {
    my ($hash, $key_list, $callback) = @_;
    while (my ($k, $v) = each %$hash) {
        # Keep track of the hierarchy of keys, in case
        # our callback needs it.
        push @$key_list, $k;

        if (ref($v) eq 'HASH') {
            # Recurse.
            hash_walk($v, $key_list, $callback);
        }
        else {
            # Otherwise, invoke our callback, passing it
            # the current key and value, along with the
            # full parentage of that key.
            $callback->($k, $v, $key_list);
        }

        pop @$key_list;
    }
}

sub print_keys_and_value {
    my ($k, $v, $key_list) = @_;
    printf "k = %-8s  v = %-4s  key_list = [%s]\n", $k, $v, "@$key_list";
}

sub main() {
    my $parser = new XML::Simple;

    my $url = 'http://capitalbikeshare.com/data/stations/bikeStations.xml';
    my $content = get $url or die "Unable to get $url\n";
    my $data = $parser->XMLin($content);

    # print Dumper($data);

    # hash_walk($data, [], \&print_keys_and_value);

    # Loop through top node
    while (my ($k, $v) = each %$data) {
        if ($k eq "version") {
            print "Version: $v\n";
        } elsif ($k eq "lastUpdate") {
            print "Last Updated: " . localtime($v) . "\n";
        } else {
            # Loop through individual stations
            while (my ($station_name, $station_data) = each %$v) {

#                foreach my $k (keys %$station_data) {
#                    print "$k: " . $station_data->{$k} . "\n";
#                }

                my $lastUpdateTime = localtime($station_data->{'latestUpdateTime'});
                print "$station_name\n";
                print "---------------------------------------------------\n";
                print "Num Bikes: $station_data->{'nbBikes'}\n";
                print "Num Open Docks: $station_data->{'nbEmptyDocks'}\n";
                print "Time: $lastUpdateTime\n";
                print "\n\n";
            }
        } 
    }
}
