package Util::Timeout;
use Util::Log;
use Exporter::Declare;                                                                                                                                               
use Sys::SigAction qw{timeout_call};

=head1 NAME 

Util::Timeout - thin wrapper around Sys::SigAction::timeout_call

=head1 SYNOPSIS 

  use Util::Timeout;
  timeout $seconds { ... } or do { ... };

=head1 DESCRIPTION 

Sys::SigAction::timeout_call sets a timer for $seconds, if your code block is still running when the 
timer trips then it is killed off. timeout then returns a false value thus you can chain with 'or'
to allow for a clean syntaticaly correct syntax

=cut

export timeout sublike { 
   my ($seconds, $code) = @_;
   # invert return to allow the use of 'or'
   !timeout_call( $seconds, $code );
}


1;
