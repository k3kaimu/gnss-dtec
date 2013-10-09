//##$ dmd -m64 -unittest -version=MAIN_IS_PLOTOBJ_TO_CSV_MAIN plotobj_to_csv sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrmain sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize util/numeric

/**
sdr.exeが吐くSerializedData内のdatファイルを解析して、様々な形式に変換するプログラム

datの中身は、util.serialized.PlotObjectをmsgpackでpackしたバイナリ。
このプログラムでは、そのバイナリデータをmsgpackでunpackし、CSVやText, Gnuplotのコマンドに変換するプログラム

コマンドライン引数
    ./plotobj_to_csv <datfile> <OutputTypes...>
        <datfile> :     対象のdatファイル
        <OutputTypes>:  出力したい形式のリスト
                        すべての形式で出力したい場合には何も書かない。

    ex.
        ./plotobj_to_csv SerializedData\acq_G03__20130721T161530.0874797.dat
        ./plotobj_to_csv SerializedData\acq_G03__20130721T161530.0874797.dat Text
        ./plotobj_to_csv SerializedData\acq_G03__20130721T161530.0874797.dat Text CSV
        ./plotobj_to_csv SerializedData\acq_G03__20130721T161530.0874797.dat GnuplotCmd


出力一覧
    .txt:   datファイルに格納されているPlotObjectの文字列表現.
    .csv:   csvファイル. Excelで処理したい場合に有用.
    .plt:   Gnuplotのloadコマンドでこのファイルを指定すればグラフが表示される
*/
module plotdata;

import sdr;
import std.stdio;
import msgpack;
import util.serialize;
import std.file;
import std.process;
import std.range;
import std.algorithm;
import std.math;
import std.conv;
import std.array;


enum OutputType
{
    Text,
    CSV,
    GnuplotCmd,
//    GnuplotPNG,
//    GnuplotEPS,
}


