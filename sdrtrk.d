/*-------------------------------------------------------------------------------
* sdrtrk.c : SDR tracking functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;
import sdrrcv;
import sdrmain;
import sdrcmn;
import sdrnav;

import util.trace;
import util.numeric;

import std.math;
import std.stdio;
import std.traits;
import std.parallelism;
import std.exception;
import std.array;

private F atan(F)(F y, F x)
if(isFloatingPoint!F)
out(r){
    assert(r.isNaN || (-PI/2 <= r && r <= PI/2));
}
body{
    return x.signbit ? atan2(-y, -x) : atan2(y, x);
}


/* sdr tracking function --------------------------------------------------------
* sdr tracking function called from sdr channel thread
* args   : sdrch_t *sdr      I/O sdr channel struct
*          ulong buffloc  I   buffer location
*          ulong cnt      I   counter of sdr channel thread
* return : ulong              current buffer location
*------------------------------------------------------------------------------*/
size_t sdrtracking(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr, size_t buffloc, size_t cnt)
{
    traceln("called");
    
    /* memory allocation */

    // [sample/code]
    // tracking-loopによって更新されるnsamp
    enforce(sdr.clen.isValidNum);
    enforce(sdr.trk.remcode.isValidNum);
    enforce(sdr.trk.codefreq.isValidNum);
    enforce(sdr.f_sf.isValidNum);
    
    //sdr.currnsamp = ((sdr.clen - sdr.trk.remcode)/(sdr.trk.codefreq/sdr.f_sf)).to!int();

    immutable lenOf1ms = sdr.crate * 0.001,
              remcode1ms = (a => a < 1 ? a : (a - lenOf1ms))(sdr.trk.remcode % lenOf1ms),
              trkN = ((lenOf1ms - remcode1ms)/(sdr.trk.codefreq/sdr.f_sf)).to!int();

    sdr.currnsamp = ((lenOf1ms - remcode1ms)/(sdr.trk.codefreq/sdr.f_sf) * (sdr.ctime / 0.001L)).to!int();

    traceln();

    scope byte[] data = new byte[trkN * sdr.dtype];
    rcvgetbuff(&sdrini, buffloc, trkN, sdr.ftype, sdr.dtype, data);

    traceln();

    {
        traceln();
        immutable copySize = 1 + 2 * sdr.trk.ncorrp;
        sdr.trk.oldI[0 .. copySize] = sdr.trk.I[0 .. copySize];
        sdr.trk.oldQ[0 .. copySize] = sdr.trk.Q[0 .. copySize];
    }

    traceln();

    sdr.trk.oldremcode = sdr.trk.remcode;
    sdr.trk.oldremcarr = sdr.trk.remcarr;

    traceln();

    /* correlation */
    correlator(data, sdr.dtype, sdr.ti, trkN, sdr.trk.carrfreq, sdr.trk.oldremcarr, sdr.trk.codefreq, sdr.trk.oldremcode,
               sdr.trk.prm1.corrp, sdr.trk.ncorrp, sdr.trk.Q, sdr.trk.I, &sdr.trk.remcode, &sdr.trk.remcarr, sdr.code);
    
    traceln();

    /* navigation data */
    sdrnavigation(sdr, buffloc, cnt);
    sdr.flagtrk = true;
    
    traceln();

    return buffloc + trkN;
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
                       double crate, double coff, in size_t[] s, int ns, double[] I, double[] Q,
                       double *remc, double *remp, in short[] codein)
