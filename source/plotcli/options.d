module plotcli.options;

import docopt;

version(unittest)
{
    import dunit.toolkit;
}

version(assert)
{
    import std.stdio : writeln;
}

import plotcli.parse : toRange;

private string addDashes( string arg )
{
    string dashes = "--";
    if (arg.length == 1)
        dashes = "-";
    return dashes ~ arg;
}

string helpText() // TODO cache result because will stay the same;
{
    import std.string : toUpper, leftJustify;
    import plotcli.data : aesDefaults;
    auto header = "Usage: plotcli [-f]";

    auto bodyText = "Plotcli is a plotting program that will plot data from provided data streams (files). It will ignore any lines it doesn't understand, making it possible to feed it \"dirty\" streams/files. All options can also be provided within the stream by using the prefix #plotcli (e.g. #plotcli -x 1 -y 2).

Options:
  -f                   Follow the stream, i.e. keep listening for new lines.";

    foreach( field; aesDefaults.fieldNames )
    {
        header ~= " [" ~ field.addDashes ~ " " ~ field.toUpper ~ "]";
        bodyText ~= "\n  " ~ leftJustify(field.addDashes ~ " " ~ field.toUpper,20)~ " Specify " ~ field ~ " either by indices or labels/names";
    }

    return header ~ "\n\n" ~ bodyText ~ "\n\nExamples:\n\tMost options allow you to specify indices or labels. If you provide integers (e.g. 0,2) they are interpreted as a column index (starting value 0), and that column is used as the values. For example passing `-x 0,1` will use the values from column 0 and 1 as x values. Any other value is used as a label. For example `--plotname name1,name2` will cause two plots to be created with the names name1 and name2. 
    Specifying a single value for each option, except x and y, will result in that value to be used for all different lines/column. For example `-x 0,1 --type box` will use the first and second column for box plots. Finally one can also use `..` to indicate keep repeating/increasing. So `-x 0,2,..` will cause all even columns to be used. Similarly `-x 0,1,2 -y 3,..` will result in the first three columns being used for x values, but the 4 column being used for y values. In general it is also possible to keep values empty if they are not needed, e.g. `-x 0,1,2 -y ,2 --type box,line,box`.\n";
}

private struct Options
{
    bool follow = false;

    OptionRange!string[string] values; 
    Options dup() const
    {
        Options opts;
        opts.follow = follow;
        opts.explicitly_initialised = explicitly_initialised;
        foreach(k, v; values)
            opts.values[k] = v.dup;
        return opts;
    }

    bool explicitly_initialised = false;
}

unittest {
    Options opts1;
    opts1.values["x"] = OptionRange!string("1,2");
    assertEqual(opts1.values["x"].front, "1");
    auto opts2 = opts1.dup;
    opts2.values["x"].popFront;
    assertEqual(opts1.values["x"].front, "1");
}

auto defaultOptions()
{
    import plotcli.data : aesDefaults;
    Options options;
    foreach( field; aesDefaults.fieldNames )
    {
        if (field != "x" && field != "y")
            options.values[ field ] = OptionRange!string( 
                "", true);
        else
            options.values[ field ] = OptionRange!string( 
                "", true);
    }

    options.values["y"] = OptionRange!string( "0", true );
    options.values["y"].delta = 1;
    return options;
}

unittest
{
    auto opts = defaultOptions();
    assert(!opts.follow);
}

import std.functional : memoize;

alias cachedDocopt = memoize!(docopt.docopt);

Options updateOptions(ref Options options, string[] args)
{
    import std.algorithm : map;
    import std.array : array;
    import std.conv : to;

    auto arguments = cachedDocopt(helpText, args, true, "plotcli", false);

    debug writeln("Added arguments: ", arguments);
    
    if (arguments["-f"].to!string == "true")
    {
        options.follow = true;
    }

    import plotcli.data : aesDefaults;
    foreach( field; aesDefaults.fieldNames )
    {
        if (!arguments[field.addDashes].isNull)
        {
            if (field != "x" && field != "y")
                options.values[ field ] = OptionRange!string( 
                    arguments[field.addDashes].to!string, true);
            else {
                if (!options.explicitly_initialised)
                {
                    options.values["y"] = OptionRange!string("",false);
                    options.explicitly_initialised = true;
                }

                options.values[ field ] = OptionRange!string( 
                    arguments[field.addDashes].to!string, false);
            }
        }
    }

    return options;
}

Options updateOptions(ref Options options, string message)
{
    import std.regex : match;

    auto m = message.match(r"^#plotcli (.*)");
    if (containOptions(message))
    {
        options = updateOptions(options, splitArgs(m.captures[1]));
    }
    return options;
}

bool containOptions( string message )
{
    import std.stdio;
    if (message.length < 9)
        return false;
    return (message[0..9] == "#plotcli ");
}

unittest
{
    assert( "#plotcli bla".containOptions );
    assert( !"#plotclibla".containOptions );
    assert( !"#pl".containOptions );
}
 
auto parseOptions(T)( T msg )
{
    auto opts = defaultOptions();
    return updateOptions( opts, msg );
}

unittest
{
    import std.array : array;
    import std.range : empty;
    Options options = defaultOptions;
    assertEqual( 
        updateOptions( options, "#plotcli -x 1,2,4" ).values["x"].array,
        ["1","2","4"] );
    assert( options.values["y"].empty ); 
    assert( !options.follow ); 

    assertEqual( 
        updateOptions( options, "#plotcli -y 3,2,4" ).values["y"].array,
        ["3","2","4"] );
    assertEqual( options.values["x"].array, ["1","2","4"] ); 
}

