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

module plotcli.parsing;

import std.algorithm;
import std.conv : ConvException, to;
import std.functional : memoize;
import std.math : isNaN;
import std.range;
import std.regex : regex, replaceFirst;
import std.stdio : write, writeln;
import std.string;
import std.regex : ctRegex, match, split;
import docopt;
import axes = plotd.axes : AdaptationMode;
import plotd.data.binning;
import plotd.drawing;
import plotd.plot;
import plotd.primitives;
import plotcli.algorithm : groupBy;
import plotcli.column;
import plotcli.figure : drawHistogram, drawBoxPlot, Figure, getColor, PlotInterface;
import plotcli.options : helpText, Settings, updateSettings;

version(unittest)
{
    import std.stdio;

}
alias Event = void delegate(PlotInterface plot);
private auto csvRegex = ctRegex!(`,\s*|\s`);
string[] toRange(string line)
{
    // Cut of any comments
    line = line.replaceFirst(regex("#.*"), "");
    return line.split(csvRegex).map!((d) => d.strip(' ')).array.filter!("a!=\"\"")
        .array;
}

unittest
{
    assert(("1,2").toRange == ["1", "2"]);
    assert(("1,2 #bla").toRange == ["1", "2"]);
    assert(("#bla").toRange == []);
    assert(("0.5, 2").toRange == ["0.5", "2"]);
    assert(("bla, 2").toRange == ["bla", "2"]);
    assert(("1\t2").toRange == ["1", "2"]);
    assert(("1 2").toRange == ["1", "2"]);
    assert(("nan, 2").toRange == ["nan", "2"]);
}

Point[] toPoints(double[] coords)
{
    Point[] points;
    if (coords.length >= 2)
        points ~= Point(coords[0], coords[1]);
    return points;
}

unittest
{
    assert([1.0].toPoints.length == 0);
    assert(equal([1.0, 2.0].toPoints, [Point(1, 2)]));
}


// Workaround point not properly copied in foreach loop
void delegate(PlotState!"png") createColorEvent(Color col)
{
    return delegate(PlotState!"png"plot)
    {
        plot.plotContext = color(plot.plotContext, col);
    }

    ;
}


// Workaround point not properly copied in foreach loop
void delegate(PlotState!"png") createPointEvent(Point point)
{
    return delegate(PlotState!"png"plot)
    {
        plot.plotContext = drawPoint(point, plot.plotContext);
    }

    ;
}


// Workaround point not properly copied in foreach loop
void delegate(PlotState!"png") createLineEvent(Point toP, Point fromP)
{
    return delegate(PlotState!"png"plot)
    {
        plot.plotContext = drawLine(toP, fromP, plot.plotContext);
    }

    ;
}


/// Struct to hold the different points etc
struct ParsedRow
{
    Point[] points;
    Point[] linePoints;
    Point[] histPoints;
    double[] histData;
    double[] boxData;
}


// Warning assumes array with either one x or one y value.
private Point[] columnDataToPoints(ColumnData[] cMs, double defaultCoord)
{
    Point[] pnts;
    if (cMs.length == 0)
        return pnts;
    auto coords = cMs.groupBy!((cm)
    {
        if (cm.xCoord)
            return "x";
        return "y";
    }

    );
    if ("x"!in coords)
    {
        return coords["y"].map!((cmy) => Point(defaultCoord, cmy.value)).array;
    }
    else if ("y"!in coords)
    {
        return coords["x"].map!((cmx) => Point(cmx.value, defaultCoord)).array;
    }
    else if (coords["x"].length == 1)
    {
        return coords["y"].map!((cmy) => Point(coords["x"].front.value, cmy
            .value)).array;
    }
    else if (coords["y"].length == 1)
    {
        return coords["x"].map!((cmx) => Point(cmx.value, coords["y"].front
            .value)).array;
    }
    assert(0, "Invalid input for columnModeToPoints " ~ cMs.to!string);
}


