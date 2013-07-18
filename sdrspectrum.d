

/*-------------------------------------------------------------------------------
* sdrspec.c : SDR spectrum analyzer functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/

import sdr;

import core.thread;

import std.c.string : memset;
import std.math;
import std.random;
import std.concurrency;

version(none):


/* initialize spectrum analyzer -------------------------------------------------
* create spectrum analyzer thread
* args   : sdrspec_t* sdrspecgui I   sdr spectrum struct
* return : none
* note : this function is only called from GUI application
*------------------------------------------------------------------------------*/
void initsdrspecgui(sdrspec_t* sdrspecgui)
{
    sdrspec_t spec;
    memcpy(&sdrspec,sdrspecgui,sdrspec_t.sizeof); /* copy setting from GUI */

    /* start specthread */
    //hspecthread = new Thread(() => specthread(&sdrspec));
    //hspecthread.start();
    hspecthread = spawn(&specthread);
}
/* spectrum analyzer thread -----------------------------------------------------
* spectrum analyzer thread
* args   : void * arg       I   sdr spectrum struct
* return : none
*------------------------------------------------------------------------------*/
void specthread() 
{
    sdrspec_t* spec = &sdrspec;
    int stop=0;
    //char *data;
    ulong buffloc;
    double* xI, yI, xQ, yQ, freq, pspec;
    
    /* check front end */
    if (sdrini.fend==Fend.FILE) {
        if (spec.ftype==FType.Type2&&(!sdrini.useif2)) {
            SDRPRINTF("error: spectrum analysis FE2 doesn't exist\n");
            return;
        }
    }
    if (sdrini.fend==Fend.GN3SV2||sdrini.fend==Fend.GN3SV3) {
        if (spec.ftype==FType.Type2) {
            SDRPRINTF("error: spectrum analysis FE2 doesn't exist\n");
            return;
        }
    }

    //data=cast(char*)malloc(char.sizeof * spec.nsamp*spec.dtype*SPEC_LEN).enforce();
    //scope(failure) free(data);
    scope byte[] data = new byte[spec.nsamp * spec.dtype * SPEC_LEN];
    freq = cast(double*)malloc(double.sizeof * SPEC_NFFT*spec.dtype).enforce();
    scope(failure) free(freq);
    pspec = cast(double*)malloc(double.sizeof * SPEC_NFFT*spec.dtype).enforce();
    scope(failure) free(pspec);
    xI = cast(double*)malloc(double.sizeof * SPEC_BITN).enforce();
    scope(failure) free(xI);
    yI = cast(double*)malloc(double.sizeof * SPEC_BITN).enforce();
    scope(failure) free(yI);
    xQ = cast(double*)malloc(double.sizeof * SPEC_BITN).enforce();
    scope(failure) free(xQ);
    yQ = cast(double*)malloc(double.sizeof * SPEC_BITN).enforce();
    scope(failure) free(yQ);
    
    /* initiarize plot structs */   
    if (initspecpltstruct(spec)<0) {
        sdrstat.stopflag=ON;
        stop=ON;
    }

    /* checking stop flag */
    //WaitForSingleObject(hstopmtx,INFINITE);
    synchronized(hstopmtx)
        stop = sdrstat.stopflag || sdrstat.specflag;
    //ReleaseMutex(hstopmtx);

    while (!stop) {
        /* spectrum analysis interval */
        Sleep(SPEC_MS);
        
        /* checking stop flag */
        //WaitForSingleObject(hstopmtx,INFINITE);
        synchronized(hstopmtx)
            stop = sdrstat.stopflag||sdrstat.specflag;
        //ReleaseMutex(hstopmtx);
        if (stop) break;

        /* current buffer location */
        //WaitForSingleObject(hreadmtx,INFINITE);
        synchronized(hreadmtx)
            buffloc = (sdrini.fendbuffsize*sdrstat.buffloccnt)-SPEC_LEN*spec.nsamp;
        //ReleaseMutex(hreadmtx);

        /* get current if data */
        rcvgetbuff(&sdrini,buffloc,SPEC_LEN*spec.nsamp,spec.ftype,spec.dtype,data);      

        /* histogram calculation */
        calchistgram(data,spec.dtype,SPEC_LEN*spec.nsamp,xI,yI,xQ,yQ);

        /* histogram plot */
        if (spec.dtype==DType.I||spec.dtype==DType.IQ) {
            spec.histI.x=xI;
            spec.histI.y=yI;
            plot(&spec.histI, "histI_");
        }
        if (spec.dtype==DType.IQ) {
            spec.histQ.x=xQ;
            spec.histQ.y=yQ;
            plot(&spec.histQ, "histQ");
        }

        /* checking stop flag */
        //WaitForSingleObject(hstopmtx,INFINITE);
        synchronized(hstopmtx)
            stop = sdrstat.stopflag || sdrstat.specflag;
        //ReleaseMutex(hstopmtx);
        if (stop) break;

        /* spectrum analyzationr */
        if (spectrumanalyzer(data,spec.dtype,spec.nsamp*SPEC_LEN,spec.f_sf,SPEC_NFFT,freq,pspec)<0) {
            sdrstat.stopflag=ON;
            stop=ON;
        }

        /* power spectrum plot */
        spec.pspec.x=freq;
        spec.pspec.y=pspec;
        plot(&spec.pspec, "pspec_");
    }
    
    /* free plot structs */
    quitspecpltstruct(spec);
    //free(data);
    //delete data;
    SDRPRINTF("spectrum thred is finished!\n");
}
/* initialize spectrum plot struct ----------------------------------------------
* initialize spectrum plot struct
* args   : sdrspec_t *spec  I/O sdr spectrum struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int initspecpltstruct(sdrspec_t *spec)
{
    int n;

    /* histogram (real sample) */
    setsdrplotprm(&spec.histI,PlotType.Box,SPEC_BITN,0,0,OFF,1,SPEC_PLT_H,SPEC_PLT_W,SPEC_PLT_MH,SPEC_PLT_MW,1);
    if (initsdrplot(&spec.histI)<0) return -1;
    settitle(&spec.histI, "Real Sample Histogram");
    setlabel(&spec.histI, "Sample Value", "Number of Samples");
    setyrange(&spec.histI,0,70000);

    /* histogram (imaginary sample) */
    setsdrplotprm(&spec.histQ,PlotType.Box,SPEC_BITN,0,0,OFF,1,SPEC_PLT_H,SPEC_PLT_W,SPEC_PLT_MH,SPEC_PLT_MW,2);
    if (initsdrplot(&spec.histQ)<0) return -1;
    settitle(&spec.histQ,"Imaginary Sample Histogram");
    setlabel(&spec.histQ,"Sample Value","Number of Samples");
    setyrange(&spec.histQ,0,70000);

    if (spec.dtype==DType.IQ) n=3;
    else n=2;

    /* power spectrum analysis */
    setsdrplotprm(&spec.pspec,PlotType.XY,SPEC_NFFT*spec.dtype,0,20,OFF,1,SPEC_PLT_H,SPEC_PLT_W,SPEC_PLT_MH,SPEC_PLT_MW,n);
    if (initsdrplot(&spec.pspec)<0) return -1;
    settitle(&spec.pspec,"Power Spectrum Analysis");
    setlabel(&spec.pspec,"Frequency (MHz)","Power Spectrum (dB)");
    setyrange(&spec.pspec,-40,0);

    return 0;
}
/* clean spectrum plot struct ---------------------------------------------------
* free memory and close pipe
* args   : sdrspec_t *spec  I/O spectrum struct
* return : none
*------------------------------------------------------------------------------*/
void quitspecpltstruct(sdrspec_t *spec)
{
    quitsdrplot(&spec.histI);
    quitsdrplot(&spec.histQ);
    quitsdrplot(&spec.pspec);
}
/* histogram calculation --------------------------------------------------------
* histogram calculation of input IF data
* args   : char   *data     I   sampling data vector (n x 1 or 2n x 1)
*          int    dtype     I   sampling data type (1:real,2:complex)
*          int    n         I   number of samples
*          double *xI       O   histogram bins {-7,-5,-3,-1,+1,+3,+5,+7}
*          double *yI       O   histogram values (in-phase samples) 
*          double *xQ       O   histogram bins {-7,-5,-3,-1,+1,+3,+5,+7}
*          double *yQ       O   histogram values (quadrature-phase samples)
* return : none
*------------------------------------------------------------------------------*/
void calchistgram(byte[] data, int dtype, int n, double *xI, double *yI, double *xQ, double *yQ)
{
    int i;
    double[SPEC_BITN] xx = [-7,-5,-3,-1,+1,+3,+5,+7]; /* 3bit */
    
    memcpy(xI,xx.ptr,double.sizeof * SPEC_BITN);
    memcpy(xQ,xx.ptr,double.sizeof * SPEC_BITN);
    memset(yI,0,double.sizeof * SPEC_BITN);
    memset(yQ,0,double.sizeof * SPEC_BITN);

    /* count samples */
    if (dtype==DType.I) {
        for (i=0;i<n;i++) {
            yI[(data[i]+7)/2]++;
        }
    }else if(dtype==DType.IQ) {
        for (i=0;i<n;i++) {
            yI[(data[2*i  ]+7)/2]++;
        }
        for (i=0;i<n;i++) {
            yQ[(data[2*i+1]+7)/2]++;
        }
    }
}
/* hanning window ---------------------------------------------------------------
* create hanning window
* args   : int    n         I   number of samples
*          float *win       O   hanning window
* return : none
*------------------------------------------------------------------------------*/
void hanning(int n, float *win)
{
    int i;
    for (i=0;i<n;i++)
        win[i] = cast(float)(0.5*(1-cos(2*PI*(i+1)/(n+1))));
}
/* spectrum analyzer ------------------------------------------------------------
* power spectrum analyzer function
* args   : char   *data     I   sampling data vector (n x 1 or 2n x 1)
*          int    dtype     I   sampling data type (1:real,2:complex)
*          int    n         I   number of samples
*          double f_sf      I   sampling frequency (Hz)
*          int    nfft      I   number of fft points
*          double *freq     O   fft frequency vector (Hz)
*          double *pspec    O   fft power spectrum vector (dB)
* return : int                  status 0:okay -1:failure
* note : http://billauer.co.il/easyspec.html as a reference
*------------------------------------------------------------------------------*/
int spectrumanalyzer(const(byte)[] data, int dtype, int n, double f_sf, int nfft, double *freq, double *pspec)
{
    int i,j,k,zuz,nwin=nfft/2,maxshift=n-nwin;
    float* x,xxI,xxQ,win;
    double *s;
    cpx_t *xxx;

    x = cast(float*)malloc(float.sizeof*n*dtype).enforce();
    scope(exit) free(x);
    xxI=cast(float*)malloc(float.sizeof*nfft*2).enforce();
    scope(exit) free(xxI);
    xxQ=cast(float*)malloc(float.sizeof*nfft*2).enforce();
    scope(exit) free(xxQ);
    s  =cast(double*)calloc(double.sizeof,nfft*2).enforce();
    scope(exit) free(s);
    xxx=cpxmalloc(nfft*2).enforce();
    scope(exit) cpxfree(xxx);
    win=cast(float*)malloc(float.sizeof*nwin).enforce();
    scope(exit) free(win);
    
    /* create hanning window */
    hanning(nwin,win);

    for (i=0;i<dtype*n;i++)
        x[i]=cast(float)(data[i]*(17.127/(nfft*2)/sqrt(cast(float)SPEC_NLOOP)));

    /* spectrum analysis */
    for (i=0;i<SPEC_NLOOP;i++) {
        
        //zuz=cast(int)floor(cast(double)rand()/RAND_MAX*maxshift);
        zuz = uniform(0, maxshift);
        memset(xxI,0,float.sizeof*nfft*2);
        memset(xxQ,0,float.sizeof*nfft*2);
        
        for (j=zuz,k=0;j<nwin+zuz;j++,k++) {
            if (dtype==DType.I) {
                xxI[k]=win[k]*x[j];
            }
            if (dtype==DType.IQ) {
                xxI[k]=win[k]*x[2*j];
                xxQ[k]=win[k]*x[2*j+1];
            }
        }
        /* to complex domain */
        if (dtype==DType.I)
            cpxcpxf(xxI,null,1.0,nfft*2,xxx);
        if (dtype==DType.IQ)
            cpxcpxf(xxI,xxQ,1.0,nfft*2,xxx);
        
        /* compute power spectrum */
        cpxpspec(xxx,nfft*2,1,s);
    }

    /* frequency and power */
    if (dtype==DType.I) {
        for (i=0;i<nfft;i++) {
            pspec[i]=10*log10(s[i]); /* dB */
            freq[i]=(i*(f_sf/2)/(nfft))/1e6; /* MHz */
        }
    } else if (dtype==DType.IQ) {
        for (i=0;i<dtype*nfft;i++) {
            if (i<nfft)
                pspec[i]=10*log10(s[ nfft+i]); /* dB */
            else
                pspec[i]=10*log10(s[-nfft+i]); /* dB */
            freq[i]=(-f_sf/2+i*f_sf/nfft/2)/1e6; /* MHz */
        }
    }

    return 0;
}