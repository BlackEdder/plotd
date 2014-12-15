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

import axes = plotd.axes : AdaptationMode;
import plotd.primitives : Bounds;

version( unittest ) {
	import std.algorithm : equal;
	import std.stdio : writeln;
	import docopt : docopt;
}

import cli.column;

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

auto helpText = "Usage: plotcli [-f] [-o OUTPUT] [-d FORMAT] [-b BOUNDS] [--xlabel XLABEL] [--ylabel YLABEL] [--margin-bounds MARGINBOUNDS]

Plotcli is a plotting program that will plot data from provided data streams (files). It will ignore any lines it doesn't understand, making it possible to feed it \"dirty\" streams/files. All options can also be provided within the stream by using the prefix #plotcli (e.g. #plotcli -d x,y).

Options:
  -f          Follow the stream, i.e. keep listening for new lines.
  -d FORMAT   String describing the content of each row. Different row formats supported: x, y and h, with h indication histogram data. For more information see Data format section.
  -o OUTPUT	  Outputfile (without extension).
  -b BOUNDS   Give specific bounds for the plot in a comma separated list (min_x,max_x,min_y,max_y).
  --xlabel XLABEL
  --ylabel YLABEL
  --margin-bounds MARGINBOUNDS  Specific bounds (in pixel size) for the margins. Format (all in pixels): xmargin,xwidth,ymargin,yheight. Default values 70,400,70,400.

Data format:
  Using -d it is possible to specify what each column in your data file represents. Supported formats are:

  x,y   The x and y coordinate for points
  lx,ly Line data
  h     Histogram data
  hx,hy 2D Histogram data 
  ..	  Extrapolate from previous options, i.e. x,y,.. -> x,y,x,y,..
  id    Default data id to use for this row of data (it is also possible to provide a column specific id (see Data ids below))
  pn    Default plot id id to use for this row of data (it is also possible to provide a column specific id (see Plot ids below))

  Examples: x,y,y or h,x,y. When there are more ys provided than xs (or vice versa) the last x will be matched to all remaining ys.

  Data ids: plotcli by default does a good job of figuring out which x and y data belong together, but you can optionally provide an numeric id to make this completely clear. I.e. x1,y1. Data ids always need to directly follow the format type (before plot ids).

  Plot ids: if you want to plot the data to different figures you can add a letter/name at the end: xa,ya or x1a,y1a. This plot id will be appended to the OUTPUT file name. 

  Extrapolating (..): plotcli will try to extrapolate from your previous options. This also works for simple plot ids. I.e. if you want a separate histogram for each column: ha,hb,.. results in ha,hb,hc,hd,he etc. Other examples: y,.. -> y,y,y,y etc. x,y,y,.. -> x,y,y,y,y etc.

";

/* Future options

	--adaptive MODE (not adaptive, scrolling, full) First two need bounds or alternatively adaptive-cache for initial bounds 
	--adaptive-cache CACHESIZE (does it stop being adaptive after this or does it stop caching? Maybe combine with not adaptive or scrolling)
	--bounds BOUNDS (minx,maxx,miny,maxy) sets default MODE to not
	--image	IMAGETYPE (pdf,png)
	--debug 		Output lines that are not successfully parsed
	*/

struct Settings {
	Formats formats;
	string outputFile = "plotcli";
	bool follow = false;
	auto adaptationMode = axes.AdaptationMode.full;
	Bounds plotBounds = Bounds( 0, 1, 0, 1 );
	Bounds marginBounds = Bounds( 70, 400, 70, 400 );
	string xlabel = "x";
	string ylabel = "y";
}

unittest {
	Settings settings;
	assert( settings.formats.empty );
	assert( settings.outputFile == "plotcli" );
}

Settings updateSettings( Settings settings, ArgValue[string] options ) {
	if ( !options["-d"].isNull ) 
	{
		settings.formats = parseDataFormat( options["-d"].to!string );
	}
	if ( !options["-o"].isNull )
		settings.outputFile = options["-o"].to!string;
	if ( options["-f"].isTrue )
		settings.follow = true;
	if ( !options["-b"].isNull ) {
		settings.adaptationMode = axes.AdaptationMode.none;
		settings.plotBounds = Bounds( options["-b"].to!string );
	}
	if ( !options["--margin-bounds"].isNull ) {
		settings.marginBounds = Bounds( options["--margin-bounds"].to!string );
	}	
	if ( !options["--xlabel"].isNull ) 
		settings.xlabel = options["--xlabel"].to!string;
	if ( !options["--ylabel"].isNull ) 
		settings.ylabel = options["--ylabel"].to!string;
	return settings;
}

unittest {
	Settings settings;
	auto args = docopt(helpText, [], true, "plotcli");
	assert( args["-d"].isNull );
	settings = settings.updateSettings( 
			docopt(helpText, [], true, "plotcli") );
	assert( settings.formats.empty );
	assert( settings.outputFile == "plotcli" );

	settings = settings.updateSettings( 
			docopt(helpText, ["-d", "x,y"], true, "plotcli") );
	assert( settings.formats.front.mode == "x" );
	assert( settings.outputFile == "plotcli" );

	settings = settings.updateSettings( 
			docopt(helpText, ["-o", "name"], true, "plotcli") );
	assert( settings.outputFile == "name" );
	assert( settings.follow == false );

	settings = settings.updateSettings( 
			docopt(helpText, ["-f"], true, "plotcli") );
	assert( settings.follow == true );
	settings = settings.updateSettings( 
			docopt(helpText, ["-o", "name"], true, "plotcli") );
	assert( settings.follow == true );

	// Bounds
	assert( settings.adaptationMode == AdaptationMode.full );
	settings = settings.updateSettings( 
			docopt(helpText, ["-b", "-10,9,12,15"], true, "plotcli") );
	assert( settings.adaptationMode == AdaptationMode.none );
	assert( settings.plotBounds == Bounds( -10,9,12,15 ) );
}
