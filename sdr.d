//##$ dmd -m64 -release -inline -unittest sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrmain sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw

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
const DPI = 2 * PI;
const D2R = PI / 180;
const R2D = 180 / PI;
const CLIGHT = 299792458.0;
const ON = 1;
const OFF = 0;
const CDIV = 32;
const CMASK = 0x1F;
const CSCALE = 1.0 /16.0;


/* front end setting */
const FEND_STEREO = 0;
const FEND_GN3SV2 = -1;
const FEND_GN3SV3 = 1;
const FEND_FILESTEREO = 2;
const FEND_FILE = 3;
const FTYPE1 = 1;
const FTYPE2 = 2;
const DTYPEI = 1;
const DTYPEIQ = 2;
const MEMBUFLEN = 5000;

const FILE_BUFFSIZE = 8192;
const NFFTTHREAD = 2;
const ACQINTG = 4;
const ACQHBAND = 5000;
const ACQSTEP = 250;
const ACQTH = 2.0;
const ACQLENF = 10;
const ACQFFTFRESO = 10;

const ACQSLEEP = 2000;
const TRKCN = 8;
const LOOP_MS_L1CA = 10;
const LOOP_MS_SBAS = 2;
const LOOP_MS_LEX = 4;


/* tracking parameter 1 */
/* (before nav frame synchronization) */
const TRKCDN1 = 3;
const TRKCP1 = 12;
const TRKDLLB1 = 1.0;
const TRKPLLB1 = 20.0;
const TRKFLLB1 = 250.0;
const TRKDT1 = 0.001;


/* tracking parameter 2 */
/* (after nav frame synchronization) */
const TRKCDN2 = 3;
const TRKCP2 = 12;
const TRKDLLB2 = 0.5;
const TRKPLLB2 = 20.0;
const TRKFLLB2 = 50.0;
const TRKDT2 = 0.001;


/* navigation parameter */
/* GPS/QZSS L1CA */
const NAVBITTH = 5;
const NAVRATE_L1CA = 20;
const NAVFLEN_L1CA = 300;
const NAVADDFLEN_L1CA = 2;
const NAVADDPLEN_L1CA = 2;


/* QZSS L1SAIF */
const NAVPRELEN_L1CA = 8;
const NAVRATE_L1SAIF = 2;
const NAVFLEN_L1SAIF = 500;
const NAVADDFLEN_L1SAIF = 12;
const NAVADDPLEN_L1SAIF = 0;
const NAVPRELEN_L1SAIF = 8;

/* observation data generation */
const PTIMING = 68.802;
const OBSINTERPN = 8;
const SNSMOOTHMS = 100;


/* code generation parameter */
const MAXGPSSATNO = 210;
const MAXGALSATNO = 50;
const MAXCMPSATNO = 37;
const CTYPE_L1CA = 1;
const CTYPE_L1CP = 2;
const CTYPE_L1CD = 3;
const CTYPE_L1CO = 4;
const CTYPE_L2CM = 5;
const CTYPE_L2CL = 6;
const CTYPE_L5I = 7;
const CTYPE_L5Q = 8;
const CTYPE_E1B = 9;
const CTYPE_E1C = 10;
const CTYPE_E5AI = 11;
const CTYPE_E5AQ = 12;
const CTYPE_E5BI = 13;
const CTYPE_E5BQ = 14;
const CTYPE_E1CO = 15;
const CTYPE_E5AIO = 16;
const CTYPE_E5AQO = 17;
const CTYPE_E5BIO = 18;
const CTYPE_E5BQO = 19;
const CTYPE_G1 = 20;
const CTYPE_G2 = 21;
const CTYPE_B1 = 22;
const CTYPE_LEXS = 23;
const CTYPE_LEXL = 24;
const CTYPE_L1SAIF = 25;
const CTYPE_L1SBAS = 26;


