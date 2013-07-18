module util.serialize;

import sdr;
import msgpack;
import std.file;
import std.stdio;


struct PlotObject
{
    int nx;
    int ny;
    double[] x;
    double[] y;
    double[] z;
    PlotType type;
    int skip;
    bool flagabs;
    double scale = 0;
    int pltno;
    double pltms = 0;
}



void serializedWrite(string file = __FILE__, size_t line = __LINE__)(string filename, PlotObject obj)
{
    traceln("called: ", file);
    ubyte[] packed = pack(obj);
    std.file.write(filename, packed);
}