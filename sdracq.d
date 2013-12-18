/*-------------------------------------------------------------------------------
* sdracq.c : SDR acquisition functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;
import sdrcmn;
import util.trace;
import util.range;
import sdrrcv;

import std.math;
import std.stdio;

import std.algorithm;
import std.range;
import std.conv;
import std.datetime;
import std.random;
import std.typecons;


/* sdr acquisition function -----------------------------------------------------
* sdr acquisition function called from sdr channel thread
* args   : sdrch_t *sdr     I/O sdr channel struct
*          double *power    O   normalized correlation power vector (2D array)
* return : uint64_t             current buffer location
*------------------------------------------------------------------------------*/
double[][] sdracquisition(Sdr)(ref Sdr sdr)
{
    traceln("called");

    auto power = uninitializedArray!(double[][])(sdr.acq.nfreq, sdr.acq.nfft);

    foreach(e; power)
        e[] = 0;

    // FFTを使った、正確なコード位相と、曖昧な搬送波周波数(ドップラー周波数)の探索
    /* acquisition integration */
    foreach(i; 0 .. sdr.acq.intg){
        /* get new 1ms data */
        scope data = sdr.copyTo(uninitializedArray!(byte[])(sdr.acq.nfft * sdr.dtype));
        sdr.consume((cast(size_t)((cast(real)sdr.acq.nfft)/sdr.nsamp + 1)) * sdr.nsamp);

        /* fft correlation */
        pcorrelator(data, sdr.dtype, sdr.ti, sdr.acq.nfft, sdr.acq.freq, sdr.crate, sdr.acq.nfft, sdr.xcode, power);

        /* check acquisition result */
        if (sdr.checkacquisition(power)) {
            sdr.flagacq = true;
            sdr.consume(sdr.acq.acqcodei);      // バッファの先頭にコードの先頭が来るようにする
            break;
        }
    }

    // FFTを使った、それなりに正確な搬送波周波数(ドップラー周波数)の探索, L2CMの場合は前段の周波数探索で十分に正確に探索しているため不要
    if (sdr.flagacq && !(sdr.ctype == CType.L2RCCM)){
        scope datal = sdr.copyTo(uninitializedArray!(byte[])(sdr.acq.nfft * sdr.dtype * sdr.acq.lenf));

        /* fine doppler search */
        sdr.acq.acqfreqf = carrfsearch(datal, sdr.dtype, sdr.ti, sdr.crate, sdr.nsamp * sdr.acq.lenf, sdr.acq.nfftf, sdr.lcode[0 .. sdr.clen * sdr.acq.lenf]);
        writefln("%s, C/N0=%.1f, peak=%.1f, codei=%d, freq=%.1f, freqf=%.1f, diff=%.1f", sdr.satstr, sdr.acq.cn0, sdr.acq.peakr, cast(int)sdr.acq.acqcodei, sdr.acq.acqfreq - sdr.f_if, sdr.acq.acqfreqf - sdr.f_if, sdr.acq.acqfreq - sdr.acq.acqfreqf);
        
        sdr.trk.carrfreq = sdr.acq.acqfreqf;
        sdr.trk.codefreq = sdr.crate;

        /* check fine acquisition result */
        if (std.math.abs(sdr.acq.acqfreqf - sdr.acq.acqfreq) > sdr.acq.step)
            sdr.flagacq = false; /* reset */
    }else if(sdr.flagacq && sdr.ctype == CType.L2RCCM){
        sdr.acq.acqfreqf = sdr.acq.acqfreq;     // fineサーチしてないけど、してるように見せかけ
        sdr.trk.carrfreq = sdr.acq.acqfreq;
        sdr.trk.codefreq = sdr.crate;
        writefln("%s, C/N0=%.1f, peak=%.1f, codei=%d, freq=%.1f", sdr.satstr,sdr.acq.cn0,sdr.acq.peakr,sdr.acq.acqcodei,sdr.acq.acqfreq-sdr.f_if);
    }else
        writefln("%s, C/N0=%.1f, peak=%.1f, codei=%d, freq=%.1f", sdr.satstr,sdr.acq.cn0,sdr.acq.peakr,sdr.acq.acqcodei,sdr.acq.acqfreq-sdr.f_if);


    if(!sdr.flagacq){
        // 今までに何回連続で捕捉に失敗したかで、次のバッファの場所が決まる
        ++sdr.acq.failCount;
        sdr.consume(min(sdr.acq.failCount ^^ 2 * (sdr.nsamp >> 4), sdr.f_sf * 10).to!size_t());
    }else
        sdr.acq.failCount = 0;

    return power;
}


