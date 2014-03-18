module plotd.commandline;
import std.string;
import std.conv;


import plotd.message;
import plotd.primitives;

/// Turn command line string into color message
Message[] rgbaHandler( string value, Message[] parameters ) {
   parameters ~= toMessage( to!Color( value ) );
   return parameters;
}

unittest {
    Message[] msg;
    msg = rgbaHandler( "0.1,0.3,0.4,0.5", msg );
    auto color = new Color( 0.1, 0.3, 0.4, 0.5 );
    assert( msg[0].to!string == toMessage( color ).to!string );
}

Message[] coordHandler( string value, Message[] parameters ) {
    parameters ~= toMessage( to!Point( value ) );
    return parameters;
}

unittest {
    Message[] msg;
    msg = coordHandler( "0.1,0.4", msg );
    auto point = Point( 0.1, 0.4 );
    assert( msg[0].to!string == toMessage( point ).to!string );
}
