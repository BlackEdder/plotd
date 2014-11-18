/*
	 -------------------------------------------------------------------

	 Copyright (C) 2014, Edwin van Leeuwen

	 This file is part of plotd plotting library.

	 Plotd is free software; you can redistribute it and/or modify
	 it under the terms of the GNU General Public License as published by
	 the Free Software Foundation; either version 3 of the License, or
	 (at your option) any later version.

	 Plotd is distributed in the hope that it will be useful,
	 but WITHOUT ANY WARRANTY; without even the implied warranty of
	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 GNU General Public License for more details.

	 You should have received a copy of the GNU General Public License
	 along with Plotd. If not, see <http://www.gnu.org/licenses/>.

	 -------------------------------------------------------------------
	 */

module plotd.primitives;

import std.algorithm : min, max;
import std.conv : to;
import std.math;
import std.range: isInputRange;
import std.stdio;
import std.string;

version( unittest ) {
	import std.algorithm : take;
}

/// Color class using rgba representation internally
class Color {
    double r = 1, g = 1, b = 1, a = 1;
    this( double red, double green, double blue, double alpha ) { 
        r = red; g = green; b = blue; a = alpha; }

    this( string value ) {
        auto rgba = value.split( "," );
        assert( rgba.length == 4 );
        r = to!double(rgba[0]); g = to!double(rgba[1]); 
        b = to!double(rgba[2]); a = to!double(rgba[3]);
    }

    unittest {
        assert( new Color( "0.1,0.2,0.3,0.4" ) == new Color( 0.1, 0.2, 0.3, 0.4 ) );
    }

    override bool opEquals( Object o ) const {
        auto color = cast( typeof( this ) ) o;
        return ( r == color.r &&
                g == color.g &&
                b == color.b &&
                a == color.a );
    }

    static Color black() {
        auto color = new Color( 0, 0, 0, 1 );
        return color;
    }

    static Color white() {
        auto color = new Color( 1, 1, 1, 1 );
        return color;
    }

    unittest {
        auto col1 = Color.black;
        auto col2 = Color.black;
        assert( col1.r == col2.r );
        assert( col1.g == col2.g );
        assert( col1.b == col2.b );
        assert( col1.a == col2.a );
        assert ( col1.opEquals( col2 ) );
        assert ( col1 == col2 );
    }
}

/// Infinite range of colors
struct ColorRange {
	@property bool empty() const
	{
		return false;
	}

	@property Color front() {
		return new Color( r, g, b, a );
	}

	void popFront() {
		if ( r == 0 && g == 0 && b == 0 )
			r = 1;
		else if ( r == 1 && g == 0 && b == 0 )
		{
			r = 0; // Skip yellow, because difficult to see on white
			g = 1;
		}
		else if ( r == 0 && g == 1 && b == 0 )
			b = 1;
		else if ( r == 0 && g == 1 && b == 1 )
			g = 0;
		else if ( r == 0 && g == 0 && b == 1 ) {
			b = 0;
		}
	}

	private:
		double r = 0;
		double g = 0;
		double b = 0;
		double a = 1;
}

unittest {
	Color prevColor = Color.white;
	ColorRange colorRange;
	foreach( col ; take( colorRange, 15 ) ) {
		assert( prevColor != col );
		prevColor = col;
	}
}

/// Bounds struct holding the bounds (min_x, max_x, min_y, max_y)
struct Bounds {
    double min_x;
    double max_x;
    double min_y;
    double max_y;

    this( double my_min_x, double my_max_x, double my_min_y, double my_max_y ) {
        min_x = my_min_x;
        max_x = my_max_x;
        min_y = my_min_y;
        max_y = my_max_y;
    }

    this( string value ) {
        auto bnds = value.strip.split( "," );
        assert( bnds.length == 4 );
        min_x = to!double(bnds[0]); max_x = to!double(bnds[1]); 
        min_y = to!double(bnds[2]); max_y = to!double(bnds[3]);
    }