/* gnuplot plotting setting */
const PLT_Y = 1;
const PLT_XY = 2;
const PLT_SURFZ = 3;
const PLT_BOX = 4;
const PLT_WN = 5;
const PLT_HN = 3;
const PLT_W = 180;
const PLT_H = 250;
const PLT_MW = 0;
const PLT_MH = 0;
const PLT_MS = 500;
const PLT_MS_FILE = 2000;

/* spectrum analysis */
const SPEC_MS = 200;
const SPEC_LEN = 7;
const SPEC_BITN = 8;
const SPEC_NLOOP = 100;
const SPEC_NFFT = 16384;
const SPEC_PLT_W = 400;
const SPEC_PLT_H = 500;
const SPEC_PLT_MW = 0;
const SPEC_PLT_MH = 0;

/* QZSS LEX setting */
const DSAMPLEX = 7;
const LEXMS = 4;
const LENLEXPRE = 4;
const LENLEXMSG = 250;
const LENLEXRS = 255;
const LENLEXRSK = 223;
const LENLEXRSP = LENLEXRS - LENLEXRSK;
const LENLEXERR = LENLEXRSP / 2;
const LENLEXRCV = 8 + LENLEXMSG - LENLEXRSP;

alias Complex!float cpx_t;
alias size_t SOCKET;

const SOMAXCONN = 5;


struct _N183
{
    int fend;
    double[2] f_sf = 0;
    double[2] f_if = 0;
    int[2] dtype;
    File fp1;
    File fp2;
    string file1;
    string file2;
    int useif1;
    int useif2;
    int confini;
    int nch;
    int nchL1;
    int nchL2;
    int nchL5;
    int nchL6;
    int[109] sat;
    int[109] sys;
    int[109] ctype;
    int[109] ftype;
    int pltacq;
    int plttrk;
    int outms;
    int rinex;
    int rtcm;
    string rinexpath;
    ushort rtcmport;
    ushort lexport;
    int pltspec;
    int buffsize;
    int fendbuffsize;
}
alias _N183 sdrini_t;


struct _N184
{
    int stopflag;
    int specflag;
    byte *buff;
    byte *buff1;
    byte *buff2;
    ulong buffloccnt;
}
alias _N184 sdrstat_t;


struct _N185
{
    int sat;
    double tow = 0;
    int week;
    double P = 0;
    double L = 0;
    double D = 0;
    double S = 0;
}
alias _N185 sdrobs_t;


struct _N186
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
alias _N186 sdracq_t;


struct _N187
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
alias _N187 sdrtrkprm_t;


struct _N188
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
alias _N188 sdrtrk_t;


