import std.stdio;
import std.socket;
import std.string;
import std.conv;
import std.random;
import std.outbuffer;

int main(string[] args) {
  if (args.length != 3) {
    writefln("usage: %s <server host> <port>",args[0]); 
    return 0;
  }

  auto s = new UdpSocket();

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
  }



  return 0;
}
