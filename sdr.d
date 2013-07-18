//##$ dmd -m64 -unittest -release -inline -debug=LPrint -version=MAIN_IS_SDRMAIN_MAIN sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrmain sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize

/*
Change Log:
2013/07/16 v2.0beta バッファ読み込みを、sdrスレッドが操るように修正
*/

module sdr;
/*------------------------------------------------------------------------------
* sdr.h : constants, types and function prototypes

* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*-----------------------------------------------------------------------------*/
import core.thread;
import std.concurrency;
import std.complex;
import std.stdio;
import std.c.stdlib;
import std.c.math;
import std.math;
import std.format : formattedWrite;
import std.array  : appender;
import std.traits : isSomeString;
import std.process;
public import std.c.windows.windows;
public import std.c.windows.winsock;
import std.c.time;
import std.c.process;

pragma(lib, "winmm.lib");
pragma(lib, "ws2_32.lib");
pragma(lib, "shell32.lib");
pragma(lib, "User32.lib");
pragma(lib, "kernel32.lib");
pragma(lib, "msgpack_x64.lib");

/* FEC */
pragma(lib, "libfec.a");
public import fec;

/* FFT */
public import fftw;
pragma(lib, "libfftw3f-3.lib");

/* RTKLIB */
public import rtklib;
pragma(lib, "rtklib.lib");

/* STEREO */
pragma(lib, "libnslstereo.a");

/* GN3S */
//C     #include "rcv/GN3S/src/GN3S.h"
//import GN3S;

/* USB */
pragma(lib, "libusb.lib");

/* constants -----------------------------------------------------------------*/
immutable DPI = 2 * PI;
immutable D2R = PI / 180;
immutable R2D = 180 / PI;
immutable CLIGHT = 299792458.0;
immutable ON = true;
immutable OFF = false;
immutable CDIV = 32;
immutable CMASK = 0x1F;
immutable CSCALE = 1.0 /16.0;


/* front end setting */
enum Fend{
    STEREO = 0,
    GN3SV2 = -1,
    GN3SV3 = 1,
    FILESTEREO,
    FILE
}


immutable MEMBUFLEN = 5000;

enum FType{
    Type1 = 1,
    Type2
}


enum DType{
    I = 1,
    IQ = 2,
}

immutable FILE_BUFFSIZE = 8192;
immutable NFFTTHREAD = 2;
immutable ACQINTG = 4;
immutable ACQHBAND = 5000;
immutable ACQSTEP = 250;
immutable ACQTH = 2.0;
immutable ACQLENF = 10;
immutable ACQFFTFRESO = 10;

immutable ACQSLEEP = 2000;
immutable TRKCN = 8;
immutable LOOP_MS_L1CA = 10;
immutable LOOP_MS_SBAS = 2;
immutable LOOP_MS_LEX = 4;


/* tracking parameter 1 */
/* (before nav frame synchronization) */
immutable TRKCDN1 = 3;
immutable TRKCP1 = 12;
immutable TRKDLLB1 = 1.0;
immutable TRKPLLB1 = 20.0;
immutable TRKFLLB1 = 250.0;
immutable TRKDT1 = 0.001;


/* tracking parameter 2 */
/* (after nav frame synchronization) */
immutable TRKCDN2 = 3;
immutable TRKCP2 = 12;
immutable TRKDLLB2 = 0.5;
immutable TRKPLLB2 = 20.0;
immutable TRKFLLB2 = 50.0;
immutable TRKDT2 = 0.001;


/* navigation parameter */
/* GPS/QZSS L1CA */
immutable NAVBITTH = 5;
immutable NAVRATE_L1CA = 20;
immutable NAVFLEN_L1CA = 300;
immutable NAVADDFLEN_L1CA = 2;
immutable NAVADDPLEN_L1CA = 2;


/* QZSS L1SAIF */
immutable NAVPRELEN_L1CA = 8;
immutable NAVRATE_L1SAIF = 2;
immutable NAVFLEN_L1SAIF = 500;
immutable NAVADDFLEN_L1SAIF = 12;
immutable NAVADDPLEN_L1SAIF = 0;
immutable NAVPRELEN_L1SAIF = 8;

