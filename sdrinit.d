/*-------------------------------------------------------------------------------
* sdrinit.c : SDR initialize/cleanup functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;
import util.trace;
import sdrcode;
import sdrcmn;
import sdrplot;
import sdrconfig;

import core.sync.mutex;

import std.algorithm;
import std.array;
//import std.c.string;
//import std.c.stdlib : atoi, atof;
import std.exception;
import std.file;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;



/* check initial value ----------------------------------------------------------
* checking value in sdrini struct
* args   : sdrini_t *ini    I   sdrini struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
void checkInitValue()()
{
    traceln("called");

    static if(Config.Receiver.fends.length > 0)
        with(Config.Receiver.fends[0]){
            static assert(Config.Receiver.fends[0].f_sf.isInInterval!"()"(0, 100e6), "error: wrong freq. input sf1: %s".format(f_sf));
            static assert(Config.Receiver.fends[0].f_if.isInInterval!"[)"(0, 100e6), "error: wrong freq. input if1: %s".format(f_if));
        }

    static if(Config.Receiver.fends.length > 1)
        with(Config.Receiver.fends[1]){
            static assert(Config.Receiver.fends[1].f_sf.isInInterval!"()"(0, 100e6), "error: wrong freq. input sf2: %s".format(f_sf));
            static assert(Config.Receiver.fends[0].f_if.isInInterval!"[)"(0, 100e6), "error: wrong freq. input if2: %s".format(f_if));
        }

    with(Config.Output){
        static if(rtcm)
            static assert(rtcmPort.isInInterval!"[]"(0, short.max), "error: wrong rtcm port rtcm:%s".format(rtcmPort));

        static if(lex)
            static assert(lexPort.isInInterval!"[]"(0, short.max), "error: wrong rtcm port lex:%d".format(lexPort));
    }

    // checking filepath
    with(Config.Receiver){
        static if(fendType == Fend.FILE || fendType == Fend.FILESTEREO)
        {
            static assert(fends.length.isInInterval!"(]"(0, 2), "error: file1 or file2 are not selected");

          static if(fendType == Fend.FILE)
          {
            static if(fends.length > 0)
                assert(exists(fends[0].path), "error: file1 doesn't exist: %s".format(fends[0].path));

            static if(fends.length > 1)
                assert(exists(fends[1].path), "error: file2 doesn't exist: %s".format(fends[1].path));
          }
          else static if(fendType == Fend.FILESTEREO)
          {
            assert(exists(path), "error: file doesn't exist: %s".format(path));
          }
        }
    }

    // checking rinex directory
    static if(Config.Output.rinex)
        assert(exists(Config.Output.rinexDirPath), "error: rinex output directory doesn't exist: %s".format(Setting.Output.rinexDirPath));
}


/* initialization plot struct ---------------------------------------------------
* set value to plot struct
* args   : sdrplt_t *acq    I/0 plot struct for acquisition
*          sdrplt_t *trk    I/0 plot struct for tracking
*          sdrch_t  *sdr    I   sdr channel struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
void initpltstruct(string file = __FILE__, size_t line = __LINE__)(in ref sdrch_t sdr, ref sdrplt_t acq, ref sdrplt_t trk)
{
    traceln("called");

    /* acquisition */
    if (Config.Plot.acq) {
        setsdrplotprm(acq, PlotType.SurfZ, sdr.acq.nfreq.to!int, sdr.acq.nfft, sdr.nsampchip/3, Flag!"doAbs".no, 1, Constant.Plot.H, Constant.Plot.W, Constant.Plot.MH, Constant.Plot.MW, sdr.no);
        initsdrplot(acq);
        settitle(acq,sdr.satstr);
        setlabel(acq,"Frequency (Hz)","Code Offset (sample)");

        acq.otherSetting = "set size 0.8,0.8\n";

        acq.xvalue = sdr.acq.freq[0 .. sdr.acq.nfreq].dup;
        acq.yvalue = iota(sdr.acq.nfft).map!"cast(double)a"().array();
    }

    /* tracking */
    if (Config.Plot.trk) {
        setsdrplotprm(trk, PlotType.XY, 1 + 2 * sdr.trk.ncorrp, 0, 0, Flag!"doAbs".yes, 0.001, Constant.Plot.H, Constant.Plot.W, Constant.Plot.MH, Constant.Plot.MW, sdr.no);
        initsdrplot(trk);
        settitle(trk, sdr.satstr);
        setlabel(trk, "Code Offset (sample)", "Correlation Output");
        setyrange(trk, 0, 8 * sdr.trk.loopms);

        trk.otherSetting = "set size 0.8,0.8\n";
    }

    if (Config.Receiver.fendType == Fend.FILE || Config.Receiver.fendType == Fend.FILESTEREO)
        trk.pltms = Constant.Plot.MS_FILE;
    else
        trk.pltms = Constant.Plot.MS;
}


