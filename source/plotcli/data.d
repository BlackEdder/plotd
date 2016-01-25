module plotcli.data;

import std.typecons : Tuple;

version( unittest )
{
    import dunit.toolkit;
}

import ggplotd.colour : ColourID;

import plotcli.options : Options, OptionRange;

//import ggplotd.aes : DefaultValues, merge;
import ggplotd.aes : merge;

auto AesDefaults = Tuple!(
    double, "x", double, "y",
    ColourID, "colour", string, "label", double, "size",
    double, "angle", double, "alpha", bool, "mask", double, "fill" )
    (double.init, double.init, ColourID("black"), "", 10, 0, 1, true, 0.0);

auto toTuples( string[] columns, Options options, int lineCount )
{
    // TODO use generate?
    struct Tuples
    {
        this( string[] columns, Options options, int lineCount )
        {
            import std.range : empty, repeat;
            import std.array : array;
            _columns = columns;
            xColumnIDs = options.xColumns;
            yColumnIDs = options.yColumns;
            _lineCount = lineCount;
        }

        @property bool empty()
        {
            import std.range : empty, front;
            return (
                    (!xColumnIDs.empty && xColumnIDs.front >= _columns.length) ||
                    (!yColumnIDs.empty && yColumnIDs.front >= _columns.length) ||
                    (xColumnIDs.empty && yColumnIDs.empty)
                   );
        }

        @property auto front()
        {
            import std.conv : to;
            import std.range : empty, front;

            double x = lineCount.to!double;
            double y = lineCount.to!double;
            
            if (!xColumnIDs.empty)
                x = _columns[xColumnIDs.front].to!double;
            if (!yColumnIDs.empty)
                y = _columns[yColumnIDs.front].to!double;

            return AesDefaults.merge(Tuple!(double, "x", double, "y", ColourID,
                "colour")( x, y,
                    ColourID(columnID)));
        }

        void popFront()
        {
            import std.range : empty, popFront;
            if (!xColumnIDs.empty)
                xColumnIDs.popFront;
            if (!yColumnIDs.empty)
                yColumnIDs.popFront;
            ++columnID;
        }

        string[] _columns;
        typeof(options.xColumns) xColumnIDs;
        typeof(options.xColumns) yColumnIDs;
        int columnID = 0;
        int _lineCount;
    }

    return Tuples( columns, options, lineCount );
}

unittest
{
    Options options;
    options.yColumns = OptionRange!int("1");

    auto ts = ["1","2","3"].toTuples( options, -1 );
    assertEqual( ts.front.x, -1 );
    assertEqual( ts.front.y, 2 );

    options.xColumns = OptionRange!int("2");

    ts = ["1","2","3"].toTuples( options, -1 );
    assertEqual( ts.front.x, 3 );
    assert(!ts.empty);
    ts.popFront;
    assert(ts.empty);

    options.xColumns = OptionRange!int("0,1,..");
    ts = ["1","2","3"].toTuples( options, -1 );
    assertEqual( ts.front.x, 1 );
    ts.popFront;
    assertEqual( ts.front.x, 2 );
    ts.popFront;
    assertEqual( ts.front.x, 3 );
    ts.popFront;
    assert( ts.empty );
}


