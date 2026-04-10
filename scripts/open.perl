#!/usr/bin/env perl
use strict;
use warnings;

# TODO: I know I'm inconsistently using forward slashes for directory paths in
# variables, maybe I should do something about that.
#
# Also, maybe I should change the list script's behavior to be more like how
# this one functions
#
# And also I'm not sure if this is properly handling STDIN, but it works
my $input = <STDIN>;
exit 0 unless defined $input;

my @fields = split(/\/\n/, $input);
for my $file (@fields) {
    if (-T "$ENV{'kak_mindmap_dir'}/" . $file . ".adoc") {
        print "edit \"$ENV{'kak_mindmap_dir'}/$file.adoc\"\n";
    }
    else {
        print "fail \"$ENV{'kak_mindmap_dir'}/$file.adoc: $!\"\n";
    }
}

