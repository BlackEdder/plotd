module plotd.messages;
import std.json;

import plotd.primitives;

/**
	Message will be a jsonValue which makes it easy to pass them over network or
	write them to disk

	Need Color to message and point to message
	*/
alias JSONValue Message;

Message toMessage( const Point point ) {
	Message msg;
	msg = [ "type": JSONValue("point"), 
			"x" : JSONValue( point.x ), 
			"y": JSONValue( point.y ) ];
	return msg;
}

Point toPoint( const Message msg ) {
	Point pnt;
	pnt.x = msg["x"].floating;
	pnt.y = msg["y"].floating;
	return pnt;
}

unittest {
	assert( toMessage( Point( 1, 2 ) ).toString() == 
		"{\"type\":\"point\",\"x\":1,\"y\":2}" );
	assert( toPoint( toMessage( Point( 1, 2 ) ) ) ==
			Point( 1, 2 ) );
}

Message toMessage( const Color color ) {
	Message msg;
	msg = [ "type": JSONValue("color"), 
			"r" : JSONValue( color.r ), 
			"g" : JSONValue( color.g ), 
			"b" : JSONValue( color.b ), 
			"a" : JSONValue( color.a ) ];
	return msg;
}

Color toColor( const Message msg ) {
	Color color = new Color( 0, 0, 0, 0 );
	color.r = msg["r"].floating;
	color.g = msg["g"].floating;
	color.b = msg["b"].floating;
	color.a = msg["a"].floating;
	return color;
}

unittest {
	assert( toMessage( Color.black() ).toString() == 
		"{\"a\":1,\"b\":1,\"g\":1,\"r\":1,\"type\":\"color\"}" );
	assert( toColor( toMessage( Color.black ) ) ==
			Color.black );
}