    unittest {
        assert( Bounds( "0.1,0.2,0.3,0.4" ) == Bounds( 0.1, 0.2, 0.3, 0.4 ) );
        assert( Bounds( "0.1,0.2,0.3,0.4\n" ) == Bounds( 0.1, 0.2, 0.3, 0.4 ) );
    }
}

/// Return the height of the given bounds 
double height( Bounds bounds ) {
	return bounds.max_y-bounds.min_y;
}

unittest {
	assert( Bounds(0,1.5,1,5).height == 4 );
}

/// Return the width of the given bounds 
double width( Bounds bounds ) {
	return bounds.max_x-bounds.min_x;
}

unittest {
	assert( Bounds(0,1.5,1,5).width == 1.5 );
}

/// Is the point within the Bounds
bool withinBounds( Bounds bounds, Point point ) {
	return ( point.x <= bounds.max_x && point.x >= bounds.min_x
			&& point.y <= bounds.max_y && point.y >= bounds.min_y );
}

unittest {
	assert( Bounds( 0, 1, 0, 1 ).withinBounds( Point( 1, 0 ) ) );
	assert( Bounds( 0, 1, 0, 1 ).withinBounds( Point( 0, 1 ) ) );
	assert( !Bounds( 0, 1, 0, 1 ).withinBounds( Point( 0, 1.1 ) ) );
	assert( !Bounds( 0, 1, 0, 1 ).withinBounds( Point( -0.1, 1 ) ) );
	assert( !Bounds( 0, 1, 0, 1 ).withinBounds( Point( 1.1, 0.5 ) ) );
	assert( !Bounds( 0, 1, 0, 1 ).withinBounds( Point( 0.1, -0.1 ) ) );
}

/// Returns adjust bounds based on given bounds to include point
Bounds adjustedBounds( Bounds bounds, Point point ) {
	if ( bounds.min_x > point.x ) {
		bounds.min_x = min( bounds.min_x - 0.1*bounds.width, point.x );
	} else if ( bounds.max_x < point.x ) {
		bounds.max_x = max( bounds.max_x + 0.1*bounds.width, point.x );
	}
	if ( bounds.min_y > point.y ) {
		bounds.min_y = min( bounds.min_y - 0.1*bounds.height, point.y );
	} else if ( bounds.max_y < point.y ) {
		bounds.max_y = max( bounds.max_y + 0.1*bounds.height, point.y );
	}
	return bounds;
}

unittest {
	assert( adjustedBounds( Bounds( 0, 1, 0, 1 ), Point( 0, 1.01 ) ) ==
			Bounds( 0, 1, 0, 1.1 ) );
	assert( adjustedBounds( Bounds( 0, 1, 0, 1 ), Point( 0, 1.5 ) ) ==
			Bounds( 0, 1, 0, 1.5 ) );
	assert( adjustedBounds( Bounds( 0, 1, 0, 1 ), Point( -1, 1.01 ) ) ==
			Bounds( -1, 1, 0, 1.1 ) );
	assert( adjustedBounds( Bounds( 0, 1, 0, 1 ), Point( 1.2, -0.01 ) ) ==
			Bounds( 0, 1.2, -0.1, 1 ) );
}

/// Can we construct valid bounds given these points
bool validBounds( Point[] points ) {
	if (points.length < 2)
		return false;

	bool validx = false;
	bool validy = false;
	double x = points[0].x;
	double y = points[0].y;

	foreach( point; points[1..$] ) {
		if ( point.x != x )
			validx = true;
		if ( point.y != y )
			validy = true;
		if (validx && validy)
			return true;
	}
	return false;
}

unittest {
	assert( validBounds( [ Point( 0, 1 ), Point( 1, 0 ) ] ) );
	assert( !validBounds( [ Point( 0, 1 ) ] ) );
	assert( !validBounds( [ Point( 0, 1 ), Point( 0, 0 ) ] ) );
	assert( !validBounds( [ Point( 0, 1 ), Point( 1, 1 ) ] ) );
}

