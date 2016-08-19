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

    import plotcli.options : containOptions, defaultOptions, updateOptions;
    auto options = defaultOptions();
    options = updateOptions(options, args.dup[1 .. $]);
    const defOptions = options.dup;

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
            } else {
                if (msg.containOptions)
                {
                    options = defOptions.dup;
                    options = updateOptions(options, msg);
                } else
                    handleReceivedMessage(msg, options, aes, lineCount);
            }
        });

        if (MonoTime.currTime - drawTime > 100.dur!"msecs" || finished)
        {
            draw(aes);
            drawTime = MonoTime.currTime;
        }
    }
    send(ownerTid, true);
}

void handleReceivedMessage(string message, Options options,
    ref Appender!(typeof(aesDefaults())[]) aes, ref int lineCount)
{
    import std.array : array;
    import plotcli.data : toTuples;
    import plotcli.parse : toRange, stripComments;
    import plotcli.options : validData;

    message = message.stripComments;
    auto cols = message.toRange.array;
    if (options.validData(cols))
    {
        debug writeln("Accepting data: ", cols);
        foreach (t; cols.toTuples(options.dup, lineCount))
        {
            debug writeln("Converted data to aes: ", t);
            aes.put(t);

            if (options.rolling > 0 && aes.data.length > options.rolling)
                aes = Appender!(typeof(aesDefaults())[])( aes.data[($-options.rolling)..$] );
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
}

void draw(Appender!(typeof(aesDefaults())[]) aes)
{
    import std.range : empty, front;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.aes : group;
    import ggplotd.axes : xaxisLabel, yaxisLabel;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;
    import ggplotd.geom : geomType;
    import ggplotd.legend : continuousLegend, discreteLegend;

    version(plotcliGTK)
    {
        import core.thread : Thread;
        import ggplotd.ggplotd : title, Facets;
        import ggplotd.gtk : GTKWindow;
        static GTKWindow[string] windows;
        auto facets = Facets();
    }

    if (!aes.data.empty)
    {
        foreach (ps; group!("plotID","plotname","format")(aes.data))
        {
            GGPlotD gg;
            foreach (g; group!("type")(ps))
            {
                gg.put( xaxisLabel( ps.front.xlabel ) );
                gg.put( yaxisLabel( ps.front.ylabel ) );
                gg.put( colourGradient!XYZ( ps.front.colourgradient ) );
                if (!ps.front.legend.empty && ps.front.legend[0..1] == "c")
                    gg.put(continuousLegend);
                else if (!ps.front.legend.empty && ps.front.legend[0..1] == "d")
                    gg.put(discreteLegend);
            }
            gg.put( geomType( ps ) );
            version(plotcliGTK)
            {
                if (ps.front.format == "gtk")
                {
                    gg.put( title(
                        ps.front.plotname ~ "_" ~ ps.front.plotID) );
                    facets.put( gg );
                } else {
                    gg.save(ps.front.plotname ~ ps.front.plotID ~ "." ~
                        ps.front.format);
                }
            } else
                gg.save(ps.front.plotname ~ ps.front.plotID ~ "." ~
                    ps.front.format);
        }
    }
    version(plotcliGTK) {
        if (!facets.ggs.data.empty)
        {
            if ("main" !in windows )
            {
                auto window = new GTKWindow();
                new Thread( 
                  () { window.run("plotcli"); } ).start();
                windows["main"] = window;
            }
            windows["main"].clearWindow();
            windows["main"].draw(facets, 1280, 768);
        }
    }
}
