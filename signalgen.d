//##$ dmd -unittest -O -release -inline -version=Dnative -version=SignalGenerate signalgen sdr sdrmain fec rtklib sdracq sdrcmn sdrcode sdrinit sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize util/numeric

/**
GPS/GNSS信号を生成します。
*/
module signalgen;

import std.array : appender;
import std.conv : to;
import std.exception : enforce;
import std.math : cos, PI;
import std.range : hasSlicing, isForwardRange, isInfinite, take;
import std.stdio : File;

import std.stdio : writeln, writefln;
import std.getopt;


immutable Nbits = 3;

version(SignalGenerate):

import sdr : sdrini_t, CType, DType;
import sdrcode : gencode;
import sdrinit : readIniFile, checkInitValue;
import util.trace : tracing;


auto signal(sdrini_t ini, size_t idx)
{
    static struct Result()
    {
        real opIndex(size_t i) const
        {
            immutable x = codeAt(i),
                      c = carrierAt(i);

            return x * c * (1 << Nbits);
        }


        real codeAt(size_t i) const
        {
            scope(failure) writeln("fail %s(%s)", __FILE__, __LINE__);
            immutable idx = (to!size_t(idxToTime(i) * _codeFreq) + 8) % _code.length;
            return _code[idx];
        }


        real carrierAt(size_t i) const
        {
            scope(failure) writeln("fail %s(%s)", __FILE__, __LINE__);
            immutable theta = idxToTime(i) *_intermFreq * 2 * PI;
            return cos(theta);
        }


        real idxToTime(size_t i) const
        {
            return i / _samplingFreq;
        }


        real timeToIdx(real time) const
        {
            return time * _samplingFreq;
        }


        auto infRange() const @property
        {
            
            static struct InfRange()
            {
                static struct DollarToken{}
                enum bool empty = false;
                real front() @property const { return _result[_idx]; }
                void popFront() { ++_idx; }
                real opIndex(size_t i) const { return _result[_idx + i]; }
                InfRange!() save() @property const { return this; }
                DollarToken opDollar() const { return DollarToken(); }
                InfRange!() opSlice(size_t i, DollarToken) const
                {
                    InfRange!() dst = this;
                    dst._idx += i;
                    return dst;
                }


              private:
                size_t _idx;
                const Result!() _result;
            }

            static assert(isForwardRange!(InfRange!()));
            static assert(isInfinite!(InfRange!()));

            InfRange!() dst = {0, this};
            return dst;
        }


      private:
        //real _carrierFreq;
        real _codeFreq;
        real _samplingFreq;
        real _intermFreq;
        immutable(short)[] _code;
    }


    Result!() dst;
    int clen;
    double crate;
    short* codePtr = gencode(ini.sat[idx], ini.ctype[idx], &clen, &crate).enforce();

    with(dst){
        _codeFreq = crate;
        _samplingFreq = ini.f_sf[ini.ftype[idx] - 1];
        _intermFreq = ini.f_if[ini.ftype[idx] -1];
        _code = codePtr[0 .. clen].dup;
    }

    return dst;
}


void main(string[] args)
{
    string iniPath = "gnss-sdrcli.ini";
    size_t iniIndex = 0;
    string output;
    real totalTime = 1;

    getopt(args,
           "ini", &iniPath,
           "idx", &iniIndex,
           "time", &totalTime);

    tracing = false;


    sdrini_t ini;

    ini.readIniFile(iniPath);
    checkInitValue(ini);

    
    {
        scope(failure) writeln("fail %s(%s)", __FILE__, __LINE__);
        auto file = File("generatedCode_" ~ ini.ctype[iniIndex].to!string() ~ "_" ~ ini.sat[iniIndex].to!string() ~ ".dat", "w");

        auto signal = .signal(ini, iniIndex);

        auto app = appender!(ubyte[])();
        foreach(e; signal.infRange.take(signal.timeToIdx(totalTime).to!size_t()))
        {
            scope(failure) writeln("fail %s(%s)", __FILE__, __LINE__);
            app.put(cast(ubyte)(cast(byte)e));
            if(ini.dtype[iniIndex] == DType.IQ)
                app.put(cast(ubyte)0);

            if(app.data.length > 1024 * 1024){
                file.rawWrite(app.data);
                app.clear();
            }
        }

        file.rawWrite(app.data);
    }
    

    {
        scope(failure) writefln("fail %s(%s)", __FILE__, __LINE__);
        auto signal = .signal(ini, iniIndex);

        immutable ctime     = signal._code.length / signal._codeFreq;
        immutable nsamp     = cast(int)(signal._samplingFreq * ctime);
        immutable nsampchip = cast(int)(nsamp / signal._code.length);

        File file = File("gened.csv", "w");
        immutable start = nsampchip;
        foreach(i; start .. start + nsampchip * 100)
        {
            scope(failure) writefln("fail %s(%s)", __FILE__, __LINE__);
            file.writefln("%s, %s, %s, %s", signal.idxToTime(i), signal[i], signal.carrierAt(i), signal.codeAt(i));
        }

        writefln("interm : %s, samp : %s", signal._intermFreq, signal._samplingFreq);
    }
}