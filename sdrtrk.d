/*-------------------------------------------------------------------------------
* sdrtrk.c : SDR tracking functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;

import std.math;
import std.stdio;

/* sdr tracking function --------------------------------------------------------
* sdr tracking function called from sdr channel thread
* args   : sdrch_t *sdr      I/O sdr channel struct
*          ulong buffloc  I   buffer location
*          ulong cnt      I   counter of sdr channel thread
* return : ulong              current buffer location
*------------------------------------------------------------------------------*/
ulong sdrtracking(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr, ulong buffloc, ulong cnt)
{
    traceln("called");
    
    /* memory allocation */
    immutable tmp = cast(size_t)((sdr.clen-sdr.trk.remcode)/(sdr.trk.codefreq/sdr.f_sf));
    sdr.currnsamp = cast(int)tmp;

    scope byte[] data = new byte[sdr.nsamp * sdr.dtype];
    rcvgetbuff(&sdrini, buffloc, sdr.currnsamp, sdr.ftype, sdr.dtype, data);

    {
        immutable copySize = 1 + 2 * sdr.trk.ncorrp;
        sdr.trk.oldI[0 .. copySize] = sdr.trk.I[0 .. copySize];
        sdr.trk.oldQ[0 .. copySize] = sdr.trk.Q[0 .. copySize];
    }

    sdr.trk.oldremcode = sdr.trk.remcode;
    sdr.trk.oldremcarr = sdr.trk.remcarr;

    /* correlation */
    correlator(data, sdr.dtype, sdr.ti, sdr.currnsamp, sdr.trk.carrfreq, sdr.trk.oldremcarr, sdr.trk.codefreq, sdr.trk.oldremcode,
               sdr.trk.prm1.corrp, sdr.trk.ncorrp, sdr.trk.Q, sdr.trk.I, &sdr.trk.remcode, &sdr.trk.remcarr, sdr.code,sdr.clen);
    
    /* navigation data */
    sdrnavigation(sdr, buffloc, cnt);
    sdr.flagtrk = ON;
    
    return buffloc + sdr.currnsamp;
}
/* correlator -------------------------------------------------------------------
* multiply sampling data and carrier (I/Q), multiply code (E/P/L), and integrate
* args   : char   *data     I   sampling data vector (n x 1 or 2n x 1)
*          int    dtype     I   sampling data type (1:real,2:complex)
*          double ti        I   sampling interval (s)
*          int    n         I   number of samples
*          double freq      I   carrier frequency (Hz)
*          double phi0      I   carrier initial phase (rad)
*          double crate     I   code chip rate (chip/s)
*          double coff      I   code chip offset (chip)
*          int    s         I   correlator points (sample)
*          short  *I,*Q     O   correlation power I,Q
*                                 I={I_P,I_E1,I_L1,I_E2,I_L2,...,I_Em,I_Lm}
*                                 Q={Q_P,Q_E1,Q_L1,Q_E2,Q_L2,...,Q_Em,Q_Lm}
* return : none
* notes  : see above for data
*------------------------------------------------------------------------------*/
void correlator(string file = __FILE__, size_t line = __LINE__)(const(byte)[] data, DType dtype, double ti, int n, double freq, double phi0, 
                       double crate, double coff, int* s, int ns, double *I, double *Q,
                       double *remc, double *remp, short* codein, int coden)
{
    traceln("called");
    short* dataI, dataQ, code_e, code;
    int i;
    int smax=s[ns-1];

    dataI = cast(short*)sdrmalloc(short.sizeof * n+32);
    scope(exit) sdrfree(dataI);
    dataQ = cast(short*)sdrmalloc(short.sizeof * n+32);
    scope(exit) sdrfree(dataQ);
    code_e = cast(short*)sdrmalloc(short.sizeof * (n+2*smax));
    scope(exit) sdrfree(code_e);
    
    code = code_e + smax;
    
    /* mix local carrier */
    *remp = mixcarr(data,dtype,ti,n,freq,phi0,dataI,dataQ);
    
    /* resampling code */
    *remc = rescode(codein,coden,coff,smax,ti*crate,n,code_e);

    /* multiply code and integrate */
    dot_23(dataI,dataQ,code,code-s[0],code+s[0],n,I,Q);
    for (i=1;i<ns;i++) {
        dot_22(dataI,dataQ,code-s[i],code+s[i],n,I+1+i*2,Q+1+i*2);
    }

    I[0 .. 1 + 2 * ns] *= CSCALE;
    Q[0 .. 1 + 2 * ns] *= CSCALE;

    //dataI=dataQ=code_e=null;
}
/* cumulative sum of correlation output -----------------------------------------
* phase/frequency lock loop (2nd order PLL with 1st order FLL)
* carrier frequency is computed
* args   : double *I        I   correlation output in 1ms (in-phase)
*          double *Q        I   correlation output in 1ms (quadrature-phase)
*          sdrtrk_t trk     I/0 sdr tracking struct
*          int    flag1     I   reset flag 1
*          int    flag2     I   reset flag 2
* return : none
*------------------------------------------------------------------------------*/
void cumsumcorr(string file = __FILE__, size_t line = __LINE__)(double *I, double *Q, sdrtrk_t *trk, int flag1, int flag2)
{
    traceln("called");
    immutable loopMax = 1+2*trk.ncorrp;

    if (!flag1||(flag1&&flag2)) {
        trk.oldsumI[0 .. loopMax] = trk.sumI[0 .. loopMax];
        trk.oldsumQ[0 .. loopMax] = trk.sumQ[0 .. loopMax];
        trk.sumI[0 .. loopMax] = I[0 .. loopMax];
        trk.sumQ[0 .. loopMax] = Q[0 .. loopMax];
    }else{
        trk.sumI[0 .. loopMax] += I[0 .. loopMax];
        trk.sumQ[0 .. loopMax] += Q[0 .. loopMax];
    }
}
/* phase/frequency lock loop ----------------------------------------------------
* phase/frequency lock loop (2nd order PLL with 1st order FLL)
* carrier frequency is computed
* args   : sdrch_t *sdr     I/0 sdr channel struct
*          sdrtrkprm_t *prm I   sdr tracking prameter struct
* return : none
*------------------------------------------------------------------------------*/
void pll(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr, sdrtrkprm_t *prm)
{
    traceln("called");
    double carrErr,freqErr;
    immutable IP = sdr.trk.sumI[0],
              QP = sdr.trk.sumQ[0];
    immutable oldIP = sdr.trk.oldsumI[0],
              oldQP = sdr.trk.oldsumQ[0];
    
    carrErr=atan(QP / IP) / DPI;
    freqErr=atan2(cast(real)oldIP*QP-IP*oldQP, fabs(oldIP*IP)+fabs(oldQP*QP))/PI;

    /* 2nd order PLL with 1st order FLL */
    sdr.trk.carrNco+=prm.pllaw*(carrErr-sdr.trk.carrErr)+prm.pllw2*prm.dt*carrErr+prm.fllw*prm.dt*freqErr;

    sdr.trk.carrfreq=sdr.acq.acqfreqf+sdr.trk.carrNco;
    sdr.trk.carrErr=carrErr;
}
/* delay lock loop --------------------------------------------------------------
* delay lock loop (2nd order DLL)
* code frequency is computed
* args   : sdrch_t *sdr     I/0 sdr channel struct
*          sdrtrkprm_t *prm I   sdr tracking prameter struct
* return : none
*------------------------------------------------------------------------------*/
void dll(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr, sdrtrkprm_t *prm)
{
    real abs(real i, real q){ return (i^^2 + q^^2) ^^ 0.5; }

    traceln("called");
    double codeErr;
    int ne=sdr.trk.prm1.ne, nl=sdr.trk.prm1.nl;
    immutable IE = sdr.trk.sumI[ne],
              IL = sdr.trk.sumI[nl],
              QE = sdr.trk.sumQ[ne],
              QL = sdr.trk.sumQ[nl],
              IEQE = abs(IE, QE),
              ILQL = abs(IL, QL);

    codeErr = (IEQE - ILQL) / (IEQE + ILQL);
    
    /* 2nd order DLL */
    sdr.trk.codeNco += prm.dllaw * (codeErr - sdr.trk.codeErr)
                     + prm.dllw2 * prm.dt * codeErr;
    
    sdr.trk.codefreq = sdr.crate - sdr.trk.codeNco + (sdr.trk.carrfreq - sdr.f_if) / (FREQ1 / sdr.crate); /* carrier aiding */
    sdr.trk.codeErr = codeErr;
}
/* set observation data ---------------------------------------------------------
* calculate doppler/carrier phase/SNR
* args   : sdrch_t *sdr     I   sdr channel struct
*          ulong buffloc I   current buffer location
*          ulong cnt     I   current counter of sdr channel thread
*          sdrtrk_t trk     I/0 sdr tracking struct
*          int    snrflag   I   SNR calculation flag
* return : none
*------------------------------------------------------------------------------*/
void setobsdata(sdrch_t *sdr, ulong buffloc, ulong cnt, sdrtrk_t *trk, int snrflag)
{   
    shiftright(&trk.tow[1],&trk.tow[0],double.sizeof,OBSINTERPN);
    shiftright(&trk.L[1],&trk.L[0],double.sizeof,OBSINTERPN);
    shiftright(&trk.D[1],&trk.D[0],double.sizeof,OBSINTERPN);
    shiftright(&trk.codei[1],&trk.codei[0],ulong.sizeof,OBSINTERPN);
    shiftright(&trk.cntout[1],&trk.cntout[0],ulong.sizeof,OBSINTERPN);
    shiftright(&trk.remcodeout[1],&trk.remcodeout[0],double.sizeof,OBSINTERPN);

    trk.tow[0]=sdr.nav.firstsftow+(cast(double)(cnt-sdr.nav.firstsfcnt))/1000;
    trk.codei[0]=buffloc;
    trk.cntout[0]=cnt;
    trk.remcodeout[0]=trk.oldremcode*sdr.f_sf/trk.codefreq;

    /* doppler */
    trk.D[0]=trk.carrfreq-sdr.f_if;

    /* carrier phase */
    if (!trk.flagremcarradd) {
        trk.L[0]+=trk.remcarr/DPI;
        trk.flagpolarityadd=ON;
    }

    if (sdr.flagnavpre&&!trk.flagpolarityadd) {
        if (sdr.nav.polarity==-1) { trk.L[0]+=0.5; }
        trk.flagpolarityadd=ON;
    }

    trk.L[0]+=trk.D[0]*trk.prm2.dt; 
    
    trk.Isum+=fabs(trk.sumI[0]);
    if (snrflag) {
        shiftright(&trk.S[1],&trk.S[0],double.sizeof,OBSINTERPN);
        shiftright(&trk.codeisum[1],&trk.codeisum[0],ulong.sizeof,OBSINTERPN);
        
        /* signal to noise ratio */
        trk.S[0]=10*log(trk.Isum/100.0/100.0)+log(500.0);
        trk.codeisum[0]=buffloc;
        trk.Isum=0;
    }
}