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

module cli.column;

import std.conv : to;
import std.regex : ctRegex, match;
import std.range;
import std.string;

version( unittest ) {
	import std.stdio : writeln;
}

struct Format {
	string mode; /// x,y,lx,ly,h
	int dataID = -1; /// -1 is the default value
	string plotID; /// plotName/id 
}

Format parseColumnFormat( string mode ) {
	Format colMode;
	auto columnRegex = ctRegex!( r"(lx|ly|x|y|hx|hy|hz|h|..)(\d*)(.*)" );
	auto m = mode.match( columnRegex );
	colMode.mode = m.captures[1];
	if ( m.captures[2].length > 0 )
		colMode.dataID = m.captures[2].to!int;
	colMode.plotID = m.captures[3];
	return colMode;
}

unittest {
	auto col = parseColumnFormat( "lx1a" );
	assert( col.mode == "lx" );
	assert( col.dataID == 1 );
	assert( col.plotID == "a" );
	col = parseColumnFormat( "ly1a" );
	assert( col.mode == "ly" );
	col = parseColumnFormat( "xb" );
	assert( col.mode == "x" );
	assert( col.dataID == -1 );
	assert( col.plotID == "b" );

	col = parseColumnFormat( "y3" );
	assert( col.mode == "y" );
	assert( col.dataID == 3 );
	assert( col.plotID == "" );

	col = parseColumnFormat( "hx" );
	assert( col.mode == "hx" );
	col = parseColumnFormat( "hy" );
	assert( col.mode == "hy" );
	col = parseColumnFormat( "h" );
	assert( col.mode == "h" );
}
/// Return true if Format represents an x value
bool xCoord( Format cm ) {
	return cm.mode.back.to!string == "x";
}

unittest {
	auto cm = Format();
	cm.mode = "x";
	assert( cm.xCoord );
	cm.mode = "lx";
	assert( cm.xCoord );
	cm.mode = "yx";
	assert( cm.xCoord );
	cm.mode = "y";
	assert( !cm.xCoord );
	cm.mode = "ly";
	assert( !cm.xCoord );
	cm.mode = "xy";
	assert( !cm.xCoord );
}

/// Return true if Format represents an y value
bool yCoord( Format cm ) {
	return cm.mode.back.to!string == "y";
}

unittest {
	auto cm = Format();
	cm.mode = "y";
	assert( cm.yCoord );
	cm.mode = "ly";
	assert( cm.yCoord );
	cm.mode = "xy";
	assert( cm.yCoord );
	cm.mode = "x";
	assert( !cm.yCoord );
	cm.mode = "lx";
	assert( !cm.yCoord );
	cm.mode = "yx";
	assert( !cm.yCoord );
}

///
struct Formats {

	this( size_t noColumns ) {
		if (noColumns > 1)
			_formats = parseDataFormat( "x,y,.." )._formats;
		else
			_formats = parseDataFormat( "h,.." )._formats;
	}

	@property Format front() {
		auto fm = _formats.front;
		if ( _formats.length == 1 && fm.mode == ".." ) {
			auto pfm = prevFormats[dotdotID%prevFormats.length];

			// Increase plot ID if needed
			if ( prevFormats.length == 2 
					&& prevFormats[0].plotID.length > 0
					&& prevFormats[1].plotID.length > 0 ) {
				pfm.plotID = pfm.plotID[0..$-1] ~
					(prevFormats[1].plotID.back.to!char + 
					 (1+dotdotID)*(prevFormats[1].plotID.back.to!char -
						prevFormats[0].plotID.back.to!char)).to!char.to!string;
			}
			return pfm;
		}
		return fm;
	}

	void popFront() {
		if (_formats.length <= 3 && prevFormats.length == 0
				&& _formats.back.mode == "..") {
			prevFormats = _formats[0..$-1].dup;
		}
		if (_formats.front.mode != ".." ) 
			_formats.popFront;
		else
			dotdotID++;
	}

	@property bool empty() {
		return _formats.empty;
	}

	private:
		Format[] _formats;
		Format[] prevFormats;
		size_t dotdotID = 0;
}

///
Formats parseDataFormat( string dataFormat ) {
	Formats formats;
	foreach( fm; dataFormat.split( ',' ) ) {
		formats._formats ~= parseColumnFormat( fm ); 
	}
	return formats;
}

unittest {
	auto fmts = parseDataFormat( "x,y" );
	assert( fmts.front.mode == "x" );
	fmts = parseDataFormat( "x,.." );
	fmts.popFront;
	assert( fmts.front.mode == "x" );
	fmts.popFront;
	assert( fmts.front.mode == "x" );
	fmts = parseDataFormat( "x,y,.." );
	fmts.popFront;
	fmts.popFront;
	assert( fmts.front.mode == "x" );
	fmts.popFront;
	assert( fmts.front.mode == "y" );
	fmts = parseDataFormat( "haa,hab,.." );
	fmts.popFront;
	fmts.popFront;
	assert( fmts.front.plotID == "ac" );
	fmts.popFront;
	assert( fmts.front.plotID == "ad" );
	fmts.popFront;
	assert( fmts.front.plotID == "ae" );
}

///
bool validFormat( Formats formats, size_t noColumns ) {
	if ( formats._formats.length == noColumns ||
			formats._formats.back.mode == ".." 	) {
		return true;
	}
	return false;
}

/// Format and data of a specific column
struct ColumnData {
	double value;

	this( Format fm ) {
		_format = fm;
	}

	this( string mode, int dataID, string plotID, double v ) {
		_format.mode = mode;
		_format.dataID = dataID;
		_format.plotID = plotID;
		value = v;
	}

	alias _format this;

	Format _format;
}

unittest {
	auto fm = Format( "lx", 1, "a" );
	ColumnData cm = ColumnData( fm );
	assert( cm.mode == "lx" );
	assert( cm.dataID == 1 );
	assert( cm.plotID == "a" );
}
