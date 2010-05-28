package Data::Manip;
use strict;
use warnings;
use Exporter qw{import};
use Util::Log;
use Carp::Assert::More;

our @EXPORT_OK = qw{
   is_valid
   flat
   flat_count
   flat_count_valid
   flat_count_grep
   arrayref_unique
   invert_hash
   hash_from_list
   array_to_hash
   key_arrayref
   delete_keys
   whitelist_keys
   rename_keys
   unpacked
   unpacked_ref
   prepend_keys
   unnest_hash
   };
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


#---------------------------------------------------------------------------
#  SCALAR STUFF
#---------------------------------------------------------------------------
sub is_valid {
   my ($val) = @_;
   return ( defined $val
            && length $val > 0
            && $val =~ m/\w/
          ) ? 1 : 0 ;
}

#---------------------------------------------------------------------------
#  CONVERT TO LIST FUNCTIONS
#---------------------------------------------------------------------------
#===  FUNCTION  ================================================================
#         NAME:  flat   
#      PURPOSE:  flaten data objects
#   PARAMETERS:  anything really
#      RETURNS:  a list of all the values
#       THROWS:  no exceptions
#     COMMENTS:  none
#     SEE ALSO:  the tests
#===============================================================================
sub flat {
   map { 
      ( (ref $_) =~ m/Quantum::Superpositions.*/ ) ? flat( $_->eigenstates ) #unpack Q:S objects
    : ( ref $_ eq 'ARRAY')                    ? flat(@$_) #unpack arrayrefs
    : ( ref $_ eq 'HASH')                     ? flat(%$_) #unpack hashrefs
    :                                           $_ ;      #other wise just leave it alone
   } @_;
} ## end sub flat

#===  FUNCTION  ================================================================
#         NAME:  flat_count
#      PURPOSE:  get a count of all the entries
#   PARAMETERS:  anything that flat will take
#      RETURNS:  an int of the number of items
#       THROWS:  no exceptions
#     COMMENTS:  none
#     SEE ALSO:  tests
#===============================================================================
sub flat_count {
   return scalar @{ [ flat( @_ ) ] };
}

#===  FUNCTION  ================================================================
#         NAME:  flat_count_grep
#      PURPOSE:  use a given sub to filter the items that you want to count
#   PARAMETERS:  subref as the first thing, rest any thing you would pass to find
#      RETURNS:  an int
#===============================================================================
sub flat_count_grep {
   my $sub = shift;
   return flat_count( grep{ &$sub } flat( @_ ) );
}

#===  FUNCTION  ================================================================
#         NAME:  flat_count_valid
#      PURPOSE:  count the valid items (based on is_valid) 
#   PARAMETERS:  anything that you would pass to find
#===============================================================================
sub flat_count_valid {
   return flat_count_grep( sub{is_valid($_)}, @_ );
}


