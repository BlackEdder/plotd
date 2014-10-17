# Plotcli: Plot streams of data from the command line

Plotcli is a command line application that can create plots from text/csv files. It will ignore any lines it does not understand, so it is safe to use with files that contain non csv data as well. Typically I use it during simulations, where I simulate data, which I pipe to a file and then I plot it using plotcli

```
plotcli < path/to/file
```

While new data is coming in it will plot them and save the plot to a file (by default plotcli.png). I then normally use the eye of gnome (eog) to open the plot. The nice thing about eog is that it will keep reloading the updated plot, every time it is being written to. Currently plotcli will keep checking for new data until it is killed with ctrl+c.

Plotcli is meant to be adaptive and will automatically adapt the plot boundaries to encompass all the data.

## Installation

```
git clone http://github.com/BlackEdder/plotd.git
cd plotd
dub build -c plotcli -b release
```

This will create a binary in bin/plotcli which you can copy anywhere in your path.

## Usage:

```
$ plotcli --help
Usage: plotcli [-o OUTPUT] [-d FORMAT]

Plotcli is a plotting program that will plot data from provided data streams (files). It will ignore any lines it doesn't understand, making it possible to feed it "dirty" streams/files. All options can also be provided within the stream by using the prefix #plotcli (e.g. #plotcli -d x,y).

  -d FORMAT             String describing the content of each row. Different row formats supported: x, y and h, with h indication histogram data. For example: x,y,y or h,x,y. When there are more ys provided than xs (or vice versa) the last x will be matched to all remaining ys.
  -o OUTPUT             Outputfile (without extension).

Data format:
  Using -d it is possible to specify what each column in your data file represents. Supported formats are:

  x,y           The x and y coordinate for points
  lx,ly Line data
  h                     Histogram data

  Plotcli by default does a good job of figuring out which x and y data belong together, but you can optionally provide an numeric id to make this completely clear. I.e. x1,y1.

  Finally if you want to plot the data to different figures you can add a letter/name at the end: xa,ya or x1a,y1a. This plot id will be appended to the OUTPUT file name. 

```

## Examples

See the [wiki for examples](https://github.com/BlackEdder/plotd/wiki).

## License

The library is distributed under the GPL-v3 license. See the file COPYING for more details.
