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
import std.stdio : write, writeln;
import std.string;

import std.regex : ctRegex, match, split;

import docopt;

import plotd.binning;
import plotd.drawing;
import plotd.plot;
import plotd.primitives;

import cli.algorithm : groupBy;
import cli.column;
import cli.figure : Figure;
import cli.options : helpText, Settings, updateSettings;

version( unittest ) {
	import std.stdio;
}

alias void delegate( PlotState plot ) Event;

private auto csvRegex = ctRegex!(`,\s*|\s`);

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
	assert( "1 2".toRange == [1,2] );
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

// Warning assumes array with either one x or one y value.
private Point[] columnDataToPoints( ColumnData[] cMs, double defaultCoord )
{
	Point[] pnts;
	if (cMs.length == 0)
		return pnts;

	auto coords = cMs.groupBy!( (cm) { 
			if (cm.xCoord) 
				return "x"; 
			return "y"; } );

	if ( "x" !in coords ) {
		return coords["y"]
			.map!( (cmy) => Point( defaultCoord, cmy.value ) ).array;
	} else if ( "y" !in coords ) {
		return coords["x"]
			.map!( (cmx) => Point( cmx.value, defaultCoord ) ).array;
	}
	else if ( coords["x"].length == 1 ) {
		return coords["y"]
			.map!( (cmy) => Point( coords["x"].front.value, cmy.value ) ).array;
	}
 	else if ( coords["y"].length == 1 ) {
		return coords["x"]
			.map!( (cmx) => Point( cmx.value, coords["y"].front.value ) ).array;
	}
	assert( 0, "Invalid input for columnModeToPoints " ~ cMs.to!string );
}

/** Turn columns into drawable results. If no x or y value is present then columnID is used as the x or y value;

	This function tries to be relative human like in parsing and the logic is difficult to follow. See the unittests for its behaviour
	*/
ParsedRow applyColumnData( ColumnData[] cMs, size_t columnID ) {
	ParsedRow parsed;
	foreach ( type, groupedCMs;
			cMs.groupBy!( (cm) {
				if ( cm.mode.to!string == "" )
					return "none";
				if ( cm.mode.front.to!string == "l" )
					return "line";
				if ( cm.mode.front.to!string == "h" )
					return "hist";
				return "point";
			}
		) ) 
	{
		if ( type != "none" ) {
			ColumnData[] xyGroup;
			size_t xs = 0;
			size_t ys = 0;
			double lastX; // If x is used set lastX to isNaN?
			double lastY;
			Point[] addRange;
			foreach ( cM; groupedCMs ) {
				if ( cM.xCoord || cM.yCoord ) {
					if ( xs > 1 && ys > 1 ) { 
						// We never want a group with more than 1 x coord or y coord
						xs = 0;
						ys = 0;
						addRange ~= columnDataToPoints( 
								xyGroup[0..$-1], columnID );
						xyGroup = [xyGroup.back];
					} else if ( xs >= 1 && ys >= 1 && xyGroup.back.mode != cM.mode ) {
						xs = 0;
						ys = 0;
						addRange ~= columnDataToPoints( xyGroup, columnID );
						xyGroup = [cM];
					} else
						xyGroup ~= cM;
					if (cM.xCoord) {
						lastX = cM.value;
						xs++;
					} else if (cM.yCoord) {
						lastY = cM.value;
						ys++;
					}
				} else {
					if (type == "hist")
						parsed.histData ~= cM.value;
				}
			}
			if (xyGroup.length > 0) {
				// If we found no x or y coord at all then use columnID
				if (lastX.isNaN || lastY.isNaN)
					addRange ~= columnDataToPoints( xyGroup, columnID ); 
				else if ( xyGroup.front.xCoord )
					addRange ~= columnDataToPoints( xyGroup, lastY ); 
				else
					addRange ~= columnDataToPoints( xyGroup, lastX ); 
			}
			if ( type == "line" ) {
				parsed.linePoints ~= addRange;
			} else if ( type == "point" )
				parsed.points ~= addRange;
		}
	}
	return parsed;
}

