import std.stdio : writeln;

import docopt;
import ggplotd.aes;

import plotcli.parse;
import plotcli.options;

import std.algorithm : map, reduce;
import std.array : array;
import std.conv : to;
import std.range : repeat;
import std.regex : match;

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

    Appender!(Tuple!(double, "x", double, "y", ColourID, "colour")[]) aes;
    GGPlotD gg;
    foreach (msg; readStdinByLine(false))
    {
        options = updateOptions(options, msg);
        msg = msg.stripComments;
        auto cols = msg.toRange.array;

        if (options.validData( cols ))
        {
            // REFACTOR: IDS to Numeric Values (given options.xColumns/options.yColumns, cols, max(xs,ys), lineCount)
            double[] xs;
            if (!options.xColumns.empty)
                xs = options.xColumns.map!((a) => cols[a].to!double).array;
            else
                xs = (to!double(lineCount)).repeat(options.yColumns.length).array;
            auto ys = options.yColumns.map!((a) => cols[a].to!double).array;

            // Build tuples
            foreach (i, x; xs)
                aes.put(Tuple!(double, "x", double, "y", ColourID,
                    "colour")(x, ys[i], ColourID(i)));

            //msg.writeln;
            // Should only increase if actual data
            ++lineCount;
        }
    }
    import ggplotd.geom : geomLine;

    gg.put(geomLine!(typeof(aes.data))(aes.data));
    gg.save("plotcli.png");
}