/* termination plot struct ------------------------------------------------------
* termination plot struct
* args   : sdrplt_t *acq    I/0 plot struct for acquisition
*          sdrplt_t *trk    I/0 plot struct for tracking
* return : none
*------------------------------------------------------------------------------*/
void quitpltstruct(ref sdrplt_t acq, ref sdrplt_t trk)
{
    traceln("called");
    if (Config.Plot.acq)
        quitsdrplot(acq);
    
    if (Config.Plot.trk)
        quitsdrplot(trk);
}


/* initialize acquisition struct ------------------------------------------------
* set value to acquisition struct
* args   : int sys          I   system type (SYS_GPS...)
*          int ctype        I   code type (CType.L1CA...)
*          sdracq_t *acq    I/0 acquisition struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
void initacqstruct(string file = __FILE__, size_t line = __LINE__)(int sys, CType ctype, sdracq_t *acq)
{
    traceln("called");

    enum sourceCode = q{
        acq.intg = INTG;
        acq.hband = HBAND;
        acq.step = STEP;
        acq.nfreq = 2 * (HBAND / STEP) + 1;
        //acq.lenf = LENF;
    };

    switch(ctype){
      case CType.L1CA:
        with(Constant.L1CA.Acquisition){
            mixin(sourceCode);
            acq.lenf = LENF;
        }
        break;

      case CType.L1SAIF:
        with(Constant.L1SAIF.Acquisition){
            mixin(sourceCode);
            acq.lenf = LENF;
        }
        break;

      case CType.L2RCCM:
        with(Constant.L2C.Acquisition)
            mixin(sourceCode);
        break;

      default:
        enforce(0);
    }
}


/* initialize tracking parameter struct -----------------------------------------
* set value to tracking parameter struct
* args   : sdrtrkprm_t *prm I/0 tracking parameter struct
*          int    sw        I   tracking mode selector switch (1 or 2)
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
void inittrkprmstruct(string file = __FILE__, size_t line = __LINE__)(CType ctype, sdrtrkprm_t *prm, int sw)
{
    traceln("called");
    int trkcp, trkcdn;
    
    /* tracking parameter selection */
    switch(sw){
      case 1:
        prm.dllb = Constant.get!"Tracking.Parameter1.DLLB"(ctype);
        prm.pllb = Constant.get!"Tracking.Parameter1.PLLB"(ctype);
        prm.fllb = Constant.get!"Tracking.Parameter1.FLLB"(ctype);
        prm.dt   = Constant.get!"Tracking.Parameter1.DT"(ctype);
        trkcp    = Constant.get!"Tracking.Parameter1.CP"(ctype);
        trkcdn   = Constant.get!"Tracking.Parameter1.CDN"(ctype);
        break;

      case 2:
        prm.dllb = Constant.get!"Tracking.Parameter2.DLLB"(ctype);
        prm.pllb = Constant.get!"Tracking.Parameter2.PLLB"(ctype);
        prm.fllb = Constant.get!"Tracking.Parameter2.FLLB"(ctype);
        prm.dt   = Constant.get!"Tracking.Parameter2.DT"(ctype);
        trkcp    = Constant.get!"Tracking.Parameter2.CP"(ctype);
        trkcdn   = Constant.get!"Tracking.Parameter2.CDN"(ctype);
        break;

      default:
        assert(0, "error: inittrkprmstruct sw = %s".format(sw));
    }


    /* correlation point */
    //prm.corrp = cast(int*)malloc(int.sizeof * Constant.TRKCN).enforce();
    prm.corrp = (){
        auto dst = new size_t[Constant.TRKCN];
        foreach(i, ref e; dst){
            e = trkcdn * (i + 1);

            if (e == trkcp){
                prm.ne = (i + 1) * 2 - 1; /* Early */
                prm.nl = (i + 1) * 2;   /* Late */
            }
        }

        return dst.idup;
    }();


    /* correlation point for plot */
    //prm.corrx = cast(double*)calloc(Constant.TRKCN *2 + 1, double.sizeof).enforce();
    prm.corrx = (){
        auto dst = new double[Constant.TRKCN *2 + 1];
        foreach(i; 1 .. Constant.TRKCN){
            dst[i*2 - 1] = -trkcdn * i;
            dst[i*2    ] = +trkcdn * i;
        }

        return dst.idup;
    }();


    /* calculation loop filter parameters */
    {
        immutable dll_k = prm.dllb / 0.53,
                  pll_k = prm.pllb / 0.53;

        prm.dllw2 = dll_k ^^ 2;
        prm.dllaw = 1.414 * dll_k;
        prm.pllw2 = pll_k ^^ 2;
        prm.pllaw = 1.414 * pll_k;
        prm.fllw  = prm.fllb / 0.25;
    }
}


