/*-------------------------------------------------------------------------------
* sdrfunc.c : SDR common functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
* Copyright (C) 2013 T. Takasu <http://www.rtklib.com>
*------------------------------------------------------------------------------*/
import sdr;
import util.trace;

import core.memory;
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
}


static if(!isVersion!"UseFFTW")
{
    private Fft fftObj;
    private size_t fftObjSize;
    private cpx_t[] buffer;
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

  static if(!isVersion!"UseFFTW"){
    immutable size = cpx.length;

    if(size != fftObjSize)
        fftObj = new Fft(size);

    if(sdrcmn.buffer.length < size)
        sdrcmn.buffer.length = size;

    sdrcmn.fftObj.fft(cpx, buffer[0 .. size]);
    cpx[] =  buffer[];
  }else{
    immutable n = cast(int)cpx.length;

    fftwf_plan_with_nthreads(NFFTTHREAD);  //fft execute in multi threads 
    fftwf_plan p = fftwf_plan_dft_1d(n, cpx.ptr, cpx.ptr, FFTW_FORWARD, FFTW_ESTIMATE);
    fftwf_execute(p); /* fft */
    fftwf_destroy_plan(p);
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

  static if(!isVersion!"UseFFTW"){
    immutable size = cpx.length;

    if(size != fftObjSize)
        fftObj = new Fft(size);

    if(sdrcmn.buffer.length < size)
        sdrcmn.buffer.length = size;

    sdrcmn.fftObj.inverseFft(cpx, buffer[0 .. size]);
    cpx[] =  buffer[];
  }else{
    immutable n = cast(int)cpx.length;

    fftwf_plan_with_nthreads(NFFTTHREAD); /* ifft execute in multi threads */
    fftwf_plan p = fftwf_plan_dft_1d(n, cpx.ptr, cpx.ptr, FFTW_BACKWARD, FFTW_ESTIMATE);
    fftwf_execute(p); /* ifft */
    fftwf_destroy_plan(p);
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



/* dot products: d1=dot(a1,b),d2=dot(a2,b) --------------------------------------
* args   : short  *a1       I   input short array
*          short  *a2       I   input short array
*          short  *b        I   input short array
*          size_t    n         I   number of input data
*          short  *d1       O   output short array
*          short  *d2       O   output short array
* return : none
*------------------------------------------------------------------------------*/
deprecated void dot_21(const short *a1, const short *a2, const short *b, size_t n,
                   double *d1, double *d2) nothrow
{
    version(none){
        immutable result = dot!long(a1[0 .. n], a2[0 .. n])(b[0 .. n]);
        d1[0] = result[0][0];
        d2[0] = result[1][0];
    }else{

        const(short)* p1=a1, p2=a2, q=b;
        
        d1[0]=d2[0]=0.0;
        
        for (;p1<a1+n;p1++,p2++,q++) {
            d1[0]+=(*p1) * (*q);
            d2[0]+=(*p2) * (*q);
        }
    }
}


deprecated void dot_21(in short[] a1, in short[] a2, in short[] b, double[] d1, double[] d2) nothrow
{
    dot_21(a1.ptr, a2.ptr, b.ptr, a1.length, d1.ptr, d2.ptr);
}


/* dot products: d1={dot(a1,b1),dot(a1,b2)},d2={dot(a2,b1),dot(a2,b2)} ----------
* args   : short  *a1       I   input short array
*          short  *a2       I   input short array
*          short  *b1       I   input short array
*          short  *b2       I   input short array
*          size_t    n         I   number of input data
*          short  *d1       O   output short array
*          short  *d2       O   output short array
* return : none
*------------------------------------------------------------------------------*/
deprecated void dot_22(in short *a1, in short *a2, in short *b1, in short *b2, size_t n,
            double *d1, double *d2) nothrow
{
    version(none){
        immutable result = dot!long(a1[0 .. n], a2[0 .. n])(b1[0 .. n], b2[0 .. n]);
        d1[0] = result[0][0];
        d1[1] = result[0][1];
        d2[0] = result[1][0];
        d2[1] = result[1][1];
    }else{
        const(short)* p1 = a1,
                      p2 = a2,
                      q1 = b1,
                      q2 = b2;
        
        d1[0] = d1[1] = d2[0] = d2[1] = 0.0;
        
        for (;p1<a1+n;p1++,p2++,q1++,q2++) {
            d1[0] += (*p1) * (*q1);
            d1[1] += (*p1) * (*q2);
            d2[0] += (*p2) * (*q1);
            d2[1] += (*p2) * (*q2);
        }
    }
}

deprecated void dot_22(in short[] a1, in short[] a2, in short[] b1, in short[] b2, double[] d1, double[] d2) nothrow
{
    dot_22(a1.ptr, a2.ptr, b1.ptr, b2.ptr, a1.length, d1.ptr, d2.ptr);
}


/* dot products: d1={dot(a1,b1),dot(a1,b2),dot(a1,b3)},d2={...} -----------------
* args   : short  *a1       I   input short array
*          short  *a2       I   input short array
*          short  *b1       I   input short array
*          short  *b2       I   input short array
*          short  *b3       I   input short array
*          size_t    n         I   number of input data
*          short  *d1       O   output short array
*          short  *d2       O   output short array
* return : none
*------------------------------------------------------------------------------*/
deprecated void dot_23(const short *a1, const short *a2, const short *b1,
                   const short *b2, const short *b3, size_t n, double *d1,
                   double *d2) nothrow
{
    version(none){
        immutable result = dot!long(a1[0 .. n], a2[0 .. n])(b1[0 .. n], b2[0 .. n], b3[0 .. n]);

        d1[0] = result[0][0];
        d1[1] = result[0][1];
        d1[2] = result[0][2];
        d2[0] = result[1][0];
        d2[1] = result[1][1];
        d2[2] = result[1][2];
    }else{
        const(short)* p1=a1, p2=a2, q1=b1, q2=b2, q3=b3;
        
        d1[0] = d1[1] = d1[2] = d2[0] = d2[1] = d2[2] = 0.0;
        
        for (;p1<a1+n;p1++,p2++,q1++,q2++,q3++) {
            d1[0] += (*p1) * (*q1);
            d1[1] += (*p1) * (*q2);
            d1[2] += (*p1) * (*q3);
            d2[0] += (*p2) * (*q1);
            d2[1] += (*p2) * (*q2);
            d2[2] += (*p2) * (*q3);
        }
    }
}


deprecated void dot_23(in short[] a1, in short[] a2, in short[] b1, in short[] b2, in short[] b3, double[] d1, double[] d2) nothrow
{
    dot_23(a1.ptr, a2.ptr, b1.ptr, b2.ptr, b3.ptr, a1.length, d1.ptr, d2.ptr);
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


/* multiply char/short vectors --------------------------------------------------
* multiply char/short vectors: out=data1.*data2
* args   : char   *data1    I   input char array
*          short  *data2    I   input short array
*          int    n         I   number of input data
*          short  *out      O   output short array
* return : none
*------------------------------------------------------------------------------*/

deprecated void mulvcs(const(byte)* data1, const short *data2, size_t n, short *out_) pure nothrow
{   
    int i;
    for (i=0;i<n;i++) out_[i]=cast(short)(data1[i]*data2[i]);
}


deprecated void mulvcs(in byte[] data1, in short[] data2, short[] out_) pure nothrow
{
    foreach(i; 0 .. data1.length)
        out_[i] = cast(short)(data1[i] * data2[i]);
}


/* sum float vectors ------------------------------------------------------------
* sum float vectors: out=data1.+data2
* args   : float  *data1    I   input float array
*          float  *data2    I   input float array
*          int    n         I   number of input data
*          float  *out      O   output float array
* return : none
* note   : AVX command is used if "AVX" is defined
*------------------------------------------------------------------------------*/
deprecated void sumvf(const float *data1, const float *data2, int n, float *out_) pure nothrow
{
    int i;
    for (i=0;i<n;i++) out_[i]=data1[i]+data2[i];
}


void sumvf(in float[] data1, in float[] data2, float[] out_) @safe
{
    out_[] = data1[] + data2[];
}


/* sum double vectors -----------------------------------------------------------
* sum double vectors: out=data1.+data2
* args   : double *data1    I   input double array
*          double *data2    I   input double array
*          int    n         I   number of input data
*          double *out      O   output double array
* return : none
* note   : AVX command is used if "AVX" is defined
*------------------------------------------------------------------------------*/
deprecated void sumvd(const double *data1, const double *data2, size_t n, double *out_) pure nothrow
{
    int i;
    for (i=0;i<n;i++) out_[i]=data1[i]+data2[i];
}


void sumvd(in double[] data1, in double[] data2, double[] out_) @safe
{
    out_[] = data1[] + data2[];
}

/* maximum value and index (int array) ------------------------------------------
* calculate maximum value and index
* args   : double *data     I   input int array
*          int    n         I   number of input data
*          int    exinds    I   exception index (start)
*          int    exinde    I   exception index (end)
*          int    *ind      O   index at maximum value
* return : int                  maximum value
* note   : maximum value and index are calculated without exinds-exinde index
*          exinds=exinde=-1: use all data
*------------------------------------------------------------------------------*/
deprecated int maxvi(const int *data, size_t n, ptrdiff_t exinds, ptrdiff_t exinde, int *ind) pure nothrow
{
    int i;
    int max=data[0];
    *ind=0;
    for(i=1;i<n;i++) {
        if ((exinds<=exinde)&&(i<exinds||i>exinde)||((exinds>exinde)&&(i<exinds&&i>exinde))) {
            if (max<data[i]) {
                max=data[i];
                *ind=i;
            }
        }
    }
    return max;
}


deprecated int maxvi(in int[] data, ptrdiff_t exinds, ptrdiff_t exinde, out int ind) pure nothrow
{
    return maxvi(data.ptr, data.length, exinds, exinde, &ind);
}


/* maximum value and index (float array) ----------------------------------------
* calculate maximum value and index
* args   : float  *data     I   input float array
*          int    n         I   number of input data
*          int    exinds    I   exception index (start)
*          int    exinde    I   exception index (end)
*          int    *ind      O   index at maximum value
* return : float                maximum value
* note   : maximum value and index are calculated without exinds-exinde index
*          exinds=exinde=-1: use all data
*------------------------------------------------------------------------------*/
deprecated float maxvf(const float *data, size_t n, ptrdiff_t exinds, ptrdiff_t exinde, int *ind) pure nothrow
{
    int i;
    float max=data[0];
    *ind=0;
    for(i=1;i<n;i++) {
        if ((exinds<=exinde)&&(i<exinds||i>exinde)||((exinds>exinde)&&(i<exinds&&i>exinde))) {
            if (max<data[i]) {
                max=data[i];
                *ind=i;
            }
        }
    }
    return max;
}


deprecated float maxvf(in float[] data, int exinds, int exinde, out int ind) pure nothrow
{
    return maxvf(data.ptr, data.length, exinds, exinde, &ind);
}


/* maximum value and index (double array) ---------------------------------------
* calculate maximum value and index
* args   : double *data     I   input double array
*          int    n         I   number of input data
*          int    exinds    I   exception index (start)
*          int    exinde    I   exception index (end)
*          int    *ind      O   index at maximum value
* return : double               maximum value
* note   : maximum value and index are calculated without exinds-exinde index
*          exinds=exinde=-1: use all data
*------------------------------------------------------------------------------*/
deprecated double maxvd(const double *data, size_t n, int exinds, int exinde, int *ind) pure nothrow
in{
    assert(n <= int.max);
    foreach(e; data[0 .. n])
        assert(!isNaN(e));
}
out(result){
    assert(!isNaN(result));
}
body{
    double max=data[0];
    *ind=0;
    foreach(i; 1 .. n) {
        if ((exinds<=exinde)&&(i<exinds||i>exinde)||((exinds>exinde)&&(i<exinds&&i>exinde))) {
            if (max<data[i]) {
                max=data[i];
                *ind = cast(int)i;
            }
        }
    }
    return max;
}


deprecated double maxvd(in double[] data, int exinds, int exinde, out int ind) pure nothrow
{
    return maxvd(data.ptr, data.length, exinds, exinde, &ind);
}


Tuple!(ElementType!R, size_t) findMaxWithIndex(alias pred = "a > b", R)(R r)
if(isForwardRange!R && hasLength!R && is(typeof(binaryFun!pred(r.front, r.front))))
{
    auto maxPos = r.save.minPos!pred;
    immutable olen = r.length,
              nlen = maxPos.length;

    return typeof(return)(maxPos.front, olen - nlen);
}


//Tuple!(ElementType!R, size_t) findMaxWithIndex(alias pred = "a > b", R)(R r, ptrdiff_t excludeIndexStart, ptrdiff_t excludeIndexEnd)
//if(isForwardRange!R && hasLength!R && is(typeof(binaryFun!pred(r.front, r.front))))
//{
//    if(excludeIndexStart <= excludeIndexEnd)
//        return r.save.zip(iota(size_t.max))
//                     .filter!(a => a[1].isIntervalIn!")("(excludeIndexStart, excludeIndexEnd))()
//                     .minPos!((a, b) => binaryFun!pred(a[0], b[0]))().front;
//    else
//        return r.save.zip(iota(size_t.max))
//                     .filter!(a => a[1].isIntervalIn!"()"(excludeIndexEnd, excludeIndexStart))()
//                     .minPos!((a, b) => binaryFun!pred(a[0], b[0]))().front;
//}


/* mean value (double array) ----------------------------------------------------
* calculate mean value
* args   : double *data     I   input double array
*          int    n         I   number of input data
*          int    exinds    I   exception index (start)
*          int    exinde    I   exception index (end)
* return : double               mean value
* note   : mean value is calculated without exinds-exinde index
*          exinds=exinde=-1: use all data
*------------------------------------------------------------------------------*/
deprecated double meanvd(const double *data, int n, int exinds, int exinde) /*pure nothrow*/
in{
    foreach(e; data[0 .. n])
        assert(!isNaN(e));
}
out(result){
    assert(!isNaN(result));
}
body{
    debug(AcqDebug) writefln("exind: arr.length = %s, arr[%s .. %s];", n, exinds, exinde);
    int i,ne=0;
    double mean=0.0;
    for(i=0;i<n;i++) {
        if ((exinds<=exinde)&&(i<exinds||i>exinde)) mean+=data[i];
        else if ((exinds>exinde)&&(i<exinds&&i>exinde)) mean+=data[i];
        else ne++;
    }

    return mean/(n-ne);
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


/* 1D interpolation -------------------------------------------------------------
* interpolation of 1D data
* args   : double *x,*y     I   x and y data array
*          int    n         I   number of input data
*          double t         I   interpolation point on x data
* return : double               interpolated y data at t
*------------------------------------------------------------------------------*/
deprecated double interp1()(double* x, double* y, int n, double t) pure nothrow
{
    return interp1(x[0 .. n], y[0 .. n], t);
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
deprecated void uint64todouble(ulong *data, ulong base, int n, double *out_) pure nothrow
{
    int i;
    for (i=0;i<n;i++) out_[i]=cast(double)(data[i]-base);
}


void uint64todouble(in ulong[] data, ulong base, double[] out_) pure nothrow @safe
in{
    assert(data.length <= out_.length);
}
body{
    foreach(i, e; data)
        out_[i] = e - base;
}



/* index to subscribe -----------------------------------------------------------
* 1D index to subscribe (index of 2D array)
* args   : int    *ind      I   input data
*          int    nx, ny    I   number of row and column
*          int    *subx     O   subscript index of x
*          int    *suby     O   subscript index of y
* return : none
*------------------------------------------------------------------------------*/
deprecated void ind2sub(int ind, int nx, int ny, int *subx, int *suby) pure nothrow @safe
in{
    assert(ind >= 0);
    assert(nx >= 0);
    assert(ny >= 0);
}
out{
    assert(*subx >= 0);
    assert(*subx < nx);
    assert(*suby >= 0);
    assert(*suby < ny);
}
body{
    *subx = ind % nx;
    *suby = cast(int)(((cast(long)ny) * ind)/(nx*ny));      // 実際には、ny*ind/(nx*ny)
                                                            // castはoverflow対策
}


/* vector circle shift function  ------------------------------------------------
* circle shift of vector data
* args   : void   *dst      O   input data
*          void   *src      I   shifted data
*          size_t size      I   type of input data (byte)
*          int    n         I   number of input data
* return : none
*------------------------------------------------------------------------------*/
deprecated void shiftright(void *dst, void *src, size_t size, int n) pure nothrow
{
    scope tmp = new void[size * n];
    tmp[0 .. size*n] = src[0 .. size*n];
    dst[0 .. size*(n-1)] = tmp[0 .. size*(n-1)];
}


/* resample data to (2^bits) samples --------------------------------------------
* resample data to (2^bits) samples
* args   : char   *data     I   data
*          int    dtype     I   data type (1:real,2:complex)
*          int    n         I   number of data
*          int    m         I   number of resampled points
*          char   *rdata    O   resampled data
* return : none
*------------------------------------------------------------------------------*/
deprecated void resdata(const char *data, int dtype, int n, int m, char *rdata) pure nothrow
{
    char *p;

//#if !defined(SSE2)
    double index=0.0;
    int ind;
    
    if (dtype == DType.IQ) { /* complex */
        for (p=rdata;p<rdata+m;p+=2,index+=n*2) {
            ind=cast(int)(index/m)*2;
            p[0]=data[ind  ];
            p[1]=data[ind+1];
        }
    }
    if (dtype == DType.I) { /* real */
        for (p=rdata;p<rdata+m;p++,index+=n) {
            ind=cast(int)(index/m);
            p[0]=data[ind];
        }
    }
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
deprecated double rescode(string file = __FILE__, size_t line = __LINE__)(const short *code, size_t len, double coff, size_t smax, double ci, size_t n, short[] rcode)
{
    traceln("called");
    traceln("len: ", len);
    traceln("ci: ", ci);

    coff -= smax*ci;
    coff -= floor(coff / len) * len; /* 0<=coff<len */
    traceln("coff: ", coff);

    //for (p=rcode;p<rcode+n+2*smax;p++,coff+=ci) {
    foreach(i; 0 .. n + 2 * smax){
        coff %= len;
        rcode[i] = code[coff.to!size_t()];

        coff += ci;
    }

    traceln("return");

    return coff - smax * ci;
}



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
double mixcarr(string file = __FILE__, size_t line = __LINE__)(const(byte)[] data, DType dtype, double ti, double freq, double phi0, short[] I, short[] Q)
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
            immutable idx = (cast(int)phi)&CMASK;
            I[i] = cast(short)(cost[idx]*data[0] - sint[idx]*data[1]);
            Q[i] = cast(short)(cost[idx]*data[1] + sint[idx]*data[0]);

            data.popFrontN(2);
            phi += ps;
        }

    else if (dtype==DType.I)    /* real */
        foreach(i, e; data){
            immutable idx=(cast(int)phi)&CMASK;
            I[i] = cast(short)(cost[idx] * e);
            Q[i] = cast(short)(sint[idx] * e);

            phi += ps;
        }

    return (phi*DPI/CDIV) % DPI;
}
