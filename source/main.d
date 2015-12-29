import std.stdio : writeln;

import docopt;
import ggplotd.aes;

import plotcli.parse;

import std.functional : memoize;
alias cachedDocopt = memoize!(docopt.docopt);

void main(string[] args)
{
    // Options
    debug writeln("Arguments: ", args);
    auto arguments = docopt.docopt(helpText, args[1 .. $], true, "plotcli");

    // In general we add it all to "aes". The aes also has column for figure output, and geomType. When plotting we group by figure, then type and then pass all the aes to each type.. The "aes" is a tuple appender that takes default types + x,y.. How do we deal with numeric/strings?

    // Also keep track of row number?
    foreach( msg; readStdinByLine( false ) ) {
        import std.regex : match;
        import std.conv : to;
        auto m = msg.match(r"^#plotcli (.*)");
        if (m)
        {
            arguments = cachedDocopt(helpText, splitArgs(m
                .captures[1]), true, "plotcli", false);
            if (!arguments["-y"].isNull)
                arguments["-y"]
                    .to!string
                    .toRange // This should be smarted and interpret ,..
                    .map!((a)=>a.to!int).writeln;
        }

        msg.writeln;
    }
}
