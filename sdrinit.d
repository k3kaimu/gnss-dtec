//##$ rdmd -m64 -main sdr

/*-------------------------------------------------------------------------------
* sdrinit.c : SDR initialize/cleanup functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;

import core.sync.mutex;

import std.c.string;
import std.c.stdlib : atoi, atof;
import std.string;
import std.exception;
import std.traits;
import std.algorithm;
import std.stdio;
import std.array;
import std.range;
import std.file;


string readIniValue(T : string)(string file, string section, string key)
{
    // ファイルを行区切りでいれこむ
    string[] lines = (){
        string[] lns;
        auto file = File(file);

        foreach(line; file.byLine)
            lns ~= line.strip().dup;

        return lns;
    }();


    immutable secStr = "[" ~ section ~ "]";

    lines = lines.find!(a => a.startsWith(secStr))(); // sectionを探す
    lines = lines.find!(a => a.startsWith(key))();    // keyを探す

    auto str = lines.front.find!(a => a == '=')().drop(1);
    return str.until!(a => a == ';')().array().to!string().strip();
}


T readIniValue(T)(string file, string section, string key)
if(!is(T == string))
{
    string value = file.readIniValue!string(section, key);

    static if(isArray!T)
    {
        return ("[" ~ value ~ "]").to!(T)();
    }
    else if(isSomeString!T)
    {
        return value.to!T();
    }
    else
    {
        return value.to!T();
    }
}


/* read ini file ----------------------------------------------------------------
* read ini file and set value to sdrini struct
* args   : sdrini_t *ini    I/0 sdrini struct
* return : int                  0:okay -1:error
* note : this function is only used in CLI application
*------------------------------------------------------------------------------*/
int readinifile(string file = __FILE__, size_t line = __LINE__)(sdrini_t *ini)
{
    traceln("called");
    int ret;
    string iniFile = "gnss-sdrcli.ini";

    enforce(exists("gnss-sdrcli.ini"), "error: gnss-sdrcli.ini doesn't exist");

    ini.fend = (){
        immutable tmp = iniFile.readIniValue!string("RCV", "FEND");

        switch(tmp)
        {
          case "STEREO":
            return FEND_STEREO;

          case "FILESTEREO":
            return FEND_FILESTEREO;

          case "GN3Sv2":
            return FEND_GN3SV2;

          case "GN3Sv3":
            return FEND_GN3SV3;

          case "FILE":
            return FEND_FILE;

          default:
            enforce(0, "error: wrong frontend type: %s".formattedString(tmp));
        }
        assert(0);
    }();

    if (ini.fend==FEND_FILE || ini.fend==FEND_FILESTEREO ) {
        ini.file1 = iniFile.readIniValue!string("RCV", "FILE1");
        if(ini.file1.length)
            ini.useif1 = ON;
    }

    if (ini.fend == FEND_FILE) {
        ini.file2 = iniFile.readIniValue!string("RCV", "FILE2");
        if(ini.file2.length)
            ini.useif2 = ON;
    }

    ini.f_sf[0] = iniFile.readIniValue!double("RCV", "SF1");
    ini.f_if[0] = iniFile.readIniValue!double("RCV", "IF1");
    ini.dtype[0] = iniFile.readIniValue!int("RCV", "DTYPE1");
    ini.f_sf[1] = iniFile.readIniValue!double("RCV", "SF1");
    ini.f_if[1] = iniFile.readIniValue!double("RCV", "IF1");
    ini.dtype[1] = iniFile.readIniValue!int("RCV", "DTYPE2");
    ini.confini = iniFile.readIniValue!int("RCV", "CONFINI");

    ini.nch = iniFile.readIniValue!int("CHANNEL", "NCH").enforce("error: wrong inifile value NCH=%d".formattedString(ini.nch));

    {
        int[] getChannelSpec(string key)
        {
            int[] tmp;
            tmp = iniFile.readIniValue!(int[])("CHANNEL", key);
            enforce(tmp.length >= ini.nch);
            return tmp[0 .. ini.nch];
        }

        ini.sat[0 .. ini.nch]   = getChannelSpec("SAT");
        ini.sys[0 .. ini.nch]   = getChannelSpec("SYS");
        ini.ctype[0 .. ini.nch] = getChannelSpec("CTYPE");
        ini.ftype[0 .. ini.nch] = getChannelSpec("FTYPE");
    }

    {
        ini.pltacq = iniFile.readIniValue!int("PLOT", "ACQ");
        ini.plttrk = iniFile.readIniValue!int("PLOT", "TRK");

        ini.outms = iniFile.readIniValue!int("OUTPUT", "OUTMS");
        ini.rinex = iniFile.readIniValue!int("OUTPUT", "RINEX");
        ini.rtcm = iniFile.readIniValue!int("OUTPUT", "RTCM");
        ini.rinexpath = iniFile.readIniValue!string("OUTPUT", "RINEXPATH");
        ini.rtcmport = iniFile.readIniValue!ushort("OUTPUT", "RTCMPORT");
        ini.lexport = iniFile.readIniValue!ushort("OUTPUT", "LEXPORT");

        /* spectrum setting */
        ini.pltspec = iniFile.readIniValue!int("SPECTRUM", "SPEC");
    }

    /* sdr channel setting */
    //for (i=0;i<sdrini.nch;i++) {
    foreach(i; 0 .. sdrini.nch){
        if (sdrini.ctype[i]==CTYPE_L1CA) {
            sdrini.nchL1++;
        }else if (sdrini.ctype[i]==CTYPE_LEXS) {
            sdrini.nchL6++;
        }else
            enforce(0, "ctype: %n is not supported.".formattedString(sdrini.ctype[i]));
    }
    return 0;
}
/* check initial value ----------------------------------------------------------
* checking value in sdrini struct
* args   : sdrini_t *ini    I   sdrini struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
int chk_initvalue(string file = __FILE__, size_t line = __LINE__)(sdrini_t *ini)
{
    traceln("called");
    int ret;

    enforce(ini.f_sf[0] > 0 && ini.f_sf[0] < 100e6, "error: wrong freq. input sf1: %s".formattedString(ini.f_sf[0]));
    enforce(ini.f_if[0] >= 0 && ini.f_if[0] < 100e6, "error: wrong freq. input if1: %s".formattedString(ini.f_if[0]));

    enforce(ini.f_sf[1] > 0 && ini.f_sf[1] < 100e6, "error: wrong freq. input sf1: %s".formattedString(ini.f_sf[1]));
    enforce(ini.f_if[1] >= 0 && ini.f_if[1] < 100e6, "error: wrong freq. input if1: %s".formattedString(ini.f_if[1]));

    enforce(ini.rtcmport >= 0 && ini.rtcmport <= short.max, "error: wrong rtcm port rtcm:%s".formattedString(ini.rtcmport));
    enforce(ini.lexport >= 0 && ini.lexport <= short.max, "error: wrong rtcm port lex:%d".formattedString(ini.lexport));

    /* checking filepath */
    if(ini.fend==FEND_FILE||ini.fend==FEND_FILESTEREO) {
        if (ini.useif1&& !exists(ini.file1)) {
            SDRPRINTF("error: file1 doesn't exist: %s\n",ini.file1);
            return -1;
        }
        if (ini.useif2 && !exists(ini.file2)) {
            SDRPRINTF("error: file2 doesn't exist: %s\n",ini.file2);
            return -1;
        }
        if ((!ini.useif1) && (!ini.useif2)) {
            SDRPRINTF("error: file1 or file2 are not selected\n");
            return -1;
        }
    }

    /* checking rinex directory */
    if (ini.rinex) {
        if ((ret=exists(ini.rinexpath))<0) {
            SDRPRINTF("error: rinex output directory doesn't exist: %s\n",ini.rinexpath);
            return -1;
        }
    }

    return 0;
}
/* initialize mutex and event ---------------------------------------------------
* create mutex and event handles
* args   : none
* return : none
*------------------------------------------------------------------------------*/
void openhandles()
{
    /* mutexes */
    hstopmtx = new Mutex();
    hbuffmtx = new Mutex();
    hreadmtx = new Mutex();
    hfftmtx = new Mutex();
    hpltmtx = new Mutex();
    hobsmtx = new Mutex();

    /* events */
    hlexeve=CreateEvent(null,true,false,null);
}
/* close mutex and event --------------------------------------------------------
* close mutex and event handles
* args   : none
* return : none
*------------------------------------------------------------------------------*/
void closehandles()
{
    /* mutexes */
    //CloseHandle(hstopmtx); hstopmtx=null;
    //CloseHandle(hbuffmtx); hbuffmtx=null;
    //CloseHandle(hreadmtx); hreadmtx=null;
    //CloseHandle(hfftmtx);  hfftmtx=null;
    //CloseHandle(hpltmtx);  hpltmtx=null;
    //CloseHandle(hobsmtx);  hobsmtx=null;

    /* events */
    CloseHandle(hlexeve);  hlexeve=null;
}
/* initialization plot struct ---------------------------------------------------
* set value to plot struct
* args   : sdrplt_t *acq    I/0 plot struct for acquisition
*          sdrplt_t *trk    I/0 plot struct for tracking
*          sdrch_t  *sdr    I   sdr channel struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
int initpltstruct(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *acq, sdrplt_t *trk, sdrch_t *sdr)
{
    traceln("called");
    /* acquisition */
    if (sdrini.pltacq) {
        setsdrplotprm(acq,PLT_SURFZ,sdr.acq.nfreq,sdr.acq.nfft,3,OFF,1,PLT_H,PLT_W,PLT_MH,PLT_MW,sdr.no);
        if (initsdrplot(acq)<0) return -1;
        settitle(acq,sdr.satstr);
        setlabel(acq,"Frequency (Hz)","Code Offset (sample)");
    }
    /* tracking */
    if (sdrini.plttrk) {
        setsdrplotprm(trk,PLT_XY,1+2*sdr.trk.ncorrp,0,0,ON,0.001,PLT_H,PLT_W,PLT_MH,PLT_MW,sdr.no);
        if(initsdrplot(trk)<0) return -1;
        settitle(trk,sdr.satstr);
        setlabel(trk,"Code Offset (sample)","Correlation Output");
        setyrange(trk,0,8*sdr.trk.loopms);
    }
    if (sdrini.fend==FEND_FILE||sdrini.fend==FEND_FILESTEREO)
        trk.pltms=PLT_MS_FILE;
    else
        trk.pltms=PLT_MS;
    return 0;
}
/* termination plot struct ------------------------------------------------------
* termination plot struct
* args   : sdrplt_t *acq    I/0 plot struct for acquisition
*          sdrplt_t *trk    I/0 plot struct for tracking
* return : none
*------------------------------------------------------------------------------*/
void quitpltstruct(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *acq, sdrplt_t *trk)
{
    traceln("called");
    if (sdrini.pltacq)
        quitsdrplot(acq);
    
    if (sdrini.plttrk)
        quitsdrplot(trk);
}
/* initialize acquisition struct ------------------------------------------------
* set value to acquisition struct
* args   : int sys          I   system type (SYS_GPS...)
*          int ctype        I   code type (CTYPE_L1CA...)
*          sdracq_t *acq    I/0 acquisition struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
int initacqstruct(string file = __FILE__, size_t line = __LINE__)(int sys, int ctype, sdracq_t *acq)
{
    traceln("called");
    acq.intg=ACQINTG;
    acq.hband=ACQHBAND;
    acq.step=ACQSTEP;
    acq.nfreq=2*(ACQHBAND/ACQSTEP)+1;
    acq.lenf=ACQLENF;

    return 0;
}
/* initialize tracking parameter struct -----------------------------------------
* set value to tracking parameter struct
* args   : sdrtrkprm_t *prm I/0 tracking parameter struct
*          int    sw        I   tracking mode selector switch (1 or 2)
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
int inittrkprmstruct(string file = __FILE__, size_t line = __LINE__)(sdrtrkprm_t *prm, int sw)
{
    traceln("called");
    int i,trkcp,trkcdn;
    
    /* tracking parameter selection */
    switch (sw) {
        case 1:
            prm.dllb=TRKDLLB1;
            prm.pllb=TRKPLLB1;
            prm.fllb=TRKFLLB1;
            prm.dt=TRKDT1;
            trkcp=TRKCP1;
            trkcdn=TRKCDN1;
            break;
        case 2:
            prm.dllb=TRKDLLB2;
            prm.pllb=TRKPLLB2;
            prm.fllb=TRKFLLB2;
            prm.dt=TRKDT2;
            trkcp=TRKCP2;
            trkcdn=TRKCDN2;
            break;
        default:
            SDRPRINTF("error: inittrkprmstruct sw=%d\n",sw);
            return -1;
    }
    /* correlation point */
    prm.corrp = cast(int*)malloc(int.sizeof * TRKCN).enforce();
    for (i=0;i<TRKCN;i++) {
        prm.corrp[i]=trkcdn*(i+1);
        if (prm.corrp[i]==trkcp){
            prm.ne=2*(i+1)-1; /* Early */
            prm.nl=2*(i+1);   /* Late */
        }
    }
    /* correlation point for plot */
    prm.corrx = cast(double*)calloc(2*TRKCN+1, double.sizeof).enforce();
    for (i=1;i<=TRKCN;i++) {
        prm.corrx[2*i-1]=-trkcdn*i;
        prm.corrx[2*i  ]= trkcdn*i;
    }   

    /* calculation loop filter parameters */
    prm.dllw2=(prm.dllb/0.53)*(prm.dllb/0.53);
    prm.dllaw=1.414*(prm.dllb/0.53);
    prm.pllw2=(prm.pllb/0.53)*(prm.pllb/0.53);
    prm.pllaw=1.414*(prm.pllb/0.53);
    prm.fllw =prm.fllb/0.25;

    return 0;
}
/* initialize tracking struct --------------------------------------------------
* set value to tracking struct
* args   : int sys          I   system type (SYS_GPS...)
*          int ctype        I   code type (CTYPE_L1CA...)
*          sdrtrk_t *trk    I/0 tracking struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
int inittrkstruct(string file = __FILE__, size_t line = __LINE__)(int sys, int ctype, sdrtrk_t *trk)
{
    traceln("called");
    int ret;
    if ((ret=inittrkprmstruct(&trk.prm1,1))<0 ||
        (ret=inittrkprmstruct(&trk.prm2,2))<0 ) {
            SDRPRINTF("error: inittrkprmstruct\n");
            return -1;
    }
    trk.ncorrp=TRKCN;
    trk.I      =cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.I);
    trk.Q      =cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.Q);
    trk.oldI   =cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.oldI);
    trk.oldQ   =cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.oldQ);
    trk.sumI   =cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.sumI);
    trk.sumQ   =cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.sumQ);
    trk.oldsumI=cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.oldsumI);
    trk.oldsumQ=cast(double*)calloc(1+2*trk.ncorrp,double.sizeof).enforce();
    scope(failure) free(trk.oldsumQ);

    if (sys==SYS_GPS&&ctype==CTYPE_L1CA)   trk.loopms=LOOP_MS_L1CA;
    if (sys==SYS_SBS&&ctype==CTYPE_L1SBAS) trk.loopms=LOOP_MS_SBAS;
    if (sys==SYS_QZS&&ctype==CTYPE_L1CA)   trk.loopms=LOOP_MS_L1CA;
    if (sys==SYS_QZS&&ctype==CTYPE_LEXS)   trk.loopms=LOOP_MS_LEX;
    if (sys==SYS_QZS&&ctype==CTYPE_L1SAIF) trk.loopms=LOOP_MS_SBAS;

    //if (!trk.I||!trk.Q||!trk.oldI||!trk.oldQ||!trk.sumI||!trk.sumQ||!trk.oldsumI||!trk.oldsumQ) {
    //    SDRPRINTF("error: inittrkstruct memory allocation\n");
    //    return -1;
    //}
    return 0;
}
/* initialize navigation struct -------------------------------------------------
* set value to navigation struct
* args   : int sys          I   system type (SYS_GPS...)
*          int ctype        I   code type (CTYPE_L1CA...)
*          sdrnav_t *nav    I/0 navigation struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
int initnavstruct(string file = __FILE__, size_t line = __LINE__)(int sys, int ctype, sdrnav_t *nav)
{
    traceln("called");
    int[32] preamble = 0;
    int[] pre_l1ca = [1,-1,-1,-1,1,-1,1,1]; /* GPS L1CA preamble*/
    int[] pre_l1saif=[1,-1,1,-1,1,1,-1,-1]; /* QZSS L1SAIF preamble */
    int[2] poly = [V27POLYA,V27POLYB];

    nav.ctype=ctype;
    nav.bitth=NAVBITTH;        
    if (ctype==CTYPE_L1CA) {
        nav.rate=NAVRATE_L1CA;
        nav.flen=NAVFLEN_L1CA;
        nav.addflen=NAVADDFLEN_L1CA;
        nav.addplen=NAVADDPLEN_L1CA;
        nav.prelen=NAVPRELEN_L1CA;
        memcpy(preamble.ptr,pre_l1ca.ptr,int.sizeof*nav.prelen);
    }
    if (ctype==CTYPE_L1SAIF) {
        nav.rate=NAVRATE_L1SAIF;
        nav.flen=NAVFLEN_L1SAIF;
        nav.addflen=NAVADDFLEN_L1SAIF;
        nav.addplen=NAVADDPLEN_L1SAIF;
        nav.prelen=NAVPRELEN_L1SAIF;
        memcpy(preamble.ptr,pre_l1saif.ptr,int.sizeof*nav.prelen);

        /* create fec */
        if((nav.fec=create_viterbi27_port(NAVFLEN_L1SAIF/2))==null) {
            SDRPRINTF("error: create_viterbi27 failed\n");
            return -1;
        }
        /* set polynomial */
        set_viterbi27_polynomial_port(poly.ptr);
    }

    nav.prebits= cast(int*)malloc(int.sizeof*nav.prelen).enforce();
    scope(failure) free(nav.prebits);
    nav.bitsync= cast(int*)calloc(nav.rate,int.sizeof).enforce();
    scope(failure) free(nav.bitsync);
    nav.fbits=   cast(int*)calloc(nav.flen+nav.addflen,int.sizeof).enforce();
    scope(failure) free(nav.fbits);
    nav.fbitsdec=cast(int*)calloc(nav.flen+nav.addflen,int.sizeof).enforce();
    scope(failure) free(nav.fbitsdec);

    memcpy(nav.prebits,preamble.ptr,int.sizeof*nav.prelen);
    return 0;
}
/* initialize sdr channel struct ------------------------------------------------
* set value to sdr channel struct
* args   : int    chno      I   channel number (1,2,...)
*          int    sys       I   system type (SYS_***)
*          int    prn       I   PRN number
*          int    ctype     I   code type (CTYPE_***)
*          int    dtype     I   data type (DTYPEI or DTYPEIQ)
*          int    ftype     I   front end type (FTYPE1 or FTYPE2)
*          double f_sf      I   sampling frequency (Hz)
*          double f_if      I   intermidiate frequency (Hz)
*          sdrch_t *sdr     I/0 sdr channel struct
* return : int                  0:okay -1:error
*------------------------------------------------------------------------------*/
int initsdrch(string file = __FILE__, size_t line = __LINE__)(int chno, int sys, int prn, int ctype, int dtype, int ftype, double f_sf, double f_if, sdrch_t *sdr)
{
    traceln("called");
    int i;
    short *rcode;
    
    sdr.no=chno;
    sdr.sys=sys;
    sdr.prn=prn;
    sdr.sat=satno(sys,prn);
    sdr.ctype=ctype;
    sdr.dtype=dtype;
    sdr.ftype=ftype;
    sdr.f_sf=f_sf;
    sdr.f_if=f_if;
    sdr.ti=1/f_sf;
    /* code generation */
    sdr.code = gencode(prn,ctype,&sdr.clen,&sdr.crate).enforce();
    scope(failure) free(sdr.code);
    

    sdr.ci=sdr.ti*sdr.crate;
    sdr.ctime=sdr.clen/sdr.crate;
    sdr.nsamp=cast(int)(f_sf*sdr.ctime);
    sdr.nsampchip=cast(int)(sdr.nsamp/sdr.clen);
    char[] tmpStr = new char[5];
    satno2id(sdr.sat, tmpStr.ptr);
    sdr.satstr = tmpStr.ptr.to!string();
    

    /* acqisition struct */
    if (initacqstruct(sys,ctype,&sdr.acq)<0) return -1;
    sdr.acq.nfft=sdr.nsamp;//calcfftnum(2*sdr.nsamp,0);
    sdr.acq.nfftf=calcfftnumreso(ACQFFTFRESO,sdr.ti);


    /* memory allocation */
    sdr.acq.freq = cast(double*)malloc(double.sizeof * sdr.acq.nfreq).enforce();
    scope(failure) free(sdr.acq.freq);


    /* doppler search frequency */
    for (i=0;i<sdr.acq.nfreq;i++)
        sdr.acq.freq[i]=sdr.f_if+((i-(sdr.acq.nfreq-1)/2)*sdr.acq.step);


    /* tracking struct */
    if (inittrkstruct(sys,ctype,&sdr.trk)<0) return -1;

    /* navigation struct */
    if (initnavstruct(sys,ctype,&sdr.nav)<0) {
        return -1;
    }
    /* memory allocation */
    sdr.lcode = cast(short*)malloc(short.sizeof * sdr.clen * sdr.acq.lenf).enforce();
    scope(failure) free(sdr.lcode);

    rcode = cast(short*)sdrmalloc(short.sizeof * sdr.acq.nfft).enforce();
    scope(exit) sdrfree(rcode);

    sdr.xcode = cpxmalloc(sdr.acq.nfft);
    scope(failure) cpxfree(sdr.xcode);

    /* other code generation */
    for (i=0;i<sdr.acq.nfft;i++) rcode[i]=0;
    rescode(sdr.code,sdr.clen,0,0,sdr.ci,sdr.nsamp,rcode); /* resampled code */
    cpxcpx(rcode,null,1.0,sdr.acq.nfft,sdr.xcode); /* FFT code */
    cpxfft(sdr.xcode,sdr.acq.nfft);

    for (i=0;i<sdr.clen*sdr.acq.lenf;i++) /* long code for fine search */
        sdr.lcode[i]=sdr.code[i%sdr.clen];
    
    return 0;
}
/* free sdr channel struct ------------------------------------------------------
* free memory in sdr channel struct
* args   : sdrch_t *sdr     I/0 sdr channel struct
* return : none 
*------------------------------------------------------------------------------*/
void freesdrch(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr)
{
    traceln("called");
    free(sdr.code);
    free(sdr.lcode);
    cpxfree(sdr.xcode);
    free(sdr.nav.prebits);
    free(sdr.nav.fbits);
    free(sdr.nav.fbitsdec);
    free(sdr.nav.bitsync);
    free(sdr.trk.I);
    free(sdr.trk.Q);
    free(sdr.trk.oldI);
    free(sdr.trk.oldQ);
    free(sdr.trk.sumI);
    free(sdr.trk.sumQ);
    free(sdr.trk.oldsumI);
    free(sdr.trk.oldsumQ);
    free(sdr.trk.prm1.corrp);
    free(sdr.trk.prm2.corrp);
    free(sdr.acq.freq);

    if (sdr.nav.fec!=null)
        delete_viterbi27_port(sdr.nav.fec);
}