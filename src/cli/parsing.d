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

version( unittest ) {
	import std.stdio;
}

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
