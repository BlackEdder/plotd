import std.stdio;
import std.socket;
import std.string;
import std.conv;
import std.getopt;

import plotd.message;
import plotd.primitives;
import plotd.commandline;

/**
Convert:
--action point --point 1 0.5
--action color --color 0.4 0.5 0.1 0.9
--action line --point 3 0.1 --id 2
*/

void main(string[] args) {
    string action;
    int id;// Should initialize as NaN if possible;

    Message[] parameters;
    // Needed because delegate does not return void by default
    void add_point_to_pars( string option, string value ) {
        parameters = coordHandler( value, parameters );
    }

    void add_color_to_pars( string option, string value ) {
        parameters = rgbaHandler( value, parameters );
    }
     
    getopt(
            args,
            "action", &action,
            "point", &add_point_to_pars,
            "color|colour", &add_color_to_pars,
            "id", &id
          );


    Message action_msg = [ "action": Message(action), 
            "parameters": Message(parameters) ];
    writeln( "Client sending the following message: ", action_msg );

  auto s = new TcpSocket();

  auto addr = new InternetAddress( "localhost", 50001 );

  s.connect(addr);

  scope(exit) s.close();

  s.send( action_msg.to!string );

  /*for (int i = 0; i < 1000; i++){
    auto r = uniform(int.min,int.max);
    auto send_buf = new OutBuffer();

    send_buf.write(r);

    s.send(send_buf.toBytes());

    ubyte[r.sizeof] recv_buf;
    s.receive(recv_buf);

    assert(r == *cast(int*)(send_buf.toBytes().ptr));
  }*/
}
