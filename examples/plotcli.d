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
import std.stdio : readln, writeln;

import core.thread : Thread;
import core.time : dur;
import docopt;


import cli.parsing : handleMessage;
import cli.options : helpText, Settings, updateSettings;

/**
	Read from standard input and plot

	Mainly used to pipe data into

	myprogram > plotcli
	*/

/**
	Notes on next steps:
	Make an associative array with plots by plotID. (plots hold all events by dataID and all hist data by dataID and the plotstate of course)
	For each row do groupBy plotID, then dataID and finally create
	ParsedRow from those.
	Apply ParsedRow to the given plotID (passing an array of colors)
	*/
void main( string[] args ) {
	// Options
	auto doc = helpText;

	auto arguments = docopt.docopt(doc, args[1..$], true, "plotcli");
	Settings settings;
	settings = settings.updateSettings( arguments );

	auto msg = readln();

	while( settings.follow || msg.length > 0 ) {
		handleMessage( msg, settings );

		msg = readln();
		while ( settings.follow && msg.length == 0 ) // Got to end of file
		{
			Thread.sleep( dur!("msecs")( 100 ) );
			msg = readln();
		}
	}
}
