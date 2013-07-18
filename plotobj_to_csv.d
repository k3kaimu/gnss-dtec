//##$ dmd -m64 -unittest -version=MAIN_IS_PLOTOBJ_TO_CSV_MAIN plotobj_to_csv sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrmain sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize

module plotdata;

import sdr;
import std.stdio;
import msgpack;
import util.serialize;
import std.file;
import std.process;
//import core.thread;
import std.range;
import std.algorithm;
import std.math;

version(MAIN_IS_PLOTOBJ_TO_CSV_MAIN){
    void main(string[] args)
    {
        immutable srcfilename = args[1];
        PlotObject obj = (){
            enforce(args.length > 1);
            auto data = cast(ubyte[])(srcfilename.read());

            PlotObject dst;
            unpack(data, dst);
            return dst;
        }();

        immutable dstfilename = srcfilename.retro().find('.').retro() ~ ".csv";

        File csvFile = File(dstfilename, "w");

        switch(obj.type){
            case PlotType.Y:
                csvFile.writeln("PlotType, Y,");
                foreach(i; iota(obj.ny).stride(obj.skip + 1))
                    csvFile.writefln("%s,,", obj.flagabs ? std.math.abs(cast(real)obj.y[i]) : obj.y[i]);
                break;

            case PlotType.XY:
                csvFile.writeln("PlotType, XY,");
                foreach(i; iota(obj.nx).stride(obj.skip + 1))
                    csvFile.writefln("%s, %s,", obj.x[i], obj.flagabs ? std.math.abs(cast(real)obj.y[i]) : obj.y[i]);
                break;

            default:
                enforce(0);
        }
        //writeln(obj);

/*
        sdrplt_t* plt = new sdrplt_t;
        plt.pipe = pipe();
        plt.processId = spawnProcess(`gnuplot\gnuplot.exe`, pipe.readEnd);
        plt.fp = plt.pipe.writeEnd;
        plt.nx = obj.nx;
        plt.ny = obj.ny;
        plt.x = obj.x.ptr;
        plt.y = obj.y.ptr;
        plt.z = obj.z.ptr;
        plt.type = obj.type;
        plt.skip = obj.skip;
        plt.flagabs = obj.flagabs;
        plt.scale = obj.scale;
        plt.pltno = obj.pltno;
        plt.pltms = obj.pltms;
        writeln(*plt);

        Thread.sleep(dur!"msecs"(10000));

        //plotgnuplot(plt);
        plt.fp.writeln("plot x");
        plt.fp.flush();

        {
            auto unused = readln();
        }*/
    }
}