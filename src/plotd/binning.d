module plotd.binning;

/**
  Bins is used for binning data

  Default bins are Bins!size_t, you can build multidimensional bins using Bins!Bins!size_t
  */
class Bins(T) {
    double min;
    double width;
    size_t max_size;

    size_t length() {
        return mybins.length;
    }
    
    int opApply(int delegate( ref double, ref T ) dg)
    {
        int result;

        double x = min;
        foreach ( el; mybins )
        {
            result = dg( x, el );
            if (result)
                break;

            x += width;
        }
        return result;
    }

    Bins!T dup() {
        auto bins = new Bins!T();
        bins.min = min;
        bins.width = width;
        bins.max_size = max_size;
        foreach ( el ; mybins )
            bins.mybins ~= el;
        return bins;
    }

    bool iambin() {return true;}

    private:
        T[] mybins;
}

/// For loop over Bins
unittest {
    auto bins = new Bins!size_t;
    bins.min = -1;
    bins.width = 0.5;
    bins.mybins = [1,2,3,4];

    double correct_x = bins.min;
    double correct_el = 1;
    foreach ( x, el; bins ) {
        assert( correct_x == x );
        assert( correct_el == el );
        correct_x += bins.width;
        correct_el++;
    }
}

/**
  Add data to the given bin id

  bin_ids is an array in case of multidimensional bins

  Ignore values that fall outside of the existing bin range
 */
Bins!T add_data_to_bin( T )( Bins!T bins, const size_t[] bin_ids ) 
{
    if (bin_ids[0] < bins.mybins.length) {
        bins.mybins[bin_ids[0]].add_data_to_bin( bin_ids[1..$] );
        if (bins.mybins[bin_ids[0]].max_size > bins.max_size)
            bins.max_size = bins.mybins[bin_ids[0]].max_size;
    }
    return bins;
}

Bins!T add_data_to_bin( T : size_t )( Bins!T bins, const size_t[] bin_ids ) 
{
    if (bin_ids[0] < bins.mybins.length) {
        bins.mybins[bin_ids[0]]++;
        if (bins.mybins[bin_ids[0]] > bins.max_size)
            bins.max_size = bins.mybins[bin_ids[0]];
    }
    return bins;
}

unittest {
    auto bins = new Bins!size_t;
    bins.min = -1;
    bins.width = 0.5;
    bins.max_size = 4;
    bins.mybins = [1,2,3,4];

    bins.add_data_to_bin( [1] );
    assert( bins.mybins[1] == 3 );
    bins.add_data_to_bin( [3] );
    assert( bins.mybins[3] == 5 );
    assert( bins.max_size == 5 );

    auto mbins = new Bins!(Bins!size_t);
    mbins.min = -1;
    mbins.width = 0.5;
    mbins.mybins = [bins, bins.dup];
    mbins.max_size = 5;
    mbins.add_data_to_bin( [1,2] );
    assert( mbins.mybins[1].mybins[2] == 4 );
    mbins.add_data_to_bin( [1,3] );
    assert( mbins.mybins[1].mybins[3] == 6 );
    assert( mbins.max_size == 6 );
}
/**
  Resize the bins

  Again an array in case of resizing multidmensional arrays
 */
Bins!T resize( T )( Bins!T bins, const size_t[] new_length ) {
    T default_value;
    assert( bins.mybins.length > 0, 
            "Multidimensional need to have at least one bin to correctly resize" );
    default_value = new T;
    default_value.min = bins.mybins[0].min;
    default_value.width = bins.mybins[0].width;
    while ( bins.mybins.length < new_length[0] )
        bins.mybins ~= [default_value];

    if ( new_length.length > 1 )
        foreach ( ref T bin; bins.mybins )
            bin.resize( new_length[1..$] );

    return bins;
}

Bins!T resize( T : size_t )( Bins!T bins, const size_t[] new_length ) {
    T default_value = 0;

    while ( bins.mybins.length < new_length[0] )
        bins.mybins ~= [default_value];
    return bins;
}

unittest {
    auto bins = new Bins!size_t;
    bins.min = -1;
    bins.width = 0.5;
    bins.mybins = [1,2,3,4];

    bins.resize( [3] );
    assert( bins.length == 4 );
    bins.resize( [6] );
    assert( bins.length == 6 );

    auto mbins = new Bins!(Bins!size_t);
    mbins.min = -1;
    mbins.width = 0.5;
    mbins.mybins = [bins, bins.dup];
    mbins.resize( [6] );
    assert( mbins.length == 6 );
    assert( mbins.mybins[5].min == bins.min );
    assert( mbins.mybins[5].width == bins.width );
    mbins.resize( [7,8] );
    assert( mbins.length == 7 );

    foreach( x, bin; mbins )
        assert( bin.length == 8 );
}

 
/**
  Calculate bin id based on data value and Bins
  */
size_t bin_id(T)( const Bins!T bins, double data ) {
    assert( data >= bins.min );
    return cast(size_t)( (data-bins.min)/bins.width );
}
unittest {
    auto bins = new Bins!size_t;
    bins.min = -1;
    bins.width = 0.5;
    assert( bin_id( bins, -1 ) == 0 );
    assert( bin_id( bins, -0.5 ) == 1 );
    assert( bin_id( bins, -0.25 ) == 1 );
}
/**
  Add data to existing Bins
  */
Bins!T add_data( T )( Bins!T bins, const double[] data ) {
    size_t[] ids;
    auto bins_step = bins;
    writeln( "bla" );
    for ( size_t i = 0; i < data.length; i++ ) {
        ids ~= bin_id( bins_step, data[i] );
        if (i < data.length -1)
            bins_step = bins_step.mybins[0];
    }
    return add_data_to_bin( bins, ids.reverse );
}

Bins!T add_data( T : size_t )( Bins!T bins, const double[] data ) {
    return add_data_to_bin( bins, [bin_id( bins, data[0] )] );
}

unittest {
    auto bins = new Bins!size_t;
    bins.min = -1;
    bins.width = 0.5;
    bins.max_size = 4;
    bins.mybins = [1,2,3,4];

    bins = bins.add_data( [-0.25] );
    assert( bins.mybins[1] == 3 );
    bins = add_data( bins, [0.75] );
    assert( bins.mybins[3] == 5 );
    assert( bins.max_size == 5 );

    auto mbins = new Bins!(Bins!size_t);
    mbins.min = -1;
    mbins.width = 0.5;
    mbins.mybins = [bins, bins.dup];
    mbins.max_size = 5;
    mbins.add_data_to_bin( [1,2] );
    assert( mbins.mybins[1].mybins[2] == 4 );
    mbins.add_data_to_bin( [1,3] );
    assert( mbins.mybins[1].mybins[3] == 6 );
    assert( mbins.max_size == 6 );
}

/**
  Bin an array of data
  */
