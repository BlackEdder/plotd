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

module plotd.drawing;
import std.conv;

import cairo = cairo;

import plotd.axes : Axis, adjustTickWidth, tickLength;
import plotd.primitives;
import plotd.binning;

version( unittest ) {
	import std.stdio;
}
version( assert ) {
	import std.stdio;
}
// Design: One surface per plot (this makes it easier for PDFSurface support
// Get axes context
// Get plot context ( probably by first getting a subsurface from the main surface )

/// Create the plot surface with given width and height in pixels
cairo.Surface createPlotSurface( int width = 400, int height = 400 ) {
    auto surface = new cairo.ImageSurface(
            cairo.Format.CAIRO_FORMAT_ARGB32, width, height );
    auto context = cairo.Context( surface );
    clearContext( context );
    return surface;
}

/// Save surface to a file
void save( cairo.Surface surface, string name = "example.png" ) {
    (cast(cairo.ImageSurface)( surface )).writeToPNG( name );
}

/// Get axesContext from a surface
cairo.Context axesContextFromSurface( cairo.Surface surface, Bounds plotBounds,
			Bounds marginBounds = Bounds( 100,400,100,400 )) {
    auto context = cairo.Context( surface );

    context.translate( marginBounds.min_x, height( marginBounds ) );
    context.scale( marginBounds.width/plotBounds.width, 
            -marginBounds.height/plotBounds.height );
    context.translate( -plotBounds.min_x, -plotBounds.min_y );
    context.setFontSize( 14.0 );
    return context;
}

/// Get plotContext from a surface
cairo.Context plotContextFromSurface( cairo.Surface surface, Bounds plotBounds,
			Bounds marginBounds = Bounds( 100,400,100,400 ) ) {
    // Create a sub surface. Makes sure everything is plotted within plot surface
    auto plotSurface = cairo.Surface.createForRectangle( surface, 
            cairo.Rectangle!double( marginBounds.min_x, 0, // No support for margin at top yet. Would need to know the surface dimensions
							marginBounds.width, marginBounds.height ) );
    auto context = cairo.Context( plotSurface );
    context.translate( 0, marginBounds.height );
    context.scale( marginBounds.width/plotBounds.width, 
            -marginBounds.height/plotBounds.height );
    context.translate( -plotBounds.min_x, -plotBounds.min_y );
    context.setFontSize( 14.0 );
    return context;
}

/** Draw point onto context
    
  Template function to make it Mockable

  */
CONTEXT drawPoint(CONTEXT)( const Point point, CONTEXT context ) {
	auto width_height = context.deviceToUserDistance( 
			cairo.Point!double( 6.0, 6.0 ) );
	context.rectangle(
			point.x-width_height.x/2.0, point.y-width_height.y/2.0, 
			width_height.x, width_height.y );
	context.fill();
	return context;
}

CONTEXT drawLine(CONTEXT)( const Point from, const Point to, CONTEXT context ) {
    context.moveTo( from.x, from.y );
    context.lineTo( to.x, to.y );
    context.save();
    context.identityMatrix();
    context.stroke();
    context.restore();
    return context;
}

unittest {
    import dmocks.mocks;
    auto mocker = new Mocker();

    auto surface = createPlotSurface();
    auto mock = mocker.mockStruct!(cairo.Context, cairo.Surface )(
            surface ); 

    mocker.expect(mock.moveTo( 0.0, 0.0 )).repeat(1);
    mocker.expect(mock.lineTo( -1.0, -1.0 )).repeat(1);
    mocker.expect(mock.stroke()).repeat(1);
    mocker.expect(mock.save()).repeat(1);
    mocker.expect(mock.identityMatrix()).repeat(1);
    mocker.expect(mock.restore()).repeat(1);
    mocker.replay;
    drawLine( Point( 0, 0 ), Point( -1, -1 ), mock );
    mocker.verify;
}

/**
  Draw axes onto the given context
  */
CONTEXT drawAxes(CONTEXT)( const Bounds bounds, CONTEXT context ) {

    auto xaxis = new Axis( bounds.min_x, bounds.max_x );
    xaxis = adjustTickWidth( xaxis, 5 );

    auto yaxis = new Axis( bounds.min_y, bounds.max_y );
    yaxis = adjustTickWidth( yaxis, 5 );

    // Draw xaxis
    context = drawLine( Point( xaxis.min, yaxis.min ), 
            Point( xaxis.max, yaxis.min ), context );
    // Draw ticks
    auto tick_x = xaxis.min_tick;
    auto tick_size = tickLength(yaxis);
    while( tick_x < xaxis.max ) {
        context = drawLine( Point( tick_x, yaxis.min ),
            Point( tick_x, yaxis.min + tick_size ), context );

				context.save;
				context.identityMatrix;
				auto extents = context.textExtents( tick_x.to!string );
				auto textSize = cairo.Point!double( 0.5*extents.width, 
						-extents.height );
				context.restore;
				textSize = context.deviceToUserDistance( textSize );
        context = drawText( tick_x.to!string, 
                Point( tick_x - textSize.x, yaxis.min - 1.5*textSize.y ), context );
        tick_x += xaxis.tick_width;
    }

    // Draw yaxis
    context = drawLine( Point( xaxis.min, yaxis.min ), 
            Point( xaxis.min, yaxis.max ), context );
    // Draw ticks
    auto tick_y = yaxis.min_tick;
    tick_size = tickLength(xaxis);
    while( tick_y < yaxis.max ) {
        context = drawLine( Point( xaxis.min, tick_y ),
            Point( xaxis.min + tick_size, tick_y ), context );
				context.save;
				context.identityMatrix;
				auto extents = context.textExtents( tick_y.to!string );
				auto textSize = cairo.Point!double( extents.height, 
						-0.5*extents.width );
				context.restore;
				textSize = context.deviceToUserDistance( textSize );
        context = drawRotatedText( tick_y.to!string, 
							Point( xaxis.min - 0.5*textSize.x, tick_y-textSize.y ), 
							1.5*3.14, context );
        tick_y += yaxis.tick_width;
    }

    return context;
}

