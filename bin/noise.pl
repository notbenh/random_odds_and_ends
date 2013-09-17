#!/usr/bin/env perl 
use strict;
use warnings;

use Audio::NoiseGen ':all';
 
# Connect to your sound engine/hardware
Audio::NoiseGen::init();

play( gen => combine( gens => [ white_noise() ,
                                #triangle( freq => 160 ),
                                #square( freq => 60 ),
                                #sine( freq => 260 ),
                              ]
                    )
    );
