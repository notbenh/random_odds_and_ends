#!/usr/bin/perl 
use strict;
use warnings;
use Util::Template;
use Util::Log;
use PPI;

my $t = Util::Template->new;

sub pkg2path { my $m = $_[0]; $m =~ s/::/\//g; $m .'.pm'};

foreach my $module ( @ARGV ) {
   eval qq{require $module};
   my $m = $module->new;
   die 'CAN NOT ACCESS META' unless $m->can('meta');

   my $attrs   = { map{ $_->name => 1 } $m->meta->get_all_attributes };
   my $builtin = { map{ $_ => 1 } qw{ dump
                                      DEMOLISHALL
                                      does
                                      new
                                      BUILDALL
                                      DESTROY
                                      BUILDARGS
                                      DOES
                                      meta
                                    } 
                 };
 
   my $doc = PPI::Document->new($INC{pkg2path($module)}); 
   my $pod_docs = { map{ s/^\s+//;s/\s+$//;  $_}                          # clean up any leanding/trailing whitespace
                    map { my @L = split /\n/; shift @L => join "\n", @L } # pluck the first line as the key
                    grep{ length }                                        # exclude any blank lines
                    map { split /^=head\d\s/xms, $_ }                     # split on =head? to allow for running head blocks
                    map { s/\s+=cut//xms; $_}                             # drop =cut, it's just getting in the way
                    map { $_->content }                                   # only deal with the content of the POD
                       @{$doc->find('PPI::Token::Pod')}
                  };

   $t->process( \*DATA, { package => $module,
                          attrs   => [ map {my $a = $_; 
                                            my $default;
                                            eval { $default = &{ $a->default} } or do { $default = 'Some CodeRef' };
                                            {type    => $a->type_constraint->name,
                                             default => ( defined $default && ref($a->default) ) 
                                                        ? [map{s/\$VAR\d+ = //;s/;//g;s/ +/ /g;$_} D $default ]->[0] 
                                                        : $a->default 
                                                       || 'none',
                                             map{ $_ => $a->$_} qw{name documentation} 
                                            }; 
                                           }
                                       grep{ my $d = $_->documentation;
                                             ! defined $d || $d ne 'PRIVATE';
                                           } $m->meta->get_all_attributes
                                     ],
                          subs    => [ map  { { name => $_,
                                                documentation => delete $pod_docs->{$_},
                                            } }
                                       grep {! $attrs->{$_} && ! $builtin->{$_}
                                            } $m->meta->get_all_method_names 
                                     ],
                          pods    => $pod_docs,
                        },
              ) || die $t->error(), "\n";

   print qq{\n\n};
   
};

__END__
====== [% package %] ======

[% UNLESS pods.DESCRIPTION %]
This code does...

[% END %]

[% UNLESS pods.SYNOPSIS %]
===== SYNOPSIS =====

<code>
use [% package %];
my $obj = [% package %]->new;
</code>
[% END %]

[% IF pods.size > 0 %]

[% FOREACH pod IN pods.keys %]

===== [% pod %] =====

[% IF pod == 'SYNOPSIS' %]<code>[% END %]

[% pods.$pod %]

[% IF pod == 'SYNOPSIS' %]</code>[% END %]

[% END %]

[% END %]


===== Attributes =====
[% FOREACH attr IN attrs +%]

==== [% attr.name %] ([% attr.type %]) ====

[% attr.documentation %]


[% IF attr.default.split('\n').size > 1 %]

<code>

DEFAULT:

[% attr.default %]

</code>

[% ELSE %]

DEFAULT: [%- attr.default %]

[% END %]
[% END %]

===== Methods =====
[% FOREACH sub IN subs +%]
==== [% sub.name %] ====

[% sub.documentation %]

<code>
$obj->[%sub.name%]( ... );
</code>
 
[% END %]



