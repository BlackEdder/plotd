module plotcli.options;

import docopt;

version(unittest)
{
    import dunit.toolkit;
}

import plotcli.parse : toRange;

auto helpText = "Usage: plotcli [-f] [-o OUTPUT] [-x XCOLUMNS] [-y YCOLUMNS] [--type TYPE]

Plotcli is a plotting program that will plot data from provided data streams (files). It will ignore any lines it doesn't understand, making it possible to feed it \"dirty\" streams/files. All options can also be provided within the stream by using the prefix #plotcli (e.g. #plotcli -x 1 -y 2).

Options:
  -f          Follow the stream, i.e. keep listening for new lines.
  -x XCOLUMNS String describing the columns containing x coordinates.
  -y YCOLUMNS String describing the columns containing y coordinates.
  -o OUTPUT	  Outputfile (without extension).
  --type TYPE Type of data (line, point, hist)

";

struct Options
{
    int[] xColumns;
    int[] yColumns;
}

import std.functional : memoize;

alias cachedDocopt = memoize!(docopt.docopt);

Options updateOptions(ref Options options, string[] args)
{
    import std.algorithm : map;
    import std.array : array;
    import std.conv : to;

    auto arguments = cachedDocopt(helpText, args, true, "plotcli", false);
    if (!arguments["-x"].isNull)
    {
        options.xColumns = arguments["-x"].to!string.toRange // This should be smarted and interpret ,..
        .map!((a) => a.to!int).array;
    }
    if (!arguments["-y"].isNull)
    {
        options.yColumns = arguments["-y"].to!string.toRange // This should be smarted and interpret ,..
        .map!((a) => a.to!int).array;
    }
    return options;
}

Options updateOptions(ref Options options, string message)
{
    import std.regex : match;

    auto m = message.match(r"^#plotcli (.*)");
    if (m)
    {
        options = updateOptions(options, splitArgs(m.captures[1]));
    }
    return options;
}

unittest
{
    import std.range : empty;
    Options options;
    assertEqual( 
        updateOptions( options, "#plotcli -x 1,2,4" ).xColumns,
        [1,2,4] );
    assert( options.yColumns.empty ); 
    assertEqual( 
        updateOptions( options, "#plotcli -y 3,2,4" ).yColumns,
        [3,2,4] );
    assertEqual( options.xColumns, [1,2,4] ); 
}

string[] splitArgs(string args)
{
    import std.conv : to;

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
            else
                inner = true;
        }
        else
            curr ~= s;
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
