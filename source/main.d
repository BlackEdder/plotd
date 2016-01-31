import std.concurrency : receiveOnly;

version( assert ) 
{
    import std.stdio : writeln;
}
import plotcli.draw : drawActor;
import plotcli.parse : readStdinByLine;

void main(string[] args)
{
    debug writeln("Arguments: ", args);

    import std.concurrency : spawn, thisTid, send;

    auto childTid = spawn(&drawActor, thisTid, args.idup);

    import plotcli.options : defaultOptions, updateOptions;
    auto options = defaultOptions();
    options = updateOptions(options, args.dup[1 .. $]);

    foreach (msg; readStdinByLine(options.follow))
    {
        send(childTid, msg);
    }
    send( childTid, "#plotcli --quit" );
    auto wasSuccessful = receiveOnly!(bool);
    assert(wasSuccessful);
}