Bounds minimalBounds( Point[] points ) {
	if (points.length == 0)
		return Bounds( -1,1,-1,1 );

	double min_x = points[0].x;
	double max_x = points[0].x;
	double min_y = points[0].y;
	double max_y = points[0].y;
	if (points.length > 1) {
		foreach( point; points[1..$] ) {
			if ( point.x < min_x )
				min_x = point.x;
			else if ( point.x > max_x )
				max_x = point.x;
			if ( point.y < min_y )
				min_y = point.y;
			else if ( point.y > max_y )
				max_y = point.y;
		}
	}
	if (min_x == max_x) {
		min_x = min_x - 0.5;
		max_x = max_x + 0.5;
	}
	if (min_y == max_y) {
		min_y = min_y - 0.5;
		max_y = max_y + 0.5;
	}
	return Bounds( min_x, max_x, min_y, max_y );
}

unittest {
	assert( minimalBounds( [] ) == Bounds( -1, 1, -1, 1 ) );
	assert( minimalBounds( [Point(0,0)] ) == Bounds( -0.5, 0.5, -0.5, 0.5 ) );
	assert( minimalBounds( [Point(0,0),Point(0,0)] ) == Bounds( -0.5, 0.5, -0.5, 0.5 ) );
	assert( minimalBounds( [Point(0.1,0),Point(0,0.2)] ) == Bounds( 0, 0.1, 0, 0.2 ) );
}

///
struct AdaptiveBounds {
	/*
Notes: the main problem with adaptive bounds is the beginning, where we need to
make sure we have enough points to form valid bounds (i.e. with width and height
> 0). For example if all points fall on a vertical lines, we have no information
for the width of the plot

Here we take care to always return a valid set of bounds
	 */
	Bounds bounds = Bounds( 0,1,0,1 );
	alias bounds this;

	this( string str ) {
		bounds = Bounds( str );
	}
  this( double my_min_x, double my_max_x, double my_min_y, double my_max_y ) {
		bounds = Bounds( my_min_x, my_max_x, my_min_y, my_max_y );
	}
	this( Bounds bnds ) {
		bounds = bnds;
	}
		
	bool adapt( T : Point )( T point ) {
		bool adapted = false;
		if ( !valid ) {
			adapted = true;
			pointCache ~= point;
			valid = validBounds( pointCache );
			bounds = minimalBounds( pointCache );
			if (valid)
				pointCache = [];
		} else {
			if (!bounds.withinBounds( point )) {
				bounds = bounds.adjustedBounds( point );
				adapted = true;
			}
		}
		assert( (valid && pointCache.length == 0) || !valid );

		return adapted;
	}

	bool adapt( T )( T points ) if (isInputRange!T)
	{
		bool adapted = false;
		foreach ( point; points ) {
			auto a = adapt( point );
			if ( a )
				adapted = true;
		}
		return adapted;
	}

	private:
		Point[] pointCache;
		bool valid = false;
}

unittest {
	assert( AdaptiveBounds( "0.1,0.2,0.3,0.4" ) == Bounds( 0.1, 0.2, 0.3, 0.4 ) );

	// Test adapt
	AdaptiveBounds bounds;
	assert( bounds.width > 0 );
	assert( bounds.height > 0 );
	auto pnt = Point( 5,2 );
	assert( bounds.adapt( pnt ) );
	assert( bounds.width > 0 );
	assert( bounds.height > 0 );
	assert( bounds.withinBounds( pnt ) );
	assert( !bounds.valid );

	pnt = Point( 3,2 );
	assert( bounds.adapt( pnt ) );
	assert( bounds.width >= 2 );
	assert( bounds.height > 0 );
	assert( bounds.withinBounds( pnt ) );
	assert( !bounds.valid );

	pnt = Point( 3,5 );
	assert( bounds.adapt( pnt ) );
	assert( bounds.width >= 2 );
	assert( bounds.height >= 3 );
	assert( bounds.withinBounds( pnt ) );
	assert( bounds.valid );

	pnt = Point( 4,4 );
	assert( !bounds.adapt( pnt ) );
}

