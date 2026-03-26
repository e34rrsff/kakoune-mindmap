#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

unless ($ARGV[0]) {
    print STDERR "error: missing path argument\n";
    exit(1);
}

sub titles_from_files {
    my (@paths) = @_;
    my @titles;
    for my $path (@paths) {
        my $title = '';
        if (open my $fh, '<:encoding(UTF-8)', $path) {
            while (my $line = <$fh>) {
                if ($line =~ /^=\s*(\s.*?)\s*$/) {
                    $title = $1;
                    last;
                }
            }
            close $fh
        }
        push @titles, $title;
    }
    return @titles
}

my $notes_path = $ARGV[0];
my @files = glob("$notes_path/*.{adoc,asciidoc}");
my @titles = titles_from_files(@files);

for my $i (0 .. $#files) {
    # TODO: Fix (remove) the preceding space in @titles
    print "$files[$i] [$titles[$i] ]\n";
}
