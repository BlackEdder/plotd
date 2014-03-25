module plotd.message;

import std.algorithm;
public import std.json;

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
    if ( msg["x"].type == JSON_TYPE.INTEGER )
        pnt.x = cast(double)( msg["x"].integer );
	else
        pnt.x = msg["x"].floating;

    if ( msg["y"].type == JSON_TYPE.INTEGER )
        pnt.y = cast(double)( msg["y"].integer );
	else
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
    Color color = new Color(
            msg["r"].floating,
            msg["g"].floating,
            msg["b"].floating,
            msg["a"].floating);
    return color;
}

unittest {
	assert( toMessage( Color.black() ).toString() == 
		"{\"a\":1,\"b\":0,\"g\":0,\"r\":0,\"type\":\"color\"}" );
	assert( toColor( toMessage( Color.black ) ) ==
			Color.black );
}

Message toMessage( const Bounds bounds ) {
    Message msg;
   	msg = [ "type": JSONValue("bounds"), 
			"min_x" : JSONValue( bounds.min_x ), 
			"max_x" : JSONValue( bounds.max_x ), 
			"min_y" : JSONValue( bounds.min_y ), 
			"max_y" : JSONValue( bounds.max_y ) ];
    return msg;
}

Bounds toBounds( const Message msg ) {
    Bounds bounds = Bounds(
            msg["min_x"].floating,
            msg["max_x"].floating,
            msg["min_y"].floating,
            msg["max_y"].floating );
	return bounds;
}

unittest {
    import std.stdio;
	assert( toMessage( Bounds( 0, 2, -1, 1 ) ).toString() == 
		"{\"max_x\":2,\"max_y\":1,\"type\":\"bounds\",\"min_x\":0,\"min_y\":-1}" );
	assert( toBounds( toMessage( Bounds( 0, 2, -1, 1 ) ) ) ==
			Bounds( 0, 2, -1, 1 ) );
}

Point[] pointsFromParameters( const Message[] messages ) {
    Point[] result;
    auto pointsJSON = messages.filter!( a => a["type"].str == "point" );
    foreach ( pointJSON; pointsJSON ) {
        result ~= toPoint( pointJSON );
    }
    return result;
}

unittest {
    auto msg = parseJSON( "{\"parameters\":[{\"type\":\"point\",\"x\":1.0,\"y\":2.0}],\"action\":\"point\"}" );
    assert( pointsFromParameters( msg["parameters"].array ) == [Point( 1, 2 )] );
}
