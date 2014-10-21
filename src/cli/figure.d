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

import plotd.plot : PlotState, createPlotState;
import plotd.primitives : Bounds, Point;

class Figure {
	PlotState plot;

	Event[] eventCache;

	bool validBound = false;
	Point[] pointCache;
	Point[][int] previousLines;
	double[] histData;
	double[2] histRange;

	size_t columnCount = 0;


	this() {
		plot = createPlotState( Bounds( 0, 1, 0, 1 ),
				Bounds( 70, 400, 70, 400 ) );
	}
}
