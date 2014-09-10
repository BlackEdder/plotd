import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.datetime;
import std.socket;

import cairo = cairo;

import plotd.primitives;
import plotd.drawing;
import plotd.binning;
import plotd.message;

void main() {
    Socket server = new TcpSocket();
    server.setOption(SocketOptionLevel.SOCKET, 
            SocketOption.REUSEADDR, true);
    server.bind(new InternetAddress(50001));
    server.listen(1);
    auto startTime = Clock.currTime();
    bool wait = true;

    // Setup axes
    auto plotBounds = Bounds( -1, 1, -1, 1 );
    auto surfaceBounds = Bounds( 100, 400, 300, 0 );

    auto surface = createPlotSurface();
    auto axesContext = axesContextFromSurface( surface, plotBounds );

    axesContext = drawAxes( plotBounds, axesContext );

    auto plotContext = plotContextFromSurface( surface, plotBounds );

    /*auto pnt = Point( -1, -1 );
    plotContext = draw_point( pnt, plotContext );
    pnt = Point( 0, 0 );
    plotContext = draw_point( pnt, plotContext );
    pnt = Point( 1, 1 );
    plotContext = draw_point( pnt, plotContext );
    plotContext = draw_line( Point( -1,0 ), Point( 0,1 ), plotContext );

    auto bins = new Bins!size_t;
    bins.min = -1.0;
    bins.width = 0.5;
    bins.resize([4]);

    bins = add_data( bins, [-0.75] );
    bins = add_data( bins, [-0.73] );
    bins = add_data( bins, [-0.23] );

    plotContext = draw_bins( plotContext, bins );*/

    scope(exit) {surface.dispose();}


    while(wait) {
        save( surface );
        Socket client = server.accept();

        char[1024] buffer;
        auto received = client.receive(buffer);

        auto msg = parseJSON( buffer[0..received] );
        writeln( msg );

        switch (msg["action"].str) {
            case "point":
                foreach ( pnt; pointsFromParameters( msg["parameters"].array ))
                    plotContext = drawPoint( pnt, plotContext );
                break;
            case "resize":
                plotBounds = boundsFromParameters( msg["parameters"].array );
                axesContext = clearContext( axesContext );
                axesContext = axesContextFromSurface( surface, plotBounds );
                axesContext = drawAxes( plotBounds, axesContext );
                plotContext = plotContextFromSurface( surface, plotBounds );
                break;
            default:
                writeln( "Unrecognized action: ", msg["action"].to!string );
                break;
        }

        client.shutdown(SocketShutdown.BOTH);
        client.close();
        if( (Clock.currTime() - startTime).get!"seconds"() > 1000 )
            wait = false;
    }
}
