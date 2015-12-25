module plotcli.parse;

unittest
{
    assert( true );
}

struct FollowRange(RANGE)
{
    this( RANGE range )
    {
    }

    @property bool empty() const {
        return eof;
    }

    void popFront()
    {
        // This one either blocks till next line, or sets "" after timeout
    }

    @property ref string front() {
        return "";
    }

private:
    bool eof;
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