/** Turn columns into drawable results. If no x or y value is present then columnID is used as the x or y value;

	This function tries to be relative human like in parsing and the logic is difficult to follow. See the unittests for its behaviour
	*/

ParsedRow applyColumnData(ColumnData[] cMs, size_t columnID)
{
    ParsedRow parsed;
    foreach (type, groupedCMs; cMs.groupBy!((cm)
    {
        if (cm.mode.to!string == "")
            return "none";
        if (cm.mode.front.to!string == "l")
            return "line";
        if (cm.mode.front.to!string == "h")
            return "hist";
        if (cm.mode.front.to!string == "b")
            return "box";
        return "point";
    }

    ))
    {
        if (type != "none")
        {
            ColumnData[] xyGroup;
            size_t xs = 0;
            size_t ys = 0;
            double lastX; // If x is used set lastX to isNaN?
            double lastY;
            Point[] addRange;
            foreach (cM; groupedCMs)
            {
                if (cM.xCoord || cM.yCoord)
                {
                    if (xs > 1 && ys > 1)
                    {
                        // We never want a group with more than 1 x coord or y coord
                        xs = 0;
                        ys = 0;
                        addRange ~= columnDataToPoints(xyGroup[0 .. $ - 1], columnID);
                        xyGroup = [xyGroup.back];
                    }
                    else if (xs >= 1 && ys >= 1 && xyGroup.back.mode != cM.mode)
                    {
                        xs = 0;
                        ys = 0;
                        addRange ~= columnDataToPoints(xyGroup, columnID);
                        xyGroup = [cM];
                    }
                    else xyGroup ~= cM;
                    if (cM.xCoord)
                    {
                        lastX = cM.value;
                        xs++;
                    }
                    else if (cM.yCoord)
                    {
                        lastY = cM.value;
                        ys++;
                    }
                }
                else
                {
                    if (type == "hist")
                        parsed.histData ~= cM.value;
                    else if (type == "box")
                        parsed.boxData ~= cM.value;
                }
            }
            if (xyGroup.length > 0)
            {
                // If we found no x or y coord at all then use columnID
                if (lastX.isNaN || lastY.isNaN)
                    addRange ~= columnDataToPoints(xyGroup, columnID);
                else if (xyGroup.front.xCoord)
                    addRange ~= columnDataToPoints(xyGroup, lastY);
                else addRange ~= columnDataToPoints(xyGroup, lastX);
            }
            if (type == "line")
            {
                parsed.linePoints ~= addRange;
            }
            else if (type == "point")
                parsed.points ~= addRange;
            else if (type == "hist")
                parsed.histPoints ~= addRange;
        }
    }
    return parsed;
}