struct Point {
    double x;
    double y;
    this( double my_x, double my_y ) {
        x = my_x;
        y = my_y;
    }

    this( string value ) {
        auto coords = value.split( "," );
        assert( coords.length == 2 );
        x = to!double(coords[0]); 
        y = to!double(coords[1]);
    }

    unittest {
        assert( Point( "1.0,0.1" ) == Point( 1.0, 0.1 ) );
    }

    bool opEquals( const Point point ) {
        return point.x == x && point.y == y;
    }
}

Point convertCoordinates( const Point point, const Bounds orig_bounds, 
        const Bounds new_bounds ) {
    double new_x = new_bounds.min_x + (new_bounds.max_x-new_bounds.min_x)*(point.x-orig_bounds.min_x)/(orig_bounds.max_x-orig_bounds.min_x);
    double new_y = new_bounds.min_y + (new_bounds.max_y-new_bounds.min_y)*(point.y-orig_bounds.min_y)/(orig_bounds.max_y-orig_bounds.min_y);
    return Point( new_x, new_y );
}

unittest {
    assert( convertCoordinates( Point( 0.5, 0.1 ), Bounds( -1, 1, -1, 1 ),
                Bounds( 50, 100, -100, -50 ) ) == Point( 87.5, -72.5 ) );
}

alias int LineId;

class LineState {
    Color color;
    Point end_point;
    LineId id;
}

class Lines {

    /// Returns an unused (new) line_id
    LineId newLineId() {
        last_id++;
        return last_id;
    }

    /// Add a new line with begin point, or add to an existing line
    void addLine( LineId id, Point point ) {
        LineState state;
        lines.get( id, state );
        if ( state is null ) {
            state = new LineState;
            state.color = Color.black;
            state.id = id;
            lines[id] = state;
        }
        lines[id].end_point = point;
        mylastUsedId = id; // Keeping track of the last used line id
    }

    unittest {
        auto lines = new Lines;
        lines.addLine( 1, Point( 1, 2 ) );
        assert( lines.lines.length == 1 );
        assert( lines.lines[1].color == Color.black ); // Should implement equals for color
        assert( lines.lines[1].end_point == Point( 1, 2 ) );
        lines.addLine( 1, Point( 2, 2 ) );
        assert( lines.lines[1].end_point == Point( 2, 2 ) );
    }

    void color( LineId id, Color color ) {
        lines[id].color = color;
        mylastUsedId = id; // Keeping track of the last used line id
    }

    unittest {
        auto lines = new Lines;
        lines.addLine( 1, Point( 1, 2 ) );
        assert( lines.lines.length == 1 );
        assert( lines.lines[1].color == Color.black ); 
        lines.color( 1, new Color( 0.5, 0.5, 0.5, 0.5 ) );
        assert( lines.lines[1].color == new Color( 0.5, 0.5, 0.5, 0.5 ) ); 
    }

    /// Return last used id
    @property LineId lastUsedId() {
        return mylastUsedId;
    }

    unittest {
        auto lines = new Lines;
        lines.addLine( 1, Point( 1, 2 ) );
        assert( lines.lastUsedId == 1 );
        lines.addLine( 2, Point( 1, 2 ) );
        assert( lines.lastUsedId == 2 );
        lines.addLine( 1, Point( 1, 1 ) );
        assert( lines.lastUsedId == 1 );
        lines.color( 2, new Color( 0.5, 0.5, 0.5, 0.5 ) );
        assert( lines.lastUsedId == 2 );
    }

    private:
        LineState[LineId] lines;
        LineId last_id = 0;
        LineId mylastUsedId = 0;
}


