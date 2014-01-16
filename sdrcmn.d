/*-------------------------------------------------------------------------------
* sdrfunc.c : SDR common functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
* Copyright (C) 2013 T. Takasu <http://www.rtklib.com>
*------------------------------------------------------------------------------*/
import sdr;
import util.trace;
import util.locker;
import sdrconfig;

import core.memory;
import core.simd;
import std.math;
import std.c.windows.windows;
import std.numeric;
import std.datetime;
import core.bitop;
import std.traits;
import std.range;
import std.algorithm;
import std.complex;
import std.functional;
import std.typecons;
import std.format;
import std.typetuple;

version(unittest) import std.stdio;

/* global variables -----------------------------------------------------------*/
private shared immutable(short[]) cost, sint;   // sin, cos lockup table

shared static this()
{    
    // モジュールコンストラクタ(スレッド起動時に実行される)
    // carrier loopup tableの初期化
    short[] c = new short[CDIV],
            s = new short[CDIV];

    foreach(i; 0 .. CDIV){
        c[i] = cast(short)floor((cos(DPI/CDIV*i)/CSCALE+0.5));
        s[i] = cast(short)floor((sin(DPI/CDIV*i)/CSCALE+0.5));
    }

    cost = c.dup;
    sint = s.dup;

        /* FFT initialization */
    static if(Config.useFFTW)
        fftwf_init_threads();
}


static if(!Config.useFFTW)
{
    private Fft fftObj;
    private cpx_t[] buffer;
}
else
{
    alias fftwLock = mutexLock!"fftw";
}



/**
nextが1である場合に、next2Pow(num)はnumより大きく、かつ、最小の2の累乗数を返します。

もし、nextが0であれば、next2Powはnumより小さく、かつ、最大の2の累乗数を返します。
nextがm > 1の場合には、next2Pow(num, m)は、next2Pow(num) << (m - 1)を返します。
*/
size_t nextPow2(T)(T num, size_t next = 1)
if(isIntegral!T)
in{
    assert(num >= 1);
}
body{
    static size_t castToSize_t(X)(X value)
    {
      static if(is(X : size_t))
        return value;
      else
        return value.to!size_t();
    }

    return (cast(size_t)1) << (bsr(castToSize_t(num)) + next);
}

///
pure nothrow @safe unittest{
    assert(nextPow2(10) == 16);           // デフォルトではnext = 1なので、次の2の累乗数を返す
    assert(nextPow2(10, 0) == 8);         // next = 0だと、前の2の累乗数を返す
    assert(nextPow2(10, 2) == 32);        // next = 2なので、next2Pow(10) << 1を返す。
}


/// ditto
F nextPow2(F)(F num, size_t next = 1)
if(isFloatingPoint!F)
in{
    assert(num >= 1);
}
body{
    int n = void;
    frexp(num, n);
    return (cast(F)2.0) ^^ (n + next - 1);
}

///
pure nothrow @safe unittest{
    assert(nextPow2(10.0) == 16.0);
    assert(nextPow2(10.0, 0) == 8.0);
    assert(nextPow2(10.0, 2) == 32.0);
}




/**
numより小さく、かつ最大の2の累乗を返します。

nextPow2(num, 0)に等価です
*/
auto previousPow2(T)(T num)
{
    return nextPow2(num, 0);
}


/**
xよりも小さな2^nを計算します。
*/
/* calculation FFT number of points (2^bits samples) ----------------------------
* calculation FFT number of points (round up)
* args   : double x         I   number of points (not 2^bits samples)
*          int    next      I   increment multiplier
* return : int                  FFT number of points (2^bits samples)
*------------------------------------------------------------------------------*/
size_t calcfftnum(T)(T x, size_t next = 0)
if(isIntegral!T || isFloatingPoint!T)
in{
    assert(x >= 1);
}
body{
    static if(isIntegral!T)
        return nextPow2(x, next);
    else if(isFloatingPoint!T){
        int exp = void;
        frexp(x, exp);
        return 1 << exp;
    }
}
pure nothrow @safe unittest{
    assert(calcfftnum(10) == 8);
    assert(calcfftnum(10, 1) == 16);
    assert(calcfftnum(10, 2) == 32);
}