/* initialize tracking struct --------------------------------------------------
* set value to tracking struct
* args   : int sys          I   system type (SYS_GPS...)
*          int ctype        I   code type (CType.L1CA...)
*          sdrtrk_t *trk    I/0 tracking struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
void inittrkstruct(string file = __FILE__, size_t line = __LINE__)(int sys, CType ctype, sdrtrk_t *trk)
{
    traceln("called");

    inittrkprmstruct(ctype, &trk.prm1, 1);
    inittrkprmstruct(ctype, &trk.prm2, 2);

    trk.ncorrp = Constant.TRKCN;

    with(trk) foreach(e; TypeTuple!("I", "Q", "oldI", "oldQ", "sumI", "sumQ", "oldsumI", "oldsumQ")){
        mixin(e) = new double[1 + 2 * trk.ncorrp];
        mixin(e)[] = 0;
    }

    trk.loopms = Constant.get!"LOOP_MS"(ctype);
}


/* initialize navigation struct -------------------------------------------------
* set value to navigation struct
* args   : int sys          I   system type (SYS_GPS...)
*          int ctype        I   code type (CType.L1CA...)
*          sdrnav_t *nav    I/0 navigation struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
void initnavstruct(string file = __FILE__, size_t line = __LINE__)(int sys, CType ctype, sdrnav_t *nav)
{
    traceln("called");
    int[32] preamble = 0;
    int[] pre_l1ca = [1,-1,-1,-1,1,-1,1,1]; /* GPS L1CA preamble*/
    int[] pre_l1saif=[1,-1,1,-1,1,1,-1,-1]; /* QZSS L1SAIF preamble */
    version(none) int[2] poly = [V27POLYA,V27POLYB];

    nav.ctype = ctype;

    nav.bitth = Constant.get!"Navigation.BITTH"(ctype);
    nav.rate = Constant.get!"Navigation.RATE"(ctype);
    nav.flen = Constant.get!"Navigation.FLEN"(ctype);
    nav.addflen = Constant.get!"Navigation.ADDFLEN"(ctype);
    nav.addplen = Constant.get!"Navigation.ADDPLEN"(ctype);
    nav.prelen = Constant.get!"Navigation.PRELEN"(ctype);

    nav.prebits = pre_l1ca[0 .. nav.prelen].dup;
    nav.bitsync = new int[nav.rate];
    nav.fbits = new int[nav.flen + nav.addflen];
    nav.fbitsdec = new int[nav.flen + nav.addflen];
}


