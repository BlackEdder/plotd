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

import cli.parsing : Event;

//import plotd.plot : PlotState, createPlotState;
//import plotd.primitives : Bounds, Color, ColorRange, Point;
import plotd.drawing;
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
	PlotState plot;

	Event[] eventCache;

	bool validBound = false;
	Point[] pointCache;
	Point[][int] previousLines;

	double[] histData;

	size_t columnCount = 0;


	this() {
		plot = createPlotState( Bounds( 0, 1, 0, 1 ),
				Bounds( 70, 400, 70, 400 ) );
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
	auto fig = new Figure;
	auto col = fig.getColor( -1, 0 );
	assert( col == fig.getColor( -1, 0 ) ); 
	assert( col != fig.getColor( 1, 0 ) ); 
	assert( col != fig.getColor( -1, 1 ) ); 
}

void adjustBounds( Figure figure, Point[] newPoints ) 
{
	// Two scenarios. 
	// 1) we do not have enough points to properly 
	// initialize the bounds (if we have only one point, or multiple points
	// with the same x or y coordinate.
	//
	// 2) New points fall outside of the current validBounds and we 
	// need to adjust the bounds to incorporate the new points
	bool needAdjusting = false;
	if ( !figure.validBound ) {
		needAdjusting = true;
		figure.pointCache ~= newPoints;
		figure.validBound = validBounds( figure.pointCache );
		figure.plot.plotBounds = minimalBounds( 
				figure.pointCache );
		if (figure.validBound)
			figure.pointCache = [];
	} else {
		foreach( point; newPoints ) {
			if (!figure.plot.plotBounds.withinBounds( point )) {
				figure.plot.plotBounds = adjustedBounds( figure.plot.plotBounds, point );
				needAdjusting = true;
			}
		}
	}

	if (needAdjusting) {
		// create new plot surface
		figure.plot = createPlotState( 
				figure.plot.plotBounds, 
				figure.plot.marginBounds );

		// Repaint all previous points and lines
		foreach( event; figure.eventCache )
			event( figure.plot );
	}
}

unittest {
	auto fig = new Figure;
	fig.adjustBounds( [Point(0,1), Point( 0,2 )] );
	assert( fig.validBound == false );
	fig.adjustBounds( [Point(-1,1)] );
	assert( fig.validBound == true );
	assert( fig.plot.plotBounds == 
			minimalBounds( [Point(-1,1),Point(0,2)] ) );
}