unittest {
	ColumnData cm( string mode, double value ) {
		return ColumnData( mode, -1, "", value );
	}
	
	auto pr = applyColumnData( [cm("x",1), cm("y",2)], 0 );
	assert( pr.points == [Point( 1, 2 )] );

	pr = applyColumnData( [cm("x",3), cm("y",2), cm("y",4)], 0 );
	assert( pr.points == [Point( 3, 2 ), Point( 3, 4 )] );

	pr = applyColumnData( [cm("x",1)], 5 );
	assert( pr.points == [Point( 1, 5 )] );

	pr = applyColumnData( [cm("x",1), cm("x",3)], 5 );
	assert( pr.points == [Point( 1, 5 ),Point( 3, 5 )] );

	pr = applyColumnData( [cm("y",2)], 5 );
	assert( pr.points == [Point( 5, 2 )] );

	pr = applyColumnData( [cm("y",2), cm("y",4)], 5 );
	assert( pr.points == [Point( 5, 2 ),Point( 5, 4 )] );

	pr = applyColumnData( [cm("y",2), cm("x",1), cm("y",4), cm("y",6)], 5 );
	assert( pr.points == [Point( 1, 2 ),Point( 1, 4 ),Point( 1, 6 )] );
	pr = applyColumnData( [cm("x",2), cm("y",1), cm("x",4), cm("x",6)], 5 );
	assert( pr.points == [Point( 2, 1 ),Point( 4, 1 ),Point( 6, 1 )] );

	pr = applyColumnData( [cm("y",2), cm("x",1), cm("y",4), cm("x",3)], 5 );
	assert( pr.points == [Point( 1, 2 ),Point( 3, 4 )] );
	pr = applyColumnData( [cm("y",2), cm("y",8), cm("x",1), cm("y",4), cm("y",6), cm("x",3)], 5 );
	assert( pr.points == [Point( 1, 2 ),Point( 1, 8 ),Point( 3, 4 ),Point( 3, 6 )] );
	pr = applyColumnData( [cm("x",2), cm("y",8), cm("y",1), cm("x",4), cm("y",6), cm("y",3)], 5 );
	assert( pr.points == [Point( 2, 8 ),Point( 2, 1 ),Point( 4, 6 ),Point( 4, 3 )] );

	// Lines
	// Should really be more indepth, but since same code is used, as for
	// points should be ok
	pr = applyColumnData( [cm("lx",1), cm("ly",2)], 0 );
	assert( pr.linePoints == [Point( 1, 2 )] );

	pr = applyColumnData( [cm("x",2), cm("y",8), cm("lx",11), cm("y",1), cm("x",4), cm("y",6), cm("y",3)], 5 );
	assert( pr.points == [Point( 2, 8 ),Point( 2, 1 ),Point( 4, 6 ),Point( 4, 3 )] );
	assert( pr.linePoints == [Point( 11, 5 )] );

	// Hist
	pr = applyColumnData( [cm("h",1.1), cm("h",2.1)], 0 );
	assert( pr.histData == [1.1,2.1] );

	pr = applyColumnData( [cm("x",2), cm("h",1.1), cm("y",8), cm("lx",11), cm("y",1), cm("x",4), cm("h",2.1), cm("y",6), cm("y",3)], 5 );
	assert( pr.points == [Point( 2, 8 ),Point( 2, 1 ),Point( 4, 6 ),Point( 4, 3 )] );
	assert( pr.linePoints == [Point( 11, 5 )] );
	assert( pr.histData == [1.1,2.1] );
}

/// Check whether current RowMode makes sense for new data.
Formats updateFormat( double[] floats, Formats formats ) {
	if ( floats.length == 0 )
		return formats;
	if ( formats.validFormat( floats.length ) )
		return formats;
	else 
		return Formats( floats.length );
}


Figure[string] figures;

