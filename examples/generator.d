import core.thread : Thread;
import core.time : dur;
import std.range : iota;
import std.stdio : writeln;

import dstats.random;

void main()
{
    foreach( i; iota(0,1000) )
    {
        writeln( rNorm(0,1), ",", rNorm( -3,1 ) );
        Thread.sleep( dur!("msecs")( 100 ) );
    }
}
