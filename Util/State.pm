package Util::State;
use strict;
use warnings;

=head1 INTENT

The goal of Util::State is to provide easy and standard access to a global hash of data, much like a cookie for a running process.
This is to be provided in an abstract way such that Util::State can change the backend as needed and still provide the same API to the user.

=head2 WHAT PROBLEM IS THIS INTENDED TO SOLVE?

Well the goal is that programers don't want to have to modify a bunch of code just to pass along a hash. Lets look at an example:

  package One;
  use Util::State;
  state->user_id($uid);
  Two->method($data);

  package Two;
  sub method { $data->{user_name} = Three->user_name };

  package Three;
  use Util::State;
  use table::Customer;
  sub user_name { table::Customer->new(state->user_id)->user_name }

In this example we have data set in One but used in Three, and don't want to have to restructure Two to pass this data thru. 

=head1 WHAT MAGIC IS THIS?

=head2 import calls Util::State's constructor and then injects an object in to your class. 

In the example above 'state' is exported for you, but it's not just a function like you would find with a normal Exporter, it's a 
brand new instance of Util::State as an object (closure technically). This allows you to call state as often as you want and not have to rebuild an object, 
or stash off the object in some var as it will maintain it's own state. 

This also gets around the possibility of timing mis-match, because all 'use' statements are wrapped in BEGIN blocks you know that state
will exist in your namespace by the time you get around to running your code. WARNING: you will still run in to the possilbility of this 
problem if you have code that is also wrapped in a BEGIN block, be aware that BEGIN's are read sequentualy.

=cut

sub import {

   my $class = shift;    # import gets passed the class via $class->import

   require Data::Manip;
   my $self = Util::State->new( Data::Manip::flat(@_) ); # though currently unused, allow for the possiblity of data being passed to new

   my ($package) = caller;    # dont care about file and line
   my $function = join q{::}, $package, 'state';

   do {
      no strict 'refs';
      *{$function} = sub{$self};
   };
}

sub new { bless {}, shift };

=head2 Where is 'user_id' defined? 

AUTOLOAD is leveraged to give you getter/setter methods for free on the fly as you need them. Any time you try and access a method that 
does not exist, Util::State will build out the a method that points to the store (hash) with the key of the same name. 

In the example above we just called for a method 'user_id' and handed it a value $uid. Util::State will first do the lookup for a user_id method, if found it will use it, but as this is a fresh object, there is not one. AUTOLOAD then trips, creates a user_id method that is a getter/setter for the stored hash and then $uid to that method. The method created looks something like this:

  sub user_id { 
     my $self = shift;
     ( @_ ) ? $self->store->{user_id} = shift : $self->store->{user_id};
  }

=cut

