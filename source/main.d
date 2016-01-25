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

void main(string[] args)
{
    debug writeln("Arguments: ", args);

    Options options;

    options = updateOptions(options, args[1 .. $]);
    int maxCol = 0;
    // Also keep track of row number?
    int lineCount = 0;
    import std.range : Appender;
    import ggplotd.colour : ColourID;
    import ggplotd.ggplotd : GGPlotD;

    Appender!(typeof(AesDefaults)[]) aes;
    foreach (msg; readStdinByLine(false))
    {
        options = updateOptions(options, msg);
        msg = msg.stripComments;
        auto cols = msg.toRange.array;

        if (options.validData( cols ))
        {
            foreach( t; cols.toTuples( options, lineCount)) 
                aes.put( t );

            ++lineCount;
        }
    }
    import ggplotd.geom;

    foreach( ps; group!("plotID")( aes.data ) )
    {
        GGPlotD gg;
        foreach( g; group!("type")( ps ) )
        {
            if (g.front.type == "hist")
                gg.put(geomHist!(typeof(g))(g));
            else if (g.front.type == "line")
                gg.put(geomLine!(typeof(g))(g));
        }
        gg.save(options.basename ~ ps.front.plotID ~ ".png");
    }
}
