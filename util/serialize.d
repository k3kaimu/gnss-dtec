module util.serialize;

import sdr;
import msgpack;
import std.file;
import std.stdio;
import std.string;


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
    double[] xrange;
    double[] yrange;
    string xlabel;
    string ylabel;
    double[] xvalue;
    double[] yvalue;
    string title;
    string otherSetting;


    string toString() const
    {
        return format(`PlotObject{
    int nx              = %s;
    int ny              = %s;
    double[] x          = %s;
    double[] y          = %s;
    double[] z          = %s;
    PlotType type       = PlotType.%s;
    int skip            = %s;
    bool flagabs        = %s;
    double scale = 0    = %s;
    int pltno           = %s;
    double pltms = 0    = %s;
    double[] xrange     = %s;
    double[] yrange     = %s;
    string xlabel       = %(%s%);
    string ylabel       = %(%s%);
    double[] xvalue     = %s;
    double[] yvalue     = %s;
    string title        = %(%s%);
    string otherSetting = %(%s%);
}`, nx, ny, x, y, z, type, skip, flagabs, scale, pltno, pltms, xrange, yrange, [xlabel], [ylabel], xvalue, yvalue, [title], [otherSetting]);
    }
}



void serializedWrite(string file = __FILE__, size_t line = __LINE__)(string filename, PlotObject obj)
{
    traceln("called: ", file);
    ubyte[] packed = pack(obj);
    std.file.write(filename, packed);
}