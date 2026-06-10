#!/usr/bin/env perl
use strict;
use warnings;

use File::Find::Rule;

# for module here, at ./lib/DryMindMap.pm
use File::Basename qw(dirname);
use lib dirname(File::Spec->rel2abs(__FILE__)) . '/lib';
use DryMindMap;

my $notes_path = $ARGV[0];

unless ($notes_path and
        scalar @ARGV == 1) {
    DryMindMap::err "usage: list.perl <MindMap dir>";
}
elsif (! -d $notes_path) {
    DryMindMap::err "error: invalid directory path";
}

# this regex looks for 10 digit IDs, which would break in like 2038 or
# something
my $filename_schema = (qr/\d{10}\.(a(scii)?doc|md)$/);

File::Find::Rule
    ->file()
    ->name($filename_schema) 
    ->exec(sub {
               my $note_file = $_[2];

               my ($note_id, $file_ext)  = $_[0] =~ /(.+)\.([^.]+)$/;
               my $title = '(No Title)';

               if (-T $note_file && open(my $fh, '<:utf8', $note_file)) {

                   # feels odd placing this here... INEFFICIENCY (?)
                   my $in_md_frontmatter = 0;
                   while (my $line = <$fh>) {

                       if ($file_ext =~ /a(scii)?doc/) {
                           if ($line =~ /^=\s+(\S.+)$/) {
                               $title = $1; last;
                       }}
                       elsif ($in_md_frontmatter == 1 or $file_ext eq 'md') {
                           if ($in_md_frontmatter == 1) {
                               if ($line =~ /^title:\s+(\S.+)$/) {
                                   $title = $1; last;
                           }}
                           elsif ($line =~ /^---\s*$/) {
                               $in_md_frontmatter += 1;
                           };
                       }
                   } close $fh
               } else { $title = "($!)"; }

               print "[$note_id]" . ' ' . "$title\n";
           })
    ->in($notes_path);

# TODO: handle notes with conflicting, duplicate IDs
