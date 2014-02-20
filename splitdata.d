import std.stdio;
import std.getopt;
import std.math;
import std.exception;
import std.conv;
import std.range;


void main(string[] args)
{
    real sec, min, bs, kbs, mbs, gbs;
    string ofilename = "splittedData.dat",
           ifilename;


    getopt(args,
        "sec", &sec,
        "min", &min,
        "bs", &bs,
        "kbs", &kbs,
        "gbs", &gbs,
        "output", &ofilename,
        "input", &ifilename);


    if(!min.isNaN)
        sec = min * 60;

    if(!sec.isNaN)
        bs = sec * 26e6;
    else{
        if(!gbs.isNaN)
            mbs = gbs * 1024;

        if(!mbs.isNaN)
            kbs = mbs * 1024;

        if(!kbs.isNaN)
            bs = kbs * 1024;
    }

    enforce(!bs.isNaN);


    fileSplitOut(ifilename, ofilename, bs.to!ulong);
}


void fileSplitOut(string ifilename, string ofilename, ulong size)
{
    auto iFile = File(ifilename);
    auto oFile = File(ofilename, "w");

    auto getCnt = size / 4096;

    foreach(ubyte[] buf; iFile.byChunk(4096).take(getCnt+1))
        oFile.rawWrite(buf);
}