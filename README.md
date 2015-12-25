# Plotcli: Plot streams of data from the command line [![Build Status](https://travis-ci.org/BlackEdder/plotd.svg?branch=master)](https://travis-ci.org/BlackEdder/plotd)

Plotcli is a command line application that can create plots from text/csv
files and from piped data, making it useful during data analysis. Plotcli
works best in combination with other command line tools such as awk. Plotcli will ignore any lines it does not understand, so it is safe to use with files that contain non csv data as well. Typically I use it during simulations, where I simulate data, which I pipe to a file and then I plot it using plotcli:

```
plotcli < path/to/file
```

It will plot the data and save the plot to a file (by default plotcli.png). Plotcli has a command line switch similar to tail (-f) so that it will keep checking for new data until it is killed with ctrl+c.

Plotcli is meant to be adaptive and will automatically adapt the plot boundaries to encompass all the data.

## Installation

You need to have dub and cairo installed
(https://github.com/D-Programming-Language/dub). Then you can install
plotcli as follows:

```
git clone http://github.com/BlackEdder/plotd.git
cd plotd
dub build -b release
```

This will create a binary in bin/plotcli which you can copy anywhere in your path.

## Usage:

**plotcli** [*-f*] [*-o OUTPUT*] [*-d FORMAT*] [*-b BOUNDS*] [*--xlabel
XLABEL*] [*--ylabel YLABEL*] [*--margin-bounds MARGINBOUNDS*] [*--image
IMAGEFORMAT*]

Plotcli is a plotting program that will plot data from provided data
streams (files). It will ignore any lines it doesn’t understand, making
it possible to feed it "dirty" streams/files. All options can also be
provided within the stream by using the prefix \#plotcli (e.g. \#plotcli
**−d** x,y).

### Options

**−f**

Follow the stream, i.e. keep listening for new lines.

**−d** FORMAT

String describing the content of each row. Different row formats
supported: x, y and h, with h indication histogram data. For more
information see Data format section.

**−o** OUTPUT

Outputfile (without extension).

**−b** BOUNDS

Give specific bounds for the plot in a comma separated list
(min\_x,max\_x,min\_y,max\_y).

**−−xlabel** XLABEL

**−−ylabel** YLABEL

**−−margin−bounds** MARGINBOUNDS

Specific bounds (in pixel size) for the margins. Format (all in pixels):
xmargin,xwidth,ymargin,yheight. Default values 70,400,70,400.

**−−image** IMAGEFORMAT

Format of the resulting image (png/pdf/svg).

### Data format

Using **−d** it is possible to specify what each column in your data
file represents. Supported formats are:

Format | Description
-------|-------
x,y | The x and y coordinate for points
lx,ly | Line data h Histogram data 
hx,hy | 2D Histogram data 
.. | Extrapolate from previous options, i.e. x,y,.. −\> x,y,x,y,.. 
id | Default data id to use for this row of data (it is also possible to provide a column specific id (see Data ids below)) 
pn | Default plot name to use for this row of data (it is also possible to provide a column specific id (see Plot ids below))

Examples: x,y,y or h,x,y. When there are more ys provided than xs (or
vice versa) the last x will be matched to all remaining ys.

Data ids: plotcli by default does a good job of figuring out which x and
y data belong together, but you can optionally provide an numeric id to
make this completely clear. I.e. x1,y1. Data ids always need to directly
follow the format type (before plot ids).

Plot ids: if you want to plot the data to different figures you can add
a letter/name at the end: xa,ya or x1a,y1a. This plot id will be
appended to the OUTPUT file name.

Extrapolating (..): plotcli will try to extrapolate from your previous
options. This also works for simple plot ids. I.e. if you want a
separate histogram for each column: ha,hb,.. results in ha,hb,hc,hd,he
etc. Other examples: y,.. −\> y,y,y,y etc. x,y,y,.. −\> x,y,y,y,y etc.

## Examples

### Lines

[This example](https://github.com/BlackEdder/plotd/blob/master/examples/1/data.txt) creates lines from each column. With the x coordinate given by the row number.

![lines](http://blackedder.github.io/plotd/images/example1.png)

```
plotcli -o example1 < examples/1/data.txt
```

### Histogram

[This example](https://github.com/BlackEdder/plotd/blob/master/examples/2/data.txt) creates lines from each column. With the x coordinate given by the row number.
The following example creates 4 histograms, one for each column. See below for the histogram of the first column. You can see the other columns by following the links: [2](http://blackedder.github.io/plotd/images/example2b.png), [3](http://blackedder.github.io/plotd/images/example2c.png) and [4](http://blackedder.github.io/plotd/images/example2d.png).

![histogram 1](http://blackedder.github.io/plotd/images/example2a.png)

```
plotcli -o example2 < examples/2/data.txt
```

### 3D Histogram

[Here](https://github.com/BlackEdder/plotd/blob/master/examples/3/data.txt) the first two columns are used as the x and y data for a 3D histogram.

![histogram](http://blackedder.github.io/plotd/images/example3.png)

```
plotcli -o example3 < examples/3/data.txt
```

### Boxplot

[Here](https://github.com/BlackEdder/plotd/blob/master/examples/4/data.txt) each column is turned into a boxplot.

![Boxplot](http://blackedder.github.io/plotd/images/example4.png)

```
plotcli -o example4 < examples/4/data.txt
```

## Further tips

Of course plotcli can easily be used together with other command line tools. For example I used the following command 
```
awk '{ print $2/$3 }' abc_data/10_samples2 | plotcli -b 0,1,0,50
```
To plot a histogram of the second column divided by the third column.

## License

The library is distributed under the GPL-v3 license. See the file COPYING for more details.
