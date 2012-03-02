#!/usr/bin/env perl 
use strict;
use warnings;

use Test::Most qw{no_plan};

=pod

From Sam: 

foreach my $dakine ([1,1],[2,1],[4,2]){
  @count{'first','second'}+= @{$dakine};
}
say(join(' : ',@count{'first','second'}));
### Outputs > undef : 4

=cut

{

my %dakine = ( map{$_ => $_} 1..10 );
my %count  = ( first => 0, second => 0);

for my $slice ( [1,1], [2,1], [4,2] ) {
  my @data = @dakine{@$slice};
  do{ $count{$_} += shift @data } for qw{first second}; 
}

eq_or_diff \%count, {first => 7, second => 4};



};


;