// High level functionality for handlingMessages
void handleMessage( string msg, ref Settings settings ) {
	if ( "" !in figures )
		figures[""] = new Figure;

	debug write( "Received message: ", msg );

	auto m = msg.match( r"^#plotcli (.*)" );
	if (m) {
		settings = settings.updateSettings( 
				docopt.docopt(helpText, 
					std.string.split( m.captures[1], " " ), true, "plotcli") );
		//writeln( settings );
	}

	auto floats = msg.strip
		.toRange;

	debug writeln( "Converted to doubles: ", floats );

	settings.formats = updateFormat( floats, settings.formats );

	auto columnData = settings.formats.zip(floats).map!( 
			(mv) { auto cD = ColumnData( mv[0] ); cD.value = mv[1]; return cD; } );

	foreach( plotID, cMs1; columnData.groupBy!( (cm) => cm.plotID ) )
	{
		if ( plotID !in figures )
			figures[plotID] = new Figure;
		foreach( dataID, cMs; cMs1.groupBy!( (cm) => cm.dataID ) ) {
			debug writeln( "Plotting data: ", cMs );
			auto parsedRow = applyColumnData( cMs, figures[plotID].columnCount );

			bool needAdjusting = false;
			if ( !figures[plotID].validBound ) {
				needAdjusting = true;
				figures[plotID].pointCache ~= parsedRow.points ~ parsedRow.linePoints;
				figures[plotID].validBound = validBounds( figures[plotID].pointCache );
				figures[plotID].plot.plotBounds = minimalBounds( figures[plotID].pointCache );
				if (figures[plotID].validBound)
					figures[plotID].pointCache = [];
			} else {
				foreach( point; parsedRow.points ~ parsedRow.linePoints ) {
					if (!figures[plotID].plot.plotBounds.withinBounds( point )) {
						figures[plotID].plot.plotBounds = adjustedBounds( figures[plotID].plot.plotBounds, point );
						needAdjusting = true;
					}
				}
			}

			if (needAdjusting) {

				figures[plotID].plot = createPlotState( figures[plotID].plot.plotBounds, 
						figures[plotID].plot.marginBounds );
				foreach( event; figures[plotID].eventCache )
					event( figures[plotID].plot );
			}

			auto events = parsedRow.points.toEvents;

			if (dataID !in figures[plotID].previousLines) {
				Point[] pnts;
				figures[plotID].previousLines[dataID] = pnts;
			}


			if ( figures[plotID].previousLines[dataID].length 
					== parsedRow.linePoints.length )
				events ~= parsedRow.linePoints.toLineEvents( 
						figures[plotID].previousLines[dataID] );

			if (parsedRow.linePoints.length > 0)
				figures[plotID].previousLines[dataID] = parsedRow.linePoints;


			foreach( event; events )
				event( figures[plotID].plot );

			figures[plotID].eventCache ~= events;

			// Histograms
			foreach( data; parsedRow.histData ) {
				if ( data < figures[plotID].histRange[0] || isNaN(figures[plotID].histRange[0]) ) {
					figures[plotID].histRange[0] = data;
				} 
				if ( data > figures[plotID].histRange[1] || isNaN(figures[plotID].histRange[1]) ) {
					figures[plotID].histRange[1] = data;
				}
				figures[plotID].histData ~= data;
			}


			if (figures[plotID].histData.length > 0) {
				// Create bin
				Bins!size_t bins;
				bins.min = figures[plotID].histRange[0];
				bins.width = 0.5;
				bins.length = max( 11, min( 31, figures[plotID].histData.length/100 ) ); 
				if( figures[plotID].histRange[0] != figures[plotID].histRange[1] )
					bins.width = (figures[plotID].histRange[1]-figures[plotID].histRange[0])/bins.length;
				// add all data to bin
				foreach( data; figures[plotID].histData )
					bins = bins.addDataToBin( [bins.binId( data )] );

				auto histBounds = bins.optimalBounds( 0.99 );

				debug writeln( "Adjusting histogram to bounds: ", histBounds );
				// Adjust plotBounds 
				figures[plotID].plot = createPlotState( histBounds,
						figures[plotID].plot.marginBounds );
				// Plot Bins
				figures[plotID].plot.plotContext = drawBins( figures[plotID].plot.plotContext, bins );
				debug writeln( "Drawn bins to histogram: ", bins );
			}

		}
		figures[plotID].columnCount += 1;
	}
}

void saveFigures( string baseName ) {
	foreach ( plotID, figure; figures ) {
		figure.plot.save( baseName ~ plotID ~ ".png" );
	}
}