our $AUTOLOAD; # need to scope AUTOLOAD
sub AUTOLOAD {
   my $self  = shift;
   my ($key) = map{s/.*:://;$_} $AUTOLOAD; #pluck just the method name

   if( $self->can($key) ) { # DON'T OVERWRITE EXISTING METHODS (not likely to get handed to AUTOLOAD in this case but it's a precaution)
      return (@_) ? $self->store->{$key} = shift
                  : $self->store->{$key};
   }

   my $sub = sub{ my $self = shift;
                  ( @_ ) ? $self->store->{$key} = shift
                         : $self->store->{$key};
                };
   my $method = sprintf q{Util::State::%s}, $key;
   do{ 
      no strict 'refs';
      *{$method} = $sub;
   };
   $self->$key( @_ );
}

=head1 METHOD

=head2 store

This is more direct access to the entire hash. Because it returns the entire hash you can access parts of the hash directly:

  my $uid = state->store->{user_id};

=cut

sub store { 
   $ENV{global_state_hash} = {} unless exists $ENV{global_state_hash};
   $ENV{global_state_hash};
}

=head2 init

Used to reset the store hash, the passed values will completely overwrite the existing hash. Also delete is called for all 
existing keys before the content of the stored hash is set.

  state->store; # {user_id => 123}
  state->init(this=>1, that=>2); 
  state->store; # {this=>1, that=>2}

=cut

sub init { 
   my $self = shift;
   my $hash = ( scalar(@_) == 1 && ref($_[0]) eq 'HASH' ) ? $_[0] : {@_};
   $self->delete( keys %{ $self->store } );
   $ENV{global_state_hash} = $hash;
}

=head2 add (aliases: mod & modify)

Merge with existing hash, will create new keys and alter existing keys to the new value.

  state->store; #{this=>1, that=>2}
  state->add(user_id => 123, that=>'too');
  state->store; #{this=>1, that=>'too', user_id=> 123}
  state->modify( this => 'two', that => 'also' );
  state->store; #{this=>'two', that=>'also', user_id=> 123}
  state->mod( this => 'also')
  state->store; #{this=>'also', that=>'also', user_id=> 123}

=cut

sub mod    { shift->add(@_) };
sub modify { shift->add(@_) };
sub add { 
   my $self = shift;
   $self->init( %{ $self->store }, @_ );
   $self->store;
}

=head2 delete (alias: rm)

Delete is used to remove a list of key's from the hash and clean up any methods that have been pointed to those keys.

  state->store; #{this=>1, that=>'also', user_id=> 123}
  state->this;  # 1
  state->delete(qw{this that}); 
  state->store; #{user_id=> 123}
  state->can('this'); # FALSE
  
=cut

sub rm     { shift->delete(@_) };
sub delete {
   my $self = shift;

   for my $key (grep{!m/^(?:new|store|init|mod|modify|add|rm|delete|AUTOLOAD|set_info)$/} @_) { # pluck out known methods that we don't want to delete
      delete $ENV{global_state_hash}->{$key};
      if ($self->can($key)) {
         # drop the method for that if we had one (DANGEROUS as you can delete store this way !!! BE CAREFUL)
         my $stash = do {no strict 'refs'; \%{'Util::State::'}}; 
         delete $stash->{$key};
      }
   }

   $self->store;
}

=head1 STANDARDIZE DATA 

As nice as it is to have a standard access layer, what really matters is that there is standard data to be 
accessed. To grease the rails a bit for this Utl::State has built-ins for quick access to a standard pool of data.

This is currently done by a hash $info_methods that defines the key and a code ref to build the data. This 
hash is used by 'set_info' to init the state of the store in a standard way. Any thing that is passed to 
'set_info' will then be passed to each of the code refs and then be saved to the store via init. 

=over

=item !!! B<WARNING:> INIT IS USED SO THIS WILL WIPE ANY EXISTING DATA STORED

=item !!! B<WARNING:> CURRENTLY THIS IS NOT USED AUTOMATICLY, IT *MUST* BE CALLED DIRECTLY, THIS COULD CHANGE.

=back

=head2 EXAMPLE IN ACTION

  our $info_methods = {
   expire     => sub{0},
   is_tuesday => sub{ [localtime]->[6] == 2 },
   user_name  => \&get_user_name,
  };

  sub get_user_name {
    use table::Customer;
    my $self = shift;
    my %opts = @_;
    return undef unless defined $opts{user_id};
    table::Customer->new( $opts->user_id )->user_name;
  }

Each of the code refs will be passed what ever is handed to set_info.

  state->set_info(user_id => 123);
  state->store; # {expire=>0, is_tuesday => 0, user_name => 'ben' }


It is possible to alter the info_methods hash from the outside if it is completely nessassary for a one-off:

  package My::Thing;
  use Util::State;
  $Util::State::info_methods->{kitten} = sub{'cute'};
  state->set_info;
  state->kitten; # 'cute'
  state->expire; # 0 

=head2 WHERE DO THESE CODE REFS NEED TO LIVE?

Currently they are all either defined inline (like expire in the example) or a Util::State method (like user_name). It's 
possible to specify an external method though understand that you will be getting $self (the Util::State 
object) passed to that external method. 

=cut

#---------------------------------------------------------------------------
#  SET INFO STUFF
#---------------------------------------------------------------------------
our $info_methods = {
   exclude_stores     => \&exclude_stores,
   ge_ok              => \&google_editions_ok,
   google_editions_ok => \&google_editions_ok,
   skip_cache_check   => \&google_editions_ok,
   overwrite_expire   => \&google_editions_ok,
   expire             => sub{0},
   is_tuesday         => sub{ [localtime]->[6] == 2 },
};

sub set_info {
   my ($self) = @_; # DON'T SHIFT unless you want to add it in below
   $self->init( map{ $_ => $info_methods->{$_}->(@_) } keys %$info_methods);
}

=head2 WHAT ABOUT REQUEST OBJECTS

In an effort to further standardize the way that state gets data from the outside world there is another method provided
that will parse request objects for you then pass that info to set_info. Currently this will take a CGI::Simple or 
Apache2::Request object. Then they are parsed out to a hash of cookies, params and the request object. This hash is then
passed to set_info as stated above and any of the $info_methods then will have the data available.

  package My::Other::Thing;
  use Util::State;
  use CGI::Simple;
  my $q = CGI::Simple->new;
  state->set_from_request($q);

This will unpack the CGI::Simple object ($q) in to a hash that would look something like :

  { request => $q,
    cookies => { cookie_name => 'cookie_value',
                 cookie_name => 'cookie_value',
               },
    params  => { param_name  => 'param_value'
               },
  };
=cut

sub set_from_request {
   my $self = shift;
   my $req  = shift;

   die sprintf 'MUST pass some kind of request object to set_from_request. Currently %s is not a supported type.', ref($req)
      unless defined $req 
          && defined ref($req)
          && $req->can('param')
          && ( $req->isa('CGI::Simple') || $req->isa('CGI') || $req->isa('Apache2::Request') )
   ;

   my $info = {};
   eval { $info = $req->isa('Apache2::Request') 
                ? $self->unpack_MP_req($req) 
                : $self->unpack_CGIS_req($req)   ## Good for CGI or CGI::Simple
        } or do {
            if( ref($@) =~ m/APR::Request::Error/ ) {
              warn 'Util::State ran in to a bad cookie'; 
            } else {
              require Util::Log;
              Util::Log::DUMP( {ERROR_SET_FROM_REQUEST => {'$@' => $@, REF=> ref($@), '$!' => $!} } );
            }
        };
   return $self->set_info( %$info ); 
}

sub unpack_MP_req {
   my ($self,$req) = @_;

   my $out = { request => $req };

   if ( $req->param ) {
      $out->{params} = { map{ my @p = $req->param($_);
                              $_ => scalar(@p) > 1 ? \@p : $p[0];
                            } $req->param
                       };
   }


   $out->{cookies} = {}; # just in case

   #require 'Apache2::Cookie'; # Jar is a subpackage of Cookie
   my $cookie_jar  = Apache2::Cookie::Jar->new( $req );
   return $out unless defined $cookie_jar && $cookie_jar->can('cookies');

   my $cookie_pool = $cookie_jar->cookies; # Cookie::Table obj
   return $out unless defined $cookie_pool && scalar( keys %$cookie_pool );

   $out->{cookies} = { map{ my $c =  $cookie_pool->{$_};
                            $_ => $c->value || undef;
                          } keys %$cookie_pool
                     };
   return $out;
}

sub unpack_CGIS_req {
## Works the same for CGI or CGI::Simple
   my ($self,$req) = @_;

   return { request => $req,
            cookies => { map{ my @c = $req->cookie($_);
                              $_ => scalar(@c) > 1 ? \@c : $c[0];
                            } $req->cookie
                       },
            params  => { map{ my @p = $req->param($_);
                              $_ => scalar(@p) > 1 ? \@p : $p[0];
                            } $req->param
                       },
          };
}

   
#---------------------------------------------------------------------------
#  INFO METHODS 
#---------------------------------------------------------------------------
sub exclude_stores {
   my ( $self, %opts ) = @_;
   ( $opts{cookies}->{'GOOGLE_USER'} ) ? [] : [95];
}

sub google_editions_ok {
   my ( $self, %opts ) = @_;
   my $return = ( $opts{cookies}->{'GOOGLE_USER'} ) ? 1 : 0;
   return $return;
}

=head1 TODO or POSSIBLE FEATURES TO BE ADDED 

=head2 set_info at import time

It would be nice to say something like:

  use Util::State set_info => {user_id => 123};

The idea here is that this value would passed (derefed) to the set_info method while still in import so you wouldn't need to call it later.
The problem with this is that it's quite likely that data that you want to have set in the store would not yet exist at BEGIN, thus this could get complicated. 

=head2 define export name at import time

It's unlikely but possible that state would cause a namespace conflict, thus being able to specify the export name could be handy.

  use Util::State export_name => 'magic';

This is currently not nessassary but it's an idea so I'm putting it down as a reminder.

=head2 not really happy with the info_methods way of defining subs

This was caused by us skipping Moose as a dependancy thus we lost the ability to inspect an object and collect method names. I liked that way much better
as you had less config to keep up with, this is less clunky then it could be, but it could also be better.

=cut


1;
