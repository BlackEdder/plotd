module plotcli.parse;

import std.range : isInputRange;
import std.regex : ctRegex;

version (unittest)
{
    import dunit.toolkit;
}


bool isInteger( string str )
{
    import std.regex : ctRegex, match;
    static integer = ctRegex!(r"^\s*[+-]*[0-9]+\s*$");
    return !str.match( integer ).empty;
}

unittest
{
    assert( "-1".isInteger );
    assert( "+1".isInteger );
    assert( "1".isInteger );
    assert( !"1.0".isInteger );
}

//private auto csvRegex = ctRegex!(`,\s*|\s`);
private auto csvRegex = ctRegex!(`,\s*`);
string[] toRange(string line)
{
    import std.algorithm : map, filter;
    import std.array : array;
    import std.algorithm : strip;
    import std.regex : regex, replaceFirst, split;

    // Cut of any comments
    line = line.replaceFirst(regex("#.*"), "");
    return line.split(csvRegex).map!((d) => d.strip(' ')).array.filter!("a!=\"\"").array;
}

unittest
{
    assert(("1,2").toRange == ["1", "2"]);
    assert(("1,2 #bla").toRange == ["1", "2"]);
    assert(("#bla").toRange == []);
    assert(("0.5, 2").toRange == ["0.5", "2"]);
    assert(("bla, 2").toRange == ["bla", "2"]);
    /*assert(("1\t2").toRange == ["1", "2"]);
    assert(("1 2").toRange == ["1", "2"]);*/
    assert(("nan, 2").toRange == ["nan", "2"]);
}

bool areNumeric(R1, R2)( R1 r, R2 colIDs)
{
    import std.range : empty, front, popFront;
    import std.string : isNumeric;

    while (!colIDs.empty && colIDs.front < r.length)
    {
        if (!r[colIDs.front].isNumeric)
            return false;
        else
        {
            colIDs.popFront;
        }
    }
    return true;
}

unittest
{
    assert(["1", "1.1"].areNumeric([0, 1]));
    assert(["0", "1.1"].areNumeric([0, 1]));
    assert(!["a", "1.1"].areNumeric([0, 1]));
    assert(["a", "1.1"].areNumeric([1]));
}

auto stripComments(string str)
{
    import std.algorithm : until;
    import std.conv : to;

    return str.until!((a) => a == "#"[0]).to!string;
}

unittest
{
    assertEqual("Bla #dflkjaklf".stripComments, "Bla ");
    assertEqual("Bla".stripComments, "Bla");
    assertEqual("Bla #dflkjaklf kfdajlf".stripComments, "Bla ");
}
