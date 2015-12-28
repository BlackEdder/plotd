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
        import std.range : empty, popFront, front;
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

    void popFront()
    {
        import std.range : empty, popFront, front;
        // This one either blocks till next line, or sets "" after timeout
        if (_range.empty && _follow)
            Thread.sleep(dur!("msecs")(100));

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

    @property ref auto front() {
        return frontValue;
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


auto readFileByLine()
{
    // Returns an voldermort type that will read the new line on popFront.
    // Also add the ability to if file end -> wait for new line being added and or
    //      if certain time passed by -> return empty line.
    // For testing purposes could implement general followRange inputrange, 
    // that will
    // follow an inputrange. When it is empty wait till not empty any more...
}
