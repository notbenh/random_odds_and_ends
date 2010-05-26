package Util::Log;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw{
   D
   DUMP
   DUMP2LOG
   callstack
};


=head1 WHAT!

this is a mimic of the lib at work, long story short, I'm to lazy to 
use Data Dumper the way that it's expected.... so I made this.

=cut

#---------------------------------------------------------------------------
#  DEBUG DUMPER
#---------------------------------------------------------------------------
use Data::Dumper;
use File::Slurp;

sub D (@) { Dumper(@_) };
sub DUMP (@) {
   my (@in) = @_;    # we have to localize what was passed in
   my ( $c_package, $c_file, $c_line ) = caller;
   warn sprintf( qq{[DUMP] from %s line %d\n}, $c_file, $c_line ), sub { Dumper(@in) };
}
sub DUMP2LOG ($@) {
   my $log_file = shift;
   append_file( $log_file, Dumper(@_));
}



#---------------------------------------------------------------------------
#  Callstack simple
#---------------------------------------------------------------------------
sub callstack {
   # !!! DO NO 'use' AS THIS WILL IMPORT *EVERYTHING* and because this is going to be used in Util::Log, we want to be selective
   require Data::Manip;
   # NO REALLY DO NOT EVER CHANGE THIS TO 'use'

   my $keys = [qw{package filename line subroutine hasargs wantarray evaltext is_require hints bitmask hinthash}];

   #build the caller stack
   my $caller_depth = 0;
   my $caller_stack = [];
   while( caller($caller_depth) ) {
      push @$caller_stack, Data::Manip::key_arrayref(keys => $keys, values => [caller($caller_depth)] );
      $caller_depth++;
   }
   return $caller_stack;
}



