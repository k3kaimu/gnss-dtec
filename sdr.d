//##$ dmd -m64 -release -inline -unittest sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrmain sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw

/* Converted to D from sdr.h by htod */
module sdr;
/*------------------------------------------------------------------------------
* sdr.h : constants, types and function prototypes

* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*-----------------------------------------------------------------------------*/
//C     #ifndef SDR_H
//C     #define SDR_H
import core.thread;
import std.concurrency;
import std.complex;
//C     #define _CRT_SECURE_NO_WARNINGS
//C     #include <stdio.h>
import std.stdio;
//C     #include <stdlib.h>
import std.c.stdlib;
//C     #include <math.h>
import std.c.math;
import std.math;
import std.format : formattedWrite;
import std.array  : appender;
import std.traits : isSomeString;
import std.process;
//C     #include <stdint.h>
//import std.c.stdint;
//C     #include <shlobj.h>
//import std.c.shlobj;
//C     #include <windows.h>
public import std.c.windows.windows;
public import std.c.windows.winsock;
//C     #include <string.h>
//C     #include <signal.h>
//import std.c.signal;
//C     #include <time.h>
import std.c.time;
//C     #include <process.h>
import std.c.process;
//C     #include <stdarg.h>
//C     #include <ctype.h>
//#include <shlwapi.h>
//C     #pragma comment(lib,"winmm.lib")
pragma(lib, "winmm.lib");
pragma(lib, "ws2_32.lib");
pragma(lib, "shell32.lib");
pragma(lib, "User32.lib");
pragma(lib, "kernel32.lib");
//C     #pragma comment(lib,"ws2_32.lib")
//C     #pragma comment(lib,"shell32.lib")
//C     #pragma comment(lib,"User32.lib")

/* GUI/CLI */
//C     #if defined(GUI)
//C     #include "../gui/gnss-sdrgui/maindlg.h"
//C     using namespace gnsssdrgui;
//C     #endif

/* SIMD (SSE2) */
//C     #if defined(SSE2)
//C     #include <emmintrin.h>
//C     #include <tmmintrin.h>
//C     #endif

/* SIMD (AVX) */
//C     #if defined(AVX)
//C     #include <immintrin.h>
//C     #endif

/* FEC */
//C     #pragma comment(lib,"../../src/lib/fec/libfec.a")
pragma(lib, "libfec.a");
//C     #include "lib/fec/fec.h"
public import fec;

/* FFT */
//C     #pragma comment(lib,"../../src/lib/fft/libfftw3f-3.lib")
//C     #include "lib/fft/fftw3.h"
public import fftw;
pragma(lib, "libfftw3f-3.lib");

/* RTKLIB */
//C     #include "lib/rtklib/rtklib.h"
public import rtklib;
pragma(lib, "rtklib.lib");
/* STEREO */
//C     #pragma comment(lib,"../../src/rcv/stereo/lib/libnslstereo.a")
//C     #include "rcv/stereo/src/stereo.h"
//import stereo;
pragma(lib, "libnslstereo.a");

/* GN3S */
//C     #include "rcv/GN3S/src/GN3S.h"
//import GN3S;

/* USB */
//C     #pragma comment(lib,"../../src/lib/usb/libusb.lib")
pragma(lib, "libusb.lib");
//C     #include "lib/usb/lusb0_usb.h"
//import lusb0_usb;

/* constants -----------------------------------------------------------------*/
//C     #define ROUND(x)  ((int)floor((x)+0.5))     /* round function */
//C     #define PI              3.1415926535897932  /* pi */
//C     #define DPI             (2.0*PI)            /* 2*pi */
//const PI = 3.1415926535897932;
const DPI = 2 * PI;
//C     #define D2R             (PI/180.0)          /* deg to rad */
const D2R = PI / 180;
//C     #define R2D             (180.0/PI)          /* rad to deg */
const R2D = 180 / PI;
//C     #define CLIGHT          299792458.0         /* speed of light (m/s) */
//C     #define ON              1                   /* flag ON */
const CLIGHT = 299792458.0;
//C     #define OFF             0                   /* flag OFF */
const ON = 1;
//C     #define CDIV            32                  /* carrier lookup table divided cycle */
const OFF = 0;
//C     #define CMASK           0x1F                /* carrier lookup table mask */
const CDIV = 32;
//C     #define CSCALE          (1.0/16.0)          /* carrier lookup table scale (LSB) */
const CMASK = 0x1F;
const CSCALE = 1.0 /16.0;

