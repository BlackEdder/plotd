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

/**
	High level interface to the plotting library
	*/
module plotd.plot;

import std.conv;
import std.range;

import plotd.drawing;
import plotd.primitives;

version (assert) {
	import std.stdio : writeln;
}

/// Draw function on our plot
CONTEXT drawFunction(CONTEXT)( double delegate(double) func,
		Bounds bounds, CONTEXT context ) {
	auto points = iota( bounds.min_x, bounds.max_x, 
				bounds.width/100.0 )
			.map!( a => Point( a, func( a ) ) );

	auto from = points[0];
	foreach( to; points[1..$] ) {
		context = drawLine( from, to, context );
		from = to;
	}
	return context;
}

/// Class that holds all state to do with one figure 
class PlotState {
	Bounds plotBounds = Bounds( 0, 1, 0, 1 );
	Bounds marginBounds = Bounds( 70, 400, 70, 400 );

	cairo.Surface surface;
	cairo.Context axesContext;
	cairo.Context plotContext;
}

/// Instantiate a new plot
PlotState createPlotState( Bounds plotBounds, Bounds marginBounds ) {
	auto plot = new PlotState;
	plot.plotBounds = plotBounds;
	plot.marginBounds = marginBounds;

	plot.surface = createPlotSurface( plot.marginBounds.max_x.to!int, 
			plot.marginBounds.max_y.to!int );

	// setup axes
	plot.axesContext = axesContextFromSurface( plot.surface, 
			plot.plotBounds, plot.marginBounds );

	plot.axesContext = drawAxes( plot.plotBounds, plot.axesContext );

	plot.plotContext = plotContextFromSurface( plot.surface, 
			plot.plotBounds, plot.marginBounds );

	return plot;
}

/// Draw a range of points as a line
void drawRange(RANGE)( RANGE range, PlotState plot ) {
	if (!range.empty) {
		auto firstPoint = range.front;
		range.popFront;
		while (!range.empty) {
			auto nextPoint = range.front;
			range.popFront;
			plot.plotContext = 
				drawLine( firstPoint, nextPoint, plot.plotContext );
			firstPoint = nextPoint;
		}
	}
}

/// Draw function on our plot
void drawFunction(CONTEXT)( double delegate(double) func,
		PlotState plot ) {
	iota( plot.plotBounds.min_x, plot.plotBounds.max_x, 
				plot.plotBounds.width/100.0 )
			.map!( a => Point( a, func( a ) ) ).drawRange( plot );
}

/// Draw point on the plot
void draw( Point point, PlotState plot ) {
	plot.plotContext = drawPoint( point, plot.plotContext );
}

/// Save plot to a file
void save( PlotState plot, string name = "example.png" ) {
    (cast(cairo.ImageSurface)( plot.surface )).writeToPNG( name );
}