in{
    bool b0 = (ti.isValidNum),
         b1 = (freq.isValidNum),
         b2 = (phi0.isValidNum),
         b3 = (crate.isValidNum),
         b4 = (coff.isValidNum);

    scope(failure)
        traceln([b0, b1, b2, b3, b4]);

    assert(b0 && b1 && b2 && b3 && b4);
}
body{
    traceln("called");
    //short* dataI, dataQ, code_e, code;
    //int i;
    size_t smax = s[ns-1];

    short[] dataI = new short[n];
    short[] dataQ = new short[n];
    short[] code_e = new short[n + 2*smax];
    short* code = code_e.ptr + smax;

    /* mix local carrier */
    *remp = mixcarr(data, dtype, ti, freq, phi0, dataI, dataQ);

    /* resampling code */
    traceln("coff:= ", coff);
    traceln("ti:= ", ti);
    traceln("crate:=", crate);
    *remc = rescode(codein.ptr, coden, coff, smax, ti*crate, n, code_e);

    /* multiply code and integrate */
    dot_23(dataI.ptr, dataQ.ptr, code, code-s[0], code+s[0], n, I.ptr, Q.ptr);
    foreach(i; 1 .. ns)
        dot_22(dataI.ptr, dataQ.ptr, code-s[i], code+s[i], n, I.ptr + 1 + i*2, Q.ptr + 1 + i*2);

    I[0 .. 1 + 2 * ns] *= CSCALE;
    Q[0 .. 1 + 2 * ns] *= CSCALE;
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
void cumsumcorr(string file = __FILE__, size_t line = __LINE__)(double[] I, double[] Q, sdrtrk_t *trk, int flag1, int flag2)
{
    traceln("called");

    if (!flag1||(flag1&&flag2)) {
        trk.oldsumI[] = trk.sumI[];
        trk.oldsumQ[] = trk.sumQ[];
        trk.sumI[] = I[];
        trk.sumQ[] = Q[];
    }else{
        trk.sumI[] += I[];
        trk.sumQ[] += Q[];
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
in{
    assert(sdr.trk.sumI[0].isValidNum);
    assert(sdr.trk.sumQ[0].isValidNum);
    assert(sdr.trk.oldsumI[0].isValidNum);
    assert(sdr.trk.oldsumQ[0].isValidNum);
}
out{
    assert(sdr.trk.carrNco.isValidNum);
    assert(sdr.trk.carrfreq.isValidNum);
    assert(sdr.trk.carrErr.isValidNum);
}
body{
    traceln("called");

    double carrErr,freqErr;
    immutable IP = sdr.trk.sumI[0],
              QP = sdr.trk.sumQ[0],
              oldIP = sdr.trk.oldsumI[0],
              oldQP = sdr.trk.oldsumQ[0];
    
    //carrErr=atan(QP / IP) / DPI;
    carrErr = atan(QP, IP) / DPI;
    freqErr=atan2(cast(real)oldIP*QP-IP*oldQP, fabs(oldIP*IP)+fabs(oldQP*QP))/PI;

    /* 2nd order PLL with 1st order FLL */
    sdr.trk.carrNco += prm.pllaw * (carrErr - sdr.trk.carrErr)
                     + prm.pllw2 * prm.dt * carrErr
                     + prm.fllw  * prm.dt * freqErr;

    sdr.trk.carrfreq = sdr.acq.acqfreqf + sdr.trk.carrNco;
    sdr.trk.carrErr = carrErr;
}


/* delay lock loop --------------------------------------------------------------
* delay lock loop (2nd order DLL)
* code frequency is computed
* args   : sdrch_t *sdr     I/0 sdr channel struct
*          sdrtrkprm_t *prm I   sdr tracking prameter struct
* return : none
*------------------------------------------------------------------------------*/
void dll(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr, sdrtrkprm_t *prm)
in{
    assert(sdr.trk.sumI[sdr.trk.prm1.ne].isValidNum);
    assert(sdr.trk.sumI[sdr.trk.prm1.nl].isValidNum);
    assert(sdr.trk.sumQ[sdr.trk.prm1.ne].isValidNum);
    assert(sdr.trk.sumQ[sdr.trk.prm1.nl].isValidNum);

    assert(prm.dllaw.isValidNum);
    assert(sdr.trk.codeErr.isValidNum);
    assert(prm.dllw2.isValidNum);
    assert(prm.dt.isValidNum);

    assert(sdr.crate.isValidNum);
    assert(sdr.trk.codeNco.isValidNum);
    assert(sdr.trk.carrfreq.isValidNum);
    assert(sdr.f_if.isValidNum);
    assert(Constant.get!"freq"(sdr.ctype).isValidNum);
}
out{
    assert(sdr.trk.codeNco.isValidNum);
    assert(sdr.trk.codefreq.isValidNum);
    assert(sdr.trk.codeErr.isValidNum);
}
body{
    static real cpxAbsSq(real i, real q) pure nothrow @safe { return i^^2 + q^^2; }

    traceln("called");

    immutable ne = sdr.trk.prm1.ne,
              nl = sdr.trk.prm1.nl,
              IE = sdr.trk.sumI[ne],
              IL = sdr.trk.sumI[nl],
              QE = sdr.trk.sumQ[ne],
              QL = sdr.trk.sumQ[nl],
              IEQE = cpxAbsSq(IE, QE),
              ILQL = cpxAbsSq(IL, QL),
              codeErr = (IEQE + ILQL) != 0 ? ((IEQE - ILQL) / (IEQE + ILQL)) : 0;
    
    enforce(codeErr.isValidNum);

    /* 2nd order DLL */
    sdr.trk.codeNco += prm.dllaw * (codeErr - sdr.trk.codeErr)
                     + prm.dllw2 * prm.dt * codeErr;
    
    sdr.trk.codefreq = sdr.crate - sdr.trk.codeNco + (sdr.trk.carrfreq - sdr.f_if) / (Constant.get!"freq"(sdr.ctype) / sdr.crate); /* carrier aiding */
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
    shiftright(&trk.tow[1],        &trk.tow[0],        double.sizeof, Constant.Observation.OBSINTERPN);
    shiftright(&trk.L[1],          &trk.L[0],          double.sizeof, Constant.Observation.OBSINTERPN);
    shiftright(&trk.D[1],          &trk.D[0],          double.sizeof, Constant.Observation.OBSINTERPN);
    shiftright(&trk.codei[1],      &trk.codei[0],      ulong.sizeof,  Constant.Observation.OBSINTERPN);
    shiftright(&trk.cntout[1],     &trk.cntout[0],     ulong.sizeof,  Constant.Observation.OBSINTERPN);
    shiftright(&trk.remcodeout[1], &trk.remcodeout[0], double.sizeof, Constant.Observation.OBSINTERPN);

    trk.tow[0] = sdr.nav.firstsftow + (cast(double)(cnt-sdr.nav.firstsfcnt)) / 1000;
    trk.codei[0] = buffloc;
    trk.cntout[0] = cnt;
    trk.remcodeout[0] = trk.oldremcode * sdr.f_sf / trk.codefreq;

    /* doppler */
    trk.D[0] = (trk.carrfreq - sdr.f_if) /*+ (sdr.trk.codefreq / sdr.crate -1) * Constant.get!"freq"(sdr.ctype)*/;

    /* carrier phase */
    //if (!trk.flagremcarradd) {
    //    immutable tmpL = trk.L[0];

    //    trk.L[0]+=trk.remcarr/DPI;
    //    trk.flagpolarityadd = true;

    //    (sdr.ctype == CType.L1CA) && writefln("%s [cyc] + (%s / DPI)[cyc] -> %s [cyc]", tmpL, trk.remcarr, trk.L[0]);
    //}

    //if (sdr.flagnavpre&&!trk.flagpolarityadd) {
    //    if (sdr.nav.polarity==-1) { trk.L[0]+=0.5; }
    //    trk.flagpolarityadd = true;
    //}

    //immutable tmpL = trk.L[0];
    trk.L[0] += trk.D[0]*trk.prm2.dt;

    //(sdr.ctype == CType.L1CA) && writefln("(%s - %s)[Hz] * %s[s] == %s[cyc], sum : %s [cyc] -> %s [cyc]", trk.carrfreq, sdr.f_if, trk.prm2.dt, trk.D[0]* trk.prm2.dt, tmpL, trk.L[0]);
    
    trk.Isum+=fabs(trk.sumI[0]);
    if (snrflag){
        shiftright(&trk.S[1],&trk.S[0],double.sizeof,Constant.Observation.OBSINTERPN);
        shiftright(&trk.codeisum[1],&trk.codeisum[0],ulong.sizeof,Constant.Observation.OBSINTERPN);
        
        /* signal to noise ratio */
        trk.S[0]=10*log(trk.Isum/100.0/100.0)+log(500.0);
        trk.codeisum[0]=buffloc;
        trk.Isum=0;
    }
}