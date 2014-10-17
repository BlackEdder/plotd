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

module cli.options;

import std.conv : to;
import std.string : split;

import docopt : ArgValue;

version( unittest ) {
	import std.algorithm : equal;
	import std.stdio : writeln;
	import docopt : docopt;
}

/// Merge given associative arrays
V[K] merge( K, V )( V[K] aaBase, in V[K] aa ) {
	foreach ( k, v; aa )
		aaBase[k] = v;
	return aaBase;
}

///
unittest {
	auto aa1 = ["x" : 1.0, "y": 2.0];
	auto aa2 = ["y":3.0];
	assert( aa1.merge( aa2 ) == ["x" : 1.0, "y": 3.0] );
	aa2 = ["y":3.0, "z":4.0];
	assert( aa1.merge( aa2 ) == ["x" : 1.0, "y": 3.0, "z":4.0] );
}

auto helpText = "Usage: plotcli [-o OUTPUT] [-d FORMAT]

Plotcli is a plotting program that will plot data from provided data streams (files). It will ignore any lines it doesn't understand, making it possible to feed it \"dirty\" streams/files. All options can also be provided within the stream by using the prefix #plotcli (e.g. #plotcli -d x,y).

Options:
  -d FORMAT		String describing the content of each row. Different row formats supported: x, y and h, with h indication histogram data. For example: x,y,y or h,x,y. When there are more ys provided than xs (or vice versa) the last x will be matched to all remaining ys.
  -o OUTPUT		Outputfile (without extension).

Data format:
  Using -d it is possible to specify what each column in your data file represents. Supported formats are:

  x,y		The x and y coordinate for points
  lx,ly	Line data
  h			Histogram data

  Plotcli by default does a good job of figuring out which x and y data belong together, but you can optionally provide an numeric id to make this completely clear. I.e. x1,y1.

  Finally if you want to plot the data to different figures you can add a letter/name at the end: xa,ya or x1a,y1a. This plot id will be appended to the OUTPUT file name. 

";

/* Future options

	--adaptive MODE (not adaptive, scrolling, full) First two need bounds or alternatively adaptive-cache for initial bounds 
	--adaptive-cache CACHESIZE (does it stop being adaptive after this or does it stop caching? Maybe combine with not adaptive or scrolling)
	--bounds BOUNDS (minx,maxx,miny,maxy) sets default MODE to not
	--image	IMAGETYPE (pdf,png)
	--xlabel XLABEL
	--ylabel YLABEL
	--debug 		Output lines that are not successfully parsed
  -f 					Follow: keep listening for new lines.

Future Data formats:
  hx,hy	2D Histogram data (Not supported yet)

You can also start a new plot by passing a new output file name in the stream (e.g. #plotcli -o newplot).

	*/

struct Settings {
	string[] rowMode = [];
	string outputFile = "plotcli";
}

unittest {
	Settings settings;
	assert( settings.rowMode.length == 0 );
	assert( settings.outputFile == "plotcli" );
}

Settings updateSettings( Settings settings, ArgValue[string] options ) {
	if ( !options["-d"].isNull ) 
	{
		settings.rowMode = options["-d"].to!string.split(',');
	}
	if ( !options["-o"].isNull )
		settings.outputFile = options["-o"].to!string;
	return settings;
}

unittest {
	Settings settings;
	auto args = docopt(helpText, [], true, "plotcli");
	assert( args["-d"].isNull );
	settings = settings.updateSettings( 
			docopt(helpText, [], true, "plotcli") );
	assert( settings.rowMode.length == 0 );
	assert( settings.outputFile == "plotcli" );

	settings = settings.updateSettings( 
			docopt(helpText, ["-d", "x,y"], true, "plotcli") );
	assert( equal( settings.rowMode, ["x","y"] ) );
	assert( settings.outputFile == "plotcli" );

	settings = settings.updateSettings( 
			docopt(helpText, ["-o", "name"], true, "plotcli") );
	args = docopt(helpText, ["-o", "name"], true, "plotcli");
	assert( equal( settings.rowMode, ["x","y"] ) );
	assert( settings.outputFile == "name" );
}