unittest
{
    ColumnData cm(string mode, double value)
    {
        return ColumnData(mode, "", "", value);
    }

    auto pr = applyColumnData([cm("x", 1), cm("y", 2)], 0);
    assert(pr.points == [Point(1, 2)]);
    pr = applyColumnData([cm("x", 3), cm("y", 2), cm("y", 4)], 0);
    assert(pr.points == [Point(3, 2), Point(3, 4)]);
    pr = applyColumnData([cm("x", 1)], 5);
    assert(pr.points == [Point(1, 5)]);
    pr = applyColumnData([cm("x", 1), cm("x", 3)], 5);
    assert(pr.points == [Point(1, 5), Point(3, 5)]);
    pr = applyColumnData([cm("y", 2)], 5);
    assert(pr.points == [Point(5, 2)]);
    pr = applyColumnData([cm("y", 2), cm("y", 4)], 5);
    assert(pr.points == [Point(5, 2), Point(5, 4)]);
    pr = applyColumnData([cm("y", 2), cm("x", 1), cm("y", 4), cm("y", 6)], 5);
    assert(pr.points == [Point(1, 2), Point(1, 4), Point(1, 6)]);
    pr = applyColumnData([cm("x", 2), cm("y", 1), cm("x", 4), cm("x", 6)], 5);
    assert(pr.points == [Point(2, 1), Point(4, 1), Point(6, 1)]);
    pr = applyColumnData([cm("y", 2), cm("x", 1), cm("y", 4), cm("x", 3)], 5);
    assert(pr.points == [Point(1, 2), Point(3, 4)]);
    pr = applyColumnData([cm("y", 2), cm("y", 8), cm("x", 1), cm("y", 4), cm("y", 6), cm("x",
        3)], 5);
    assert(pr.points == [Point(1, 2), Point(1, 8), Point(3, 4), Point(3, 6)]);
    pr = applyColumnData([cm("x", 2), cm("y", 8), cm("y", 1), cm("x", 4), cm("y", 6), cm("y",
        3)], 5);
    assert(pr.points == [Point(2, 8), Point(2, 1), Point(4, 6), Point(4, 3)]);
    // Lines
    // Should really be more indepth, but since same code is used, as for
    // points should be ok
    pr = applyColumnData([cm("lx", 1), cm("ly", 2)], 0);
    assert(pr.linePoints == [Point(1, 2)]);
    pr = applyColumnData([cm("x", 2), cm("y", 8), cm("lx", 11), cm("y", 1), cm("x", 4), cm("y",
        6), cm("y", 3)], 5);
    assert(pr.points == [Point(2, 8), Point(2, 1), Point(4, 6), Point(4, 3)]);
    assert(pr.linePoints == [Point(11, 5)]);
    // Hist
    pr = applyColumnData([cm("h", 1.1), cm("h", 2.1)], 0);
    assert(pr.histData == [1.1, 2.1]);
    pr = applyColumnData([cm("x", 2), cm("h", 1.1), cm("y", 8), cm("lx", 11), cm("y", 1), cm("x",
        4), cm("h", 2.1), cm("y", 6), cm("y", 3)], 5);
    assert(pr.points == [Point(2, 8), Point(2, 1), Point(4, 6), Point(4, 3)]);
    assert(pr.linePoints == [Point(11, 5)]);
    assert(pr.histData == [1.1, 2.1]);
    pr = applyColumnData([cm("hx", 1.1), cm("hy", 2.1)], 0);
    assert(pr.histPoints == [Point(1.1, 2.1)]);

    // Box data
    pr = applyColumnData([cm("b", 1.1), cm("b", 2.1)], 0);
    assert(pr.boxData == [1.1, 2.1]);
}


/// Check whether current RowMode makes sense for new data.
Formats updateFormat(string[] columns, Formats formats)
{
    if (columns.length == 0)
        return formats;
    if (formats.validFormat(columns))
        return formats;
    else if (columns.find!((a) => !a.isNumeric).length > 0)
        return formats;
    else
    {
        debug writeln("Changing format to default format");
        return Formats(columns.length);
    }
}

unittest
{
    auto formats = updateFormat(("1,2").toRange, parseDataFormat("x,y"));
    assert(formats.front.mode == "x");
    formats = updateFormat(("1,2").toRange, parseDataFormat("y,y,y"));
    assert(formats.front.mode == "x");
    formats = updateFormat(("a,2").toRange, parseDataFormat("y,y,y"));
    assert(formats.front.mode == "y");
}

private string[] splitArgs(string args)
{
    string[] splitted;
    bool inner = false;
    string curr = "";
    foreach (s; args)
    {
        if (s == (" ").to!char && !inner)
        {
            splitted ~= curr;
            curr = "";
        }
        else if (s == ("\"").to!char || s == ("\'").to!char)
        {
            if (inner)
                inner = false;
            else inner = true;
        }
        else curr ~= s;
    }
    splitted ~= curr;
    return splitted;
}

unittest
{
    assert(("-b arg").splitArgs.length == 2);
    assert(("-b \"arg b\"").splitArgs.length == 2);
    assert(("-b \"arg b\" -f").splitArgs.length == 3);
}

