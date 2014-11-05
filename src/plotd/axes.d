/*
	 -------------------------------------------------------------------

	 Copyright (C) 2014, Edwin van Leeuwen

	 This file is part of plotd plotting library.

	 Plotd is free software; you can redistribute it and/or modify
	 it under the terms of the GNU General Public License as published by
	 the Free Software Foundation; either version 3 of the License, or
	 (at your option) any later version.

	 Plotd is distributed in the hope that it will be useful,
	 but WITHOUT ANY WARRANTY; without even the implied warranty of
	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 GNU General Public License for more details.

	 You should have received a copy of the GNU General Public License
	 along with Plotd. If not, see <http://www.gnu.org/licenses/>.

	 -------------------------------------------------------------------
	 */

module plotd.axes;

import std.math : floor, pow, abs, ceil, log10;

class Axis {
    this( double newmin, double newmax ) {
        min = newmin;
        max = newmax;
        min_tick = min;
    }
    string label;
    double min = -1;
    double max = 1;
    double min_tick = -1;
    double tick_width = 0.2;
}

/**
    Calculate optimal tick width given an axis and an approximate number of ticks
    */
Axis adjustTickWidth( Axis axis, size_t approx_no_ticks ) {
    auto axis_width = axis.max-axis.min;
    auto scale = cast(int) floor(log10( axis_width ));
    auto acceptables = [ 0.1, 0.2, 0.5, 1.0, 2.0, 5.0 ]; // Only accept ticks of these sizes
    auto approx_width = pow(10.0, -scale)*(axis_width)/approx_no_ticks;
    // Find closest acceptable value
    double best = acceptables[0];
    double diff = abs( approx_width - best );
    foreach ( accept; acceptables[1..$] ) { 
        if (abs( approx_width - accept ) < diff) {
            best = accept;
            diff = abs( approx_width - accept );
        }
    }

    axis.tick_width = best*pow(10.0, scale);

    // Find good min_tick
    axis.min_tick = ceil(axis.min*pow(10.0, -scale))*pow(10.0, scale);

		//debug writeln( "Here 120 ", axis.min_tick, " ", axis.min, " ", 
		//		axis.max,	" ", axis.tick_width, " ", scale );
    while (axis.min_tick - axis.tick_width > axis.min)
        axis.min_tick -= axis.tick_width;
    return axis;
}

unittest {
    adjustTickWidth( new Axis( 0, .4 ), 5 );
    adjustTickWidth( new Axis( 0, 4 ), 8 );
    assert( adjustTickWidth( new Axis( 0, 4 ), 5 ).tick_width == 1.0 );
    assert( adjustTickWidth( new Axis( 0, 4 ), 8 ).tick_width == 0.5 );
    assert( adjustTickWidth( new Axis( 0, 0.4 ), 5 ).tick_width == 0.1 );
    assert( adjustTickWidth( new Axis( 0, 40 ), 8 ).tick_width == 5 );
    assert( adjustTickWidth( new Axis( -0.1, 4 ), 8 ).tick_width == 0.5 );
    
   
    assert( adjustTickWidth( new Axis( -0.1, 4 ), 8 ).min_tick == 0.0 );
    assert( adjustTickWidth( new Axis( 0.1, 4 ), 8 ).min_tick == 0.5 );
    assert( adjustTickWidth( new Axis( 1, 40 ), 8 ).min_tick == 5 );

    assert( adjustTickWidth( new Axis( 3, 4 ), 5 ).min_tick == 3 );
    assert( adjustTickWidth( new Axis( 3, 4 ), 5 ).tick_width == 0.2 );

		assert( adjustTickWidth( 
					new Axis( 1.79877e+07, 1.86788e+07 ), 5).min_tick == 1.8e+07 );
		assert( adjustTickWidth( 
					new Axis( 1.79877e+07, 1.86788e+07 ), 5).tick_width == 100000 );
}

/// Calculate tick length
double tickLength( const Axis axis ) {
    return (axis.max-axis.min)/25.0;
}

unittest {
    auto axis = new Axis( -1, 1 );
    assert( tickLength( axis ) == 0.08);
}
