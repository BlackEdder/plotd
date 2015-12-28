import plotcli.parse;

void main()
{
    import std.range : take;
    import std.stdio : writeln, write;

    auto rd = readStdinByLine();
    foreach( _; 0..100 ) {
        rd.front.writeln;
        rd.popFront;
    }
}
