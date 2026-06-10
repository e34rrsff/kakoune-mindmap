use strict;
use warnings;

package DryMindMap;

sub err {
    my $msg = shift;

    print STDERR "$msg\n";
    exit(1);
}

sub kak_fail {
    return;
}

1;
