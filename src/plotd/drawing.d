module plotd.drawing;
import std.conv;

import cairo = cairo;

import plotd.primitives;

// Design: One surface per plot (this makes it easier for PDFSurface support
// Get axes context
// Get plot context ( probably by first getting a subsurface from the main surface )

/*

class Dependency
{
    //string call(TYPE)();  wouldn't be mocked as it's a template
    string call()
    {
        return "Call on me, baby!";
    }
}

void funcToTest(CONTEXT)(CONTEXT cnt)
{
    cnt.fill();
}

unittest
{
    import dmocks.mocks;
    auto mocker = new Mocker();

    auto axes_surface = new cairo.ImageSurface(
            cairo.Format.CAIRO_FORMAT_ARGB32, 400, 400);
    
    //auto axes_context = cairo.Context( axes_surface );
    auto mock = mocker.mockStruct!(cairo.Context, cairo.ImageSurface )(
            axes_surface ); 

    mocker.expect(mock.fill()).repeat( 1 );
    mocker.replay;
    funcToTest(mock);
    mocker.verify;
}
*/

/// Create the plot surface
cairo.Surface create_plot_surface() {
    return new cairo.ImageSurface(
            cairo.Format.CAIRO_FORMAT_ARGB32, 400, 400);
}

/// Save surface to a file
void save( cairo.Surface surface ) {
    (cast(cairo.ImageSurface)( surface )).writeToPNG( "example.png" );
}

/// Get axes_context from a surface
cairo.Context axes_context_from_surface( cairo.Surface axes_surface ) {
    auto context = cairo.Context( axes_surface );
    context.setFontSize( 14.0 );
    return context;
}

/** Draw point onto context
    
  Template function to make it Mockable

  */
CONTEXT draw_point(CONTEXT)( const Point point, const Bounds bounds, 
        CONTEXT context ) {
    auto surface_bounds = Bounds( 100, 400, 300, 0 );
    auto pixel_point = convert_coordinates( point, bounds, surface_bounds );
    context.rectangle(
            pixel_point.x-5, pixel_point.y-5, 
                10, 10 );
    context.fill();
    return context;
}

unittest {
    import dmocks.mocks;
    auto mocker = new Mocker();

    auto surface = create_plot_surface();
    auto mock = mocker.mockStruct!(cairo.Context, cairo.Surface )(
            surface ); 

    mocker.expect(mock.fill()).repeat( 2 );
    mocker.expect(mock.rectangle( 245.0, 145.0, 10.0, 10.0 )).repeat(1);
    mocker.expect(mock.rectangle( 95.0, 295.0, 10.0, 10.0 )).repeat(1);
    mocker.replay;
    draw_point( Point( 0, 0 ), Bounds( -1, 1, -1, 1 ), mock );
    draw_point( Point( -1, -1 ), Bounds( -1, 1, -1, 1 ), mock );
    mocker.verify;
}

CONTEXT draw_line(CONTEXT)( const Point from, const Point to, const Bounds bounds,
        CONTEXT context ) {
    auto surface_bounds = Bounds( 100, 400, 300, 0 );
    auto pixel_from = convert_coordinates( from, bounds, surface_bounds );
    context.moveTo( pixel_from.x, pixel_from.y );
    auto pixel_to = convert_coordinates( to, bounds, surface_bounds );
    context.lineTo( pixel_to.x, pixel_to.y );
    context.stroke();
    return context;
}

unittest {
    import dmocks.mocks;
    auto mocker = new Mocker();

    auto surface = create_plot_surface();
    auto mock = mocker.mockStruct!(cairo.Context, cairo.Surface )(
            surface ); 

    mocker.expect(mock.moveTo( 250.0, 150.0 )).repeat(1);
    mocker.expect(mock.lineTo( 100.0, 300.0 )).repeat(1);
    mocker.expect(mock.stroke()).repeat(1);
    mocker.replay;
    draw_line( Point( 0, 0 ), Point( -1, -1 ), Bounds( -1, 1, -1, 1 ), mock );
    mocker.verify;
}

/**
  Draw axes onto the given context
  */
CONTEXT draw_axes(CONTEXT)( const Bounds bounds, CONTEXT context ) {
    auto xaxis = new Axis( bounds.min_x, bounds.max_x );
    xaxis = adjust_tick_width( xaxis, 5 );

    auto yaxis = new Axis( bounds.min_y, bounds.max_y );
    yaxis = adjust_tick_width( yaxis, 5 );

    // Draw xaxis
    context = draw_line( Point( xaxis.min, yaxis.min ), 
            Point( xaxis.max, yaxis.min ), bounds, context );
    // Draw ticks
    auto tick_x = xaxis.min_tick;
    auto tick_size = tick_length(yaxis);
    while( tick_x < xaxis.max ) {
        context = draw_line( Point( tick_x, yaxis.min ),
            Point( tick_x, yaxis.min + tick_size ), bounds, context );
        context = draw_text( tick_x.to!string, 
                Point( tick_x, yaxis.min - 1.5*tick_size ), 
                bounds, context );
        tick_x += xaxis.tick_width;
    }

    // Draw yaxis
    context = draw_line( Point( xaxis.min, yaxis.min ), 
            Point( xaxis.min, yaxis.max ), bounds, context );
    // Draw ticks
    auto tick_y = yaxis.min_tick;
    tick_size = tick_length(yaxis);
    while( tick_y < yaxis.max ) {
        context = draw_line( Point( xaxis.min, tick_y ),
            Point( xaxis.min + tick_size, tick_y ), bounds, context );
        context = draw_text( tick_y.to!string, 
                Point( xaxis.min - 1.5*tick_size, tick_y ), 
                bounds, context );
        tick_y += yaxis.tick_width;
    }

    return context;
}

CONTEXT draw_text(CONTEXT)( string text, const Point location, const Bounds bounds,
        CONTEXT context ) {
    auto surface_bounds = Bounds( 100, 400, 300, 0 );
    auto pixel_point = convert_coordinates( location, bounds, surface_bounds );
    context.moveTo( pixel_point.x, pixel_point.y ); 
    context.showText( text );
    return context;
}

unittest {
    import dmocks.mocks;
    auto mocker = new Mocker();

    auto surface = create_plot_surface();
    auto mock = mocker.mockStruct!(cairo.Context, cairo.Surface )(
            surface ); 

    mocker.expect(mock.moveTo( 250.0, 150.0 )).repeat(1);
    mocker.expect(mock.showText( "text" )).repeat(1);
    mocker.replay;
    draw_text( "text", Point( 0, 0 ), Bounds( -1, 1, -1, 1 ), mock );
    mocker.verify;
}


