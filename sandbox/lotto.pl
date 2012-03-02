#!/usr/bin/env perl 
use strict;
use warnings;
use YAML qw{LoadFile DumpFile};
use Getopt::Std;
 
my %opts = (p => 1);
getopt('Mp:', \%opts); 
die 'too many plays' unless $opts{p} <= 26;

# USEAGE : lotto.pl [-m] [-p1-20,26] [ 5 white picks ] [red] 
# EXAMPLE: lotto.pl -m -p 26 25 26 27 28 29 10 

# our winnings -> {white matches} -> {red matches} = cash prize
my $winnings = { 5 => { 1 => 'JACKPOT' , 0 => 20000 } 
               , 4 => { 1 => 10000     , 0 => 100   }
               , 3 => { 1 => 100       , 0 => 7     }
               , 2 => { 1 => 7         , 0 => 0     }
               , 1 => { 1 => 4         , 0 => 0     }
               , 0 => { 1 => 3         , 0 => 0     }
               };
 
# given a range pick $count unique values with in that range, returns a hashref.
sub rpick{
  my ($min,$max,$count) = @_;
  $count = 1 unless $count; # default
  my $stash = {};
  while (scalar(keys (%$stash)) < $count) {
    my $num = int(rand($max));
    next unless $num >= $min;
    $stash->{ $num } = 1;
  }
  return $stash;
}

# what did the robot pick
my $pick = { white => rpick(1, 59, 5)
           , red   => [keys %{rpick(1, 39)}]->[0]
           , mult  => [keys %{rpick(2,  5)}]->[0]
           };

printf qq{PICK    : %02d, %02d, %02d, %02d, %02d [%02d]\n}
     , keys %{$pick->{white}}
     , $pick->{red}
     ;

# just save off any matches for clarity 
my $match = { white => scalar( grep{defined} @{$pick->{white}}{map{shift @ARGV}1..5})
            , red   => $pick->{red} == shift @ARGV ? 1 : 0
            };

my $persist = -r '.lotto' ? LoadFile('.lotto') : {cost => 0, won => 0, plays => 0, ratio => 0};

my $cost    = ($opts{p} == 26 ? 25 : $opts{p}) * ($opts{m} ? 2 : 1);
$persist->{cost} += $cost;
$persist->{plays} += $opts{p};
printf qq{COST    : \$% 5d (\$% 8d) :%d plays\n}, $cost, $persist->{cost}, $persist->{plays};
my $won = $winnings->{ $match->{white} }->{ $match->{red} } 
        * $opts{p} 
        * ($opts{m} ? $pick->{mult} : 1) # did we ask for the multiplyer
        ; 
$persist->{won}  += $won;
$persist->{ratio} = ($persist->{won}/$persist->{cost}) * 100;
printf qq{WINNINGS: \$% 5d (\$% 8d) :%f%%\n}, $won, $persist->{won}, $persist->{ratio};

DumpFile('.lotto', $persist);

__END__
use Data::Dumper;
warn Dumper({ pick  => $pick
            , match => $match
            , LOTTO => $persist
            , opt   => \%opts
            , cost  => $cost
            , won   => $won
            });






my $value = $thing > 100 ? 'lots' 
          : $thing > 50  ? 'some'
          : $thing > 20  ? 'enough' 
          :                'lame' 
          ;






my @even_bigger_then_10 = grep{ $_ > 10 && !$_ % 2 } 1..100;