#---------------------------------------------------------------------------
#  ARRAY FUNCTIONS
#---------------------------------------------------------------------------
#===  FUNCTION  ================================================================
#         NAME:  arrayref_unique
#      PURPOSE:  hand back all unique items in a list while mainaining order
#                 based on first seen 
#                 EX: (1,1,2,1,1,3,2,1) => (1,2,3)
#   PARAMETERS:  a single layer arrayref
#      RETURNS:  an ordered single layer arrayref
#                the order is based on first seen in the input.
#       THROWS:  requires that you pass in a single layer arrayref
#     COMMENTS:  none
#     SEE ALSO:  tests
#===============================================================================
# really we should use Array::Unique
sub arrayref_unique {
   my ($array) = @_;
   assert_listref($array);
   $array = [grep{defined} @$array]; #lets trim out undefs, they make the noise in the logs
   return [] unless scalar(@$array) > 0; #if we were passed a bunch of undefs, or nothing worth working on then lets not work on it
   assert_is( join('',@$array),
              join('',flat($array)),
              q{I'm sorry but arrayref unique needs a single layer to work},
   );

   #create a hash with a id for the first seen value (unique)
   my $i;      #counter for keeping the order seen
   my $h = {}; #tmp storage
   for (@$array) {
      next unless defined $_; #this should never happen but its not going to hurt to check twice
      $h->{$_} = $i++      #add an entry to our local hash
         unless $h->{$_};  #if we have not already seen it
   }

   # now sort based on value and return as an arrayref
   return [ sort { $h->{$a} <=> $h->{$b} } keys %$h ];
}


#---------------------------------------------------------------------------
#  HASH FUNCTIONS
#---------------------------------------------------------------------------
#===  FUNCTION  ================================================================
#         NAME:  invert_hash
#      PURPOSE:  invert a hash of arrays in to another hash of arrays
#                EXAMPLE: { k1 => [ v1, V2 ], k2 => v3 }  
#                         Becomes { v1 => [ k1 ], V2 => [ k1 ], v3 => [ k2 ] }
#   PARAMETERS:  $hash : Hashref to flip
#                $opts : hashref of options
#                          - mod_keys : lower => lc(new_keys) ... {v2 => [key]}
#                                     : upper => uc(new_keys) ... {V1 => [key]}
#                          - flat     : if true your new values will not be arrayrefs
#                                       {k=>v} -> {v=>k} vs {v=>[k]}
#      RETURNS:  hashref
#       THROWS:  Asserts that $hash is a hasref
#     COMMENTS:  n/a
#     SEE ALSO:  n/a
#===============================================================================
sub invert_hash {
   my ( $hash, $opts ) = @_;
   assert_hashref($hash);

   #stash for our output
   my $out = {};

   my $ul = sub{ my $f = shift; $f =~ s/\s/_/g; return $f };

   #handler for the mod_keys opt
   my $mk = ( ! defined $opts->{mod_keys} )    ? sub { $ul->(shift) }     #no mod
          : ( $opts->{mod_keys} =~ m/lower/i ) ? sub { $ul->(lc(shift)) } #lower mod
          : ( $opts->{mod_keys} =~ m/upper/i ) ? sub { $ul->(uc(shift)) } #upper mod
          :                                      sub { $ul->(shift) }     #no mod
          ;

   #handler for the flat opt
   my $po = ( $opts->{flat} ) 
          ? sub { my ($k,$v) = @_; $out->{$k} = $v; }
          : sub { my ($k,$v) = @_; push @{$out->{$k}}, $v; }
          ;

   #build up our output
   while ( my ($old_key, $old_value) = each %$hash ) {
      if ( ref($old_value) eq q{} ) { # scalar
         $po->($mk->($old_value), $old_key);
      }
      elsif ( ref($old_value) eq 'ARRAY' ) { 
         foreach my $item (@$old_value) {
            $po->($mk->($item), $old_key);
         }
      }
      else {
         die sprintf q{ [%s->%s] is not a valid type to allow inversion }, $old_key, $old_value;
      }
   }
   return $out;
}


#===  FUNCTION  ================================================================
#         NAME:  hash_from_list
#      PURPOSE:  create a hash of keys from a list
#   PARAMETERS:  $list: any single element (hashref, arrayref, scalar), it's run thru flat.
#                       !NOTE! a hashref will include keys!!
#                $value: what you want the value of your hash to be, default is 1.
#      EXAMPLE:  hash_from_list([qw{a b c}],'hello') :: {a=>'hello',b=>'hello',c=>'hello'}
#      RETURNS:  a hashref
#     COMMENTS:  none
#     SEE ALSO:  n/a
#===============================================================================
sub hash_from_list {
   my ($K,$V) = @_;
   my @list = flat($K);
   my $val  = (defined($V)) ? $V : 1;
   return { map {$_ => $val} @list };
}


#===  FUNCTION  ================================================================
#         NAME:  array_to_hash
#      PURPOSE:  build a hash of values, with the keys as the id of the array
#   PARAMETERS:  $a is required to be an arrayref
#      RETURNS:  a hashref
#  DESCRIPTION:  This is kinda the inverse of hash_from_list, it takes keys
#                 and then builds values. This takes an array of values and 
#                 will build keys.
#       THROWS:  will barf if you do not pass it an arrayref
#     COMMENTS:  none
#     SEE ALSO:  n/a
#===============================================================================
sub array_to_hash {
   my ($a) = @_;
   assert_listref($a);
   my $i;
   return {map{$i++ => $_} @$a};
   
}

#===  FUNCTION  ================================================================
#         NAME:  key_arrayref
#      PURPOSE:  link up keys to values
#      EXAMPLE:  key_arrayref(keys => [qw{one two three}], values => [1,2,3]) 
#                results in {one=>1,two=>2,three=>3}
#   PARAMETERS:  hash: two keys 'keys' and 'values' both are expected to be arrayref
#      RETURNS:  hashref
#       THROWS:  will fail if the length of keys != values or if there are duplicate 'keys'
#===============================================================================
sub key_arrayref {
   my %opts = (scalar(@_) == 1 && ref($_[0]) eq 'HASH') ? %{$_[0]} : @_; #deref hashrefs
   die 'key_arrayref expects "keys" to be specified as an arrayref' 
      unless defined $opts{keys} && ref($opts{keys}) eq 'ARRAY';
   die 'key_arrayref expects "values" to be specified as an arrayref' 
      unless defined $opts{values} && ref($opts{values}) eq 'ARRAY';
   die 'key_arrayref expects all "keys" to be unique' 
      unless scalar(@{ $opts{keys} }) == scalar(@{arrayref_unique($opts{keys})});
   
   my %out = map{ $opts{keys}->[$_] => $opts{values}->[$_]
                } 0..(scalar(@{ $opts{keys} })-1);
   return \%out;
}

#---------------------------------------------------------------------------
#  DESTRUCTIVE HASH MANIPULATION
#---------------------------------------------------------------------------
###   Delete all keys listed
###   $opts = {d => 'X', kitten => 'cute', title => 'Y'}
###   $opts = delete_keys($opts, qw{d title size});
###   # $opts is {kitten => 'cute'}
sub delete_keys {
   my ($hash, @keys) = @_;
   assert_hashref($hash);
   for (@keys) {
      delete $hash->{$_} if $hash->{$_};
   }
   return $hash;
}

###   Delete all keys not in give list
###   $opts = {d => 'X', kitten => 'cute', title => 'Y'}
###   $opts = whitelist_keys($opts, qw{d title size});
###   # $opts is {d => 'X', title => 'Y'}
sub whitelist_keys {
   my ($hash, @keys) = @_;
   assert_hashref($hash);
   my $whitelist = hash_from_list(\@keys);

   foreach my $key (keys %$hash ) {
      delete $hash->{$key} 
         unless $whitelist->{$key};
   } 
   return $hash;
}

###   Rename any instance of a key of 'isbn' in $opts to 'isbns'
###   $opts = {isbn => 'X', exp => 'Y'}
###   $opts = rename_keys($opts, isbn => 'isbns', exp => 'expire');
###   # $opts is {isbns => 'X', expire => 'Y'}
sub rename_keys {
   my ($hash, %rename) = @_;
   assert_hashref($hash);
   while ( my ($old, $new) = each %rename ) {
      $hash->{$new} = delete $hash->{$old}
         if defined $hash->{$old};
   }
   return $hash;
}


#---------------------------------------------------------------------------
#  NON-DESTRUCTIVE HASH MANIPULATION
#---------------------------------------------------------------------------
# [TODO] there should be an exclude and include keys that just make a copy
#        of the given hash and return that so that you do not modify the 
#        inital hash.
   

#---------------------------------------------------------------------------
#  Reduce complex data structures
#---------------------------------------------------------------------------
#===  FUNCTION  ================================================================
#         NAME:  unpacked
#      PURPOSE:  given a formated string, unpack all data pased sequentually
#   PARAMETERS:  $def = string with all keys to unpack, split on ':'
#      RETURNS:  an array of all the unpacked values,
#                if nothing is found based on the def, undef is returned
#     COMMENTS:  none
#     SEE ALSO:  n/a
#===============================================================================
sub unpacked {
   my $def = shift;
   $def = [ split /:/, $def ] unless ref($def) eq 'ARRAY';
   my @out = map { (!scalar(@$def))        ? $_ #DUMP { DONE => $_ }
                 : ( ref($_) eq q{HASH} )  ? unpacked( $def, $_->{shift @$def} )
                   # make a copy of def so that all sub-instances get a unique copy
                 : ( ref($_) eq q{ARRAY} ) ? map{ unpacked( [@$def], $_ ) } @$_ 
                 :                           $_ ;
   } @_ ;
   return @out;
}

#===  FUNCTION  ================================================================
#         NAME:  unpacked_ref
#      PURPOSE:  wrap up unpacked to return a single ref value
#   PARAMETERS:  the same stuff that you would pass to unpacked
#      RETURNS:  an hashref or arrayref based on what unpacked returns
#       THROWS:  no exceptions
#     COMMENTS:  none
#     SEE ALSO:  n/a
#===============================================================================
sub unpacked_ref {
   my @out = grep{defined} unpacked(@_);
   return ( scalar(@out) <= 1 && ref($out[0]) ) 
        ? $out[0]
        : \@out ;
}

#===  FUNCTION  ================================================================
#         NAME:  prepend_keys
#      PURPOSE:  prepend a string to each key of a hash
#   PARAMETERS:  ????
#      RETURNS:  ????
#  DESCRIPTION:  ????
#       THROWS:  no exceptions
#     COMMENTS:  none
#     SEE ALSO:  n/a
#===============================================================================
sub prepend_keys {
   my ($in, $str, $glue) = @_;
   die DUMP {'prepend_keys takes hashrefs only'=>\@_} unless ref($in) eq 'HASH';
   rename_keys($in, map { $_ => join($glue || ' ', $str,$_) } keys %$in);
}

sub unnest_hash {
   my ($in, $glue) = @_;
   die DUMP {'unnest_hash takes hashrefs only'=>\@_} unless ref($in) eq 'HASH';
   my %out = map{ ( ref($in->{$_}) eq 'HASH' ) 
                  ? %{prepend_keys( unnest_hash($in->{$_},$glue),$_, $glue) }
                  : ($_ => $in->{$_} );
                } keys %$in ;
   return \%out;
}

1;

