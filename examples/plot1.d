import std.conv;

import cr = cairo.cairo;

import plotd.drawing;
import plotd.primitives;
import plotd.plot;

void main() {
	auto marginBounds = Bounds( 70, 400, 70, 400 );
	auto plot = createPlotState( Bounds( 0, 1, 0, 1 ),
			marginBounds );

	plot.plotContext = drawPoint( Point( 0.5, 0.8 ), plot.plotContext );

	plot.axesContext = drawXLabel( "xlabel", plot.plotBounds, 
			plot.axesContext );
	plot.axesContext = drawYLabel( "ylabel", plot.plotBounds, 
			plot.axesContext );

	plot.save;
}

