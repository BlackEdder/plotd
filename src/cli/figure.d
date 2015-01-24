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
TODO: Rename this to better fit with its function, i.e. mostly keeping color data around
*/
class Figure {
	Point[][string] previousLines;

	double[] histData;
	Point[] histPoints;

	size_t columnCount = 0;

	LazyFigure lf;

	this() {
		lf = new LazyFigure;
		lf.plotBounds = Bounds( 0, 1, 0, 1 );
		lf.marginBounds = Bounds( 70, 400, 70, 400 );
	}

	this( string name, Bounds bounds, Bounds marginBounds ) {
		lf = new LazyFigure( name );
		lf.plotBounds = bounds;
		lf.marginBounds = marginBounds;
	}

	private:
  	ColorRange colorRange;
	  Color[][string] colors;
}

Color getColor( Figure figure, string dataID, size_t id = 0 ) {
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
	auto col = fig.getColor( "", 0 );
	assert( col == fig.getColor( "", 0 ) ); 
	assert( col != fig.getColor( "1", 0 ) ); 
	assert( col != fig.getColor( "", 1 ) ); 
}

// Wrapper classes for PlotState, to make them inheritable
interface PlotInterface
{
    void create( string name, Bounds plotBounds, Bounds marginBounds );
    void save();
    void drawPoint( Point pnt );
    void drawColor( Color clr );
    void drawLine( Point toP, Point fromP );
    void drawXLabel( string xlabel );
    void drawYLabel( string ylabel );
    void drawBins2D( Bins!size_t bins );
    void drawBins3D( Bins!(Bins!(size_t)) bins );
    void drawBins(BINS)( BINS bins );
}

class PNGPlot : PlotInterface
{
    void create( string name, Bounds plotBounds, Bounds marginBounds )
    {
        _plot = createPlotState!"png"( name, plotBounds,
            marginBounds );
    }

    void save() 
    {
        _plot.save();
    }

    void drawPoint( Point pnt )
    {
        _plot.plotContext = draw.drawPoint( pnt, _plot.plotContext ); 
    }

    void drawColor( Color clr )
    {
        _plot.plotContext = draw.color( _plot.plotContext, clr );
    }

    void drawLine( Point toP, Point fromP )
    {
        _plot.plotContext = draw.drawLine( toP, fromP, _plot.plotContext );
    }

    void drawXLabel( string xlabel )
    {
        plotd.plot.drawXLabel( xlabel, _plot );
    }

    void drawYLabel( string ylabel )
    {
        plotd.plot.drawYLabel( ylabel, _plot );
    }

    void drawBins2D( Bins!size_t bins )
    {
        plotd.plot.drawBins( bins, _plot );
    }

    void drawBins3D( Bins!(Bins!(size_t)) bins )
    {
        plotd.plot.drawBins( bins, _plot );
    }

    // This seems not to work correctly, use drawBins2D/3D instead
    void drawBins(BINS)( BINS bins )
    {
        plotd.plot.drawBins!BINS( bins, _plot );
    }

    private:
        PlotState!"png" _plot;
}

class PDFPlot : PlotInterface
{
    void create( string name, Bounds plotBounds, Bounds marginBounds )
    {
        _plot = createPlotState!"pdf"( name, plotBounds,
            marginBounds );
    }

    void save() 
    {
        _plot.save();
    }

    void drawPoint( Point pnt )
    {
        _plot.plotContext = draw.drawPoint( pnt, _plot.plotContext ); 
    }

    void drawColor( Color clr )
    {
        _plot.plotContext = draw.color( _plot.plotContext, clr );
    }

    void drawLine( Point toP, Point fromP )
    {
        _plot.plotContext = draw.drawLine( toP, fromP, _plot.plotContext );
    }

    void drawXLabel( string xlabel )
    {
        plotd.plot.drawXLabel( xlabel, _plot );
    }

    void drawYLabel( string ylabel )
    {
        plotd.plot.drawYLabel( ylabel, _plot );
    }

    void drawBins2D( Bins!size_t bins )
    {
        plotd.plot.drawBins( bins, _plot );
    }

    void drawBins3D( Bins!(Bins!(size_t)) bins )
    {
        plotd.plot.drawBins( bins, _plot );
    }

