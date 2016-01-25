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
    OptionRange!int xColumns;
    OptionRange!int yColumns;
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
        options.xColumns = OptionRange!int(arguments["-x"].to!string);
    }
    if (!arguments["-y"].isNull)
    {
        options.yColumns = OptionRange!int(arguments["-y"].to!string);
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
    import std.array : array;
    import std.range : empty;
    Options options;
    assertEqual( 
        updateOptions( options, "#plotcli -x 1,2,4" ).xColumns.array,
        [1,2,4] );
    assert( options.yColumns.empty ); 
    assertEqual( 
        updateOptions( options, "#plotcli -y 3,2,4" ).yColumns.array,
        [3,2,4] );
    assertEqual( options.xColumns.array, [1,2,4] ); 

    assertEqual( options.basename, "plotcli" );

    assertEqual( 
        updateOptions( options, "#plotcli -o test" ).basename,
        "test" );
}

/// Does the data fit with the given options?
bool validData(R1, R2)( R1 xColumns, R1 yColumns, in R2 columns )
{
    import std.algorithm : max, reduce;
    import std.range : empty;
    import plotcli.parse : areNumeric;
    if (xColumns.empty && yColumns.empty )
    {
        return ( columns.length > 0 && columns.areNumeric([0]));
    }
    auto maxCol = max(
            xColumns.minimumExpectedIndex,
            yColumns.minimumExpectedIndex );

    return (columns.length > maxCol 
            && columns.areNumeric(xColumns) 
            && columns.areNumeric(yColumns) 
           );
}

unittest
{
    assert( validData( OptionRange!int(""), OptionRange!int(""), 
                ["1","a", "-2"] ) );
    assert( validData( OptionRange!int("0,2"), OptionRange!int(""), 
                ["1","a", "-2"] ) );
    assert( validData( OptionRange!int(""), OptionRange!int("0,2"), 
                ["1","a", "-2"] ) );
    assert( !validData( OptionRange!int("1"), OptionRange!int("0,2"), 
                ["1","a", "-2"] ) );
    assert( validData( OptionRange!int(""), OptionRange!int("0,2,.."), 
                ["1","a", "-2"] ) );
}

/// Does the data fit with the given options?
bool validData(RANGE)( Options options, in RANGE columns )
{
    return validData( options.xColumns, options.yColumns, columns );
}

unittest
{
    Options options;
    assert( options.validData( ["1","a", "-2"] ) );
    options.xColumns = OptionRange!int("0");
    options.yColumns = OptionRange!int("0");
    assert( options.validData( ["1","a", "-2"] ) );
    options.yColumns = OptionRange!int("0,2");
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
        import std.range : back, empty, popBack;

        splittedOpts = opts.split(csvRegex).array;

        if (!splittedOpts.empty && splittedOpts.back == "..")
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

    assert( OptionRange!int( "" ).empty );
}


auto minimumExpectedIndex( R : OptionRange!U, U )(R r)
{
    static if (is(u==string))
        return "";
    else
    {
        // TODO This is not the best way of doing it.
        import std.algorithm : map, reduce;
        import std.range : back;
        if (r.empty)
            return 0;
        if (r.splittedOpts.back == "..")
            return reduce!("max(a,b)")(0, r.splittedOpts[0..$-1].map!("a.to!int"));
        else
            return reduce!("max(a,b)")(0, r.splittedOpts[0..$].map!("a.to!int"));
    }
}

auto minimumExpectedIndex( R )(R r)
{
    // TODO This is not the best way of doing it.
    import std.algorithm : map, reduce;
    import std.range : back;
    return reduce!("max(a,b)")(0, r);
}
