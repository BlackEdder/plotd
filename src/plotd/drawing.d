module plotd.drawing;

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
    return cairo.Context( axes_surface );
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