    // This seems not to work correctly, use drawBins2D/3D instead
    void drawBins(BINS)( BINS bins )
    {
        plotd.plot.drawBins!BINS( bins, _plot );
    }

    private:
        PlotState!"pdf" _plot;
}

/// Only plot when needed not before
class LazyFigure {
    string _name = "plotcli";
    this() {}

    this( string name ) 
    {
        _name = name;
    }

	@property point( Point pnt ) {
		if ( _adaptionMode == axes.AdaptationMode.full )
		{
			auto needAdjusting = _plotBounds.adapt( pnt );

			if (needAdjusting)
				fullRedraw = true;
		}

		_events ~= delegate( PlotInterface plot ) {	
            plot.drawPoint( pnt );
		};
	}

	@property color( Color clr ) {
		_events ~= delegate( PlotInterface plot ) {	
            plot.drawColor( clr );
		};
	}

	@property xlabel( string xl ) {
		_xlabel = xl;
	}

	@property ylabel( string yl ) {
		_ylabel = yl;
	}

	@property adaptationMode() 
	{
		return _adaptionMode;
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

		_events ~= delegate( PlotInterface plot ) {	
            plot.drawLine( toP, fromP );
		};
	}

	void plot() {
        if ( fullRedraw ) 
        {
            if (true) // TODO make if format is ...
            {
                _plot = new PNGPlot;
            }
            _plot.create( _name, _plotBounds, _marginBounds );
            foreach( event; _eventCache )
                event( _plot );
            fullRedraw = false;
        }

		debug writeln( "LazyFigure::plot plotting xlabel ", _xlabel );

        _plot.drawXLabel( _xlabel );
        _plot.drawYLabel( _ylabel );

		foreach( event; _events ) {
			event( _plot );
			_eventCache ~= event;
		}
		_events.length = 0;
	}

    void save()
    {
        _plot.save();
    }

	private:
		bool fullRedraw = true; // Is a new redraw needed 
		PlotInterface _plot;
		AdaptiveBounds _plotBounds;
		Bounds _marginBounds;
		Event[] _eventCache; // Old events
		Event[] _events; // Events since last plot

		string _xlabel;
		string _ylabel;

		axes.AdaptationMode _adaptionMode;
}

//TODO: this is a bit of a hack, need to properly implement separate context
// for histograms and then combining contexts
void drawHistogram( Figure figure ) {
	if (figure.histData.length > 0) {
		// Create bin
		auto bins = figure.histData.toBins!size_t(
				max( 11, min( 31, figure.histData.length/100 ) ) );

		if ( figure.lf.adaptationMode == axes.AdaptationMode.full ) {
			// Adjust plotBounds 
			figure.lf.plotBounds = bins.optimalBounds( 0.99 );
			debug writeln( "Adjusting histogram to bounds: ", 
					figure.lf._plotBounds );
		}
		// Empty current events/plot (this is the hacky bit)
		figure.lf.fullRedraw = true;
		figure.lf._events.length = 0;
		figure.lf._eventCache.length = 0;
		figure.lf.plot;

		// Plot Bins
        figure.lf._plot.drawBins2D( bins );
		debug writeln( "Drawn bins to histogram: ", bins );
	}

	if (figure.histPoints.length > 0) {
		auto bins = figure.histPoints
			.map!( (pnt) => [pnt.x,pnt.y] )
			.toBins!(Bins!size_t)( 
					max( 11, min( 31, figure.histData.length/100 ) ) );
		debug writeln( "Drawing 2D histogram: ", bins );
		if ( figure.lf.adaptationMode == axes.AdaptationMode.full ) {
			// Adjust plotBounds 
			figure.lf.plotBounds = Bounds( bins.min, bins.max,
					bins[0].min, bins[0].max);
			debug writeln( "Adjusting 2D histogram to bounds: ", 
					figure.lf._plotBounds );
		}
		// Empty current events/plot (this is the hacky bit)
		figure.lf.fullRedraw = true;
		figure.lf._events.length = 0;
		figure.lf._eventCache.length = 0;
		figure.lf.plot;

		figure.lf._plot.drawBins3D( bins );
	}
}
