#!/usr/bin/env perl
use strict;
use warnings;

# TODO: There may be some tuning I can apply to the script for better
# performance; but in a test I did with a directory containing 10,000 generated
# notes, it seems to perform about on par with grep + sed (under 0.5s on my
# machine).

my $notes_path = $ARGV[0];

unless ($notes_path) {
    print STDERR "error: missing ARGV[0] (path to notes)\n";
    exit(1);
}
elsif (! -d $notes_path) {
    print STDERR "error: ARGV[0] is not a valid directory path";
    exit(1);
}
elsif (substr($notes_path, -1) ne '/') {
    $notes_path = $notes_path . '/'
}

# TODO: support UTF-8 for filenames
my @files = glob("$notes_path*.adoc");

sub paths_and_titles_from_files {
    my (@file_paths) = @_;
    my %notes_file_hash;

    foreach (@file_paths) {
        my $title = '';
	if (-T $_) {
	    if (open my $fh, '<:utf8', $_) {
                while (my $line = <$fh>) {
                    if ($line =~ /=\s+(.*)?$/) {
                        $title = $1;
                        last;
                    }
                }
                close $fh;
            }
        }
        else {
            $title = "$!";
        }
	$notes_file_hash{"$_"} = "$title";
    }
    return %notes_file_hash;
}

my %notes_listing = paths_and_titles_from_files(@files);

foreach my $path (reverse sort keys %notes_listing) {
    my $file_id = do { $path =~ /(.*\/)+(.*)\.a(scii)?doc/; $2 };
    print "$file_id/[$notes_listing{$path}]\n";
}
