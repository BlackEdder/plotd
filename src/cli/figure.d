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

module cli.figure;

import std.algorithm : map;

import cli.parsing : Event;

//import plotd.plot : PlotState, createPlotState;
//import plotd.primitives : Bounds, Color, ColorRange, Point;
import axes = plotd.axes : AdaptationMode;
import plotd.binning : Bins, optimalBounds, toBins;
import draw = plotd.drawing;
import plotd.plot;
import plotd.primitives;

/*
TODO: add unique id struct that can be calculated from plotID and either
a dataID or a counter (columnID) if no dataID was given

This can then be used to access previous line points and colorID...
Isn't the previousLine cache already like that and an easier solution? Probably!
Maybe jus separate color events is easier, instead of including them in points.i.e. always change color and add to events before the point.. Think that that is the solution.. foreach column -> eventCache ~ colorChange, eventCache point
*/

class Figure {
	Event[] eventCache;

	Point[] pointCache;
	Point[][int] previousLines;

	double[] histData;
	Point[] histPoints;

	size_t columnCount = 0;

	AdaptiveBounds plotBounds;

	LazyFigure lf = new LazyFigure;

	this() {
		lf.plotBounds = Bounds( 0, 1, 0, 1 );
		lf.marginBounds = Bounds( 70, 400, 70, 400 );
	}

	this( Bounds bounds, Bounds marginBounds ) {
		lf.plotBounds = bounds;
		lf.marginBounds = marginBounds;
	}

	private:
  	ColorRange colorRange;
	  Color[][int] colors;
}

Color getColor( Figure figure, int dataID, size_t id = 0 ) {
	/// Make sure we cache the color
	if (dataID !in figure.colors) {
		figure.colors[dataID] ~= figure.colorRange.front;
		figure.colorRange.popFront;
	}
	while ( figure.colors[dataID].length <= id ) {
		figure.colors[dataID] ~= figure.colorRange.front;
		figure.colorRange.popFront;
	}
	return figure.colors[dataID][id];
}
unittest {
	assert( true );
}

unittest {
	auto fig = new Figure;
	auto col = fig.getColor( -1, 0 );
	assert( col == fig.getColor( -1, 0 ) ); 
	assert( col != fig.getColor( 1, 0 ) ); 
	assert( col != fig.getColor( -1, 1 ) ); 
}

/*void drawHistogram( Figure figure, string xlabel, string ylabel, axes.AdaptationMode adaptationMode ) {
	if (figure.histData.length > 0) {
		// Create bin
		auto bins = figure.histData.toBins!size_t(
				max( 11, min( 31, figure.histData.length/100 ) ) );

		if ( adaptationMode == axes.AdaptationMode.full ) {
			// Adjust plotBounds 
			figure.plotBounds = bins.optimalBounds( 0.99 );
			debug writeln( "Adjusting histogram to bounds: ", 
					figure.plot.plotBounds );
		}
		// Create empty plot
		figure.lf._plot = createPlotState( figure.lf._plotBounds,
				figure.lf._marginBounds );
		figure.drawLabels( xlabel, ylabel );
		// Plot Bins
		figure.plot.plotContext = draw.drawBins( figure.plot.plotContext, bins );
		debug writeln( "Drawn bins to histogram: ", bins );
	}

	if (figure.histPoints.length > 0) {
		auto bins = figure.histPoints
			.map!( (pnt) => [pnt.x,pnt.y] )
			.toBins!(Bins!size_t)( 
					max( 11, min( 31, figure.histData.length/100 ) ) );
		debug writeln( "Drawing 2D histogram: ", bins );
		if ( adaptationMode == axes.AdaptationMode.full ) {
			// Adjust plotBounds 
			figure.plot.plotBounds = Bounds( bins.min, bins.max,
					bins[0].min, bins[0].max);
			debug writeln( "Adjusting 2D histogram to bounds: ", 
					figure.plot.plotBounds );
		}
		// Create empty plot
		figure.plot = createPlotState( figure.plot.plotBounds,
				figure.plot.marginBounds );
		figure.drawLabels( xlabel, ylabel );
		figure.plot.plotContext 
			= draw.drawBins( figure.plot.plotContext, bins );
	}
}*/

/// Only plot when needed not before
class LazyFigure {
	@property point( Point pnt ) {
		if ( _adaptionMode == axes.AdaptationMode.full )
		{
			auto needAdjusting = _plotBounds.adapt( pnt );

			if (needAdjusting)
				fullRedraw = true;
		}

		_events ~= delegate( PlotState plot ) {	
			plot.plotContext = draw.drawPoint( pnt, plot.plotContext ); 
		};
	}

	@property color( Color clr ) {
		_events ~= delegate( PlotState plot ) {	
			plot.plotContext = draw.color( plot.plotContext, clr );
		};
	}

	@property xlabel( string xl ) {
		_xlabel = xl;
	}

	@property ylabel( string yl ) {
		_ylabel = yl;
	}

	@property adaptationMode( axes.AdaptationMode am ) 
	{
		_adaptionMode = am;
	}

	@property plotBounds( Bounds pB )
	{
		_plotBounds = pB;
		fullRedraw = true;
	}

	@property marginBounds( Bounds mB )
	{
		_marginBounds = mB;
		fullRedraw = true;
	}

	void line( Point fromP, Point toP ) {
		if ( _adaptionMode == axes.AdaptationMode.full ) {
			auto needAdjustingFrom = _plotBounds.adapt( fromP );
			auto needAdjustingTo = _plotBounds.adapt( toP );
			if (needAdjustingFrom || needAdjustingTo)
				fullRedraw = true;
		}

		_events ~= delegate( PlotState plot ) {	
			plot.plotContext = draw.drawLine( toP, fromP, plot.plotContext );
		};
	}

	void plot() {
		if ( fullRedraw ) 
		{
			_plot = createPlotState( _plotBounds,
					_marginBounds );
			foreach( event; _eventCache )
				event( _plot );
			fullRedraw = false;
		}

		debug writeln( "LazyFigure::plot plotting xlabel ", _xlabel );

		_plot.axesContext = draw.drawXLabel( _xlabel, _plot.plotBounds, 
				_plot.axesContext );
		_plot.axesContext = draw.drawYLabel( _ylabel, _plot.plotBounds, 
				_plot.axesContext );

		foreach( event; _events ) {
			event( _plot );
			_eventCache ~= event;
		}
		_events.length = 0;
	}

	void save( string fn )
	{
		_plot.save( fn );
	}

	private:
		bool fullRedraw = true; // Is a new redraw needed 
		PlotState _plot;
		AdaptiveBounds _plotBounds;
		Bounds _marginBounds;
		Event[] _eventCache; // Old events
		Event[] _events; // Events since last plot

		string _xlabel;
		string _ylabel;

		axes.AdaptationMode _adaptionMode;
}