/// Draw xlabel
CONTEXT drawXLabel(CONTEXT)( string label, Bounds bounds, CONTEXT context ) {
	auto extents = context.textExtents( label );
	auto textSize = cairo.Point!double( 0.5*extents.width, 
			-extents.height );
	textSize = context.deviceToUserDistance( textSize );
	context = drawText( label, 
			Point( bounds.min_x + bounds.width/2.0 - textSize.x, 
					bounds.min_y - 3.0*textSize.y ),
			context );
	return context;
}

/// Draw ylabel
CONTEXT drawYLabel(CONTEXT)( string label, Bounds bounds, CONTEXT context ) {
	auto extents = context.textExtents( label );
	auto textSize = cairo.Point!double( -extents.height, 
			0.5*extents.width );
	textSize = context.deviceToUserDistance( textSize );
	context = drawRotatedText( label, 
			Point( bounds.min_x + 2.0*textSize.x,
				bounds.min_y + bounds.height/2.0 + textSize.y ),
			1.5*3.14, context );
	return context;
}


/// Draw text at given location
CONTEXT drawText(CONTEXT)( string text, const Point location, CONTEXT context ) {
    context.moveTo( location.x, location.y ); 
    context.save();
    context.identityMatrix();
    context.showText( text );
    context.restore();
    return context;
}

/// Draw rotated text on plot
CONTEXT drawRotatedText(CONTEXT)( string text, const Point location, 
		double radians, CONTEXT context ) {
    context.moveTo( location.x, location.y ); 
    context.save();
    context.identityMatrix();
		context.rotate( radians );
    context.showText( text );
    context.restore();
    return context;
}
unittest {
    import dmocks.mocks;
    auto mocker = new Mocker();

    auto surface = createPlotSurface();
    auto mock = mocker.mockStruct!(cairo.Context, cairo.Surface )(
            surface ); 

    mocker.expect(mock.moveTo( 0.0, 0.0 )).repeat(1);
    mocker.expect(mock.save()).repeat(1);
    mocker.expect(mock.identityMatrix()).repeat(1);
    mocker.expect(mock.showText( "text" )).repeat(1);
    mocker.expect(mock.restore()).repeat(1);
    mocker.replay;
    drawText( "text", Point( 0, 0 ), mock );
    mocker.verify;
}

CONTEXT drawBins( T : Bins!size_t, CONTEXT )( CONTEXT context, Bins!T bins ) {
	// find tallest bin
	double max = 0;
	foreach ( x, ybins; bins ) {
		foreach ( y, value; ybins ) {
			if (value > max)
				max = value;
		}
	}

	foreach ( x, ybins; bins ) {
		foreach ( y, value; ybins ) {
			double z = value/max;
			Color colour = new Color( 1-z,1-z,1-z, 1 );
    	context = color( context, colour );
			context.rectangle(
					x, y, bins.width, ybins.width );
			context.fill();
		}
	}

  return context;
}


CONTEXT drawBins( T : size_t, CONTEXT )( CONTEXT context, Bins!T bins ) {
    foreach( x, count; bins ) {
        context = drawLine( Point( x, 0 ), 
                Point( x, count.to!double ),
                context );
        context = drawLine( Point( x, count.to!double ), 
                Point( x + bins.width, count.to!double ),
                context );
        context = drawLine( 
                Point( x + bins.width, count.to!double ), 
                Point( x + bins.width, 0 ),
                context );
      }
    return context;
}

CONTEXT clearContext( CONTEXT )( CONTEXT context ) {
    context.save();
    context = color( context, Color.white );
    context.paint();
    context.restore();
    return context;
}

unittest {
    import dmocks.mocks;
    auto mocker = new Mocker();

    auto surface = createPlotSurface();
    auto mock = mocker.mockStruct!(cairo.Context, cairo.Surface )(
            surface );
    mocker.expect( mock.save() ).repeat(1);
    mocker.expect( mock.setSourceRGBA( 1, 1, 1, 1 ) ).repeat(1);
    mocker.expect( mock.paint() ).repeat(1);
    mocker.expect( mock.restore() ).repeat(1);
    mocker.replay;
    clearContext( mock );
    mocker.verify;
}

CONTEXT color( CONTEXT )( CONTEXT context, const Color color ) {
    context.setSourceRGBA( color.r, color.g, color.b, color.a );
    return context;
}
