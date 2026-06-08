#!/usr/bin/env perl
use strict;
use warnings;
use File::Find::Rule;

my $notes_path = $ARGV[0];
my $note_id = $ARGV[1];

unless ($notes_path and $note_id ) {
    print STDERR "usage: open.perl <MindMap dir> <note ID>\n";
    exit(1); 
} 
elsif (! -d $notes_path) {
    print STDERR "error: invalid directory path\n";
}

my $note_file_regex = qr/$note_id.(a(scii)?doc|md)/;
my @matched_files;

File::Find::Rule
    ->file()
    ->name($note_file_regex)
    ->exec(sub {
           my $path_to_note = $_[2];

           push @matched_files, $path_to_note;
          })
    ->in("$notes_path");

my $n_found = scalar @matched_files;

if ($n_found == 0) {
    print "fail \"note not found for ID '$note_id'\"\n";
}
elsif ($n_found > 1) {
    # TODO: test
    print "fail \"duplicate IDs for ID '$note_id'\"\n";
}
elsif (-T $matched_files[0]) {
    print "edit \"$matched_files[0]\"\n";
}
else {
    print "fail \"note with ID '$note_id': $!\"\n";
}