alias cachedDocopt = memoize!(docopt.docopt);
// High level functionality for handlingMessages
Figure[string] handleMessage(string msg, ref Settings settings)
{
    static Figure[string] figures;
    debug write("Received message: ", msg);
    auto m = msg.match(r"^#plotcli (.*)");
    if (m)
    {
        settings = settings.updateSettings(cachedDocopt(helpText, splitArgs(m
            .captures[1]), true, "plotcli", false));
        //writeln( settings );
    }
    auto columns = msg.strip.toRange;
    debug writeln("Converted to columns: ", columns);
    settings.formats = updateFormat(columns, settings.formats);
    if (validFormat(settings.formats, columns))
    {
        auto columnData = settings.formats.zip(columns).map!((mv)
        {
            auto cD = ColumnData(mv[0]);
            if (cD.mode.length > 0)
                cD.value = mv[1].to!double;
            return cD;
        }

        );
        foreach (plotID, cMs1; columnData.groupBy!((cm) => cm.plotID))
        {
            if (plotID.length == 0)
                foreach (i; settings.formats.defaultPlotIDColumns)
                plotID ~= columns[i];
            plotID = settings.outputFile ~ plotID;
            if (plotID!in figures)
            {
                figures[plotID] = new Figure(plotID, settings.imageFormat,
                    settings.plotBounds, settings.marginBounds);
                figures[plotID].lf.xlabel = settings.xlabel;
                figures[plotID].lf.ylabel = settings.ylabel;
            }
            auto figure = figures[plotID];
            figure.lf.adaptationMode = settings.adaptationMode;
            foreach (dataID, cMs; cMs1.groupBy!((cm) => cm.dataID))
            {
                if (dataID.length == 0)
                    foreach (i; settings.formats.defaultDataIDColumns)
                    dataID ~= columns[i];
                debug writeln("plotID: ", plotID, " dataID: ", dataID);
                debug writeln("Plotting data: ", cMs);
                auto parsedRow = applyColumnData(cMs, figures[plotID]
                    .columnCount);
                foreach (i; 0 .. parsedRow.points.length)
                {
                    if (dataID.length == 0)
                    {
                        figure.lf.color = figure.getColor(dataID, i);
                    }
                    else
                    {
                        figure.lf.color = figure.getColor(dataID);
                    }
                    figure.lf.point = parsedRow.points[i];
                }
                if (dataID!in figures[plotID].previousLines)
                {
                    Point[] pnts;
                    figures[plotID].previousLines[dataID] = pnts;
                }
                if (figures[plotID].previousLines[dataID].length == parsedRow
                    .linePoints.length)
                {
                    foreach (i; 0 .. parsedRow.linePoints.length)
                    {
                        if (dataID.length == 0)
                        {
                            figure.lf.color = figure.getColor(dataID, i);
                        }
                        else
                        {
                            figure.lf.color = figure.getColor(dataID);
                        }
                        figure.lf.line(figures[plotID].previousLines[dataID][i],
                            parsedRow.linePoints[i]);
                    }
                }
                if (parsedRow.linePoints.length > 0)
                    figures[plotID].previousLines[dataID] = parsedRow.linePoints;
                // Histograms
                figures[plotID].histData ~= parsedRow.histData;
                figures[plotID].histPoints ~= parsedRow.histPoints;

                // Box plot
                figures[plotID].boxData ~= [parsedRow.boxData];
            }
            figures[plotID].columnCount += 1;
        }
    }
    return figures;
}


// TODO: Add better tests valid columns etc

void plotFigures(Figure[string] figures, Settings settings)
{
    foreach (plotID, figure; figures)
    {
        drawHistogram(figure);
        drawBoxPlot(figure);
        figure.lf.plot();
    }
}

void saveFigures(Figure[string] figures)
{
    foreach (_, figure; figures)
    {
        debug writeln("Saving to file");
        figure.lf.save();
    }
}