version(MAIN_IS_PLOTOBJ_TO_CSV_MAIN){
    void main(string[] args)
    {
        immutable srcFile = args[1],
                  srcFileNameBody = args[1].retro().find('.').retro()[0 .. $-1];

        // msgpackのunpack
        PlotObject obj = (){
            enforce(args.length > 1);
            auto data = cast(ubyte[])(read(srcFile));

            PlotObject dst;
            unpack(data, dst);
            return dst;
        }();


        OutputType[] outputTypes = (){
            if(args.length > 2)
                return args[2 .. $].map!(a => a.to!OutputType())().array();
            else
                return [__traits(allMembers, OutputType)].map!(a => a.to!OutputType())().array();
        }();


        foreach(e; outputTypes) final switch(e) {
          case OutputType.Text:
            obj.outputAs!(OutputType.Text)(srcFileNameBody);
            break;

          case OutputType.CSV:
            obj.outputAs!(OutputType.CSV)(srcFileNameBody);
            break;

          case OutputType.GnuplotCmd:
            obj.outputAs!(OutputType.GnuplotCmd)(srcFileNameBody);
            break;

          //case OutputType.GnuplotPNG:
          //  obj.outputAs!(OutputType.GnuplotPNG)(srcFileNameBody);
          //  break;

          //case OutputType.GnuplotEPS:
          //  obj.outputAs!(OutputType.GnuplotEPS)(srcFileNameBody);
          //  break;
        }
    }


    auto abs(T)(T v, bool flag)
    {
        return flag ? std.math.abs(v) : v;
    }


    void outputAs(OutputType type : OutputType.Text)(in PlotObject obj, string filename)
    {
        auto file = File(filename ~ ".txt", "w");
        file.write(obj);
    }


    void outputAs(OutputType type : OutputType.CSV)(in PlotObject obj, string filename)
    {
        auto file = File(filename ~ ".csv", "w");

        switch(obj.type){
          case PlotType.Y:
            file.writeln("PlotType, Y,");
            foreach(i; iota(0, obj.nx, obj.skip + 1))
                file.writefln("%s,", abs(obj.y[i], obj.flagabs) * obj.scale);
            break;

          case PlotType.XY:
            file.writeln("PlotType, XY,");
            file.writefln("%s,%s,", obj.xlabel, obj.ylabel);
            foreach(i; iota(0, obj.nx, obj.skip + 1)){
                file.writefln("%s,%s,", obj.x[i], abs(obj.y[i], obj.flagabs) * obj.scale);
            }
            break;

          case PlotType.SurfZ:
            file.writeln("PlotType, SurfZ,");
            file.writeln(",");

            // x軸の値
            foreach(j; iota(0, obj.nx, obj.xskip+1))
                file.writef("%s,", obj.xvalue[j]);

            // 実データの書き込み
            foreach(i; iota(0, obj.ny, obj.yskip+1)){
                // y軸の値
                file.writef("%s,", obj.yvalue[i]);

                foreach(j; iota(0, obj.nx, obj.xskip+1))
                    file.writef("%s,", abs(obj.z[j * obj.ny + i], obj.flagabs) * obj.scale);
                file.writeln();
            }
            break;

          case PlotType.Box:
            file.writeln("PlotType, Box,");
            foreach(i; iota(0, obj.nx, obj.skip + 1))
                file.writefln("%s,%s,", obj.x[i], obj.y[i] * obj.scale);
            break;

          default:
            assert(0);
        }
    }

    void outputAs(OutputType type : OutputType.GnuplotCmd)(in PlotObject obj, string filename)
    {
        auto file = File(filename ~ ".plt", "w");

        (!obj.xlabel.empty)      && file.writefln("set xlabel '%s'", obj.xlabel);
        (!obj.ylabel.empty)      && file.writefln("set ylabel '%s'", obj.ylabel);
        (obj.xrange.length >= 2) && file.writefln("set xrange [%s:%s]", obj.xrange[0], obj.xrange[1]);
        (obj.yrange.length >= 2) && file.writefln("set yrange [%s:%s]", obj.yrange[0], obj.yrange[1]);
        (!obj.title.empty)       && file.writefln("set title '%s'", obj.title);


        final switch(obj.type){
          case PlotType.Y:
            file.writeln("set grid");
            file.writeln("unset key");
            file.writeln("plot '-' with lp lw 1 pt 6 ps 2");

            foreach(i; iota(0, obj.ny, obj.skip+1))
                file.writefln("%s", abs(obj.y[i], obj.flagabs) * obj.scale);
            
            file.writeln("e");
            break;

          case PlotType.XY:
            file.writeln("set grid");
            file.writeln("unset key");
            file.writeln("plot '-' with p pt 6 ps 2");

            foreach(i; iota(0, obj.nx, obj.skip+1))
                file.writefln("%s\t%s", obj.x[i], abs(obj.y[i], obj.flagabs) * obj.scale);
            
            file.writeln("e");
            break;

          case PlotType.SurfZ:
            file.writeln("unset key");
            file.writeln("splot '-' with pm3d");
            
            foreach(i; iota(0, obj.ny, obj.yskip+1)){
                foreach(j; iota(0, obj.nx, obj.xskip+1))
                    file.writefln("%s %s %s", obj.xvalue[j], obj.yvalue[i], abs(obj.z[j * obj.ny + i], obj.flagabs) * obj.scale);
                file.writeln();
            }
            file.writeln("e");
            break;

          case PlotType.Box:
            file.writeln("set grid");
            file.writeln("unset key");
            file.writeln("set boxwidth 0.95");
            file.writeln(`set style fill solid border lc rgb "black"`);
            file.writeln("plot '-' with boxes");

            foreach(i; iota(0, obj.nx, obj.skip+1))
                file.writefln("%s\t%s", obj.x[i], obj.y[i] * obj.scale);
            file.writeln("e");
            break;
        }
    }

  version(none)
  {
    void outputAs(OutputType type : OutputType.GnuplotPNG)(in PlotObject obj, string filename)
    {
        if(!exists(filename ~ ".plt"))
            obj.outputAs!(OutputType.GnuplotCmd)(filename ~ ".plt");

        auto file = File(filename ~ "_png.plt", "w");
        auto buff = std.file.read(filename ~ ".plt");

        file.writeln("set terminal png");
        file.writefln("set output '%s'", filename ~ ".png");
        file.flush();
        file.close();

        std.file.append(filename ~ "_png.plt", buff);
    }


    void outputAs(OutputType type : OutputType.GnuplotEPS)(in PlotObject obj, string filename)
    {
        if(!exists(filename ~ ".plt"))
            obj.outputAs!(OutputType.GnuplotCmd)(filename ~ ".plt");

        auto file = File(filename ~ "_eps.plt", "w");
        auto buff = std.file.read(filename ~ ".plt");

        file.writeln("set terminal postscript eps");
        file.writefln("set output '%s'", filename ~ ".eps");
        file.flush();
        file.close();

        std.file.append(filename ~ "_eps.plt", buff);
    }
  }
}


auto yskip(in PlotObject obj) pure nothrow @safe
{
    return obj.ny < obj.nx ? 0 : obj.skip;
}


auto xskip(in PlotObject obj) pure nothrow @safe
{
    return obj.ny < obj.nx ? obj.skip : 0;
}