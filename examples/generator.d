import core.thread : Thread;
import core.time : dur;
import std.random : uniform;
import std.range : iota;
import std.stdio : writeln;

import dstats.random;

void multiple()
{
    auto help = "This example shows an hypothetical example where you want to plot different things. For example if you run a simulation and are logging two different results. For example from completely separate parts of your simulation code. Run it with generator multiple | plotcli";
    writeln(help);
    foreach( i; iota(1,1000 ) )
    {
        writeln( "#plotcli -x 0 -y 1 --type hist3d --plotID a" );
        writeln( 0.01*i*rNorm( 1,1 ), " ", 0.01*i*rNorm( 3, 1 ) );
        writeln( "#plotcli -x 0 --type hist --plotID b --fill 0.5" );
        writeln( rNorm( 0,1 ) );
    }
    writeln(help);
}

void mixing_types()
{
    auto help = "Example showing how to plot the same data with different plot types. Run it with generator types | plotcli -x 0,0,1,0,1 -y ,2 --type hist,point,hist,box,box --plotID a,b,a,c,c";
    writeln(help);
    foreach( i; iota(1,1000 ) )
    {
        writeln( rNorm( 0,0.1 ), ", ", rNorm( 3, 0.3 ), ", ", i*0.3*rNorm(-1,.1 ) );
    }
    writeln(help);
}

void long_running()
{
    auto help = "This is an example for piping a long running process to plotcli. Suggested way of running is: generator long | plotcli -x 0,1 --type hist --fill .5. Note that a pipe by default buffers, to get a smoother experience use unbuffer generator long | plotcli -x 0,1 --type hist --fill .5. Unbuffer can be found in the expect-dev package on ubuntu/debian.\n\nThe generated plot is plotcli.png. With a proper image viewer (e.g. eog/eye-of-gnome) you can open it and it will automatically reload when the figure is updated.";
    writeln(help);
    foreach( i; iota(1,1000) )
    {
        writeln( rNorm(0,1), "\t", rNorm( -3,1 ) );
        Thread.sleep( dur!("msecs")( uniform(0,250) ) );
    }
    writeln(help);
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
            case "long":
                long_running();
                break;
            default:
                writeln( "Unknown example: ", args[1] );
                break;
        }
    } else {
        writeln( "Generate the data for different examples. The first line will always suggest the way to pipe the example to plotcli. The currently supported data examples are: multiple, types and long.\n\nRun each with: generator name, i.e. generator multiple" );
    }
}
