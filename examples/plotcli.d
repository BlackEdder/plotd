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
import std.math : isNaN;
import std.regex : match;
import std.stdio : writeln, readln;
import std.string : strip;

import cli.parsing;
import plotd.binning;
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

	Event[] eventCache;

	bool validBound = false;
	Point[] pointCache;
	string[] rowMode;
	double[] histData;
	double[2] histRange;

	while( true  ) {
		writeln( "Received: ", msg );

		auto m = msg.match( r"^#plotcli (.*)" );
		if (m)
			writeln( "Found command ", m.captures[1] );

		auto floats = msg.strip
			.toRange;

		rowMode = updateRowMode( floats, rowMode );
		auto parsedRow = applyRowMode( floats, rowMode );

		bool needAdjusting = false;
		if ( !validBound ) {
			needAdjusting = true;
			pointCache ~= parsedRow.points;
			validBound = validBounds( pointCache );
			plot.plotBounds = minimalBounds( pointCache );
			if (validBound)
				pointCache = [];
		} else {
			foreach( point; parsedRow.points ) {
				if (!plot.plotBounds.withinBounds( point )) {
					plot.plotBounds = adjustedBounds( plot.plotBounds, point );
					needAdjusting = true;
				}
			}
		}

		if (needAdjusting) {
			plot = createPlotState( plot.plotBounds, plot.marginBounds );
			foreach( event; eventCache )
				event( plot );
		}

		auto events = parsedRow.points.toEvents;

		foreach( event; events )
			event( plot );

		eventCache ~= events;

		// Histograms
		foreach( data; parsedRow.histData ) {
			if ( data < histRange[0] || isNaN(histRange[0]) ) {
				histRange[0] = data;
			} 
			if ( data > histRange[1] || isNaN(histRange[1]) ) {
				histRange[1] = data;
			}
			writeln( histRange );
			histData ~= data;
		}

		if (histData.length > 0) {
			// Create bin
			Bins!size_t bins;
			bins.min = histRange[0];
			bins.width = 0.5;
			bins.mybins = [0,0,0,0,0,0,0,0,0,0]; // Really need to fix this in binning.d
			if( histRange[0] != histRange[1] )
				bins.width = (histRange[1]-histRange[0])/10.0;
			// add all data to bin
			foreach( data; histData )
				bins = bins.addDataToBin( [bins.binId( data )] );
			// Adjust plotBounds 
			writeln( bins.min, " ", bins.max );
			plot = createPlotState( Bounds( bins.min, bins.max, 0, histData.length ),
					marginBounds );
			// Plot Bins
			plot.plotContext = drawBins( plot.plotContext, bins );
		}

		plot.save( "plotcli.png" );

		msg = readln();
		while ( msg.length == 0 ) // Got to end of file
		{
			Thread.sleep( dur!("msecs")( 100 ) );
			msg = readln();
		}
	}
}
