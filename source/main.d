import std.stdio : writeln;

import docopt;
import ggplotd.aes;

import plotcli.parse;

import std.algorithm : map;
import std.array : array;
import std.range : repeat;
import std.functional : memoize;
alias cachedDocopt = memoize!(docopt.docopt);

void main(string[] args)
{
    // Options
    debug writeln("Arguments: ", args);
    auto arguments = docopt.docopt(helpText, args[1 .. $], true, "plotcli");

    // In general we add it all to "aes". The aes also has column for figure output, and geomType. When plotting we group by figure, then type and then pass all the aes to each type.. The "aes" is a tuple appender that takes default types + x,y.. How do we deal with numeric/strings?

    int[] xcols;
    int[] ycols;
    int maxCol = 0;
    // Also keep track of row number?
    int lineCount = 0;
    import std.range : Appender;
    import ggplotd.colour : ColourID;
    import ggplotd.ggplotd : GGPlotD;
    Appender!(Tuple!(double, "x", double, "y", ColourID, "colour")[]) aes;
    GGPlotD gg;
    foreach( msg; readStdinByLine( false ) ) {
        import std.regex : match;
        import std.conv : to;
        import std.algorithm : max, reduce;
        auto m = msg.match(r"^#plotcli (.*)");
        if (m)
        {
            arguments = cachedDocopt(helpText, splitArgs(m
                .captures[1]), true, "plotcli", false);
            if (!arguments["-x"].isNull) {
                xcols = arguments["-x"]
                    .to!string
                    .toRange // This should be smarted and interpret ,..
                    .map!((a)=>a.to!int).array;
            }
            if (!arguments["-y"].isNull) {
                ycols = arguments["-y"]
                    .to!string
                    .toRange // This should be smarted and interpret ,..
                    .map!((a)=>a.to!int).array;
            }
            maxCol = reduce!("max(a,b)")(1,xcols ~ ycols);
            //assert( xcols.length == ycols.length || xcols.empty || ycols.empty );
        } else {
            auto cols = msg.toRange.array;
            auto allCols = xcols ~ ycols;
            if (allCols.empty)
                allCols = [0];
            if (cols.length > maxCol && cols.areNumeric( allCols )) {

                double[] xs;
                if (!xcols.empty)
                    xs = xcols.map!((a) => cols[a].to!double).array;
                else
                    xs = (to!double(lineCount)).repeat( ycols.length ).array;
                auto ys = ycols.map!((a) => cols[a].to!double).array;

                // Build tuples
                foreach( i, x; xs )
                    aes.put( 
                        Tuple!(double, "x", double, "y", ColourID, "colour")
                            ( x, ys[i], ColourID(i) ) );



                //msg.writeln;
                // Should only increase if actual data
                ++lineCount;
            }
        }
    }
    import ggplotd.geom : geomLine;
    gg.put( geomLine!(typeof(aes.data))( aes.data ) );
    gg.save( "plotcli.png" );
}