/* calculation FFT number of points (2^bits samples) ----------------------------
* calculation FFT number of points using FFT resolution
* args   : double reso      I   FFT resolution
*          double ti        I   sampling interval (s)
* return : int                  FFT number of points (2^bits samples)
*------------------------------------------------------------------------------*/
size_t calcfftnumreso(real reso, real ti) pure nothrow @safe
{
    return calcfftnum(1/(reso * ti), 0);
}


/* complex FFT -----------------------------------------------------------------
* cpx=fft(cpx)
* args   : cpx_t  *cpx      I/O input/output complex data
*          size_t    n         I   number of input/output data
* return : none
*------------------------------------------------------------------------------*/
void cpxfft(cpx_t[] cpx)
{
    traceln("called");

  static if(!Config.useFFTW)
  {
    immutable size = cpx.length;

    if(fftObj is null || fftObj.size != size)
        fftObj = new Fft(size);

    if(sdrcmn.buffer.length < size)
        sdrcmn.buffer.length = size;

    sdrcmn.fftObj.fft(cpx, buffer[0 .. size]);
    cpx[] =  buffer[];
  }
  else
  {
    immutable n = cast(int)cpx.length;

    fftwLock!fftwf_plan_with_nthreads(NFFTTHREAD);  //fft execute in multi threads 
    fftwf_plan p = fftwLock!fftwf_plan_dft_1d(n, cpx.ptr, cpx.ptr, FFTW_FORWARD, FFTW_ESTIMATE);
    fftwLock!fftwf_execute(p); /* fft */
    fftwLock!fftwf_destroy_plan(p);
  }
}


/* complex IFFT -----------------------------------------------------------------
* cpx=ifft(cpx)
* args   : cpx_t  *cpx      I/O input/output complex data
*          int    n         I   number of input/output data
* return : none
*------------------------------------------------------------------------------*/
void cpxifft(cpx_t[] cpx)
{
    traceln("called");

  static if(!Config.useFFTW)
  {
    immutable size = cpx.length;

    if(fftObj is null || fftObj.size != size)
        fftObj = new Fft(size);

    if(sdrcmn.buffer.length < size)
        sdrcmn.buffer.length = size;

    sdrcmn.fftObj.inverseFft(cpx, buffer[0 .. size]);
    cpx[] =  buffer[];
  }
  else
  {
    immutable n = cast(int)cpx.length;

    fftwLock!fftwf_plan_with_nthreads(NFFTTHREAD); /* ifft execute in multi threads */
    fftwf_plan p = fftwLock!fftwf_plan_dft_1d(n, cpx.ptr, cpx.ptr, FFTW_BACKWARD, FFTW_ESTIMATE);
    fftwLock!fftwf_execute(p); /* ifft */
    fftwLock!fftwf_destroy_plan(p);
  }
}


/* convert short vector to complex vector ---------------------------------------
* cpx=complex(I,Q)
* args   : short  *I        I   input data array (real)
*          short  *Q        I   input data array (imaginary)
*          double scale     I   scale factor
*          int    n         I   number of input data
*          cpx_t *cpx       O   output complex array
* return : none
*------------------------------------------------------------------------------*/
void cpxcpx(T : float)(in T[] I, in T[] Q, double scale, cpx_t[] cpx)
in{
    assert(I is null || I.length == cpx.length);
    assert(Q is null || Q.length == cpx.length);
}
body{
    foreach(i, ref e; cpx){
        cpx[i].re = (I !is null ? I[i] : 0.0f) * scale;
        cpx[i].im = (Q !is null ? Q[i] : 0.0f) * scale;
    }
}


