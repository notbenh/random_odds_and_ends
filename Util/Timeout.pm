package Util::Timeout;
use Util::Log;
use Exporter::Declare;                                                                                                                                               
use Sys::SigAction qw{timeout_call};

=head1 NAME 

Util::Timeout - thin wrapper around Sys::SigAction::timeout_call

=head1 SYNOPSIS 

  use Util::Timeout;
  timeout $seconds { ... } or do { ... };

  retry $times { ... } or do { ... };

=head1 DESCRIPTION 

Sys::SigAction::timeout_call sets a timer for $seconds, if your code block is still running when the 
timer trips then it is killed off. timeout then returns a false value thus you can chain with 'or'
to allow for a clean syntaticaly correct syntax

=head1 FUNCTIONS

=head2 timeout

  timeout 1 { sleep(2) } or do { $error = 'timed out' };

REMEMBER: these are lexical blocks (like eval) so any vars that you want to use else where will
need to be scoped as such.

=cut

export timeout sublike { 
   my ($seconds, $code) = @_;
   # invert return to allow the use of 'or'
   !timeout_call( $seconds, $code ); # 0 => timed out
}

=head2 retry

  my $num = 3; 
  retry 5 { timeout 1 { sleep( $num-- ) } } or do { $error = 'timed out 5 times' };

retry will run your the code block, if the block returns true then we stop running and return '1'. 
If your code block returns false then it is run again, up to $times number of times (5 in the 
exampele), in this case rerun returns '0' allowing you to use 'or' like with timeout.

=cut

export retry sublike {
   my ($times, $code) = @_;
   for (1..$times) {
      return 1 if &$code;
   }
   return 0;
}

1;