/* observation data generation */
immutable PTIMING = 68.802;
immutable OBSINTERPN = 8;
immutable SNSMOOTHMS = 100;


/* code generation parameter */
immutable MAXGPSSATNO = 210;
immutable MAXGALSATNO = 50;
immutable MAXCMPSATNO = 37;


enum CType
{
    L1CA = 1,
    L1CP,
    L1CD,
    L1CO,
    L2CM,
    L2CL,
    L5I,
    L5Q,
    E1B,
    E1C,
    E5AI,
    E5AQ,
    E5BI,
    E5BQ,
    E1CO,
    E5AIO,
    E5AQO,
    E5BIO,
    E5BQO,
    G1,
    G2,
    B1,
    LEXS,
    LEXL,
    L1SAIF,
    L1SBAS,
}


/* gnuplot plotting setting */
enum PlotType
{
    Y = 1,
    XY,
    SurfZ,
    Box,
}


immutable PLT_WN = 5;
immutable PLT_HN = 3;
immutable PLT_W = 180;
immutable PLT_H = 250;
immutable PLT_MW = 0;
immutable PLT_MH = 0;
immutable PLT_MS = 500;
immutable PLT_MS_FILE = 2000;

/* spectrum analysis */
immutable SPEC_MS = 200;
immutable SPEC_LEN = 7;
immutable SPEC_BITN = 8;
immutable SPEC_NLOOP = 100;
immutable SPEC_NFFT = 16384;
immutable SPEC_PLT_W = 400;
immutable SPEC_PLT_H = 500;
immutable SPEC_PLT_MW = 0;
immutable SPEC_PLT_MH = 0;

/* QZSS LEX setting */
immutable DSAMPLEX = 7;
immutable LEXMS = 4;
immutable LENLEXPRE = 4;
immutable LENLEXMSG = 250;
immutable LENLEXRS = 255;
immutable LENLEXRSK = 223;
immutable LENLEXRSP = LENLEXRS - LENLEXRSK;
immutable LENLEXERR = LENLEXRSP / 2;
immutable LENLEXRCV = 8 + LENLEXMSG - LENLEXRSP;

alias Complex!float cpx_t;
alias size_t SOCKET;

immutable SOMAXCONN = 5;


struct sdrini_t
{
    Fend fend;
    double[2] f_sf = 0;
    double[2] f_if = 0;
    DType[2] dtype;
    File fp1;
    File fp2;
    string file1;
    string file2;
    bool useif1;
    bool useif2;
    int confini;
    uint nch;
    uint nchL1;
    uint nchL2;
    uint nchL5;
    uint nchL6;
    int[] sat;
    int[] sys;
    CType[] ctype;
    FType[] ftype;
    bool pltacq;
    bool plttrk;
    int outms;
    bool rinex;
    bool rtcm;
    string rinexpath;
    ushort rtcmport;
    ushort lexport;
    bool pltspec;
    int buffsize;
    int fendbuffsize;
}


struct sdrstat_t
{
    bool stopflag;
    bool specflag;
    byte *buff;
    byte *buff1;
    byte *buff2;
    ulong buffloccnt;
}


struct sdrobs_t
{
    int sat;
    double tow = 0;
    int week;
    double P = 0;
    double L = 0;
    double D = 0;
    double S = 0;
}


struct sdracq_t
{
    int intg;
    double hband = 0;
    double step = 0;
    int nfreq;
    double *freq;
    int acqcodei;
    double acqfreq = 0;
    double acqfreqf = 0;
    int lenf;
    int nfft;
    int nfftf;
    double cn0 = 0;
    double peakr = 0;
}


struct sdrtrkprm_t
{
    double cspace = 0;
    int cspaces;
    int *corrp;
    double *corrx;
    int ne;
    int nl;
    double pllb = 0;
    double dllb = 0;
    double fllb = 0;
    double dt = 0;
    double dllw2 = 0;
    double dllaw = 0;
    double pllw2 = 0;
    double pllaw = 0;
    double fllw = 0;
}


