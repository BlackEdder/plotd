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

module cli.parsing;

import std.algorithm;
import std.conv;
import std.range;
import std.string;

import plotd.drawing;
import plotd.plot;
import plotd.primitives;

version( unittest ) {
	import std.stdio;
}

alias void delegate( PlotState plot ) Event;

double[] toRange( string line ) {
	try {
		return line.split( "," )
			.map!( (d) => d.strip( ' ' ).to!double )
			.array;
	} catch (ConvException exp) { 
		return [];
	}
}

unittest {
	assert( "1,2".toRange == [1,2] );
	assert( "0.5, 2".toRange == [0.5,2] );
	assert( "bla, 2".toRange == [] );
}

Point[] toPoints( double[] coords ) {
	Point[] points;
	if (coords.length >= 2)
		points ~= Point( coords[0], coords[1] );
	return points;
}

unittest {
	assert( [1.0].toPoints.length == 0 );
	assert( equal([1.0,2.0].toPoints, [Point( 1, 2 )] ) );
}

Event[] toEvents( Point[] points ) {
	Event[] events;

	ColorRange colorRange;

	// Workaround point not properly copied in foreach loop
  void delegate( PlotState ) createEvent( Point point ) {
		return delegate( PlotState plot ) {	
			plot.plotContext = color( plot.plotContext, colorRange.front );
			colorRange.popFront;
			point.draw( plot ); 
		};
  }

	foreach( point; points ) {
		events ~= createEvent( point ); 
	}
	return events;
}

/// Struct to hold the different points etc
struct ParsedRow {
	Point[] points;
	Point[] linePoints;
	double[] histData;
}

Point[] idsToPoint( double[] floats, size_t[] xIDs, size_t[] yIDs, 
		double defaultX, double defaultY ) {
	Point[] points;
	foreach( i; 0..max(xIDs.length,yIDs.length) ) {
		double x, y;
		if (xIDs.length == 0) {
			x = defaultX;
		} else if ( i >= xIDs.length )
			x = floats[ xIDs[$-1] ];
		else
			x = floats[ xIDs[i] ];

		if (yIDs.length == 0) {
			y = defaultY;
		} else if ( i >= yIDs.length )
			y = floats[ yIDs[$-1] ];
		else
			y = floats[ yIDs[i] ];

		points ~= Point( x, y);
	}

	return points;
}

/// Parse the row and return a struct containing the results
ParsedRow applyRowMode( double[] floats, string[] rowMode ) {
	static double defaultX = 0;
	static double defaultY = 0;
	ParsedRow result;
	if (floats.length == 0)
		return result;

	size_t[] xIDs;
	size_t[] yIDs;
	size_t[] lxIDs;
	size_t[] lyIDs;
	foreach( i; 0..rowMode.length ) {
		switch( rowMode[i] ) {
			case "lx":
				lxIDs ~= i;
				break;
			case "ly":
				lyIDs ~= i;
				break;
			case "x":
				xIDs ~= i;
				break;
			case "y":
				yIDs ~= i;
				break;
			case "h":
				result.histData ~= floats[i];
				break;
			default:
		}
	}
	
	result.points ~= idsToPoint( floats, xIDs, yIDs, defaultX, defaultY );
	result.linePoints ~= idsToPoint( floats, lxIDs, lyIDs, defaultX, defaultY );

	if (xIDs.length == 0)
		++defaultX;
	if (yIDs.length == 0)
		++defaultY;
	return result;
}

unittest {
	assert( applyRowMode( [], ["x","y"] ).points.length == 0 );

	auto parsed = applyRowMode( [1.0,2.0], ["x","y"] );
	assert( equal( parsed.points, [ Point( 1.0, 2.0 ) ] ) );
	assert( parsed.histData.length == 0 );

	parsed = applyRowMode( [1.0,2.0,3.0], ["x","y","y"] );
	assert( equal( parsed.points, [ Point( 1.0, 2.0 ), Point( 1.0, 3.0 ) ] ) );
	assert( parsed.histData.length == 0 );

	parsed = applyRowMode( [1.0,2.0,3.0], ["x","y","x"] );
	assert( equal( parsed.points, [ Point( 1.0, 2.0 ), Point( 3.0, 2.0 ) ] ) );
	assert( parsed.histData.length == 0 );

	parsed = applyRowMode( [1.0,2.0,3.0,4.0], ["x","y","x","y"] );
	assert( equal( parsed.points, [ Point( 1.0, 2.0 ), Point( 3.0, 4.0 ) ] ) );
	assert( parsed.histData.length == 0 );
	
	// default x value
	parsed = applyRowMode( [1.0,2.0], ["y","y"] );
	assert( equal( parsed.points, [ Point( 0.0, 1.0 ), Point( 0.0, 2.0 ) ] ) );
	assert( parsed.histData.length == 0 );
	parsed = applyRowMode( [1.0,2.0], ["y","y"] );
	assert( equal( parsed.points, [ Point( 1.0, 1.0 ), Point( 1.0, 2.0 ) ] ) );
	assert( parsed.histData.length == 0 );

	// default y value
	parsed = applyRowMode( [1.0,2.0], ["x","x"] );
	assert( equal( parsed.points, [ Point( 1.0, 0.0 ), Point( 2.0, 0.0 ) ] ) );
	assert( parsed.histData.length == 0 );
	parsed = applyRowMode( [1.0,2.0], ["x","x"] );
	assert( equal( parsed.points, [ Point( 1.0, 1.0 ), Point( 2.0, 1.0 ) ] ) );
	assert( parsed.histData.length == 0 );

	parsed = applyRowMode( [5.0,2.0,3.0], ["h","y","y"] );
	assert( parsed.points.length == 2 );
	assert( parsed.histData.length == 1 );
	assert( equal( parsed.histData, [5.0] ) );

	// Line points
	parsed = applyRowMode( [1.0,2.0,3.0], ["lx","ly","lx"] );
	assert( equal( parsed.linePoints, [ Point( 1.0, 2.0 ), Point( 3.0, 2.0 ) ] ) );
	assert( parsed.histData.length == 0 );
}

/// Check whether current RowMode makes sense for new data.
string[] updateRowMode( double[] floats, string[] rowMode ) {
	if (floats.length == 0)
		return rowMode;
	if (floats.length == rowMode.length)
		return rowMode;
	if (floats.length == 1)
		return ["h"];
	else {
		rowMode = ["x"];
		foreach( i; 1..floats.length )
			rowMode ~= "y";
	}
	return rowMode;
}

unittest {
	assert( equal( updateRowMode( [], ["h"] ), ["h"] ) );
	assert( equal( updateRowMode( [1.0], [] ), ["h"] ) );
	assert( equal( updateRowMode( [1.0,2.0], [] ), ["x","y"] ) );
	assert( equal( updateRowMode( [1.0,2.0,3.0], [] ), ["x","y","y"] ) );
	assert( equal( updateRowMode( [1.0,2.0], ["y","y"] ), ["y","y"] ) );
	assert( equal( updateRowMode( [1.0], ["y","y"] ), ["h"] ) );
}
