package Data::Manip::Range;
use strict;
use warnings;
use Exporter qw{import};
use Util::Log;
use Carp::Assert::More;

our @EXPORT = qw{
   ranges
   };

=pod
   build out range sets as arrayref of arrayrefs.

      my $arrayref = ranges(start,end,step);

   example:
      ranges(1,10,2) => [[1,2],[3,4],[5,6],[7,8],[9,10]]

   useful for batching sql queries:
   
      my $max = $d->selectcol_arrayref(q{SELECT MAX(id) FROM table})->[0];
      
      for (@{ranges(1,$max,5000)}) {
         # RAW DBI:
         do_something( $d->selectall_arrayref(q{SELECT * from table where id >= ? AND id < ?},{Slice=>{}},@$_) );

         # FINDERS:
         do_something( $obj->find(id => {'>=' => $from, '<' => $to}) );
      }
=cut

sub ranges {
   my ( $from, $to, $step ) = @_;
   my $out = [];
   for ( my $i = ( $from - 1 ); $to >= ( $i + 1 ); $i += $step ) {
      push @$out, [ ( $i + 1 ), ( $i + $step ) ];
   }
   return $out;
}

1;

