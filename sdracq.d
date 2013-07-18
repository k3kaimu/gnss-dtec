/*-------------------------------------------------------------------------------
* sdracq.c : SDR acquisition functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;
import sdrcmn;

import std.math;

/* sdr acquisition function -----------------------------------------------------
* sdr acquisition function called from sdr channel thread
* args   : sdrch_t *sdr     I/O sdr channel struct
*          double *power    O   normalized correlation power vector (2D array)
* return : uint64_t             current buffer location
*------------------------------------------------------------------------------*/
ulong sdracquisition(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr, double *power, ref ulong cnt)
{
    import std.stdio;
    traceln("called");
    //int i;
    //char* data, datal;
    ulong buffloc,bufflocnow;

    /* memory allocation */
    //data = cast(char*)sdrmalloc(char.sizeof * sdr.nsamp * sdr.dtype);
    //datal = cast(char*)sdrmalloc(char.sizeof * sdr.nsamp * sdr.acq.lenf * sdr.dtype);
    byte[] data = new byte[sdr.nsamp * sdr.dtype];
    byte[] datal = new byte[sdr.nsamp * sdr.dtype * sdr.acq.lenf];

    /* current buffer location */
    //WaitForSingleObject(hreadmtx,INFINITE);
    writefln("##### acq cnt: %s", cnt);
    if(cnt == 0)    // 最初のサイクルでは、先頭から読み込むようにする
    {
        ++cnt;
        immutable needBuffCnt = sdr.acq.intg * sdr.nsamp / sdrini.fendbuffsize;
        size_t now = 0;
        do{
            synchronized(hreadmtx)
                now = sdrstat.buffloccnt;
        }while(now < needBuffCnt);

        buffloc = needBuffCnt * sdrini.fendbuffsize;
        writefln("###### acq buffloc %s", buffloc);
    }else{
        synchronized(hreadmtx)
            buffloc = sdrini.fendbuffsize * sdrstat.buffloccnt - sdr.acq.intg * sdr.nsamp;
    }
    //ReleaseMutex(hreadmtx);

    /* acquisition integration */
    //for (i = 0; i < sdr.acq.intg; i++) {
    foreach(i; 0 .. sdr.acq.intg){

        /* wait until buffer is not full */
        do {
            //WaitForSingleObject(hreadmtx,INFINITE);
            synchronized(hreadmtx)
                bufflocnow = sdrini.fendbuffsize * sdrstat.buffloccnt - sdr.nsamp;
            //ReleaseMutex(hreadmtx);
        } while (bufflocnow < buffloc);

        /* get current 1ms data */
        rcvgetbuff(&sdrini, buffloc, sdr.nsamp, sdr.ftype, sdr.dtype, data);
        buffloc += sdr.nsamp;

        /* fft correlation */
        pcorrelator(data, sdr.dtype, sdr.ti, sdr.nsamp, sdr.acq.freq, sdr.acq.nfreq, sdr.crate, sdr.acq.nfft, sdr.xcode, power);

        /* check acquisition result */
        if (checkacquisition(power, sdr)) {
            sdr.flagacq = ON;
            break;
        }
    }
    /* fine doppler search */
    if (sdr.flagacq) {
        buffloc+=sdr.acq.acqcodei; /* set buffer location at top of code */
        rcvgetbuff(&sdrini,buffloc,sdr.nsamp*sdr.acq.lenf,sdr.ftype,sdr.dtype,datal);

        /* fine doppler search */
        sdr.acq.acqfreqf=carrfsearch(datal,sdr.dtype,sdr.ti,sdr.crate,sdr.nsamp*sdr.acq.lenf,sdr.acq.nfftf,sdr.clen*sdr.acq.lenf,sdr.lcode);
        SDRPRINTF("%s, C/N0=%.1f, peak=%.1f, codei=%d, freq=%.1f, freqf=%.1f, diff=%.1f\n",sdr.satstr,sdr.acq.cn0,sdr.acq.peakr,cast(int)sdr.acq.acqcodei, sdr.acq.acqfreq-sdr.f_if, sdr.acq.acqfreqf-sdr.f_if, sdr.acq.acqfreq-sdr.acq.acqfreqf);
        
        sdr.trk.carrfreq=sdr.acq.acqfreqf;
        sdr.trk.codefreq=sdr.crate;

        /* check fine acquisition result */
        if (fabs(sdr.acq.acqfreqf-sdr.acq.acqfreq)>sdr.acq.step) 
            sdr.flagacq=OFF; /* reset */
    } else {
        SDRPRINTF("%s, C/N0=%.1f, peak=%.1f, codei=%d, freq=%.1f\n",sdr.satstr,sdr.acq.cn0,sdr.acq.peakr,sdr.acq.acqcodei,sdr.acq.acqfreq-sdr.f_if);
        Sleep(ACQSLEEP);
    }
    //sdrfree(data); sdrfree(datal);
    delete data;
    delete datal;
    return buffloc;
}
/* check acquisition result -----------------------------------------------------
* check GNSS signal exists or not
* carrier frequency is computed
* args   : sdrch_t *sdr     I/0 sdr channel struct
*          double *P        I   normalized correlation power vector
* return : int                  acquisition flag (0: not acquired, 1: acquired) 
* note : first/second peak ratio and c/n0 computation
*------------------------------------------------------------------------------*/
bool checkacquisition(string file = __FILE__, size_t line = __LINE__)(double *P, sdrch_t *sdr)
{
    traceln("called");
    int maxi,codei,freqi,exinds,exinde;
    double maxP,maxP2,meanP;
    
    maxP=maxvd(P,sdr.acq.nfft*sdr.acq.nfreq,-1,-1,&maxi);
    ind2sub(maxi,sdr.acq.nfft,sdr.acq.nfreq,&codei,&freqi);

    /* C/N0 calculation */
    exinds=codei-2*sdr.nsampchip; if(exinds<0) exinds+=sdr.nsamp; /* excluded index */
    exinde=codei+2*sdr.nsampchip; if(exinde>=sdr.nsamp) exinde-=sdr.nsamp;
    meanP=meanvd(&P[freqi*sdr.acq.nfft],sdr.nsamp,exinds,exinde); /* mean of correlation */
    sdr.acq.cn0=10*log10(maxP/meanP/sdr.ctime);

    /* peak ratio */
    maxP2=maxvd(&P[freqi*sdr.acq.nfft],sdr.nsamp,exinds,exinde,&maxi);

    sdr.acq.peakr=maxP/maxP2;
    sdr.acq.acqcodei=codei;
    sdr.acq.acqfreq=sdr.acq.freq[freqi];

    return sdr.acq.peakr>ACQTH;
}
/* parallel correlator ----------------------------------------------------------
* fft based parallel correlator
* args   : char   *data     I   sampling data vector (n x 1 or 2n x 1)
*          int    dtype     I   sampling data type (1:real,2:complex)
*          double ti        I   sampling interval (s)
*          int    n         I   number of samples
*          double *freq     I   doppler search frequencies (Hz)
*          int    nfreq     I   number of frequencies
*          double crate     I   code chip rate (chip/s)
*          int    m         I   number of resampling data
*          cpx_t  codex     I   frequency domain code
*          double *P        O   normalized correlation power vector
* return : none
* notes  : P=abs(ifft(conj(fft(code)).*fft(data.*e^(2*pi*freq*t*i)))).^2
*------------------------------------------------------------------------------*/
void pcorrelator(string file = __FILE__, size_t line = __LINE__)(const(byte)[] data, int dtype, double ti, int n, double *freq,
                        int nfreq, double crate, int m, cpx_t* codex, double *P)
{
    traceln("called");
    //int i;
    cpx_t *datax;
    short* dataI, dataQ;
    //byte *dataR;
/*    
    if (!(dataR=cast(char*)sdrmalloc(char.sizeof*m*dtype))||
        !(dataI=cast(short*)sdrmalloc(short.sizeof*m))||
        !(dataQ=cast(short*)sdrmalloc(short.sizeof*m))||
        !(datax=cpxmalloc(m))) {
            SDRPRINTF("error: pcorrelator memory allocation\n");
            return;
    }
*/
    auto dataR = new byte[m*dtype];
    dataI=cast(short*)sdrmalloc(short.sizeof*m);
    dataQ=cast(short*)sdrmalloc(short.sizeof*m);
    datax=cpxmalloc(m);

    if(dataR is null || dataI is null || dataQ is null || datax is null){
        SDRPRINTF("error: pcorrelator memory allocation\n");
            return;
    }

    /* zero padding */
    //memset(dataR,0,m*dtype);
    dataR[0 .. m * dtype] = 0;
    //memcpy(dataR,data,n*dtype);
    dataR[0 .. n * dtype] = data[0 .. n * dtype];

    //for (i=0;i<nfreq;i++) {
    foreach(i; 0 .. nfreq){
        /* mix local carrier */
        mixcarr(dataR,dtype,ti,m,freq[i],0.0,dataI,dataQ);
    
        /* to complex */
        cpxcpx(dataI,dataQ,CSCALE/m,m,datax);
    
        /* convolution */
        cpxconv(datax,codex,m,n,1,&P[i*n]);
    }
    //sdrfree(dataR); 
    delete dataR;
    sdrfree(dataI); 
    sdrfree(dataQ); 
    cpxfree(datax);
}
/* doppler fine search ----------------------------------------------------------
* doppler frequency search with FFT
* args   : char   *data     I   sampling data vector (n x 1 or 2n x 1)
*          int    dtype     I   sampling data type (1:real,2:complex)
*          double ti        I   sampling interval (s)
*          double crate     I   code chip rate (chip/s)
*          int    n         I   number of samples
*          int    m         I   number of FFT points
*          int    clen      I   number of code
*          short  *code     I   long code
* return : double               doppler frequency (Hz)
*------------------------------------------------------------------------------*/
double carrfsearch(string file = __FILE__, size_t line = __LINE__)(const(byte)[] data, int dtype, double ti, double crate, int n, int m, int clen, short* code)
{
    traceln("called");
    byte[] rdataI, rdataQ;
    short* rcode, rcodeI, rcodeQ;
    cpx_t* datax;
    double* fftxc;
    int i,ind=0;
    
    rdataI = new byte[m];
    rdataQ = new byte[m];
    rcode=cast(short*)sdrmalloc(short.sizeof*m);
    rcodeI=cast(short*)sdrmalloc(short.sizeof*m);
    rcodeQ=cast(short*)sdrmalloc(short.sizeof*m);
    fftxc=cast(double*)malloc(double.sizeof*m);
    datax=cpxmalloc(m);

    if(rdataI is null || rdataQ is null || rcode is null || rcodeI is null || rcodeQ is null || fftxc is null || datax is null){
        SDRPRINTF("error: carrfsearch memory allocation\n");
            return 0;
    }

    /* zero padding */
    /+
    for (i=0;i<m;i++) {
        rcodeI[i]=0;
        rcodeQ[i]=0;
        rdataI[i]=0;
        rdataQ[i]=0;
    }+/
    rcodeI[0 .. m] = 0;
    rcodeQ[0 .. m] = 0;
    rdataI[0 .. m] = 0;
    rdataQ[0 .. m] = 0;

    rescode(code,clen,0,0,ti*crate,n,rcode);        
    if (dtype==DTYPEI) {  /* real */
        //for (i=0;i<n;i++) rdataI[i]=data[i];
        rdataI[0 .. n] = data[0 .. n];

        mulvcs(rdataI.ptr,rcode,m,rcodeI);
    
        /* to frequency domain */
        cpxcpx(rcodeI,null,1.0,m,datax);

    }
    if (dtype==DTYPEIQ) {  /* complex */
        for (i=0;i<n;i++) {
            rdataI[i]=data[2*i];
            rdataQ[i]=data[2*i+1];
        }

        mulvcs(rdataI.ptr,rcode,n,rcodeI);
        mulvcs(rdataQ.ptr,rcode,n,rcodeQ);
    
        /* to frequency domain */
        cpxcpx(rcodeI,rcodeQ,1.0,m,datax);
    }

    /* compute power spectrum */
    cpxpspec(datax,m,0,fftxc);

    if (dtype==DTYPEI)
        maxvd(fftxc,m/2,-1,-1,&ind);
    if (dtype==DTYPEIQ)
        maxvd(&fftxc[m/2],m/2,-1,-1,&ind);

    /*sdrfree(rdataI); sdrfree(rdataQ); */sdrfree(rcode); sdrfree(rcodeI);
    sdrfree(rcodeQ); free(fftxc); cpxfree(datax);
    delete rdataI;
    delete rdataQ;
    
    if (dtype==DTYPEI)
        return cast(double)ind/(m*ti);
    else
        return (m/2.0-ind)/(m*ti);
}