struct _N189
{
    File fpnav;
    int ctype;
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
alias _N189 sdrnav_t;


struct _N190
{
    Tid hsdr;
    int no;
    int sat;
    int sys;
    int prn;
    string satstr;
    int ctype;
    int dtype;
    int ftype;
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
alias _N190 sdrch_t;


struct _N191
{
    Pid processId;
    Pipe pipe;
    File fp;
    HWND hw;
    int nx;
    int ny;
    double *x;
    double *y;
    double *z;
    int type;
    int skip;
    int flagabs;
    double scale = 0;
    int plth;
    int pltw;
    int pltmh;
    int pltmw;
    int pltno;
    double pltms = 0;
}
alias _N191 sdrplt_t;


struct _N192
{
    Tid hsoc;
    ushort port;
    SOCKET s_soc;
    SOCKET c_soc;
    int flag;
}
alias _N192 sdrsoc_t;


struct _N193
{
    int nsat;
    obsd_t *obsd;
    eph_t *eph;
    rnxopt_t opt;
    sdrsoc_t soc;
    string rinexobs;
    string rinexnav;
}
alias _N193 sdrout_t;


struct _N194
{
    int dtype;
    int ftype;
    int nsamp;
    double f_sf = 0;
    sdrplt_t histI;
    sdrplt_t histQ;
    sdrplt_t pspec;
}
alias _N194 sdrspec_t;


extern(C):

extern(Windows) HANDLE CreateEventW(
  LPSECURITY_ATTRIBUTES lpEventAttributes, // セキュリティ記述子
  BOOL bManualReset,                       // リセットのタイプ
  BOOL bInitialState,                      // 初期状態
  LPCTSTR lpName                           // イベントオブジェクトの名前
);

alias CreateEvent = CreateEventW;

BOOL CloseHandle(
  HANDLE hObject   // オブジェクトのハンドル
);

extern(C) BOOL SetEvent(
  HANDLE hEvent   // イベントオブジェクトのハンドル
);

extern(Windows) HRESULT SHGetFolderPathW(
    HWND hwndOwner,
    int nFolder,
    HANDLE hToken,
    DWORD dwFlags,
    LPTSTR pszPath
);


alias SHGetFolderPath = SHGetFolderPathW;

immutable CSIDL_DESKTOP                 =  0x0000;        // <desktop>
immutable CSIDL_INTERNET                =  0x0001;        // Internet Explorer (icon on desktop)
immutable CSIDL_PROGRAMS                =  0x0002;        // Start Menu\Programs
immutable CSIDL_CONTROLS                =  0x0003;        // My Computer\Control Panel
immutable CSIDL_PRINTERS                =  0x0004;        // My Computer\Printers
immutable CSIDL_PERSONAL                =  0x0005;        // My Documents
immutable CSIDL_FAVORITES               =  0x0006;        // <user name>\Favorites
immutable CSIDL_STARTUP                 =  0x0007;        // Start Menu\Programs\Startup
immutable CSIDL_RECENT                  =  0x0008;        // <user name>\Recent
immutable CSIDL_SENDTO                  =  0x0009;        // <user name>\SendTo
immutable CSIDL_BITBUCKET               =  0x000a;        // <desktop>\Recycle Bin
immutable CSIDL_STARTMENU               =  0x000b;        // <user name>\Start Menu
immutable CSIDL_MYDOCUMENTS             =  CSIDL_PERSONAL; //  Personal was just a silly name for My Documents
immutable CSIDL_MYMUSIC                 =  0x000d;        // "My Music" folder
immutable CSIDL_MYVIDEO                 =  0x000e;        // "My Videos" folder
immutable CSIDL_DESKTOPDIRECTORY        =  0x0010;        // <user name>\Desktop
immutable CSIDL_DRIVES                  =  0x0011;        // My Computer
immutable CSIDL_NETWORK                 =  0x0012;        // Network Neighborhood (My Network Places)
immutable CSIDL_NETHOOD                 =  0x0013;        // <user name>\nethood
immutable CSIDL_FONTS                   =  0x0014;        // windows\fonts
immutable CSIDL_TEMPLATES               =  0x0015;
immutable CSIDL_COMMON_STARTMENU        =  0x0016;        // All Users\Start Menu
immutable CSIDL_COMMON_PROGRAMS         =  0X0017;        // All Users\Start Menu\Programs
immutable CSIDL_COMMON_STARTUP          =  0x0018;        // All Users\Startup
immutable CSIDL_COMMON_DESKTOPDIRECTORY =  0x0019;        // All Users\Desktop
immutable CSIDL_APPDATA                 =  0x001a;        // <user name>\Application Data
immutable CSIDL_PRINTHOOD               =  0x001b;        // <user name>\PrintHood

extern(D):

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


bool tracing = true;


void tracefln(string file = __FILE__, size_t line = __LINE__, string fn = __FUNCTION__, S, T...)(S format, T args)
if(isSomeString!S)
{
    version(TRACE){
        if(tracing){
            stdout.writef("log: %s(%s): %s: ", file, line, fn);
            stdout.writefln(format, args);
            stdout.flush();
        }
    }
}


void traceln(string file = __FILE__, size_t line = __LINE__, string fn = __FUNCTION__, T...)(T args)
{
    version(TRACE){
        if(tracing){
            stdout.writef("log: %s(%s): %s: ", file, line, fn);
            stdout.writeln(args);
            stdout.flush();
        }
    }
}


void ctTrace(string file = __FILE__, size_t line = __LINE__)()
{
    pragma(msg, file ~ "(" ~ line.to!string() ~ "): ");
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
              sdrtrk;