import std.stdio;
import std.socket;
import std.string;
import std.conv;
import std.getopt;

import plotd.message;
import plotd.primitives;

/**
Convert:
--action point --point 1 0.5
--action color --color 0.4 0.5 0.1 0.9
--action line --point 3 0.1 --id 2
*/

void main(string[] args) {
    string action;
    double[] coords;
    double[] rgba;
    int id;// Should initialize as NaN if possible;

    getopt(
            args,
            "action", &action,
            "point", &coords,
            "color|colour", &rgba,
            "id", &id
          );

    Message msg;
    if (coords.length == 2) {
        msg = toMessage( Point( coords[0], coords[1] ) );
    }


    writeln( msg );

  /*auto s = new TcpSocket();

  auto addr = new InternetAddress(args[1], to!ushort(args[2]));
  s.connect(addr);
  scope(exit) s.close();

  for (int i = 0; i < 1000; i++){
    auto r = uniform(int.min,int.max);
    auto send_buf = new OutBuffer();

    send_buf.write(r);

    s.send(send_buf.toBytes());

    ubyte[r.sizeof] recv_buf;
    s.receive(recv_buf);

    assert(r == *cast(int*)(send_buf.toBytes().ptr));
  }*/
}
