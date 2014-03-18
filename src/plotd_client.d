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
void rgbaHandler2( string value, Message msg ) {
    auto rgba = value.split( "," );
    Color color;
    color.r = to!double(rgba[0]);
    color.g = to!double(rgba[1]);
    color.b = to!double(rgba[2]);
    color.a = to!double(rgba[3]);

    msg = toMessage( color );
}

unittest {
    Message msg;
    rgbaHandler2( "0.1,0.3,0.4,0.5", msg );
    Color color;
    color.r = 0.1; color.g = 0.3, color.b = 0.4, color.a = 0.5;
    assert( msg == toMessage( color ) );
}


void main(string[] args) {
    string action;
    int id;// Should initialize as NaN if possible;

    Message msg;
    void coordHandler( string option, string value ) {
        auto coords = value.split( "," );
        msg = toMessage( Point( to!double(coords[0]), to!double(coords[1]) ) );
    }

    void rgbaHandler( string option, string value ) {
        rgbaHandler2( value, msg );
    }

    getopt(
            args,
            "action", &action,
            "point", &coordHandler,
            "color|colour", &rgbaHandler,
            "id", &id
          );

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
