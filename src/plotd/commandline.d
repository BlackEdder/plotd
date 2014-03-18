module plotd.commandline;
import std.string;
import std.conv;


import plotd.message;
import plotd.primitives;

/// Turn command line string into color message
void rgbaHandler( string value, ref Message msg ) {
   msg = toMessage( to!Color( value ) );
}

unittest {
    Message msg;
    rgbaHandler( "0.1,0.3,0.4,0.5", msg );
    auto color = new Color( 0.1, 0.3, 0.4, 0.5 );
    assert( msg.to!string == toMessage( color ).to!string );
}

void coordHandler( string value, ref Message msg ) {
    msg = toMessage( to!Point( value ) );
}

unittest {
    Message msg;
    coordHandler( "0.1,0.4", msg );
    auto point = Point( 0.1, 0.4 );
    assert( msg.to!string == toMessage( point ).to!string );
}

unittest {
    import std.stdio;
    Message msg;
    coordHandler( "0.1,0.4", msg );
    auto point = Point( 0.1, 0.4 );
    assert( msg.to!string == toMessage( point ).to!string );
    rgbaHandler( "0.1,0.3,0.4,0.5", msg );
    auto color = new Color( 0.1, 0.3, 0.4, 0.5 );
    writeln( msg );
    assert( msg.to!string == toMessage( color ).to!string );

}


