import core.thread : Thread;
import core.time : dur;
import std.random : uniform;
import std.range : iota;
import std.stdio : writeln;

import dstats.random;

void multiple()
{
}

void mixing_types()
{
}

void tab_separator()
{
}

void long_running()
{
    writeln( "This is an example for piping a long running process to plotcli. Suggested way of running is: generator long | plotcli -x 0,1 --type hist --fill .5. Note that a pipe by default buffers, to get a smoother experience use unbuffer generator long | plotcli -x 0,1 --type hist --fill .5. Unbuffer can be found in the expect-dev package on ubuntu/debian.\n\nThe generated plot is plotcli.png. With a proper image viewer (e.g. eog/eye-of-gnome) you can open it and it will automatically reload when the figure is updated." );
    foreach( i; iota(0,1000) )
    {
        writeln( rNorm(0,1), ",", rNorm( -3,1 ) );
        Thread.sleep( dur!("msecs")( uniform(0,250) ) );
    }
}

void main(string[] args)
{
    writeln( "Given arguments: ", args );
    if (args.length >= 2)
    {
        writeln( "Generating example: ", args[1] );
        switch (args[1])
        {
            case "multiple":
                multiple();
                break;
            case "types":
                mixing_types();
                break;
            case "tab":
                tab_separator();
                break;
            case "long":
                long_running();
                break;
            default:
                writeln( "Unknown example: ", args[1] );
                break;
        }
    } else {
        writeln( "Generate the data for different examples. The first line will always suggest the way to pipe the example to plotcli. The currently supported data examples are: multiple, types, tab and long.\n\nRun each with: generator name, i.e. generator multiple" );
    }
}
