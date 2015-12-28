import plotcli.parse;

void main()
{
    import std.stdio : writeln;

    foreach( msg; readStdinByLine( false ) ) {
        msg.writeln;
    }
}