/* FFT convolution --------------------------------------------------------------
* conv=sqrt(abs(ifft(fft(cpxa).*conj(cpxb))).^2) 
* args   : cpx_t  *cpxa     I   input complex data array
*          cpx_t  *cpxb     I   input complex data array
*          int    m         I   number of input data
*          int    n         I   number of output data
*          int    flagsum   I   cumulative sum flag (conv+=conv)
*          double *conv     O   output convolution data
* return : none
*------------------------------------------------------------------------------*/
void cpxconv(cpx_t[] cpxa, in cpx_t[] cpxb, bool flagsum, double[] conv)
out{
    foreach(e; conv){
        assert(!isNaN(e));
    }
}
body{
    traceln("called");

    cpxfft(cpxa); /* fft */
    
    foreach(i, ref e; cpxa)
        e *= -cpxb[i].conj;

    cpxifft(cpxa); /* ifft */

    immutable m2 = (cast(double)cpxa.length) ^^ 2;
    foreach(j, ref e; conv){
        if(flagsum)
            e += cpxa[j].abs^^2 / m2;
        else
            e = cpxa[j].abs^^2 / m2;
    }
}


/* power spectrum calculation ---------------------------------------------------
* power spectrum: pspec=abs(fft(cpx)).^2
* args   : cpx_t*  cpx      I   input complex data array
*          int    n         I   number of input data
*          int    flagsum   I   cumulative sum flag (pspec+=pspec)
*          double *pspec    O   output power spectrum data
* return : none
*------------------------------------------------------------------------------*/
void cpxpspec(cpx_t[] cpx, bool flagsum, double[] pspec)
{
    cpxfft(cpx); /* fft */
    
    foreach(i, e; cpx){
        if (flagsum) /* cumulative sum */
            pspec[i] += e.abs ^^ 2;
        else
            pspec[i] = e.abs ^^ 2;
    }
}


template dot(size_t N, size_t M)
{
    private string genDotFunction()
    {
        auto app = appender!string();
        app ~= "void dot(A, B, C)(";

        app.formattedWrite("%(in A* a%s, %|%)", iota(0, N));
        app.formattedWrite("%(in B* b%s, %|%)", iota(0, M));
        app.formattedWrite("size_t n, ");
        app.formattedWrite("%(C* c%s, %)", iota(0, N));

        app ~= ") @system pure nothrow\n{\n";

        app ~= "    ";
        foreach(i; 0 .. N)
            foreach(j; 0 .. M)
                app.formattedWrite("c%1$s[%2$s] = ", i, j);
        app ~= "0;\n";

        app ~= "    foreach(i; 0 .. n){\n";
        foreach(i; 0 .. N)
            foreach(j; 0 .. M)
                app.formattedWrite("        c%1$s[%2$s] += a%1$s[i] * b%2$s[i];\n", i, j);

        app ~= "    }\n";
        app ~= "}\n";

        return app.data;
    }

    mixin(genDotFunction());
}


Tuple!(ElementType!R, size_t) findMaxWithIndex(alias pred = "a > b", R)(R r)
if(isForwardRange!R && hasLength!R && is(typeof(binaryFun!pred(r.front, r.front))))
{
    auto maxPos = r.save.minPos!pred;
    immutable olen = r.length,
              nlen = maxPos.length;

    return typeof(return)(maxPos.front, olen - nlen);
}


ElementType!R mean(R)(R r)
if(isInputRange!R)
{
    size_t s;
    ElementType!R sum = 0;
    foreach(e; r){
        sum += e;
        ++s;
    }

    return sum / s;
}


