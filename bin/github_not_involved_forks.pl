#!/usr/bin/perl 
use strict;
use warnings;
use JSON;
use LWP::Simple;
use Util::Log;


#---------------------------------------------------------------------------
#  DSL
#---------------------------------------------------------------------------
sub jget ($)   { from_json( get(shift) ) };
#sub API  (@)   {my $url = join '/', q{http://github.com/api/v2/json}, @_; DUMP {URL => $url}; $url;};
sub API  (@)   {join '/', q{http://github.com/api/v2/json}, @_};
sub REPO ($;$$){API qw{repos show}, @_};

my $repos = jget REPO notbenh => ;
my @forks = grep{$_->{fork}} @{ $repos->{repositories} };

DUMP [ map {  $_->{name} }
       grep{my $contrib = jget REPO notbenh => $_->{name} => contributors => ;
            ! scalar( grep{ m/notbenh/ } @{ $contrib->{contributors} } ) # only keep the ones that I'm not contribing to
           } @forks
     ];








