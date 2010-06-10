package three;
use strict;
use warnings;
use vars qw{$hash};
sub new { bless {}, shift };

sub go { warn 'THREE';  $main::hash }
#`sub go { warn 'THREE';  $ENV{HASH} }


1;


