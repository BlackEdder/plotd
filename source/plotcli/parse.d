module plotcli.parse;

import std.range : isInputRange;

version( unittest )
{
    import dunit.toolkit;
}

struct FollowRange(RANGE) if (isInputRange!RANGE)
{
    import std.range : ElementType;
    import core.thread : Thread;
    import core.time : dur;

    this( RANGE range, bool follow = true )
    {
        import std.range : empty, front;
        // TODO add non follow mode, and pollingDelay, timeoutDelay 
        _range = range;
        _follow = follow;
        if (!_range.empty)
            frontValue = _range.front; 
        else if (!_follow)
            eof = true;
    }

    @property bool empty() const {
        return eof;
    }

    @property ref auto front() {
        return frontValue;
    }

    void popFront()
    {
        if (this.empty)
            assert(0, "FollowRange is empty");

        import std.range : empty, popFront, front;
        // This one either blocks till next line, or sets "" after timeout
        if (_range.empty && _follow)
            Thread.sleep(dur!("msecs")(100));
        if (_range.empty && !_follow)
            eof = true;

        if (!_range.empty)
        {
            _range.popFront;
            if (!_range.empty)
                frontValue = _range.front; // Immediately set front value, 
                // otherwise
                // the _range could fill up between our popFront and front call
            else if (_follow)
                frontValue = ElementType!RANGE.init;
            else
                eof = true;
        }
    }

private:
    bool eof = false;
    bool _follow;
    RANGE _range;
    ElementType!RANGE frontValue;
}

unittest 
{
    struct TestRange {
        @property bool empty() const { return true; }
        void popFront() {}
        @property string front() { return "bla"; }
    }

    auto r = TestRange();

    auto f = FollowRange!TestRange( r );

    assertEqual( f.empty, false );
    f.popFront;
    assertEqual( f.front, "" );
}

unittest 
{
    import std.math : isNaN;
    import std.array : array;
    import std.range : take;
    auto f = FollowRange!(double[])( [1.0,2.0,3.0] );

    assertEqual([1.0,2.0,3.0], f.take(3).array);
    assert(isNaN(f.take(4).array[3]));

    auto f2 = FollowRange!(double[])( [1.0,2.0,3.0], false );
    assertEqual([1.0,2.0,3.0], f2.array);
}

auto readStdinByLine( bool follow = true )
{
    struct ReadLines
    {
        import std.stdio : readln;

        @property bool empty() {
            import std.range : empty;
            if (msgs.empty) {
                auto msg = readln();
                if (msg.length > 0)
                    msgs ~= msg;
            }
            return msgs.empty;
        }

        @property ref auto front() {
            import std.range : front;
            if (!initialized) {
                initialized = true;
            }
            return msgs.front;
        }
        
        void popFront() {
            import std.range : popFront;
            msgs.popFront;
            // This range behaves different, because stdin can be filled up
            // So we read on a call to empty
        }

        bool initialized = false;
        string[] msgs;
    }

    return FollowRange!ReadLines( ReadLines(), follow );
    //return ReadLines();
}

auto helpText = "Usage: plotcli [-f] [-o OUTPUT] [-x XCOLUMNS] [-y YCOLUMNS] [--type TYPE]

Plotcli is a plotting program that will plot data from provided data streams (files). It will ignore any lines it doesn't understand, making it possible to feed it \"dirty\" streams/files. All options can also be provided within the stream by using the prefix #plotcli (e.g. #plotcli -x 1 -y 2).

Options:
  -f          Follow the stream, i.e. keep listening for new lines.
  -x XCOLUMNS String describing the columns containing x coordinates.
  -y YCOLUMNS String describing the columns containing y coordinates.
  -o OUTPUT	  Outputfile (without extension).
  --type TYPE Type of data (line, point, hist)

";

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

import std.algorithm : map, filter;
import std.array : array;
import std.algorithm : strip;
import std.regex : ctRegex, regex, replaceFirst, split;
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


