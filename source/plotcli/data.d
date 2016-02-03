module plotcli.data;

import std.typecons : Tuple;

version( unittest )
{
    import dunit.toolkit;
}


import plotcli.options : Options, OptionRange;


auto aesDefaults()
{
    import ggplotd.aes : DefaultValues, merge;
    import ggplotd.colour : ColourID;
    return DefaultValues.merge(Tuple!(double, "x", double, "y",
        ColourID, "colour", string, "plotID", string, "type", 
        string, "plotname" )
        ( double.init, double.init, ColourID("black"), "", "", "plotcli") ); 
}

private int safeToIndex( string str )
{
    import std.conv : to;
    import std.range : empty;
    if (str.empty)
        return -1;
    else
        return str.to!int;
}

auto toTuples( string[] columns, Options options, int lineCount )
{
    // TODO use generate?
    struct Tuples
    {
        import std.regex : ctRegex, match;
        this( string[] columns, Options options, int lineCount )
        {
            import std.range : empty, repeat;
            import std.array : array;
            _columns = columns;
            _lineCount = lineCount;
            _options = options;
        }

        @property bool empty()
        {
            import std.conv : to;
            import std.range : empty, front;
            return ( 
                    (!_options.values["x"].empty 
                        && _options.values["x"].front.safeToIndex 
                            >= _columns.length.to!int) 
                || (!_options.values["y"].empty 
                        && _options.values["y"].front.safeToIndex 
                            >= _columns.length.to!int) 
                || (_options.values["x"].empty && _options.values["y"].empty)
                   );
        }

        @property auto front()
        {
            import std.conv : to;
            import std.range : empty, front;
            import ggplotd.aes : DefaultValues, merge;
            import ggplotd.colour : ColourID;
            import plotcli.parse : isInteger;

            auto tuple = aesDefaults().merge(Tuple!(double, "x", double, "y",
                ColourID, "colour" )
                ( lineCount.to!double, lineCount.to!double, ColourID(columnID) ) 
            );

            foreach( i, field; tuple.fieldNames )
            {
                if (field in _options.values && !_options.values[field].empty)
                {
                    auto f = _options.values[field].front;
                    if (f.isInteger)
                    {
                        tuple[i] = _columns[f.to!int].to!(typeof(tuple[i]));
                    } else if (!f.empty) {
                        tuple[i] = f.to!(typeof(tuple[i]));
                    }
                }
            }
            return tuple;
        }

        void popFront()
        {
            import std.range : empty, popFront;
            foreach( k, ref v; _options.values )
                if (!v.empty)
                    v.popFront;
            ++columnID;
        }

        string[] _columns;
        Options _options;
        int columnID = 0;
        int _lineCount;
    }

    return Tuples( columns, options, lineCount );
}

unittest
{
    Options options;
    options.values["y"] = OptionRange!string("1");

    auto ts = ["1","2","3"].toTuples( options, -1 );
    assertEqual( ts.front.x, -1 );
    assertEqual( ts.front.y, 2 );

    options.values["x"] = OptionRange!string("2");

    ts = ["1","2","3"].toTuples( options, -1 );
    assertEqual( ts.front.x, 3 );
    assert(!ts.empty);
    ts.popFront;
    assert(ts.empty);

    options.values["x"] = OptionRange!string("0,1,..");
    ts = ["1","2","3"].toTuples( options, -1 );
    assertEqual( ts.front.x, 1 );
    ts.popFront;
    assertEqual( ts.front.x, 2 );
    ts.popFront;
    assertEqual( ts.front.x, 3 );
    ts.popFront;
    assert( ts.empty );

    import plotcli.options : defaultOptions;
    options = defaultOptions();
    options.values["x"] = OptionRange!string("0,0,1,0,1");
    options.values["y"] = OptionRange!string(",2,,,");
    ts = ["0.04", "3.22", "-0.27"].toTuples( options, -1 );
    import std.stdio;
    assertEqual( ts.front.x, 0.04 );
    assertEqual( ts.front.y, -1 );
    ts.popFront;
    assertEqual( ts.front.x, 0.04 );
    assertEqual( ts.front.y, -0.27 );
}


