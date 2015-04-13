/*
   Functions to calculate summary statistics
   */
module plotd.data.summary;

import std.conv : to;
import std.math : floor, ceil;

version( unittest )
{
    import std.stdio : writeln;
    import std.algorithm : equal;
}

/// Return the limits indicated with different alphas
RANGE limits( RANGE )( RANGE range, double[] alphas )
{
    import std.algorithm : sort;
    auto sorted = range.sort();
    RANGE lims;
    foreach( a; alphas ) {
        lims ~= sorted[ floor( a*sorted.length ).to!size_t ];
    }
    return lims;
}

///
unittest
{
    assert( equal( [1,2,3,4,5].limits( [0.05, 0.5, 0.95] ), 
            [1,3,5] ) );
}


