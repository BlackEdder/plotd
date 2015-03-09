module plotd.data.transform;

version( unittest )
{
    import std.algorithm : equal;
    import std.stdio : writeln;
}
/// Transpose that deals with unequal row lengths
double[][] sloppyTranspose( double[][] data )
{
    double[][] transform;
    foreach( i; 0..data.length )
    {
        foreach( j; 0..data[i].length )
        {
            if (j>=transform.length)
                transform ~= [data[i][j]];
            else
                transform[j] ~= data[i][j];
        }
    }
    return transform;
}

///
unittest 
{
    assert( equal( [[0.0,1.0],[0.0],[0.0,1.0]].sloppyTranspose,
                [[0.0,0.0,0.0],[1.0,1.0]] ) );
}
