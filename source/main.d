import std.stdio : writeln;

import docopt;

import std.algorithm : map, reduce;
import std.array : array;
import std.conv : to;
import std.range : front, repeat;
import std.regex : match;

import ggplotd.aes : group;

import plotcli.parse;
import plotcli.options;
import plotcli.data;

import core.time : MonoTime, dur;
import std.concurrency : send, receiveOnly, receiveTimeout, Tid;
import std.range : Appender;
import ggplotd.colour : ColourID;
import ggplotd.ggplotd : GGPlotD;

void run(Tid ownerTid, immutable string[] args)
{
    import std.range : walkLength;
    auto options = defaultOptions();
    options = updateOptions(options, args.dup[1 .. $]);
    Appender!(typeof(aesDefaults())[]) aes;
    auto drawTime = MonoTime.currTime - 1.dur!"seconds";
    auto lineCount = 0;
    bool finished = false;
    while (!finished)
    {
        auto received = receiveTimeout(100.dur!"msecs", (string msg) {
            writeln("Received msg: ", msg);
            handleReceivedMessage(msg, options, aes, lineCount, drawTime);
            if (aes.data.walkLength > 0 && MonoTime.currTime - drawTime > 100.dur!"msecs")
            {
                draw(options, aes, lineCount, drawTime);
                drawTime = MonoTime.currTime;
            }}
        );

        if (!received)// && !options.follow)
        {
            finished = true;
            draw(options, aes, lineCount, drawTime);
        }
    }
    send(ownerTid, true);
}

void handleReceivedMessage(string message, ref Options options,
    ref Appender!(typeof(aesDefaults())[]) aes, ref int lineCount, ref MonoTime drawTime)
{
    options = updateOptions(options, message);
    message = message.stripComments;
    auto cols = message.toRange.array;

    if (options.validData(cols))
    {
        debug writeln("Accepting data: ", cols);
        foreach (t; cols.toTuples(options.dup, lineCount))
        {
            debug writeln("Converted data to aes: ", t);
            aes.put(t);
        }
        ++lineCount;
    }
}

void draw(ref Options options, ref Appender!(typeof(aesDefaults())[]) aes, ref int lineCount, ref MonoTime drawTime)
{
    import ggplotd.geom;
    import plotcli.geom;

    foreach (ps; group!("plotID")(aes.data))
    {
        GGPlotD gg;
        foreach (g; group!("type")(ps))
        {
            gg.put(g.toGeom(g.front.type));
        }
        gg.save(options.basename ~ ps.front.plotID ~ ".png");
    }
}

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