/* front end setting */
//C     #define FEND_STEREO     0                   /* front end type: NSL stereo */
//C     #define FEND_GN3SV2     -1                  /* front end type: SiGe GN3S v2 (not supported in v1.0) */	
const FEND_STEREO = 0;
//C     #define FEND_GN3SV3     1                   /* front end type: SiGe GN3S v3 */	
const FEND_GN3SV2 = -1;
//C     #define	FEND_FILESTEREO 2                   /* front end type: NSL stereo binary file */
const FEND_GN3SV3 = 1;
//C     #define	FEND_FILE       3                   /* front end type: IF file */
const FEND_FILESTEREO = 2;
//C     #define FTYPE1          1                   /* front end number */
const FEND_FILE = 3;
//C     #define FTYPE2          2                   /* front end number */
const FTYPE1 = 1;
//C     #define DTYPEI          1                   /* sampling type: real */
const FTYPE2 = 2;
//C     #define DTYPEIQ         2                   /* sampling type: real+imag */
const DTYPEI = 1;
//C     #define MEMBUFLEN       5000                /* number of temporary buffer */
const DTYPEIQ = 2;
//C     #define FILE_BUFFSIZE   65536               /* buffer size for post processing */
const MEMBUFLEN = 5000;

const FILE_BUFFSIZE = 8192;
/* acquisition setting */
//C     #define NFFTTHREAD      2                   /* number of thread for executing FFT */
//C     #define ACQINTG         4                   /* number of non-coherent integration */
const NFFTTHREAD = 2;
//C     #define ACQHBAND        5000                /* half-band width for doppler search (Hz) */
const ACQINTG = 4;
//C     #define ACQSTEP         250                 /* doppler search frequency step (Hz) */
const ACQHBAND = 5000;
//C     #define ACQTH           2.0                 /* acquisition threshold (peak ratio) */
const ACQSTEP = 250;
//C     #define ACQLENF         10                  /* number of code for fine doppler search */
const ACQTH = 2.0;
//C     #define ACQFFTFRESO     10                  /* frequency resolution for fine doppler search (Hz) */
const ACQLENF = 10;
//C     #define ACQSLEEP        2000                /* acquisition process interval (ms) */
const ACQFFTFRESO = 10;

const ACQSLEEP = 2000;
/* tracking setting */
//C     #define TRKCN           8                   /* number of correlation points (half side) */
//C     #define LOOP_MS_L1CA    10                  /* loop filter interval (ms) */
const TRKCN = 8;
//C     #define LOOP_MS_SBAS    2                   /* loop filter interval (ms) */
const LOOP_MS_L1CA = 10;
//C     #define LOOP_MS_LEX     4                   /* loop filter interval (ms) */
const LOOP_MS_SBAS = 2;
/* tracking parameter 1 */
const LOOP_MS_LEX = 4;
/* (before nav frame synchronization) */
//C     #define TRKCDN1         3                   /* distance of correlation points (sample) */
//C     #define TRKCP1          12                  /* Early/Late correlation points (sample) */
const TRKCDN1 = 3;
//C     #define TRKDLLB1        1.0                 /* DLL noise bandwidth (Hz) */
const TRKCP1 = 12;
//C     #define TRKPLLB1        20.0                /* PLL noise bandwidth (Hz) */
const TRKDLLB1 = 1.0;
//C     #define TRKFLLB1        250.0               /* FLL noise bandwidth (Hz) */
const TRKPLLB1 = 20.0;
//C     #define TRKDT1          0.001               /* loop interval (s) */
const TRKFLLB1 = 250.0;
/* tracking parameter 2 */
const TRKDT1 = 0.001;
/* (after nav frame synchronization) */
//C     #define TRKCDN2         3                   /* distance of correlation points (sample) */
//C     #define TRKCP2          12                  /* Early/Late correlation points (sample) */
const TRKCDN2 = 3;
//C     #define TRKDLLB2        0.5                 /* DLL noise bandwidth (Hz) */
const TRKCP2 = 12;
//C     #define TRKPLLB2        20.0                /* PLL noise bandwidth (Hz) */  
const TRKDLLB2 = 0.5;
//C     #define TRKFLLB2        50.0                /* FLL noise bandwidth (Hz) */
const TRKPLLB2 = 20.0;
//C     #define TRKDT2          0.001               /* loop interval (s) */
const TRKFLLB2 = 50.0;

