import std.stdio;
import std.socket;
import std.string;
import std.conv;

import std.datetime;

import std.stdio;
import std.socket;

import cairo = cairo;

import plotd.primitives;
import plotd.drawing;

void main() {
    Socket server = new TcpSocket();
    server.setOption(SocketOptionLevel.SOCKET, 
            SocketOption.REUSEADDR, true);
    server.bind(new InternetAddress(50001));
    server.listen(1);
    auto startTime = Clock.currTime();
    bool wait = true;

    // Setup axes
    auto plot_bounds = Bounds( -1, 1, -1, 1 );
    auto surface_bounds = Bounds( 100, 400, 300, 0 );

    auto axes_surface = new cairo.ImageSurface(
            cairo.Format.CAIRO_FORMAT_ARGB32, 400, 400);
    auto axes_context = cairo.Context( axes_surface );
    
    auto pnt = Point( -1, -1 );
    axes_context = draw_point( pnt, plot_bounds, axes_context );
    pnt = Point( 0, 0 );
    axes_context = draw_point( pnt, plot_bounds, axes_context );
    pnt = Point( 1, 1 );
    axes_context = draw_point( pnt, plot_bounds, axes_context );
    axes_context = draw_line( Point( -1,0 ), Point( 0,1 ), 
            plot_bounds, axes_context );
    axes_surface.writeToPNG("example.png");
    axes_surface.dispose();


    while(wait) {
        Socket client = server.accept();

        char[1024] buffer;
        auto received = client.receive(buffer);

        writeln( buffer[0.. received] );

        client.shutdown(SocketShutdown.BOTH);
        client.close();
        if( (Clock.currTime() - startTime).get!"seconds"() > 1000 )
            wait = false;
    }
}
