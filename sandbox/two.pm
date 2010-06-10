package two;
use strict;
use warnings;
sub new { bless {}, shift };
sub three { use three; three->new};

sub go {
   warn 'TWO';
   shift->three->go;
}


1;


