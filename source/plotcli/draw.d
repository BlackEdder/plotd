module plotcli.draw;

import core.time : MonoTime;
import std.concurrency : Tid;
import std.range : Appender;

version(assert)
{
    import std.stdio : writeln;
}

import plotcli.options : Options;
import plotcli.data : aesDefaults;

void drawActor(Tid ownerTid, immutable string[] args)
{
    import core.time : dur, MonoTime;
    import std.concurrency : receive, send;

    import plotcli.options : defaultOptions, updateOptions;
    auto options = defaultOptions();
    options = updateOptions(options, args.dup[1 .. $]);

    Appender!(typeof(aesDefaults())[]) aes;
    auto drawTime = MonoTime.currTime - 1.dur!"seconds";
    auto lineCount = 0;
    bool finished = false;
    while (!finished)
    {
        receive( (string msg) {
            debug writeln("Received msg: ", msg);
            if (msg == "#plotcli --quit") {
                finished = true;
            } else 
                handleReceivedMessage(msg, options, aes, lineCount);
        });

        if (MonoTime.currTime - drawTime > 100.dur!"msecs" || finished)
        {
            draw(options, aes);
            drawTime = MonoTime.currTime;
        }
    }
    send(ownerTid, true);
}

void handleReceivedMessage(string message, ref Options options,
    ref Appender!(typeof(aesDefaults())[]) aes, ref int lineCount)
{
    import std.array : array;
    import plotcli.data : toTuples;
    import plotcli.parse : toRange, stripComments;
    import plotcli.options : updateOptions, validData;

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

void draw(in Options options, Appender!(typeof(aesDefaults())[]) aes)
{
    import std.range : empty, front;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.aes : group;
    import plotcli.geom : toGeom;

    if (!aes.data.empty)
    {
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
}
