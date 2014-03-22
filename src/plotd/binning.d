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

    int opApply(int delegate( ref Tuple!(double, T) ) dg)
    {
        int result;

        double x = min;
        foreach ( T el; mybins )
        {
            result = dg((x, el));
            if (result)
                break;

            x += width;
        }
        return result;
    }

    /// For loop over Bins
    unittest {
        Bins!size_t bins;
        bins.min = -1;
        bins.width = 0.5;
        bins.mybins = [1,2,3,4];

        double x = bins.min;
        double el = 1;
        foreach ( Tuple!(double, size_t) tuple; bins ) {
            assert( tuple[0] == x );
            assert( tuple[1] == el );
            x += bins.width;
            el++;
        }
    }

    /**
      Add data to the given bin id

      bin_ids is an array in case of multidimensional bins

      Ignore values that fall outside of the existing bin range
      */
    void add_data_to_bin( const size_t[] bin_ids ) {
        if (bin_ids[0] < mybins.length) {
            static if (typeof(T) == Bins) {
                mybins[bin_ids[0]].add_data_to_bin( bin_ids[1..$] );
                if (mybins[bin_ids[0]].max_size > max_size)
                    max_size = mybins[bin_ids[0]];
             } else {
                mybins[bin_ids[0]]++;
                if (mybins[bin_ids[0]] > max_size)
                    max_size = mybins[bin_ids[0]];
            }
        }
    }

    unittest {
        Bins!size_t bins;
        bins.min = -1;
        bins.width = 0.5;
        bins.max_size = 4;
        bins.mybins = [1,2,3,4];

        bins.add_data_to_bin( [1] );
        assert( bins.mybins[1] == 3 );
        bins.add_data_to_bin( [3] );
        assert( bins.mybins[3] == 5 );
        assert( bins.max_size == 5 );

        Bins!(Bins!size_t) mbins;
        mbins.min = -1;
        mbins.width = 0.5;
        mbins.mybins = [bins, bins.dup];
        mbins.max_size = 5;
        bins.add_data_to_bin( [1,2] );
        assert( bins.mybins[1].mybins[2] == 4 );
        bins.add_data_to_bin( [1,3] );
        assert( bins.mybins[1].mybins[3] == 6 );
        assert( bins.max_size == 6 );
    }

    /**
      Resize the bins

      Again an array in case of resizing multidmensional arrays
      */
    void resize( const size_t[] new_length ) {
        T default_value;
        static if (typeof(T) == Bins) {
            assert( mybins.length > 0, "Multidimensional need to have at least one bin to correctly resize" );
            default_value = new Bins!T();
            default_value.min = mybins[0].min;
            default_value.width = mybins[0].width;
            if ( new_length.length > 1 )
                foreach ( ref T bin; mybins )
                    bin.resize( new_length[1] );
        } else
            default_value = 0;

        while ( mybins.length < new_length[0] )
            mybins ~= [default_value];
    }

    unittest {
        Bins!size_t bins;
        bins.min = -1;
        bins.width = 0.5;
        bins.mybins = [1,2,3,4];

        bins.resize( 3 );
        assert( bins.length == 4 );
        bins.resize( 6 );
        assert( bins.length == 6 );

        Bins!(Bins!size_t) mbins;
        mbins.min = -1;
        mbins.width = 0.5;
        mbins.mybins = [bins, bins.dup];
        mbins.resize( 6 );
        assert( mbins.length == 6 );
        assert( mbins.mybins[5].min == bins.min );
        assert( mbins.mybins[5].width == bins.width );
    }

    private:
        T[] mybins;
}

/**
  Calculate bin id based on data value and Bins
  */

/**
  Add data to existing Bins
  */

/**
  Bin an array of data
  */