/**
t付近の最大3点について、ラグランジュ補完を行った結果を返します。

Params:
    x =     xのデータ列
    y =     f(x)のデータ列
    t =     補間したいxの値

Return: 補間されたf(t)
*/
F interp1(F, G)(in F[] x, in F[] y, G t) pure nothrow @safe
if(isFloatingPoint!F && is(G : F))
in{
    assert(x.length > 0);
    assert(y.length > 0);
}
body{
    immutable inputN = x.length < y.length ? x.length : y.length;

    if(inputN == 1)
        return y[0];
    else if(inputN == 2)    // loop unrolling
        return (y[0] * (t - x[1]) - y[1] * (t - x[0])) / (x[0] - x[1]);
    else if(inputN == 3){
        // loop unrolling
        immutable real x0m1 = x[0] - x[1],
                       x0m2 = x[0] - x[2],
                       x1m2 = x[1] - x[2],
                       tmx0 = t - x[0],
                       tmx1 = t - x[1],
                       tmx2 = t - x[2],
                       k0 = tmx1 * tmx2 / (x0m1 * x0m2) * y[0],
                       k1 = tmx2 * tmx0 / (x1m2 * x0m1) * y[1],
                       k2 = tmx0 * tmx1 / (x0m2 * x1m2) * y[2];

        return k0 - k1 + k2;
    }else{
        // データ数 <= 3にして再帰
        // tの近傍のxを探す

        // 特殊な場合
        if(t < x[1])
            return interp1(x[0 .. 3], y[0 .. 3], t);
        else if(t >= x[inputN - 2])
            return interp1(x[inputN-3 .. inputN], y[inputN-3 .. inputN], t);


        // tが、s[s] <= t <= s[s+1]に存在するようなsを探す
        immutable s = (in F[] x, in F t) pure nothrow @safe {
            size_t s = 0,       // tの探索範囲はx[s .. e]
                   e = inputN;

            // このループではtを探す <- 2分探索でsとeを縮めていく
            while(e - s != 1){
                immutable mid = (s + e) / 2;

                if(t < x[mid])
                    e = mid;
                else
                    s = mid;
            }

            return s;
        }(x, t);

        // 確認
        assert(x[s] <= t && t <= x[s+1]);

        // 3点目の選択。近い方の3点を取る
        if(std.math.abs(t - x[s]) < std.math.abs(t - x[s+1]))
            return interp1(x[s-1 .. s+2], y[s-1 .. s+2], t);
        else
            return interp1(x[s .. s+3], y[s .. s+3], t);
    }
}

///
pure nothrow @safe unittest{
    assert(approxEqual(interp1([0.0], [1.3], 5), 1.3));                             // 1点の場合は、y[0]を返すしかない
    assert(approxEqual(interp1([1.0, 2.0], [0.0, 4.0], 3), 8));                     // 2点の場合は線形補間
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 0.1), 0.01));      // 3点以上では、近傍3点のラグランジュ補完
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 0.5), 0.25));
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 1.1), 1.21));
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 1.9), 3.61));
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 2.1), 4.41));

    double[] x = cast(double[])[1900, 1910, 1920, 1930, 1940, 1950, 1960, 1970, 1980, 1990];
    double[] y = [ 75.995,  91.972, 105.711, 123.203, 131.669,
                  150.697, 179.323, 203.212, 226.505, 249.633];

    foreach(i, xe; x)
        assert(interp1(x, y, xe) == y[i]);
}


/* convert uint64_t to double ---------------------------------------------------
* convert uint64_t array to double array (subtract base value)
* args   : uint64_t *data   I   input uint64_t array
*          uint64_t base    I   base value
*          int    n         I   number of input data
*          double *out      O   output double array
* return : none
*------------------------------------------------------------------------------*/
void uint64todouble(in ulong[] data, ulong base, double[] out_) pure nothrow @safe
in{
    assert(data.length <= out_.length);
}
body{
    foreach(i, e; data)
        out_[i] = e - base;
}


/* resample code ----------------------------------------------------------------
* resample code
* args   : char   *code     I   code
*          int    len       I   code length (len < 2^(31-FPBIT))
*          double coff      I   initial code offset (chip)
*          int    smax      I   maximum correlator space (sample) 
*          double ci        I   code sampling interval (chip)
*          int    n         I   number of samples
*          short  *rcode    O   resampling code
* return : double               code remainder
*------------------------------------------------------------------------------*/
double resampling(R, W)(R src, double coff, size_t smax, double ci, size_t n, auto ref W sink)
if(isRandomAccessRange!R && hasLength!R && isOutputRange!(W, ElementType!R))
{
    immutable len = src.length;

    traceln("called");
    traceln("len: ", len);
    traceln("ci: ", ci);
    
    coff -= smax*ci;
    coff -= floor(coff/len)*len; /* 0<=coff<len */
    traceln("coff: ", coff);

    foreach(e; 0 .. n + 2 * smax){
        coff %= len;
        sink.put(src[coff.to!size_t()]);

        coff += ci;
    }
    traceln("return");
    return coff-smax*ci;
}


