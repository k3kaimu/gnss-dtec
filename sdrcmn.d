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

/* global variables -----------------------------------------------------------*/
__gshared short cost[CDIV];            /* carrier lookup table cos(t) */
__gshared short sint[CDIV];            /* carrier lookup table sin(t) */

/**
xよりも小さな2^nを計算します。
*/
/* calculation FFT number of points (2^bits samples) ----------------------------
* calculation FFT number of points (round up)
* args   : double x         I   number of points (not 2^bits samples)
*          int    next      I   increment multiplier
* return : int                  FFT number of points (2^bits samples)
*------------------------------------------------------------------------------*/
uint calcfftnum(double x, size_t next = 0)
{
    immutable fix = x.to!size_t();

    return 1 << (bsr(fix) + next);
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
uint calcfftnumreso(double reso, double ti)
{
    return calcfftnum(1/(reso*ti), 0);
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
cpx_t *cpxmalloc(int n)
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
*          int    n         I   number of input/output data
* return : none
*------------------------------------------------------------------------------*/
/**/
void cpxfft(string file = __FILE__, size_t line = __LINE__)(cpx_t *cpx, int n)
{
    traceln("called");
    fftwf_plan p;

    synchronized(hfftmtx){
        fftwf_plan_with_nthreads(NFFTTHREAD);  //fft execute in multi threads 
        p = fftwf_plan_dft_1d(n,cpx,cpx,FFTW_FORWARD,FFTW_ESTIMATE);
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
void cpxifft(string file = __FILE__, size_t line = __LINE__)
    (cpx_t *cpx, int n)
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


/* convert short vector to complex vector ---------------------------------------
* cpx=complex(I,Q)
* args   : short  *I        I   input data array (real)
*          short  *Q        I   input data array (imaginary)
*          double scale     I   scale factor
*          int    n         I   number of input data
*          cpx_t *cpx       O   output complex array
* return : none
*------------------------------------------------------------------------------*/
void cpxcpx(string file = __FILE__, size_t line = __LINE__)(const short *I, const short *Q, double scale, int n, cpx_t *cpx)
{
    traceln("called");
    float *p=cast(float *)cpx;
    int i;
    
    for (i=0;i<n;i++,p+=2) {
        p[0]=  I[i]*cast(float)scale;
        p[1]=Q?Q[i]*cast(float)scale:0.0f;
    }
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
void cpxcpxf(string file = __FILE__, size_t line = __LINE__)(const float *I, const float *Q, double scale, int n, cpx_t *cpx)
{
    traceln("called");
    float *p=cast(float *)cpx;
    int i;
    
    for (i=0;i<n;i++,p+=2) {
        p[0]=  I[i]*cast(float)scale;
        p[1]=Q?Q[i]*cast(float)scale:0.0f;
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
void cpxconv(string file = __FILE__, size_t line = __LINE__)(cpx_t *cpxa, cpx_t *cpxb, int m, int n, int flagsum, double *conv)
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
void cpxpspec(string file = __FILE__, size_t line = __LINE__)(cpx_t *cpx, int n, int flagsum, double *pspec)
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



/* dot products: d1=dot(a1,b),d2=dot(a2,b) --------------------------------------
* args   : short  *a1       I   input short array
*          short  *a2       I   input short array
*          short  *b        I   input short array
*          int    n         I   number of input data
*          short  *d1       O   output short array
*          short  *d2       O   output short array
* return : none
*------------------------------------------------------------------------------*/
void dot_21(const short *a1, const short *a2, const short *b, int n,
                   double *d1, double *d2)
{
    const(short)* p1=a1, p2=a2, q=b;
    
    d1[0]=d2[0]=0.0;
    
    for (;p1<a1+n;p1++,p2++,q++) {
        d1[0]+=(*p1) * (*q);
        d2[0]+=(*p2) * (*q);
    }
}
/* dot products: d1={dot(a1,b1),dot(a1,b2)},d2={dot(a2,b1),dot(a2,b2)} ----------
* args   : short  *a1       I   input short array
*          short  *a2       I   input short array
*          short  *b1       I   input short array
*          short  *b2       I   input short array
*          int    n         I   number of input data
*          short  *d1       O   output short array
*          short  *d2       O   output short array
* return : none
*------------------------------------------------------------------------------*/
void dot_22(const short *a1, const short *a2, const short *b1,
                   const short *b2, int n, double *d1, double *d2)
{
    const(short)* p1=a1, p2=a2, q1=b1, q2=b2;
    
    d1[0]=d1[1]=d2[0]=d2[1]=0.0;
    
    for (;p1<a1+n;p1++,p2++,q1++,q2++) {
        d1[0]+=(*p1)*(*q1);
        d1[1]+=(*p1)*(*q2);
        d2[0]+=(*p2)*(*q1);
        d2[1]+=(*p2)*(*q2);
    }
}
/* dot products: d1={dot(a1,b1),dot(a1,b2),dot(a1,b3)},d2={...} -----------------
* args   : short  *a1       I   input short array
*          short  *a2       I   input short array
*          short  *b1       I   input short array
*          short  *b2       I   input short array
*          short  *b3       I   input short array
*          int    n         I   number of input data
*          short  *d1       O   output short array
*          short  *d2       O   output short array
* return : none
*------------------------------------------------------------------------------*/
void dot_23(const short *a1, const short *a2, const short *b1,
                   const short *b2, const short *b3, int n, double *d1,
                   double *d2)
{
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


/* multiply char/short vectors --------------------------------------------------
* multiply char/short vectors: out=data1.*data2
* args   : char   *data1    I   input char array
*          short  *data2    I   input short array
*          int    n         I   number of input data
*          short  *out      O   output short array
* return : none
*------------------------------------------------------------------------------*/

void mulvcs(const(byte)* data1, const short *data2, int n, short *out_)
{   
    int i;
    for (i=0;i<n;i++) out_[i]=cast(short)(data1[i]*data2[i]);
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
/* sum double vectors -----------------------------------------------------------
* sum double vectors: out=data1.+data2
* args   : double *data1    I   input double array
*          double *data2    I   input double array
*          int    n         I   number of input data
*          double *out      O   output double array
* return : none
* note   : AVX command is used if "AVX" is defined
*------------------------------------------------------------------------------*/
void sumvd(const double *data1, const double *data2, int n, double *out_)
{
    int i;
    for (i=0;i<n;i++) out_[i]=data1[i]+data2[i];
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
int maxvi(const int *data, int n, int exinds, int exinde, int *ind)
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
float maxvf(const float *data, int n, int exinds, int exinde, int *ind)
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
double maxvd(const double *data, int n, int exinds, int exinde, int *ind)
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
double interp1(double *x, double *y, int n, double t)
{   int i,j,k,m;
    double z,s;
    z=0.0;
    if(n<1) return(z);
    if(n==1) {z=y[0];return(z);}
    if(n==2)
    {   z=(y[0]*(t-x[1])-y[1]*(t-x[0]))/(x[0]-x[1]);
        return(z);
    }
    if(t<=x[1]) {k=0;m=2;}
    else if(t>=x[n-2]) {k=n-3;m=n-1;}
    else
    {   k=1;m=n;
        while(m-k!=1)
        {   i=(k+m)/2;
            if(t<x[i-1])m=i;
            else k=i;
        }
        k=k-1;m=m-1;
        if(fabs(t-x[k])<fabs(t-x[m]))k=k-1;
        else m=m+1;
    }
    z=0.0;
    for(i=k;i<=m;i++)
    {   s=1.0;
        for(j=k;j<=m;j++) if(j!=i)s=s*(t-x[j])/(x[i]-x[j]);
        z=z+s*y[i];
    }
    return z;
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
    
    if (dtype==DTYPEIQ) { /* complex */
        for (p=rdata;p<rdata+m;p+=2,index+=n*2) {
            ind=cast(int)(index/m)*2;
            p[0]=data[ind  ];
            p[1]=data[ind+1];
        }
    }
    if (dtype==DTYPEI) { /* real */
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
double rescode(string file = __FILE__, size_t line = __LINE__)(const short *code, int len, double coff, int smax, double ci, int n, short *rcode)
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
double mixcarr(string file = __FILE__, size_t line = __LINE__)(const(byte)[] data, int dtype, double ti, int n, double freq, double phi0, short *I, short *Q)
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

    if (dtype==DTYPEIQ) { /* complex */
        for (p=data.ptr;p<data.ptr+n*2;p+=2,I++,Q++,phi+=ps) {
            index=(cast(int)phi)&CMASK;
            *I=cast(short)(cost[index]*p[0]);
            *Q=cast(short)(cost[index]*p[1]);
        }
    }
    if (dtype==DTYPEI) { /* real */
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