unittest
{
    // Test whether setting new value properly overrides defaults
    auto opts = defaultOptions;
    assertEqual( opts.values["y"].front, "0" );
    assertEqual( opts.values["y"].minimumExpectedIndex, 0 );
    assert( !opts.values["y"].empty );

    auto optsdup = opts.dup;
    optsdup.values["y"].popFront;
    assertEqual( optsdup.values["y"].front, "1" );

    // After change override it
    assert( updateOptions( opts, "#plotcli -x 0" ).values["y"].empty );

    assertEqual( updateOptions( opts, "#plotcli -y 3" ).values["y"].front, "3" );
    // If set explicitly (above) don't override it
    assert( !updateOptions( opts, "#plotcli -x 0" ).values["y"].empty );
}

/// Does the data fit with the given options?
bool validData(R1, R2)( R1 xColumns, R1 yColumns, in R2 columns )
{
    import std.algorithm : map, max, reduce, filter;
    import std.conv;
    import std.range : empty;
    import plotcli.parse : areNumeric, isInteger;
    if (xColumns.empty && yColumns.empty )
    {
        return ( columns.length > 0 && columns.areNumeric([0]));
    }
    auto maxCol = max(
            xColumns.minimumExpectedIndex,
            yColumns.minimumExpectedIndex );

    return (columns.length > maxCol 
            && columns.areNumeric(xColumns.filter!((a) => a.isInteger)
                                          .map!((a) => a.to!int)) 
            && columns.areNumeric(yColumns.filter!((a) => a.isInteger)
                                          .map!((a) => a.to!int)) 
           );
}

unittest
{
    assert( validData( OptionRange!string(""), OptionRange!string(""), 
                ["1","a", "-2"] ) );
    assert( validData( OptionRange!string("0,2"), OptionRange!string(""), 
                ["1","a", "-2"] ) );
    assert( validData( OptionRange!string(""), OptionRange!string("0,2"), 
                ["1","a", "-2"] ) );
    assert( !validData( OptionRange!string("1"), OptionRange!string("0,2"), 
                ["1","a", "-2"] ) );
    assert( validData( OptionRange!string(""), OptionRange!string("0,2,.."), 
                ["1","a", "-2"] ) );

    auto opy = OptionRange!string("0");
    opy.delta = 1;
    assert( validData( OptionRange!string(""), opy, 
                ["1","a", "-2"] ) );
}

/// Does the data fit with the given options?
bool validData(RANGE)( Options options, in RANGE columns )
{
    return validData( options.values["x"], options.values["y"], columns );
}

unittest
{
    auto options = defaultOptions;
    assert( !options.validData( ["1","a", "-2"] ) );
    options.values["x"] = OptionRange!string("0");
    options.values["y"] = OptionRange!string("0");
    assert( options.validData( ["1","a", "-2"] ) );
    options.values["y"] = OptionRange!string("0,2");
    assert( options.validData( ["1","a", "-2"] ) );
    assert( !options.validData( ["1","a"] ) );
    assert( !options.validData( ["1","a", "b"] ) );

    options = defaultOptions();
    options.values["x"] = OptionRange!string("0,0,1,0,1");
    options.values["y"] = OptionRange!string(",2,,,");
    assert( options.validData(["0.04", "3.22", "-0.27"]));
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
    import plotcli.parse : isInteger;
    if (original.length == 0)
        return "";
    else if (original.isInteger)
        return (original.to!int + delta).to!string;
    else if (original.length == 1)
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
    assertEqual( increaseString( "19", 1 ), "20" );
}

/// Range to correctly interpret 1,2,.. a,b,.. etc
struct OptionRange( T )
{
    this( string opts, bool repeat = false )
    {
        import std.array : array;
        import std.conv : to;
        import std.algorithm : splitter;
        import std.range : back, empty, popBack;

        splittedOpts = opts.splitter(',').array;

        if (splittedOpts.length == 1 && repeat)
            splittedOpts ~= [".."];

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

    @property auto save()
    {
        return this;
    }

    OptionRange!T dup() const
    {
        auto nOptionRange = OptionRange!T();
        nOptionRange.splittedOpts = splittedOpts.dup;
        nOptionRange.delta = delta;
        nOptionRange.extrapolatedValue = extrapolatedValue;
        return nOptionRange;
    }

 private:
    import std.regex : ctRegex;
    string[] splittedOpts;
    //auto csvRegex = ctRegex!(`,\s*`);
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

    assertEqual( OptionRange!string( ",.." ).take(4).array, 
        ["","","",""] );

    assertEqual( OptionRange!string( "a", true ).take(4).array, 
        ["a","a","a","a"] );

    assert( OptionRange!int( "" ).empty );
}


auto minimumExpectedIndex( R : OptionRange!U, U )(R r)
{
    // TODO This is not the best way of doing it.
    import std.algorithm : filter, map, reduce;
    import std.range : back;
    import plotcli.parse : isInteger;

    if (r.empty)
        return 0;

    auto rs = r.splittedOpts[0..$];
    if (r.splittedOpts.back == "..")
        rs = r.splittedOpts[0..$-1];

    return reduce!("max(a,b)")(0, 
        rs
        .filter!((a) => a.isInteger)
        .map!("a.to!int"));
}

auto minimumExpectedIndex( R )(R r)
{
    // TODO This is not the best way of doing it.
    import std.algorithm : map, reduce;
    import std.range : back;
    return reduce!("max(a,b)")(0, r);
}

unittest
{
    assertEqual( OptionRange!string( ",2,," ).minimumExpectedIndex, 2 );
}