/* check acquisition result -----------------------------------------------------
* check GNSS signal exists or not
* carrier frequency is computed
* args   : sdrch_t *sdr     I/0 sdr channel struct
*          double *P        I   normalized correlation power vector
* return : int                  acquisition flag (0: not acquired, 1: acquired) 
* note : first/second peak ratio and c/n0 computation
*------------------------------------------------------------------------------*/
bool checkacquisition(ref sdrch_t sdr, double[][] P)
{
    traceln("called");

    immutable max = P.zip(iota(size_t.max)).map!(a => a[0].findMaxWithIndex().tupleof.tuple(a[1]))()
                   .reduce!((a, b) => b[0] > a[0] ? b : a)();

    immutable maxP = max[0],
              codei = max[1],
              freqi = max[2];

    immutable exinds = (a => (a < 0) ? (a + sdr.nsamp) : a)(codei - 4 * sdr.nsampchip),
              exinde = (a => (a >= sdr.nsamp) ? (a - sdr.nsamp) : a)(codei + 4 * sdr.nsampchip),
              meanP = P[freqi].sliceEx(exinds, exinde).mean(),
              maxP2 = P[freqi].sliceEx(exinds, exinde).minPos!"a > b"().front;

    /* C/N0 calculation */
    sdr.acq.cn0 = 10 * log10(maxP / meanP / sdr.ctime);

    /* peak ratio */
    sdr.acq.peakr = maxP / maxP2;
    sdr.acq.acqcodei = codei.to!int();
    sdr.acq.acqfreq = sdr.acq.freq[freqi];

    return sdr.acq.peakr > Constant.get!"Acquisition.TH"(sdr.ctype);
}


/* parallel correlator ----------------------------------------------------------
* fft based parallel correlator
* args   : char   *data     I   sampling data vector (n x 1 or 2n x 1)
*          DType  dtype     I   sampling data type (1:real,2:complex)
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
void pcorrelator(in byte[] data, DType dtype, double ti, int n, in double[] freq, double crate, int m, in cpx_t[] codex, double[][] P)
{
    traceln("called");

    scope dataR = new byte[m*dtype],
          dataI = new short[m],
          dataQ = new short[m],
          datax = new cpx_t[m];

    /* zero padding */
    dataR[] = 0;
    dataR[0 .. n * dtype] = data[0 .. n * dtype];

    foreach(i, f; freq){
        /* mix local carrier */
        mixcarr(dataR, dtype, ti, f, 0.0, dataI, dataQ);
        dataI.zip(dataQ).csvOutput("mix_carr_" ~ f.to!string() ~ ".csv");

        /* to complex */
        cpxcpx(dataI, dataQ, CSCALE / m, datax);

        /* convolution */
        cpxconv(datax, codex, true, P[i]);
    }
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
double carrfsearch(const(byte)[] data, DType dtype, double ti, double crate, int n, int m, in short[] code)
{
    traceln("called");

    scope rdataI = new short[m],
          rdataQ = new short[m],
          rcode = new short[m],
          rcodeI = new short[m],
          rcodeQ = new short[m],
          fftxc = new double[m],
          datax = new cpx_t[m];

    code.resampling(0, 0, ti * crate, n, rcode.save);

    final switch(dtype){
      case DType.I:       // real
        //rdataI[0 .. n] = data[0 .. n];
        data[0 .. n].moveTo(rdataI[0 .. n]);

        rcodeI[] = rdataI[] * rcode[];
        cpxcpx(rcodeI, null, 1.0, datax);       // to frequency domain
        cpxpspec(datax, 0, fftxc);              // compute power spectrum

        immutable ind = fftxc[0 .. m/2].findMaxWithIndex()[1];

        return (cast(double)ind) / (m * ti);

      case DType.IQ:      // complex
        foreach(i; 0 .. n){
            rdataI[i] = data[i*2];
            rdataQ[i] = data[i*2 + 1];
        }

        rcodeI[] = rdataI[] * rcode[];
        rcodeQ[] = rdataQ[] * rcode[];
        cpxcpx(rcodeI, rcodeQ, 1.0, datax);     // to frequency domain
        cpxpspec(datax, 0, fftxc);              // compute power spectrum

        immutable ind = fftxc[m/2 .. $].findMaxWithIndex()[1];

        return (m / 2.0 - ind) / (m * ti);
    }
}