const TRKDT2 = 0.001;
/* navigation parameter */
//C     #define NAVBITTH        5                   /* navigation frame synchronization threshold */
/* GPS/QZSS L1CA */
const NAVBITTH = 5;
//C     #define NAVRATE_L1CA    20                  /* navigation chip length (ms) */
//C     #define NAVFLEN_L1CA    300                 /* navigation frame data (bits) */
const NAVRATE_L1CA = 20;
//C     #define NAVADDFLEN_L1CA 2                   /* additional bits of frame (bits) */
const NAVFLEN_L1CA = 300;
//C     #define NAVADDPLEN_L1CA 2                   /* additional bits for parity check (bits) */
const NAVADDFLEN_L1CA = 2;
//C     #define NAVPRELEN_L1CA  8                   /* preamble bits length (bits) */
const NAVADDPLEN_L1CA = 2;
/* QZSS L1SAIF */
const NAVPRELEN_L1CA = 8;
//C     #define NAVRATE_L1SAIF  2                   /* navigation chip length (ms) */
//C     #define NAVFLEN_L1SAIF  500                 /* navigation frame data (bits) */
const NAVRATE_L1SAIF = 2;
//C     #define NAVADDFLEN_L1SAIF 12                /* additional bits of frame (bits) */
const NAVFLEN_L1SAIF = 500;
//C     #define NAVADDPLEN_L1SAIF 0                 /* additional bits for parity check (bits) */
const NAVADDFLEN_L1SAIF = 12;
//C     #define NAVPRELEN_L1SAIF 8                  /* preamble bits length (bits) */
const NAVADDPLEN_L1SAIF = 0;

const NAVPRELEN_L1SAIF = 8;
/* observation data generation */
//C     #define PTIMING         68.802              /* pseudo range generation timing (ms) */
//C     #define OBSINTERPN      8                   /* number of observation stock for interpolation */
const PTIMING = 68.802;
//C     #define SNSMOOTHMS      100                 /* SNR smoothing interval (ms) */
const OBSINTERPN = 8;

const SNSMOOTHMS = 100;
/* code generation parameter */
//C     #define MAXGPSSATNO     210                 /* max satellite number */
//C     #define MAXGALSATNO     50                  /* max satellite number */
const MAXGPSSATNO = 210;
//C     #define MAXCMPSATNO     37                  /* max satellite number */
const MAXGALSATNO = 50;
/* code type */
const MAXCMPSATNO = 37;
//C     #define CTYPE_L1CA      1                   /* GPS/QZSS L1C/A */
//C     #define CTYPE_L1CP      2                   /* GPS/QZSS L1C Pilot */
const CTYPE_L1CA = 1;
//C     #define CTYPE_L1CD      3                   /* GPS/QZSS L1C Data */
const CTYPE_L1CP = 2;
//C     #define CTYPE_L1CO      4                   /* GPS/QZSS L1C overlay */
const CTYPE_L1CD = 3;
//C     #define CTYPE_L2CM      5                   /* GPS/QZSS L2CM */
const CTYPE_L1CO = 4;
//C     #define CTYPE_L2CL      6                   /* GPS/QZSS L2CL */
const CTYPE_L2CM = 5;
//C     #define CTYPE_L5I       7                   /* GPS/QZSS L5I */
const CTYPE_L2CL = 6;
//C     #define CTYPE_L5Q       8                   /* GPS/QZSS L5Q */
const CTYPE_L5I = 7;
//C     #define CTYPE_E1B       9                   /* Galileo E1B (Data) */
const CTYPE_L5Q = 8;
//C     #define CTYPE_E1C       10                  /* Galileo E1C (Pilot) */
const CTYPE_E1B = 9;
//C     #define CTYPE_E5AI      11                  /* Galileo E5aI (Data) */
const CTYPE_E1C = 10;
//C     #define CTYPE_E5AQ      12                  /* Galileo E5aQ (Pilot) */
const CTYPE_E5AI = 11;
//C     #define CTYPE_E5BI      13                  /* Galileo E5bI (Data) */
const CTYPE_E5AQ = 12;
//C     #define CTYPE_E5BQ      14                  /* Galileo E5bQ (Pilot) */
const CTYPE_E5BI = 13;
//C     #define CTYPE_E1CO      15                  /* Galileo E1C overlay */
const CTYPE_E5BQ = 14;
//C     #define CTYPE_E5AIO     16                  /* Galileo E5aI overlay */
const CTYPE_E1CO = 15;
//C     #define CTYPE_E5AQO     17                  /* Galileo E5aQ overlay */
const CTYPE_E5AIO = 16;
//C     #define CTYPE_E5BIO     18                  /* Galileo E5bI overlay */
const CTYPE_E5AQO = 17;
//C     #define CTYPE_E5BQO     19                  /* Galileo E5bQ overlay */
const CTYPE_E5BIO = 18;
//C     #define CTYPE_G1        20                  /* GLONASS G1 */
const CTYPE_E5BQO = 19;
//C     #define CTYPE_G2        21                  /* GLONASS G2 */
const CTYPE_G1 = 20;
//C     #define CTYPE_B1        22                  /* BeiDou B1 */
const CTYPE_G2 = 21;
//C     #define CTYPE_LEXS      23                  /* QZSS LEX short */
const CTYPE_B1 = 22;
//C     #define CTYPE_LEXL      24                  /* QZSS LEX long */
const CTYPE_LEXS = 23;
//C     #define CTYPE_L1SAIF    25                  /* QZSS L1 SAIF */
const CTYPE_LEXL = 24;
//C     #define CTYPE_L1SBAS    26                  /* SBAS compatible L1CA */
const CTYPE_L1SAIF = 25;

