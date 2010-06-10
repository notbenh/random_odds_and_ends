package one;
use strict;
use warnings;


$main::hash = {kitten => 'ugly'};
$ENV{HASH} = {hello => jeff => };




sub new { bless {}, shift}
sub two { use two; two->new };
sub hi { $main::hash };
sub go { warn 'ONE'; 
         local $main::hash = {kitten => cute => };
         shift->two->go };


   





1;


