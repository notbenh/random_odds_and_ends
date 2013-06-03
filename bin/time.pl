#!/usr/bin/env perl 
use strict;
use warnings;
use File::Slurp;
use Date::Parse;
use List::Util qw{max sum};
use List::MoreUtils qw{natatime};
use Data::Dumper; sub D(@){warn Dumper(@_)}
our $VERSION=1.5;

sub note (@) {
  sprintf q{[%s] %s}, join( q{ }, split /\s+/, qx{date} ), join q{ }, @_;
}

sub parse ($) { 
  my ($time,$stuff) = shift =~ m{\[(.*?)\] (.*)};
  my ($proj,$note)  = split /\s+/, $stuff,2;
  return ($time,$proj,$note);
};

my $month_i= 1;
my %months = map{$_=>$month_i++} qw{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec};
sub d8 ($){
  # translate Fri May 31 17:25:52 PDT 2013 => 20130531
  $_ = shift;
  my ($y,$m,$d) = (split)[5,1,2];
  return sprintf q{%04d%02d%02d}, $y, $months{$m}, $d;
}
sub stime ($) { 
   my $in = shift;
   my $h = int($in);
   my $m = int(60 * ($in-$h));
   return sprintf q{%d:%02d}, $h, $m;
};

my $file = $ENV{TIMETRAX_FILE} || sprintf( q{%s/.timetrax}, $ENV{HOME} );

if (scalar(@ARGV)) {
   write_file( $file, {append => 1}, note(@ARGV,"\n"));
   print qq{Noted\n};
}
elsif ( -e $file) {
  my $data = {};
  # parse the existing log file in to a big hash
  for my $record ( grep{m/^./} read_file($file), note off => "now\n" ){
    my ($time,$project,$note) = parse $record;
    my $d8 = d8 $time;
    $data->{$d8}->{display}= join ' ', (split ' ', $time)[0,1,2] unless $data->{$d8}->{display};
    my @projects = ($project);
    push @projects,$project while $project=~ s/(.*):.*/$1/;
    push @{$data->{d8 $time}->{log}}
       , { time => $time
         , utime => str2time($time)
         , projects => \@projects
         , note => $note
         , record => $record
         };
  }

  # add in start/end day markers so the math works out
  # then parse over the day
  for my $d8 ( sort keys %$data) {
    my $log = $data->{$d8}->{log};
    next unless $log && @$log;
    my $fmt = $log->[0]->{time};
    $fmt =~ s/\d\d:\d\d:\d\d/%s/;
    my $start = sprintf $fmt, '00:00:00';
    my $end   = sprintf $fmt, '23:59:59';
    unshift @$log, {projects => ['off'], time => $start, utime => str2time($start), note => 'start of day', record => qq{[$start] off start of day\n}};
    push    @$log, {projects => ['off'], time => $end  , utime => str2time($end),   note => 'end of day'  , record => qq{[$end] off end of day\n}};

    my $report = {};
    my $total = 0;
    print "\nEVENT LOG:\n";
    for ( 0..($#$log -1) ) { #this is look ahead, but we add a marker for now, we don't need to bother with that so we -2 to skip that
      my ($THIS,$NEXT) = ($log->[$_], $log->[$_+1]);
       print $THIS->{record};
       my $spend = ($NEXT->{utime} - $THIS->{utime})/60/60;
       $total += $spend;
       $report->{$_} += $spend for @{$log->[$_]->{projects}}
    } 
    print $log->[-1]->{record}; # for completeness

    print "\nSUMMARY REPORT:\n";
    my $length = max( map{length($_)} keys %$report );
    printf qq{%*s : %5s (%5.2f%%)\n}, -$length, $_, stime $report->{$_}, ($report->{$_}/$total)*100 
      for reverse sort {$report->{$a} <=> $report->{$b}} keys %$report ;

    # now that each day is accounted for this is always 23:59
    #printf qq{%*s : %s\n}, $length, 'TOTAL', stime $total ;
    print "\n"; # end of day spacing
  }

}
else {
  # TODO: this should create the file rather than do nothing
   printf qq{%s does not exist\n}, $file;
}