const CTYPE_L1SBAS = 26;
/* gnuplot plotting setting */
//C     #define PLT_Y           1                   /* plotting type: 1D data */
//C     #define PLT_XY          2                   /* plotting type: 2D data */
const PLT_Y = 1;
//C     #define PLT_SURFZ       3                   /* plotting type: 3D surface data */
const PLT_XY = 2;
//C     #define PLT_BOX         4                   /* plotting type: BOX */
const PLT_SURFZ = 3;
//C     #define PLT_WN          5                   /* number of figure window column */
const PLT_BOX = 4;
//C     #define PLT_HN          3                   /* number of figure window row */
const PLT_WN = 5;
//C     #define PLT_W           180                 /* window width (pixel) */
const PLT_HN = 3;
//C     #define PLT_H           250                 /* window height (pixel) */
const PLT_W = 180;
//C     #define PLT_MW          0                   /* margin (pixel) */
const PLT_H = 250;
//C     #define PLT_MH          0                   /* margin (pixel) */
const PLT_MW = 0;
//C     #define PLT_MS          500                 /* plotting interval (ms) */
const PLT_MH = 0;
//C     #define PLT_MS_FILE     2000                /* plotting interval (ms) */
const PLT_MS = 500;

const PLT_MS_FILE = 2000;
/* spectrum analysis */
//C     #define SPEC_MS         200                 /* plotting interval (ms) */
//C     #define SPEC_LEN        7                   /* number of integration of 1 ms data */
const SPEC_MS = 200;
//C     #define SPEC_BITN       8                   /* number of bin for histogram */
const SPEC_LEN = 7;
//C     #define SPEC_NLOOP      100                 /* number of loop for smoothing */
const SPEC_BITN = 8;
//C     #define SPEC_NFFT       16384               /* number of FFT points */
const SPEC_NLOOP = 100;
//C     #define SPEC_PLT_W      400                 /* window width (pixel) */
const SPEC_NFFT = 16384;
//C     #define SPEC_PLT_H      500                 /* window height (pixel) */
const SPEC_PLT_W = 400;
//C     #define SPEC_PLT_MW     0                   /* margin (pixel) */
const SPEC_PLT_H = 500;
//C     #define SPEC_PLT_MH     0                   /* margin (pixel) */
const SPEC_PLT_MW = 0;

const SPEC_PLT_MH = 0;
/* QZSS LEX setting */
//C     #define DSAMPLEX        7                   /* L1CA-LEX DCB (sample) */
//C     #define LEXMS           4                   /* LEX short length (ms) */
const DSAMPLEX = 7;
//C     #define LENLEXPRE       4                   /* LEX preamble length (byte) */
const LEXMS = 4;
//C     #define LENLEXMSG       250                 /* LEX message length (byte) */
const LENLEXPRE = 4;
//C     #define LENLEXRS        255                 /* LEX RS data length (byte) */
const LENLEXMSG = 250;
//C     #define LENLEXRSK       223                 /* LEX RS K (byte) */
const LENLEXRS = 255;
//C     #define LENLEXRSP       (LENLEXRS-LENLEXRSK)/* LEX RS parity length (byte) */
const LENLEXRSK = 223;
//C     #define LENLEXERR       (LENLEXRSP/2)       /* RS maximum error correction length (byte) */
//C     #define LENLEXRCV       (8+LENLEXMSG-LENLEXRSP) /* LEX transmitting length */
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