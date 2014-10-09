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
import core.thread : Thread;
import core.time : dur;
import std.stdio : writeln, readln;
import std.string : strip;

import cli.parsing;
import plotd.drawing;
import plotd.plot;
import plotd.primitives;

/**
	Read from standard input and plot

	Mainly used to pipe data into

	myprogram > plotcli
	*/
void main() {
	auto marginBounds = Bounds( 70, 400, 70, 400 );
	auto plot = createPlotState( Bounds( 0, 1, 0, 1 ),
			marginBounds );

	scope(exit) plot.save( "plotcli.png" );
	auto msg = readln();

	while( true  ) {
		writeln( "Received: ", msg );

		auto coords = toRange( msg.strip );

		if (coords.length == 2) {
			Point( coords[0], coords[1] ).draw( plot );
		}

		plot.save( "plotcli.png" );
		msg = readln();
		if ( msg.length == 0 ) // Got to end of file
			Thread.sleep( dur!("msecs")( 100 ) );

	}
}
