import std.stdio;
import std.socket;
import std.string;
import std.conv;

import std.datetime;

import std.stdio;
import std.socket;

void main() {
    Socket server = new TcpSocket();
    server.setOption(SocketOptionLevel.SOCKET, 
            SocketOption.REUSEADDR, true);
    server.bind(new InternetAddress(50001));
    server.listen(1);
    auto startTime = Clock.currTime();
    bool wait = true;

    while(wait) {
        Socket client = server.accept();

        char[1024] buffer;
        auto received = client.receive(buffer);

        writefln("The client said:\n%s", buffer[0.. received]);

        string response = "Hello World!\n";
        client.send(response);

        client.shutdown(SocketShutdown.BOTH);
        client.close();
        if( (Clock.currTime() - startTime).get!"seconds"() > 1 )
            wait = false;
    }
}
