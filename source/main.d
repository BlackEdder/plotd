import std.concurrency : receiveOnly;

version( assert ) 
{
    import std.stdio : writeln;
}
import plotcli.draw : run;
import plotcli.parse : readStdinByLine;

void main(string[] args)
{
    debug writeln("Arguments: ", args);

    import std.concurrency : spawn, thisTid, send;

    auto childTid = spawn(&run, thisTid, args.idup);

    foreach (msg; readStdinByLine(false))
    {
        send(childTid, msg);
    }
    auto wasSuccessful = receiveOnly!(bool);
    assert(wasSuccessful);
}
