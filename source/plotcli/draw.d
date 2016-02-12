module plotcli.draw;

import core.time : MonoTime;
import std.concurrency : Tid;
import std.range : Appender;

version(unittest)
{
    import dunit.toolkit;
}

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
            draw(aes);
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
    import plotcli.options : containOptions, parseOptions, validData;

    if (message.containOptions)
        options = parseOptions(message);
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

unittest
{
    import plotcli.options : defaultOptions, OptionRange;
    auto opts = defaultOptions;
    opts.values["plotname"] = OptionRange!string( "bla" );
    assertEqual( opts.values["plotname"].front, "bla" );
    auto aes = Appender!(typeof(aesDefaults())[])();
    auto lc = 0;
    handleReceivedMessage("#plotcli -x 0", opts,
        aes, lc);
    assert( opts.values["plotname"].empty );
}

void draw(Appender!(typeof(aesDefaults())[]) aes)
{
    import std.range : empty, front;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.aes : group;
    import ggplotd.axes : xaxisLabel, yaxisLabel;
    import plotcli.geom : toGeom;

    version(plotcliGTK)
    {
        import core.thread : Thread;
        import ggplotd.gtk : GTKWindow;
        static GTKWindow[string] windows;
    }

    if (!aes.data.empty)
    {
        foreach (ps; group!("plotID","plotname","format")(aes.data))
        {
            GGPlotD gg;
            foreach (g; group!("type")(ps))
            {
                gg.put(g.toGeom(g.front.type));
                gg.put( xaxisLabel( ps.front.xlabel ) );
                gg.put( yaxisLabel( ps.front.ylabel ) );
            }
            version(plotcliGTK)
            {
                if (ps.front.format == "gtk")
                {
                    auto name = ps.front.plotname ~ ps.front.plotID;
                    if (name !in windows)
                    {
                        auto window = new GTKWindow();
                        new Thread( 
                            () { window.run("plotcli"); } ).start();
                        windows[name] = window;
                    }
                    windows[name].clearWindow();
                    windows[name].drawGG( gg, 470, 470 );
                } else {
                    gg.save(ps.front.plotname ~ ps.front.plotID ~ "." ~
                        ps.front.format);
                }
            } else
                gg.save(ps.front.plotname ~ ps.front.plotID ~ "." ~
                    ps.front.format);
        }
    }
}
