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
	import std.stdio;
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

struct Settings {
	string[] rowMode;
}

Settings updateSettings( Settings settings, ArgValue[string] options ) {
	if ( options["-d"] ) {
		settings.rowMode = options["FORMAT"].to!string.split(',');
	}
	return settings;
}
