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
    string basename = "plotcli";
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
    if (!arguments["-o"].isNull)
    {
        options.basename = arguments["-o"].to!string;
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

    assertEqual( options.basename, "plotcli" );

    assertEqual( 
        updateOptions( options, "#plotcli -o test" ).basename,
        "test" );
}

/// Does the data fit with the given options?
bool validData(RANGE)( in Options options, in RANGE columns )
{
    import std.algorithm : reduce;
    import std.range : empty;
    import plotcli.parse : areNumeric;
    auto allCols = options.xColumns ~ options.yColumns;
    if (allCols.empty)
        allCols = [0];
    auto maxCol = reduce!("max(a,b)")(1, options.xColumns ~ options.yColumns);

    return (columns.length > maxCol && columns.areNumeric(allCols));
}

unittest
{
    Options options;
    assert( options.validData( ["1","a", "-2"] ) );
    options.xColumns = [0];
    options.yColumns = [0];
    assert( options.validData( ["1","a", "-2"] ) );
    options.yColumns = [0,2];
    assert( options.validData( ["1","a", "-2"] ) );
    assert( !options.validData( ["1","a"] ) );
    assert( !options.validData( ["1","a", "b"] ) );
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

private string increaseString( string original, int delta )
{
    import std.conv : to;
    import std.range : back;
    if (original.length == 1)
        return (original.back.to!char + delta)
                        .to!char
                        .to!string;
    else
        return original[0..$-1] ~ (original.back.to!char + delta)
                        .to!char
                        .to!string;

}

unittest
{
    assertEqual( increaseString( "a", 0 ), "a" );
    assertEqual( increaseString( "a", 1 ), "b" );
    assertEqual( increaseString( "c", 2 ), "e" );
    assertEqual( increaseString( "cd", 1 ), "ce" );
}

/// Range to correctly interpret 1,2,.. a,b,.. etc
struct OptionRange( T )
{
    this( string opts )
    {
        import std.array : array;
        import std.conv : to;
        import std.regex : split;
        import std.range : back, popBack;

        splittedOpts = opts.split(csvRegex).array;

        if (splittedOpts.back == "..")
        {
            // Calculate the delta
            static if (is(T==string))
            {
                if (splittedOpts.length > 2)
                    delta = splittedOpts[$-2].back.to!char - 
                        splittedOpts[$-3].back.to!char;
            } else {
                if (splittedOpts.length > 2)
                    delta = splittedOpts[$-2].to!int - splittedOpts[$-3].to!int;
            }
        }
    }

    @property bool empty()
    {
        import std.range : empty, front;
        return splittedOpts.empty;
    }

    @property T front()
    {
        import std.conv : to;
        import std.range : front;
        if (splittedOpts.front == "..")
            return extrapolatedValue;
        return splittedOpts.front.to!T;
    }

    void popFront()
    {
        import std.conv : to;
        import std.range : back, empty, front, popFront;
        auto tmpCache = splittedOpts.front;
        if (splittedOpts.front != "..")
        {
            splittedOpts.popFront();
        }
        if (!splittedOpts.empty && splittedOpts.front == "..")
        {
            if (tmpCache != "..")
            {
                extrapolatedValue = tmpCache.to!T;
            }
            static if (is(T==string))
                extrapolatedValue = increaseString(extrapolatedValue, delta);
            else 
                extrapolatedValue += delta;
        }
    }

private:
    import std.regex : ctRegex;
    string[] splittedOpts;
    auto csvRegex = ctRegex!(`,\s*`);
    int delta = 0;
    T extrapolatedValue;
}

unittest
{
    import std.array;
    import std.range : take;
    assertEqual( OptionRange!int( "1,2,3" ).array, 
        [1,2,3] );
    assertEqual( OptionRange!int( "5,6,.." ).take(4).array, 
        [5,6,7,8] );
    assertEqual( OptionRange!int( "1,3,.." ).take(4).array, 
        [1,3,5,7] );
    assertEqual( OptionRange!int( "1,.." ).take(4).array, 
        [1,1,1,1] );
    assertEqual( OptionRange!string( "1,2,3" ).array, 
        ["1","2","3"] );
    assertEqual( OptionRange!string( "c,d,.." ).take(4).array, 
        ["c","d","e","f"] );
    assertEqual( OptionRange!string( "ac,ad,.." ).take(4).array, 
        ["ac","ad","ae","af"] );
    assertEqual( OptionRange!string( "bc,.." ).take(4).array, 
        ["bc","bc","bc","bc"] );
 }