struct sdrtrk_t
{
    double codefreq = 0;
    double carrfreq = 0;
    double remcode = 0;
    double remcarr = 0;
    double oldremcode = 0;
    double oldremcarr = 0;
    double codeNco = 0;
    double codeErr = 0;
    double carrNco = 0;
    double carrErr = 0;
    ulong buffloc;
    double [8]tow = 0;
    ulong [8]codei;
    ulong [8]codeisum;
    ulong [8]cntout;
    double [8]remcodeout = 0;
    double [8]L = 0;
    double [8]D = 0;
    double [8]S = 0;
    double *I;
    double *Q;
    double *oldI;
    double *oldQ;
    double *sumI;
    double *sumQ;
    double *oldsumI;
    double *oldsumQ;
    double Isum = 0;
    int ncorrp;
    int loopms;
    int flagpolarityadd;
    int flagremcarradd;
    sdrtrkprm_t prm1;
    sdrtrkprm_t prm2;
}


struct sdrnav_t
{
    File fpnav;
    CType ctype;
    int rate;
    int flen;
    int addflen;
    int addplen;
    int *prebits;
    int prelen;
    int bit;
    double bitIP = 0;
    int *fbits;
    int *fbitsdec;
    int *bitsync;
    int bitind;
    int bitth;
    ulong firstsf;
    ulong firstsfcnt;
    double firstsftow = 0;
    int polarity;
    void *fec;
    int swnavsync;
    int swnavreset;
    eph_t eph;
}


struct sdrch_t
{
    Tid hsdr;
    int no;
    int sat;
    int sys;
    int prn;
    string satstr;
    CType ctype;
    DType dtype;
    FType ftype;
    double f_sf = 0;
    double f_if = 0;
    short *code;
    short *lcode;
    cpx_t *xcode;
    int clen;
    double crate = 0;
    double ctime = 0;
    double ti = 0;
    double ci = 0;
    int nsamp;
    int nsampchip;
    int currnsamp;
    sdracq_t acq;
    sdrtrk_t trk;
    sdrnav_t nav;
    int flagacq;
    int flagtrk;
    int flagnavsync;
    int flagnavpre;
    int flagfirstsf;
    int flagnavdec;
}


struct sdrplt_t
{
    Pid processId;
    Pipe pipe;
    File fp;
    int nx;
    int ny;
    double *x;
    double *y;
    double *z;
    PlotType type;
    int skip;
    bool flagabs;
    double scale = 0;
    int plth;
    int pltw;
    int pltmh;
    int pltmw;
    int pltno;
    double pltms = 0;
}


struct sdrsoc_t
{
    Tid hsoc;
    ushort port;
    SOCKET s_soc;
    SOCKET c_soc;
    int flag;
}


struct sdrout_t
{
    int nsat;
    obsd_t *obsd;
    eph_t *eph;
    rnxopt_t opt;
    sdrsoc_t soc;
    string rinexobs;
    string rinexnav;
}


struct sdrspec_t
{
    DType dtype;
    FType ftype;
    int nsamp;
    double f_sf = 0;
    sdrplt_t histI;
    sdrplt_t histQ;
    sdrplt_t pspec;
}


void SDRPRINTF(T...)(T args)
{
    writef(args);
}

void Sleep(
  DWORD dwMilliseconds   // 中断の時間
)
{
    Thread.sleep(dur!"msecs"(dwMilliseconds));
}

import core.memory;

auto malloc(size_t size)
{
    return GC.malloc(size);
}

void free(void* p)
{
    GC.free(p);
}

void* calloc(size_t n, size_t size)
{
    return GC.calloc(n * size);
}

ushort MAKEWORD(ubyte bLow, ubyte bHigh)
{
    return bLow | (bHigh << 8);
}

string formattedString(S, T...)(S format, T args)
if(isSomeString!S)
{
    auto writer = appender!string();
    writer.formattedWrite(format, args);
    return writer.data;
}


public import sdracq,
              sdrcmn,
              sdrcode,
              sdrinit,
              sdrmain,
              sdrnav,
              sdrout,
              sdrplot,
              sdrrcv,
              stereo,
              sdrspectrum,
              sdrtrk,
              util.range,
              util.trace,
              util.serialize;