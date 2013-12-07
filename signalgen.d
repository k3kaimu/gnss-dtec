//##$ dmd -unittest -O -inline -release -m64 -version=SignalGenerate signalgen sdr sdrmain fec rtklib sdracq sdrcmn sdrcode sdrinit sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize util/numeric util/server

/**
GPS/GNSS信号を生成します。
*/
module signalgen;

import std.array : appender;
import std.conv : to;
import std.exception : enforce;
import std.math : cos, PI, cosh, exp;
import std.range : hasSlicing, isForwardRange, isInfinite, take, iota;
import std.stdio : File;

import std.stdio : writeln, writefln;
import std.getopt;
import std.parallelism : taskPool;


immutable Nbits = 3;

version(SignalGenerate):

import sdr : sdrini_t, CType, DType, Constant;
import sdrcode : gencode;
import sdrinit : readIniFile, checkInitValue;
import util.trace : tracing;


enum FuncType
{
    flat,           // [p] => TEC(t) = p
    lamp,           // [v, p] => TEC(t) = v*t + p
    parabola,       // [a, v, p] => TEC(t) = a*t^^2 + v*t + p
    sigmoid,        // [a, m, t0, p] => TEC(t) = m / (1 + exp(-a*(t-t0))) + p
}


auto signal(sdrini_t ini, size_t idx, real delegate(real) dopplerFunction)
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
            immutable theta = idxToTime(i) * 2 * PI * (_intermFreq + _dopperGen(idxToTime(i)));
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
        real delegate(real) _dopperGen;
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
        _dopperGen = dopplerFunction;
    }

    return dst;
}


void main(string[] args)
{
    string iniPath = "gnss-sdrcli.ini";
    real totalTime = 1;
    real delegate(real) diffTECFunc;
    real delegate(real) l1fdFunc;
    real delegate(real) l2fdFunc;

    {
        string tecParaStr, l1fdParaStr;
        FuncType tecFuncType = FuncType.flat, l1fdFuncType = FuncType.flat;
        real[] tecFuncParams = [0], l1fdFuncParams = [0];

        getopt(args,
               "ini", &iniPath,
               "time", &totalTime,
               "tecFunc", &tecFuncType,
               "tec_params", &tecParaStr,
               "l1fdFunc", &l1fdFuncType,
               "l1fd_params", &l1fdParaStr);

        tecFuncParams = tecParaStr.to!(real[])();
        l1fdFuncParams = l1fdParaStr.to!(real[])();

        auto diffTEC = (){
            final switch(tecFuncType){
              case FuncType.flat:
                return delegate(real t) => 0.0L;
              case FuncType.lamp:
                return delegate(real t) => tecFuncParams[0];
              case FuncType.parabola:
                return delegate(real t) => tecFuncParams[0] * 2 * t + tecFuncParams[1];
              case FuncType.sigmoid:
                return delegate(real t) => tecFuncParams[0] / 2 * tecFuncParams[1] / (cosh(tecFuncParams[0] * (t - tecFuncParams[2])) + 1);
            }
        }();

        diffTECFunc = delegate(real t) => (1 / Constant.TecCoeff.a * Constant.TecCoeff.freqTerm(Constant.L1CA.freq, Constant.L2C.freq)) ^^ -1 * diffTEC(t);

        l1fdFunc = (){
            final switch(tecFuncType){
              case FuncType.flat:
                return delegate(real t) => l1fdFuncParams[0];
              case FuncType.lamp:
                return delegate(real t) => l1fdFuncParams[0]*t + l1fdFuncParams[1];
              case FuncType.parabola:
                return delegate(real t) => l1fdFuncParams[0] * t ^^ 2 + l1fdFuncParams[1] * t + l1fdFuncParams[2];
              case FuncType.sigmoid:
                return delegate(real t) => l1fdFuncParams[1] / (1 + exp(- l1fdFuncParams[0] * (t - l1fdFuncParams[2]))) + l1fdFuncParams[3];
            }
        }();

        l2fdFunc = delegate(real t) => (Constant.L1CA.lambda * l1fdFunc(t) - diffTECFunc(t)) / Constant.L2C.lambda;
    }

    tracing = false;


    sdrini_t ini;

    ini.readIniFile(iniPath);
    checkInitValue(ini);

    foreach(iniIdx; taskPool.parallel(iota(0, ini.nch)))
    {
        scope(failure) writeln("fail %s(%s)", __FILE__, __LINE__);
        auto file = File("generatedCode_" ~ ini.ctype[iniIdx].to!string() ~ "_" ~ ini.sat[iniIdx].to!string() ~ ".dat", "w");

        auto signal = .signal(ini, iniIdx, ini.ctype[iniIdx] == CType.L1CA ? l1fdFunc : l2fdFunc);

        auto app = appender!(ubyte[])();
        foreach(e; signal.infRange.take(signal.timeToIdx(totalTime).to!size_t()))
        {
            scope(failure) writefln("fail %s(%s)", __FILE__, __LINE__);
            app.put(cast(ubyte)(cast(byte)e));
            if(ini.dtype[ini.ftype[iniIdx] - 1] == DType.IQ)
                app.put(cast(ubyte)0);

            if(app.data.length > 1024 * 1024){
                file.rawWrite(app.data);
                app.clear();
            }
        }

        file.rawWrite(app.data);
    }
}