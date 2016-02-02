import std.concurrency : receiveOnly;

version( assert ) 
{
    import std.stdio : writeln;
}
import plotcli.draw : drawActor;

void main(string[] args)
{
    debug writeln("Arguments: ", args);

    import std.concurrency : spawn, thisTid, send;

    auto childTid = spawn(&drawActor, thisTid, args.idup);

    import plotcli.options : parseOptions;
    auto options = parseOptions(args.dup[1 .. $]);

    import core.thread : Thread;
    import core.time : dur;
    import std.stdio : readln;
    import std.string : chop;
    auto reading = true;
    while(reading)
    {
        auto msg = readln();
        send(childTid, msg.chop);
        if (msg.length == 0)
        {
            if (options.follow)
                Thread.sleep( 100.dur!"msecs" );
            else
                reading = false;
        }
    }
    send( childTid, "#plotcli --quit" );
    auto wasSuccessful = receiveOnly!(bool);
    assert(wasSuccessful);
}
