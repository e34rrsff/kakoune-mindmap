#!/usr/bin/env perl
use strict;
use warnings;

my $notes_path = $ARGV[0];

unless ($notes_path) {
    print STDERR "error: missing ARGV[0] (path to notes)\n";
    exit(1);
} elsif (! -d $notes_path) {
    print STDERR "error: ARGV[0] is not a valid directory path";
    exit(1);
}

# TODO: support UTF-8 for filenames
my @files = glob("$notes_path/?*.{adoc,asciidoc}");
sub paths_and_titles_from_files {
    my (@file_paths) = @_;
    my %notes_file_hash;

    foreach (@file_paths) {
        my $title = '';
	if (-T $_) {
	    if (open my $fh, '<:utf8', $_) {
                while (my $line = <$fh>) {
                    if ($line =~ /^= (.*)?$/) {
                        $title = $1;
                        last;
                    }
                }
                close $fh;
            }
        }
        else {
	    # TODO: I accidentally left `$!` in from old (un-committed) code which I
	    # intended ro replace with a general single error message. But it
	    # seems like this is still able to use the error message from the
	    # previous "open" function. I'm not sure how this is working so I have to
	    # look into this later.
            $title = "\x1b[31m$!\x1b[m";
        }
	$notes_file_hash{"$_"} = "$title";
    }
    return %notes_file_hash;
}

my %notes_listing = paths_and_titles_from_files(@files);

foreach my ($path, $title) (%notes_listing) {
    print "$path [$title]\n";
}