/* mix local carrier ------------------------------------------------------------
* mix local carrier to data
* args   : char   *data     I   data
*          int    dtype     I   data type (0:real,1:complex)
*          double ti        I   sampling interval (s)
*          int    n         I   number of samples
*          double freq      I   carrier frequency (Hz)
*          double phi0      I   initial phase (rad)
*          short  *I,*Q     O   carrier mixed data I, Q component
* return : double               phase remainder
*------------------------------------------------------------------------------*/
double mixcarr(T, U, string file = __FILE__, size_t line = __LINE__)(const(T)[] data, DType dtype, double ti, double freq, double phi0, U[] I, U[] Q)
in{
    final switch(dtype){
      case DType.I:
        assert(data.length == I.length);
        assert(data.length == Q.length);
        break;

      case DType.IQ:
        assert(data.length == I.length * 2);
        assert(data.length == Q.length * 2);
    }
}
body{
    traceln("called");

    double phi = phi0 * CDIV / DPI;
    immutable ps = freq * CDIV * ti; /* phase step */

    if (dtype==DType.IQ)        /* complex */
        foreach(i; 0 .. data.length / 2){
            immutable idx = (cast(ptrdiff_t)phi) & CMASK;     // マイナスの周波数も対応可能
            I[i] = cast(U)(cost[idx]*data[0] - sint[idx]*data[1]);
            Q[i] = cast(U)(cost[idx]*data[1] + sint[idx]*data[0]);

            data.popFrontN(2);
            phi += ps;
        }

    else if (dtype==DType.I)    /* real */
        foreach(i, e; data){
            immutable idx=(cast(ptrdiff_t)phi) & CMASK;       // マイナスの周波数も対応可能
            I[i] = cast(U)(cost[idx] * e);
            Q[i] = cast(U)(sint[idx] * e);

            phi += ps;
        }

    return (phi*DPI/CDIV) % DPI;
}

/**
SSEで使用可能な型のリストです
*/
alias SSETypeList = TypeTuple!(void16,
                               double2,
                               float4,
                               byte16,
                               ubyte16,
                               short8,
                               ushort8,
                               int4,
                               uint4,
                               long2,
                               ulong4);


/**
AVXで使用可能な型のリストです
*/
alias AVXTypeList = TypeTuple!( void32,
                                double4,
                                float8,
                                byte32,
                                ubyte32,
                                short16,
                                ushort16,
                                int8,
                                uint8,
                                long4,
                                ulong4);


/**
SIMD-Extensionによって使用可能な型のリストです
*/
alias SIMDTypeList = TypeTuple!(SSETypeList, AVXTypeList);

enum isSIMDType(T) = staticIndexOf!(T, SIMDTypeList) != -1;
enum isSIMDArray(T) = isArray!T && isSIMDType!(ForeachType!T);

auto toArray(T)(T aligned) pure nothrow @trusted
if(isSIMDArray!T)
{
    return (cast(typeof(T.init[0].ptr))aligned.ptr)[0 .. aligned.length * ForeachType!T.array.length];
}


real toNearby(real value, real pole) pure nothrow @safe
{
    value %= pole;
    if(value > pole/2)
        return value - pole;
    else if(value < -pole/2)
        return value + pole;
    return value;
}

pure nothrow @safe
unittest
{
    assert(toNearby(0.01, 1).approxEqual(0.01));
    assert(toNearby(1.99, 1).approxEqual(-0.01));
    assert(toNearby(-1.99, 1).approxEqual(0.01));
    assert(toNearby(-0.01, 1).approxEqual(-0.01));
}
