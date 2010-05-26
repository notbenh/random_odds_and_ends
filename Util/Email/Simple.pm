package Util::Email::Simple;
use Util::Log;
use Mail::Builder::Simple;
use Sys::SigAction qw{timeout_call};
use Exporter qw{import};
require Data::Manip; # DO NOT 'use' IT WILL TRIGGER IMPORT!!!

our @EXPORT = qw{
   email
   email_error
};

=head1 NAME 

Util::Email::Simple - thin declarative wrapper around Mail::Builder::Simple

=head1 SYNOPSIS 

  use Util::Email::Simple;
  email from => 'ben@powells.com',
        to   => ['jeffs@powells.com','amyg@powells.com;'],
        subject => 'hello from ben',
        body => '...',
  ; 
        
=head1 EXPORT

=head2 email

Your basic email sender, this sends directly via Mail::Builder::Simple's send method.

=cut

sub email (@) {
   my $opts = Data::Manip::rename_keys({@_}, body => 'plaintext',
                                             subj => 'subject',
                                      );
   #DUMP $opts;
   Mail::Builder::Simple->new()->send( %$opts );
}

=head2 email_error

A bit of extra magic around email that is expected to assit in emailing errors from code.
It sets the default 'to' to the programing list, you can over ride by giving it 'to'.
It sets the default 'from' to be the first package in the stack, again override by providing 'from'.
It also accepts a 'data' block that will be an arrayref of vars that you want to have
the DUMP of appended to the body of the email.
It will append the call stack to the email body as the last item.

  email_error data => [$some_var,$some_other_var] ;

=cut

sub email_error (@) {
   my %opts = @_;

   my $stack   = callstack();
   my $last    = [reverse @$stack]->[0];
   my $call    = ( $last->{package} ne 'main' ) 
               ? $last->{package} 
               : $last->{filename};
   $call = 'unknown_location' unless defined $call;

   $opts{to}   = 'programmers.industrial@lists.powells.com'
      unless defined $opts{to};
   $opts{subject} = qq{Error tripped in $call}, 
   $call =~ s/(::|\/)/_/g; # make the 'caller' email safe for use in subject and from
   $opts{from} = sprintf( q{%s@powells.com}, $call)
      unless defined $opts{from};
   $opts{data} = ( defined $opts{data} )
               ? ( ref($opts{data}) ne 'ARRAY' )
                 ? [$opts{data}]
                 : $opts{data}
               : [] ;
   $opts{body}.= join qq{\n\n}, map{ D $_ } @{ $opts{data} }, $stack;

   Data::Manip::whitelist_keys( \%opts, qw{to from subject body plaintext reply htmltext attachment image priority mailer} );
   
   email %opts;
}

1;
