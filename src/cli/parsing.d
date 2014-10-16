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
import std.conv : ConvException, to;
import std.math : isNaN;
import std.range;
import std.string;

import std.regex : ctRegex, match, split;

import docopt;

import plotd.binning;
import plotd.drawing;
import plotd.plot;
import plotd.primitives;

import cli.figure : Figure;
import cli.options : helpText, Settings, updateSettings;

version( unittest ) {
	import std.stdio;
}

alias void delegate( PlotState plot ) Event;

private auto csvRegex = ctRegex!(`,|\t`);

double[] toRange( string line ) {
	try {
		return line.split( csvRegex )
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
	assert( "1\t2".toRange == [1,2] );
}

/// Settings of a specific column
struct ColumnMode {
	string mode; /// x,y,lx,ly,h
	string plotID; /// plotName/id 
	int dataID = -1; /// -1 is the default value
}

ColumnMode parseColumn( string mode ) {
	ColumnMode colMode;
	auto columnRegex = ctRegex!( r"(lx|ly|x|y|hx|hy|hz|h)(\d*)(.*)" );
	auto m = mode.match( columnRegex );
	colMode.mode = m.captures[1];
	if ( m.captures[2].length > 0 )
		colMode.dataID = m.captures[2].to!int;
	colMode.plotID = m.captures[3];
	return colMode;
}

unittest {
	auto col = parseColumn( "lx1a" );
	assert( col.mode == "lx" );
	assert( col.dataID == 1 );
	assert( col.plotID == "a" );
	col = parseColumn( "ly1a" );
	assert( col.mode == "ly" );
	col = parseColumn( "xb" );
	assert( col.mode == "x" );
	assert( col.dataID == -1 );
	assert( col.plotID == "b" );

	col = parseColumn( "y3" );
	assert( col.mode == "y" );
	assert( col.dataID == 3 );
	assert( col.plotID == "" );

	col = parseColumn( "hx" );
	assert( col.mode == "hx" );
	col = parseColumn( "hy" );
	assert( col.mode == "hy" );
	col = parseColumn( "h" );
	assert( col.mode == "h" );
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
  void delegate( PlotState ) createEvent( Point point, Color col ) {
		return delegate( PlotState plot ) {	
			plot.plotContext = color( plot.plotContext, col );
			colorRange.popFront;
			point.draw( plot ); 
		};
  }

	foreach( point; points ) {
		events ~= createEvent( point, colorRange.front ); 
		colorRange.popFront;
	}
	return events;
}

Event[] toLineEvents( Point[] points, Point[] previousPoints ) {
	Event[] events;

	ColorRange colorRange;

	// Workaround point not properly copied in foreach loop
  void delegate( PlotState ) createEvent( size_t i, Color col ) {
		return delegate( PlotState plot ) {	
			plot.plotContext = color( plot.plotContext, col );
			plot.plotContext = drawLine( previousPoints[i], points[i], plot.plotContext ); 
		};
  }

	foreach( i; 0..points.length ) {
		events ~= createEvent( i, colorRange.front ); 
		colorRange.popFront;
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
	auto modes = rowMode.map!( (s) => s.parseColumn );
	foreach( i; 0..modes.length ) {
		switch( modes[i].mode ) {
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

	if ((xIDs.length == 0 && yIDs.length > 0) || 
			(lxIDs.length == 0 && lyIDs.length > 0) )
		++defaultX;
	if ((yIDs.length == 0 && xIDs.length > 0) || 
			(lyIDs.length == 0 && lxIDs.length > 0) )
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

// High level functionality for handlingMessages

Figure[string] figures;

void handleMessage( string msg, ref Settings settings ) {
	if ( "" !in figures )
		figures[""] = new Figure;

	auto m = msg.match( r"^#plotcli (.*)" );
	if (m) {
		settings = settings.updateSettings( 
				docopt.docopt(helpText, 
					std.string.split( m.captures[1], " " ), true, "plotcli") );
		//writeln( settings );
	}

	auto floats = msg.strip
		.toRange;

	settings.rowMode = updateRowMode( floats, settings.rowMode );
	auto parsedRow = applyRowMode( floats, settings.rowMode );

	bool needAdjusting = false;
	if ( !figures[""].validBound ) {
		needAdjusting = true;
		figures[""].pointCache ~= parsedRow.points ~ parsedRow.linePoints;
		figures[""].validBound = validBounds( figures[""].pointCache );
		figures[""].plot.plotBounds = minimalBounds( figures[""].pointCache );
		if (figures[""].validBound)
			figures[""].pointCache = [];
	} else {
		foreach( point; parsedRow.points ~ parsedRow.linePoints ) {
			if (!figures[""].plot.plotBounds.withinBounds( point )) {
				figures[""].plot.plotBounds = adjustedBounds( figures[""].plot.plotBounds, point );
				needAdjusting = true;
			}
		}
	}

	if (needAdjusting) {
		figures[""].plot = createPlotState( figures[""].plot.plotBounds, 
				figures[""].plot.marginBounds );
		foreach( event; figures[""].eventCache )
			event( figures[""].plot );
	}

	auto events = parsedRow.points.toEvents;

	if ( figures[""].previousLines.length == parsedRow.linePoints.length )
		events ~= parsedRow.linePoints.toLineEvents( figures[""].previousLines );

	if (parsedRow.linePoints.length > 0)
		figures[""].previousLines = parsedRow.linePoints;


	foreach( event; events )
		event( figures[""].plot );

	figures[""].eventCache ~= events;

	// Histograms
	foreach( data; parsedRow.histData ) {
		if ( data < figures[""].histRange[0] || isNaN(figures[""].histRange[0]) ) {
			figures[""].histRange[0] = data;
		} 
		if ( data > figures[""].histRange[1] || isNaN(figures[""].histRange[1]) ) {
			figures[""].histRange[1] = data;
		}
		figures[""].histData ~= data;
	}

	if (figures[""].histData.length > 0) {
		// Create bin
		Bins!size_t bins;
		bins.min = figures[""].histRange[0];
		bins.width = 0.5;
		bins.length = 11; // Really need to fix this in binning.d
		if( figures[""].histRange[0] != figures[""].histRange[1] )
			bins.width = (figures[""].histRange[1]-figures[""].histRange[0])/10.0;
		// add all data to bin
		foreach( data; figures[""].histData )
			bins = bins.addDataToBin( [bins.binId( data )] );
		// Adjust plotBounds 
		figures[""].plot = createPlotState( Bounds( bins.min, bins.max, 0, 
					figures[""].histData.length ),
				figures[""].plot.marginBounds );
		// Plot Bins
		figures[""].plot.plotContext = drawBins( figures[""].plot.plotContext, bins );
	}

	figures[""].plot.save( settings.outputFile );
}
