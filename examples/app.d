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
import std.datetime : Clock, SysTime;
import core.thread : Thread;
import core.time : dur;
import docopt;
import plotcli.figure : Figure;
import plotcli.parsing : handleMessage, plotFigures, saveFigures;
import plotcli.options : helpText, Settings, updateSettings;
/**
	Read from standard input and plot

	Mainly used to pipe data into
	*/

void drawAndSave(ref Figure[string] figures, ref Settings settings)
{
    debug writeln("Plotting figures");
    plotFigures(figures, settings);
    saveFigures(figures);
}

void main(string[] args)
{
    // Options
    debug writeln("Arguments: ", args);
    auto doc = helpText;
    auto arguments = docopt.docopt(doc, args[1 .. $], true, "plotcli");
    Settings settings;
    settings = settings.updateSettings(arguments);
    auto msg = readln();
    SysTime lastTime;
    Figure[string] figures;
    while (settings.follow || msg.length > 0)
    {
        figures = handleMessage(msg, settings);
        msg = readln();
        bool waiting = false;
        while (settings.follow && msg.length == 0)
             // Got to end of file
            
            {
                if (!waiting)
                 // Always draw once when waiting
                drawAndSave(figures, settings);
            waiting = true;
            Thread.sleep(dur!("msecs")(100));
            msg = readln();
        }
        auto curr = Clock.currTime;
        if (settings.follow)
        {
            if (curr - lastTime > dur!("msecs")(500))
            {
                drawAndSave(figures, settings);
                lastTime = curr;
            }
        }
    }
    plotFigures(figures, settings);
    scope(exit) saveFigures(figures);
    scope(failure) saveFigures(figures);
}
