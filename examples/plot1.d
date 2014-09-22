import std.conv;

import cr = cairo.cairo;

import plotd.drawing;
import plotd.primitives;

class PlotState {
	Bounds plotBounds = Bounds( 0, 1, 0, 1 );
	Bounds marginBounds = Bounds( 70, 400, 70, 400 );

	cairo.Surface surface;
	cairo.Context axesContext;
	cairo.Context plotContext;
}

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

void main() {
	auto marginBounds = Bounds( 70, 400, 70, 400 );
	auto plot = createPlotState( Bounds( 0, 1, 0, 1 ),
			marginBounds );

	plot.plotContext = drawPoint( Point( 0.5, 0.8 ), plot.plotContext );

	plot.axesContext = drawXLabel( "xlabel", plot.plotBounds, 
			plot.axesContext );
	plot.axesContext = drawYLabel( "ylabel", plot.plotBounds, 
			plot.axesContext );

	plot.surface.save;
}