/* initialize sdr channel struct ------------------------------------------------
* set value to sdr channel struct
* args   : int    chno      I   channel number (1,2,...)
*          int    sys       I   system type (SYS_***)
*          int    prn       I   PRN number
*          int    ctype     I   code type (CType.***)
*          int    dtype     I   data type (DTYPEI or DTYPEIQ)
*          int    ftype     I   front end type (FTYPE1 or FTYPE2)
*          double f_sf      I   sampling frequency (Hz)
*          double f_if      I   intermidiate frequency (Hz)
*          sdrch_t *sdr     I/0 sdr channel struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
void initsdrch(ref sdrch_t sdr, size_t chno, CType ctype,/*, size_t chno, NavSystem sys, int prn, CType ctype, DType dtype, FType ftype, double f_sf, double f_if*/)
{
    traceln("called");
    
    alias chs = Config.channels;

    sdr.no      = (chno+1).to!int();
    sdr.sys     = chs[chno].sys;
    sdr.prn     = chs[chno].prn;
    sdr.sat     = satno(sdr.sys, sdr.prn);
    sdr.ctype   = ctype;
    sdr.dtype   = chs[chno].fends[ctype].dtype;
    sdr.ftype   = chs[chno].fends[ctype];
    sdr.f_sf    = chs[chno].fends[ctype].f_sf;
    sdr.f_if    = chs[chno].fends[ctype].f_if;
    sdr.ti      = sdr.f_sf ^^ -1;

    /* code generation */
    sdr.code = (){
        auto ptr = gencode(sdr.prn, sdr.ctype, &sdr.clen, &sdr.crate);
        return ptr[0 .. sdr.clen].idup;
    }();

    sdr.ci        = sdr.ti*sdr.crate;
    sdr.ctime     = sdr.clen/sdr.crate;
    sdr.nsamp     = cast(int)(sdr.f_sf * sdr.ctime);
    sdr.nsampchip = cast(int)(sdr.nsamp / sdr.clen);
    sdr.satstr    = satno2Id(sdr.sat);

    /* acqisition struct */
    initacqstruct(sdr.sys, sdr.ctype, &sdr.acq);

    sdr.acq.nfft = cast(int)nextPow2(sdr.nsamp); //sdr.nsamp;           // PRNコード1周期分

    sdr.acq.nfftf = (){
        if(sdr.ctype == CType.L1CA)
            return calcfftnumreso(Constant.get!"Acquisition.FFTFRESO"(sdr.ctype), sdr.ti).to!int();
        else if(sdr.ctype == CType.L2RCCM)
            return 0;
        else
            enforce(0);

        assert(0);
    }();


    /* doppler search frequency */
    sdr.acq.freq = {
        auto dst = new double[sdr.acq.nfreq];

        if(sdr.ctype != CType.L2RCCM)
            foreach(i; 0 .. sdr.acq.nfreq)
                dst[i] = sdr.f_if + (i - (sdr.acq.nfreq-1) / 2) * sdr.acq.step;
        else{
            immutable carrierRatio = 60.0 / 77.0;   // = f_L2C / f_L1CA = 1227.60 MHz / 1575.42 MHz = (2 * 60 * 10.23MHz) / (2 * 77 * 10.23MHz)
            immutable inferenced = (.sdr.l1ca_doppler - Config.channels[chno].fends[CType.L1CA].f_if) * carrierRatio + sdr.f_if;
            writefln("l1ca_doppler=%s, inferenced=%s,", .sdr.l1ca_doppler, inferenced);

            foreach(i; 0 .. sdr.acq.nfreq)
                dst[i] = inferenced + (i - (sdr.acq.nfreq-1) / 2) * sdr.acq.step;
        }

        return dst.idup;
    }();


    /* tracking struct */
    inittrkstruct(sdr.sys, sdr.ctype, &sdr.trk);

    /* navigation struct */
    initnavstruct(sdr.sys, sdr.ctype, &sdr.nav);


    if(sdr.ctype != CType.L2RCCM)
        sdr.lcode = sdr.code.cycle.take(sdr.clen * sdr.acq.lenf).array.assumeUnique;

    /* memory allocation */
    sdr.xcode = (){
        scope rcode = new short[sdr.acq.nfft];
        scope dst = new cpx_t[sdr.acq.nfft];

        /* other code generation */
        rcode[] = 0;       // zero padding
        sdr.code.resampling(0, 0, sdr.ci, sdr.acq.nfft, rcode.save);
        cpxcpx(rcode, null, 1.0, dst); /* FFT code */
        cpxfft(dst);
        return dst.idup;
    }();
}


/* free sdr channel struct ------------------------------------------------------
* free memory in sdr channel struct
* args   : sdrch_t *sdr     I/0 sdr channel struct
* return : none 
*------------------------------------------------------------------------------*/
void freesdrch(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr)
{
    if (sdr.nav.fec !is null)
        delete_viterbi27_port(sdr.nav.fec);
}