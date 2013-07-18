/*-------------------------------------------------------------------------------
* sdrfunc.c : SDR common functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
* Copyright (C) 2013 T. Takasu <http://www.rtklib.com>
*------------------------------------------------------------------------------*/
import sdr;

import core.memory;
import std.math;
import std.c.windows.windows;
import std.numeric;
import std.datetime;
import core.bitop;
import std.traits;
import std.range;
import std.algorithm;

version(unittest) import std.stdio;

/* global variables -----------------------------------------------------------*/
__gshared short cost[CDIV];            /* carrier lookup table cos(t) */
__gshared short sint[CDIV];            /* carrier lookup table sin(t) */


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
    return 1 << (bsr(num.to!size_t()) + next);
}

///
unittest{
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
unittest{
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
unittest{
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
size_t calcfftnumreso(A, B)(A reso, B ti)
if(is(A : real) && is(B : real))
{
    return calcfftnum(1/(cast(real)reso*ti), 0);
}


/* sdr malloc -------------------------------------------------------------------
* memorry allocation
* args   : int    size      I   sizee of allocation
* return : void*                allocated pointer
*------------------------------------------------------------------------------*/
void* sdrmalloc(size_t size)
{
    return GC.malloc(size);
}


/* sdr free ---------------------------------------------------------------------
* free data
* args   : void   *p        I/O input/output complex data
* return : none
*------------------------------------------------------------------------------*/
void sdrfree(void *p)
{
    GC.free(p);
}


/* complex malloc ---------------------------------------------------------------
* memorry allocation of complex data
* args   : int    n         I   number of allocation
* return : cpx_t*               allocated pointer
*------------------------------------------------------------------------------*/
/**/
cpx_t *cpxmalloc(size_t n)
{
    return cast(cpx_t*)GC.malloc(cpx_t.sizeof * n + 32);
}


/* complex free -----------------------------------------------------------------
* free complex data
* args   : cpx_t  *cpx      I/O input/output complex data
* return : none
*------------------------------------------------------------------------------*/
void cpxfree(cpx_t *cpx)
{
    GC.free(cpx);
}


/* complex FFT -----------------------------------------------------------------
* cpx=fft(cpx)
* args   : cpx_t  *cpx      I/O input/output complex data
*          size_t    n         I   number of input/output data
* return : none
*------------------------------------------------------------------------------*/
/**/
void cpxfft(cpx_t *cpx, int n)
{
    traceln("called");
    fftwf_plan p;

    synchronized(hfftmtx){
        fftwf_plan_with_nthreads(NFFTTHREAD);  //fft execute in multi threads 
        p = fftwf_plan_dft_1d(n, cpx, cpx, FFTW_FORWARD, FFTW_ESTIMATE);
        fftwf_execute(p); /* fft */
        fftwf_destroy_plan(p);
    }
}


void cpxfft(cpx_t *cpx, size_t n)
{
    cpxfft(cpx, n.to!int());
}


void cpxfft(cpx_t[] cpx)
{
    cpxfft(cpx.ptr, cpx.length.to!int());
}


/* complex IFFT -----------------------------------------------------------------
* cpx=ifft(cpx)
* args   : cpx_t  *cpx      I/O input/output complex data
*          int    n         I   number of input/output data
* return : none
*------------------------------------------------------------------------------*/
void cpxifft(cpx_t *cpx, int n)
{
    traceln("called");
    fftwf_plan p;
    
    synchronized(hfftmtx){
        fftwf_plan_with_nthreads(NFFTTHREAD); /* ifft execute in multi threads */
        p=fftwf_plan_dft_1d(n,cpx,cpx,FFTW_BACKWARD,FFTW_ESTIMATE);
        fftwf_execute(p); /* ifft */
        fftwf_destroy_plan(p);
    }
}


void cpxifft(cpx_t *cpx, size_t n)
{
    cpxifft(cpx, n.to!int());
}


void cpxifft(cpx_t[] cpx)
{
    cpxifft(cpx.ptr, cpx.length.to!int());
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
void cpxcpx(in short* I, in short* Q, double scale, size_t n, cpx_t *cpx)
{
    traceln("called");
    float *p=cast(float *)cpx;
    int i;
    
    for (i=0;i<n;i++,p+=2) {
        p[0]=  I[i]*cast(float)scale;
        p[1]=Q?Q[i]*cast(float)scale:0.0f;
    }
}


void cpxcpx(in short[] I, in short[] Q, double scale, cpx_t[] cpx)
{
    cpxcpx(I.ptr, Q.ptr, scale, I.length, cpx.ptr);
}


/* convert float vector to complex vector ---------------------------------------
* cpx=complex(I,Q)
* args   : float  *I        I   input data array (real)
*          float  *Q        I   input data array (imaginary)
*          double scale     I   scale factor
*          int    n         I   number of input data
*          cpx_t *cpx       O   output complex array
* return : none
*------------------------------------------------------------------------------*/
void cpxcpxf(in float* I, in float* Q, double scale, size_t n, cpx_t* cpx)
{
    traceln("called");
    float *p=cast(float *)cpx;
    int i;
    
    for (i=0;i<n;i++,p+=2) {
        p[0]=  I[i]*cast(float)scale;
        p[1]=Q?Q[i]*cast(float)scale:0.0f;
    }
}

void cpxcpxf(in float[] I, in float[] Q, double scale, cpx_t[] cpx)
{
    cpxcpxf(I.ptr, Q.ptr, scale, I.length, cpx.ptr);
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
void cpxconv(cpx_t *cpxa, cpx_t *cpxb, size_t m, size_t n, bool flagsum, double *conv)
{
    traceln("called");
    float* p, q;
    float real_, m2 = cast(float)m*m;
    int i;
    
    cpxfft(cpxa,m); /* fft */
    
    for (i=0,p=cast(float *)cpxa,q=cast(float *)cpxb;i<m;i++,p+=2,q+=2) {
        real_=-p[0]*q[0]-p[1]*q[1];
        p[1]= p[0]*q[1]-p[1]*q[0];
        p[0]=real_;
    }
    cpxifft(cpxa,m); /* ifft */
    for (i=0,p=cast(float *)cpxa;i<n;i++,p+=2) {
        if (flagsum) /* cumulative sum */
            conv[i]+=(p[0]*p[0]+p[1]*p[1])/m2;
        else
            conv[i]=(p[0]*p[0]+p[1]*p[1])/m2;
    }
}


/* power spectrum calculation ---------------------------------------------------
* power spectrum: pspec=abs(fft(cpx)).^2
* args   : cpx_t  *cpx      I   input complex data array
*          int    n         I   number of input data
*          int    flagsum   I   cumulative sum flag (pspec+=pspec)
*          double *pspec    O   output power spectrum data
* return : none
*------------------------------------------------------------------------------*/
void cpxpspec(cpx_t *cpx, size_t n, bool flagsum, double *pspec)
{
    traceln("called");
    float* p;
    float n2=cast(float)n*n;
    int i;
    
    cpxfft(cpx,n); /* fft */
    
    for (i=0,p=cast(float *)cpx;i<n;i++,p+=2) {
        if (flagsum) /* cumulative sum */
            pspec[i]+=(p[0]*p[0]+p[1]*p[1]);
        else
            pspec[i]=(p[0]*p[0]+p[1]*p[1]);
    }
}


void cpxpspec(cpx_t[] cpx, bool flagsum, double[] pspec)
{
    cpxpspec(cpx.ptr, cpx.length, flagsum, pspec.ptr);
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
void dot_21(const short *a1, const short *a2, const short *b, size_t n,
                   double *d1, double *d2)
{
    version(Dnative){
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


void dot_21(in short[] a1, in short[] a2, in short[] b, double[] d1, double[] d2)
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
void dot_22(in short *a1, in short *a2, in short *b1, in short *b2, size_t n,
            double *d1, double *d2)
{
    version(Dnative){
        immutable result = dot!long(a1[0 .. n], a2[0 .. n])(b1[0 .. n], b2[0 .. n]);
        d1[0] = result[0][0];
        d1[1] = result[0][1];
        d2[0] = result[1][0];
        d2[1] = result[1][1];
    }else{
        const(short)* p1=a1, p2=a2, q1=b1, q2=b2;
        
        d1[0]=d1[1]=d2[0]=d2[1]=0.0;
        
        for (;p1<a1+n;p1++,p2++,q1++,q2++) {
            d1[0]+=(*p1)*(*q1);
            d1[1]+=(*p1)*(*q2);
            d2[0]+=(*p2)*(*q1);
            d2[1]+=(*p2)*(*q2);
        }
    }
}

void dot_22(in short[] a1, in short[] a2, in short[] b1, in short[] b2, double[] d1, double[] d2)
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
void dot_23(const short *a1, const short *a2, const short *b1,
                   const short *b2, const short *b3, size_t n, double *d1,
                   double *d2)
{
    version(Dnative){
        immutable result = dot!long(a1[0 .. n], a2[0 .. n])(b1[0 .. n], b2[0 .. n], b3[0 .. n]);

        d1[0] = result[0][0];
        d1[1] = result[0][1];
        d1[2] = result[0][2];
        d2[0] = result[1][0];
        d2[1] = result[1][1];
        d2[2] = result[1][2];
    }else{
        const(short)* p1=a1, p2=a2, q1=b1, q2=b2, q3=b3;
        
        d1[0]=d1[1]=d1[2]=d2[0]=d2[1]=d2[2]=0.0;
        
        for (;p1<a1+n;p1++,p2++,q1++,q2++,q3++) {
            d1[0]+=(*p1)*(*q1);
            d1[1]+=(*p1)*(*q2);
            d1[2]+=(*p1)*(*q3);
            d2[0]+=(*p2)*(*q1);
            d2[1]+=(*p2)*(*q2);
            d2[2]+=(*p2)*(*q3);
        }
    }
}


void dot_23(in short[] a1, in short[] a2, in short[] b1, in short[] b2, in short[] b3, double[] d1, double[] d2)
{
    dot_23(a1.ptr, a2.ptr, b1.ptr, b2.ptr, b3.ptr, a1.length, d1.ptr, d2.ptr);
}


/**
unittestをみれば使い方わかる
*/
auto dot(T, size_t N)(const(T)[][N] a...)
if(N > 1)
{
    return dotImpl!(T, T, N)(a);
}


auto dot(T)(const(T)[] a)
{
    return dotImpl!(T, T, 1)([a]);
}


auto dot(R, T, size_t N)(const(T)[][N] a...)
{
    return dotImpl!(R, T, N)(a);
}


auto dot(R, T)(const(T)[] a)
{
    return dotImpl!(R, T, 1)([a]);
}


private auto dotImpl(R, T, size_t N)(const(T)[][N] a)
{
    static struct Result
    {
        auto opCall(U)(const(U)[] b)
        if(is(typeof(T.init * U.init)  : R))
        {
            return opCallImpl([b]);
        }


        auto opCall(U, size_t M)(const(U)[][M] b...)
        if(M > 1 && is(typeof(T.init * U.init)  : R))
        {
            return opCallImpl(b);
        }


      private:
        const(T)[][N] _inputA;

        R[M][N] opCallImpl(U, size_t M)(const(U)[][M] b)
        if(is(typeof(T.init * U.init)  : R))
        {
            static string generateMinArgs()
            {
                string dst;

                foreach(i; 0 .. N){
                    immutable idxStr = i.to!string();
                    dst ~= "_inputA[" ~ idxStr ~ "].length, ";
                }

                foreach(i; 0 .. M){
                    immutable idxStr = i.to!string();
                    dst ~= "b[" ~ idxStr ~ "].length, ";
                }

                if(dst.length)
                    return dst[0 .. $-2];
                else
                    return dst;
            }


            static string generateForeachBody()
            {
                string dst;

                foreach(i; 0 .. N){
                    immutable iStr = i.to!string(),
                              resultStr = "result[" ~ iStr ~ "][",
                              aStr = "] += _inputA[" ~ iStr ~ "][i] * b[";

                    foreach(j; 0 .. M){
                        immutable jStr = j.to!string();

                        dst ~= resultStr ~ jStr ~ aStr ~ jStr ~ "][i];\n";
                    }
                }

                return dst;
            }


            immutable size = mixin("min(" ~ generateMinArgs ~ ")");

            R[M][N] result = 0;

            foreach(i; 0 .. size)
                mixin(generateForeachBody());

            return result;
        }
    }

    Result dst = {_inputA : a};
    return dst;
}

///
unittest{
    // 返り値はint[2][2]
    auto result22 = dot([0, 1, 2], [3, 4, 5])([6, 7, 8], [9, 10, 11]);
    assert(result22[0][0] == dot([0, 1, 2])([6, 7, 8])[0][0]);
    assert(result22[0][1] == dot([0, 1, 2])([9, 10, 11])[0][0]);
    assert(result22[1][0] == dot([3, 4, 5])([6, 7, 8])[0][0]);
    assert(result22[1][1] == dot([3, 4, 5])([9, 10, 11])[0][0]);

    auto result11 = dot([0, 1, 2])([3, 4, 5, 6]);
    assert(result11[0][0] == 0*3 + 1*4 + 2*5);
}


/* multiply char/short vectors --------------------------------------------------
* multiply char/short vectors: out=data1.*data2
* args   : char   *data1    I   input char array
*          short  *data2    I   input short array
*          int    n         I   number of input data
*          short  *out      O   output short array
* return : none
*------------------------------------------------------------------------------*/

void mulvcs(const(byte)* data1, const short *data2, size_t n, short *out_)
{   
    int i;
    for (i=0;i<n;i++) out_[i]=cast(short)(data1[i]*data2[i]);
}


void mulvcs(in byte[] data1, in short[] data2, short[] out_)
{
    mulvcs(data1.ptr, data2.ptr, data1.length, out_.ptr);
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
void sumvf(const float *data1, const float *data2, int n, float *out_)
{
    int i;
    for (i=0;i<n;i++) out_[i]=data1[i]+data2[i];
}


void sumvf(in float[] data1, in float[] data2, float[] out_)
{
    //sumvf(data1.ptr, data2.ptr, data1.length, out_.ptr);
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
void sumvd(const double *data1, const double *data2, size_t n, double *out_)
{
    int i;
    for (i=0;i<n;i++) out_[i]=data1[i]+data2[i];
}


void sumvd(in double[] data1, in double[] data2, double[] out_)
{
    //sumvd(data1.ptr, data2.ptr, data1.length, out_.ptr);
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
int maxvi(const int *data, size_t n, ptrdiff_t exinds, ptrdiff_t exinde, int *ind)
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


int maxvi(in int[] data, ptrdiff_t exinds, ptrdiff_t exinde, out int ind)
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
float maxvf(const float *data, size_t n, ptrdiff_t exinds, ptrdiff_t exinde, int *ind)
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


float maxvf(in float[] data, int exinds, int exinde, out int ind)
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
double maxvd(const double *data, size_t n, int exinds, int exinde, int *ind)
{
    int i;
    double max=data[0];
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


double maxvd(in double[] data, int exinds, int exinde, out int ind)
{
    return maxvd(data.ptr, data.length, exinds, exinde, &ind);
}


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
double meanvd(const double *data, int n, int exinds, int exinde)
{
    int i,ne=0;
    double mean=0.0;
    for(i=0;i<n;i++) {
        if ((exinds<=exinde)&&(i<exinds||i>exinde)) mean+=data[i];
        else if ((exinds>exinde)&&(i<exinds&&i>exinde)) mean+=data[i];
        else ne++;
    }
    return mean/(n-ne);
}


/* 1D interpolation -------------------------------------------------------------
* interpolation of 1D data
* args   : double *x,*y     I   x and y data array
*          int    n         I   number of input data
*          double t         I   interpolation point on x data
* return : double               interpolated y data at t
*------------------------------------------------------------------------------*/
double interp1()(double* x, double* y, int n, double t)
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
unittest{
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
void uint64todouble(ulong *data, ulong base, int n, double *out_)
{
    int i;
    for (i=0;i<n;i++) out_[i]=cast(double)(data[i]-base);
}


void uint64todouble(in ulong[] data, ulong base, double[] out_)
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
void ind2sub(int ind, int nx, int ny, int *subx, int *suby)
{
    *subx = ind%nx;
    *suby = ny*ind/(nx*ny);
}


/* vector circle shift function  ------------------------------------------------
* circle shift of vector data
* args   : void   *dst      O   input data
*          void   *src      I   shifted data
*          size_t size      I   type of input data (byte)
*          int    n         I   number of input data
* return : none
*------------------------------------------------------------------------------*/
void shiftright(void *dst, void *src, size_t size, int n)
{
    void *tmp;
    tmp=malloc(size*n);
    if (tmp !is null) {
        tmp[0 .. size*n] = src[0 .. size*n];
        dst[0 .. size*(n-1)] = tmp[0 .. size*(n-1)];
        //memcpy(tmp,src,size*n);
        //memcpy(dst,tmp,size*(n-1));
        free(tmp);
    }
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
void resdata(const char *data, int dtype, int n, int m, char *rdata)
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

double rescode(string file = __FILE__, size_t line = __LINE__)(const short *code, size_t len, double coff, size_t smax, double ci, size_t n, short *rcode)
{
    traceln("called");
    traceln("len: ", len);
    traceln("ci: ", ci);
    short *p;
    
//#if !defined(SSE2)
    coff-=smax*ci;
    coff-=floor(coff/len)*len; /* 0<=coff<len */
    traceln("coff: ", coff);
    for (p=rcode;p<rcode+n+2*smax;p++,coff+=ci) {
        //while(coff>=len) coff-=len;
        coff %= len;
        *p = code[coff.to!int()];
    }
    traceln("return");
    return coff-smax*ci;
}



double resamplingCode(R, W)(R src, double coff, size_t smax, double ci, size_t n, ref W sink)
if(isInputRange!R && hasLength!R && isOutputRange!(W, ElementType!R))
{
    immutable len = src.length;

    traceln("called");
    traceln("len: ", len);
    traceln("ci: ", ci);
    auto cyc = src.cycle();
    //short *p;
    
    coff-=smax*ci;
    coff-=floor(coff/len)*len; /* 0<=coff<len */
    traceln("coff: ", coff);
    foreach(e; 0 .. n + 2 * smax)
    {
        sink.put(cyc[coff.to!size_t()]);
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
double mixcarr(string file = __FILE__, size_t line = __LINE__)(const(byte)[] data, DType dtype, double ti, int n, double freq, double phi0, short *I, short *Q)
{
    traceln("called");

    const(byte)* p;
    double phi,ps,prem;

//#if !defined(SSE2)
    int i,index;
    
    /* initialize local carrier table */
    if (!cost[0]) {
        for (i=0;i<CDIV;i++) {
            cost[i]=cast(short)floor((cos(DPI/CDIV*i)/CSCALE+0.5));
            sint[i]=cast(short)floor((sin(DPI/CDIV*i)/CSCALE+0.5));
        }
    }

    phi=phi0*CDIV/DPI;
    ps=freq*CDIV*ti; /* phase step */

    if (dtype==DType.IQ) { /* complex */
        for (p=data.ptr;p<data.ptr+n*2;p+=2,I++,Q++,phi+=ps) {
            index=(cast(int)phi)&CMASK;
            *I=cast(short)(cost[index]*p[0]);
            *Q=cast(short)(cost[index]*p[1]);
        }
    }
    if (dtype==DType.I) { /* real */
        for (p=data.ptr;p<data.ptr+n;p++,I++,Q++,phi+=ps) {
            index=(cast(int)phi)&CMASK;
            *I=cast(short)(cost[index]*p[0]);
            *Q=cast(short)(sint[index]*p[0]);
        }
    }
    prem=phi*DPI/CDIV;
    while(prem>DPI) prem-=DPI;
    return prem;
}
