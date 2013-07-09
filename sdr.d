//##$ dmd -m64 -release -inline sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrmain sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw

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

/* original printf function */
//C     #if defined(GUI)
//C     #define SDRPRINTF(...) do { 	char str[1024]; 	sprintf(str,__VA_ARGS__);  	maindlg^form=static_cast<maindlg^>(hform.Target); 	String^ strstr = gcnew String(str); 	form->mprintf(strstr); } while (0)
//C     #else
//C     #define SDRPRINTF(...) printf(__VA_ARGS__)
//C     #endif

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

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

/* type definition -----------------------------------------------------------*/
//C     typedef fftwf_complex cpx_t; /* complex type for fft */
//alias fftwf_complex cpx_t;
alias Complex!float cpx_t;
alias size_t SOCKET;

const SOMAXCONN = 5;

/* sdr initialization struct */
//C     typedef struct {
//C     	int fend;            /* front end type */
//C     	double f_sf[2];      /* sampling frequency (Hz) */
//C     	double f_if[2];      /* intermediate frequency (Hz) */
//C     	int dtype[2];        /* data type (DTYPEI/DTYPEIQ) */
//C     	FILE *fp1;           /* IF1 file pointer */
//C     	FILE *fp2;           /* IF2 file pointer */
//C     	char file1[1024];    /* IF1 file path */
//C     	char file2[1024];    /* IF2 file path */
//C     	int useif1;          /* IF1 flag */
//C     	int useif2;          /* IF2 flag */
//C     	int confini;         /* front end configuration flag */
//C     	int nch;             /* number of sdr channels */
//C     	int nchL1;           /* number of L1 channels */
//C     	int nchL2;           /* number of L2 channels */
//C     	int nchL5;           /* number of L5 channels */
//C     	int nchL6;           /* number of L6 channels */
//C     	int sat[MAXSAT];     /* PRN of channels */
//C     	int sys[MAXSAT];     /* satellite system type of channels (SYS_*) */
//C     	int ctype[MAXSAT];   /* code type of channels (CTYPE_* )*/
//C     	int ftype[MAXSAT];   /* front end type of channels (FTYPE1/FTYPE2) */
//C     	int pltacq;          /* plot acquisition flag */
//C     	int plttrk;          /* plot tracking flag */
//C     	int outms;           /* output interval (ms) */
//C     	int rinex;           /* rinex output flag */
//C     	int rtcm;            /* rtcm output flag */
//C     	char rinexpath[1024];/* rinex output path */
//C     	int rtcmport;        /* rtcm TCP/IP port */
//C     	int lexport;         /* LEX TCP/IP port */
//C     	int pltspec;         /* plot spectrum flag */
//C     	int buffsize;        /* data buffer size */
//C     	int fendbuffsize;    /* front end data buffer size */
//C     } sdrini_t;
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

/* sdr current state struct */
//C     typedef struct {
//C     	int stopflag;        /* stop flag */
//C     	int specflag;        /* spectrum flag */
//C     	unsigned char *buff; /* IF data buffer */	
//C     	unsigned char *buff1;/* IF data buffer (for file input) */	
//C     	unsigned char *buff2;/* IF data buffer (for file input) */
//C     	ulong buffloccnt; /* current buffer location */
//C     } sdrstat_t;
struct _N184
{
    int stopflag;
    int specflag;
    ubyte *buff;
    ubyte *buff1;
    ubyte *buff2;
    ulong buffloccnt;
}
alias _N184 sdrstat_t;

/* sdr observation struct */
//C     typedef struct {
//C     	int sat;             /* PRN */
//C     	double tow;          /* time of week (s) */
//C     	int week;            /* week number */
//C     	double P;            /* pseudo range (m) */
//C     	double L;            /* carrier phase (cycle) */
//C     	double D;            /* doppler frequency (Hz) */
//C     	double S;            /* SNR (dB-Hz) */
//C     } sdrobs_t;
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

/* sdr acquisition struct */
//C     typedef struct {
//C     	int intg;            /* number of integration */
//C     	double hband;        /* half band of search frequency (Hz) */
//C     	double step;         /* frequency search step (Hz) */
//C     	int nfreq;           /* number of search frequency */
//C     	double *freq;        /* search frequency (Hz) */
//C     	int acqcodei;        /* acquired code phase */
//C     	double acqfreq;      /* acquired frequency (Hz) */
//C     	double acqfreqf;     /* acquired frequency (fine search) (Hz) */
//C     	int lenf;            /* number of integration (fine search) */
//C     	int nfft;            /* number of FFT points */
//C     	int nfftf;           /* number of FFT points (fine search) */
//C     	double cn0;          /* signal C/N0 */ 
//C     	double peakr;        /* first/second peak ratio */
//C     } sdracq_t;
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

/* sdr tracking parameter struct */
//C     typedef struct {
//C     	double cspace;       /* correlation space (chip) */
//C     	int cspaces;         /* correlation space (sample) */
//C     	int *corrp;          /* correlation points (sample) */
//C     	double *corrx;       /* correlation points (for plotting) */
//C     	int ne;              /* early correlation point */
//C     	int nl;              /* late correlation point */
//C     	double pllb;         /* noise bandwidth of PLL (Hz) */
//C     	double dllb;         /* noise bandwidth of DLL (Hz) */
//C     	double fllb;         /* noise bandwidth of FLL (Hz) */
//C     	double dt;           /* loop interval (s) */
//C     	double dllw2;        /* DLL coefficient */
//C     	double dllaw;        /* DLL coefficient */
//C     	double pllw2;        /* PLL coefficient */
//C     	double pllaw;        /* PLL coefficient */
//C     	double fllw;         /* FLL coefficient */
//C     } sdrtrkprm_t;
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

/* sdr tracking struct */
//C     typedef struct {
//C     	double codefreq;     /* code frequency (Hz) */
//C     	double carrfreq;     /* carrier frequency (Hz) */
//C     	double remcode;      /* remained code phase (chip) */
//C     	double remcarr;      /* remained carrier phase (rad) */
//C     	double oldremcode;   /* previous remained code phase (chip) */
//C     	double oldremcarr;   /* previous remained carrier phase (chip) */
//C     	double codeNco;      /* code NCO */
//C     	double codeErr;      /* code tracking error */
//C     	double carrNco;      /* carrier NCO */
//C     	double carrErr;      /* carrier tracking error */
//C     	ulong buffloc;    /* current buffer location */
//C     	double tow[OBSINTERPN]; /* time of week (s) */
//C     	ulong codei[OBSINTERPN]; /* code phase (sample) */
//C     	ulong codeisum[OBSINTERPN]; /* code phase (SNR smoothing interval) (sample) */
//C     	ulong cntout[OBSINTERPN]; /* loop counter */
//C     	double remcodeout[OBSINTERPN]; /* remained code phase (chip)*/
//C     	double L[OBSINTERPN];/* carrier phase (cycle) */
//C     	double D[OBSINTERPN];/* doppler frequency (Hz) */
//C     	double S[OBSINTERPN];/* signal to noise ratio (dB-Hz) */
//C     	double *I;           /* correlation (in-phase) */
//C     	double *Q;           /* correlation (quadrature-phase) */
//C     	double *oldI;        /* previous correlation (in-phase) */
//C     	double *oldQ;        /* previous correlation (quadrature-phase) */
//C     	double *sumI;        /* integrated correlation (in-phase) */
//C     	double *sumQ;        /* integrated correlation (quadrature-phase) */
//C     	double *oldsumI;     /* previous integrated correlation (in-phase) */
//C     	double *oldsumQ;     /* previous integrated correlation (quadrature-phase) */
//C     	double Isum;         /* integrated correlation for SNR computation (in-phase) */
//C     	int ncorrp;          /* number of correlation points */
//C     	int loopms;          /* loop filter interval (ms) */
//C     	int flagpolarityadd; /* polarity (half cycle ambiguity) add flag */
//C     	int flagremcarradd;  /* remained carrier phase add flag */
//C     	sdrtrkprm_t prm1;    /* tracking parameter struct */
//C     	sdrtrkprm_t prm2;    /* tracking parameter struct */
//C     } sdrtrk_t;
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

/* sdr navigation struct */
//C     typedef struct {
//C     	FILE *fpnav;         /* for navigation bit logging */
//C     	int ctype;           /* code type */
//C     	int rate;            /* navigation data rate (ms) */
//C     	int flen;            /* frame length (bits) */
//C     	int addflen;         /* additional frame bits (bits) */
//C     	int addplen;         /* additional bits for parity check (bits) */
//C     	int *prebits;        /* preamble bits */
//C     	int prelen;          /* preamble bits length (bits) */
//C     	int bit;             /* current navigation bit */
//C     	double bitIP;        /* current navigation bit (IP data) */
//C     	int *fbits;          /* frame bits */
//C     	int *fbitsdec;       /* decoded frame bits */
//C     	int *bitsync;        /* frame bits synchronization count */
//C     	int bitind;          /* frame bits synchronization index */
//C     	int bitth;           /* frame bits synchronization threshold */
//C     	ulong firstsf;    /* first subframe location (sample) */
//C     	ulong firstsfcnt; /* first subframe count */
//C     	double firstsftow;   /* tow of first subframe */
//C     	int polarity;        /* bit polarity */
//C     	void *fec;           /* FEC (fec.h)  */
//C     	int swnavsync;       /* switch of frame synchronization (last bit) */
//C     	int swnavreset;      /* switch of frame synchronization (first bit) */
//C     	eph_t eph;           /* ephemeris struct (defined in rtklib.h) */
//C     } sdrnav_t;
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

/* sdr channel struct */
//C     typedef struct {
//C     	HANDLE hsdr;         /* thread handle */
//C     	int no;              /* channel number */
//C     	int sat;             /* satellite number */
//C     	int sys;             /* satellite system */
//C     	int prn;             /* PRN */
//C     	char satstr[5];      /* PRN string */
//C     	int ctype;           /* code type */
//C     	int dtype;           /* data type */
//C     	int ftype;           /* front end type */
//C     	double f_sf;         /* sampling rate (Hz) */
//C     	double f_if;         /* intermediate frequency (Hz) */
//C     	short *code;         /* original code */
//C     	short *lcode;        /* resampled code */
//C     	cpx_t *xcode;        /* resampled code in frequency domain */
//C     	int clen;            /* code length */
//C     	double crate;        /* code chip rate (Hz) */
//C     	double ctime;        /* code period (s) */
//C     	double ti;           /* sampling interval (s) */
//C     	double ci;           /* chip interval (s) */
//C     	int nsamp;           /* number of samples in one code (doppler=0Hz) */
//C     	int nsampchip;       /* number of samples in one code chip (doppler=0Hz) */
//C     	int currnsamp;       /* current number of sampling per one code */
//C     	sdracq_t acq;        /* acquisition struct */
//C     	sdrtrk_t trk;        /* tracking struct */
//C     	sdrnav_t nav;        /* navigation struct */
//C     	int flagacq;         /* acquisition flag */
//C     	int flagtrk;         /* tracking flag */
//C     	int flagnavsync;     /* navigation frame synchronization flag */
//C     	int flagnavpre;      /* preamble found flag */
//C     	int flagfirstsf;     /* first subframe found flag */
//C     	int flagnavdec;      /* navigation data decoded flag */
//C     } sdrch_t;
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

/* sdr plotting struct */
//C     typedef struct {
//C     	FILE *fp;            /* file pointer (gnuplot pipe) */
//C     	HWND hw;             /* window handle */
//C     	int nx;              /* length of x data */
//C     	int ny;              /* length of y data */
//C     	double *x;           /* x data */
//C     	double *y;           /* y data */
//C     	double *z;           /* z data */
//C     	int type;            /* plotting type (PLT_X/PLT_XY/PLT_SURFZ) */
//C     	int skip;            /* skip data (0: plotting all data) */
//C     	int flagabs;         /* y axis data absolute flag (y=abs(y)) */
//C     	double scale;        /* y axis data scale (y=scale*y) */
//C     	int plth;            /* plot window height */
//C     	int pltw;            /* plot window width */
//C     	int pltmh;           /* plot window margin height */
//C     	int pltmw;           /* plot window margin width */
//C     	int pltno;           /* number of figure */
//C     	double pltms;        /* plot interval (ms) */
//C     } sdrplt_t;
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

/* sdr socket struct */
//C     typedef struct {
//C     	HANDLE hsoc;         /* socket handle */
//C     	int port;            /* port number */
//C     	SOCKET s_soc,c_soc;  /* server/client socket */
//C     	int flag;            /* connection flag */
//C     } sdrsoc_t;
struct _N192
{
    Tid hsoc;
    ushort port;
    SOCKET s_soc;
    SOCKET c_soc;
    int flag;
}
alias _N192 sdrsoc_t;

/* sdr output struct */
//C     typedef struct {
//C     	int nsat;            /* number of satellite */
//C     	obsd_t *obsd;        /* observation struct (defined in rtklib.h) */
//C     	eph_t *eph;          /* ephemeris struct (defined in rtklib.h) */
//C     	rnxopt_t opt;        /* rinex option struct (defined in rtklib.h) */
//C     	sdrsoc_t soc;        /* sdr socket struct */
//C     	char rinexobs[1024]; /* rinex observation file name */
//C     	char rinexnav[1024]; /* rinex navigation file name */
//C     } sdrout_t;
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

/* sdr spectrum struct */
//C     typedef struct {
//C     	int dtype;           /* data type (DTYPEI/DTYPEIQ) */
//C     	int ftype;           /* front end type */
//C     	int nsamp;           /* number of samples in one code */
//C     	double f_sf;         /* sampling frequency (Hz) */
//C     	sdrplt_t histI;      /* plot struct for histogram */
//C     	sdrplt_t histQ;      /* plot struct for histogram */
//C     	sdrplt_t pspec;      /* plot struct for spectrum analysis */            
//C     } sdrspec_t;
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

/+
/* sdrmain.c -----------------------------------------------------------------*/
//C     #ifdef GUI
//C     extern GCHandle hform;
//C     extern void initsdrgui(maindlg^ form, sdrini_t* sdrinigui);
//C     extern void startsdr(void *arg);
//C     #else
//C     extern void startsdr(void);
void  startsdr();
//C     #endif
//C     extern void quitsdr(sdrini_t *ini, int stop);
void  quitsdr(sdrini_t *ini, int stop);
//C     extern void sdrthread(void *arg);
void  sdrthread(void *arg);
//C     extern void syncthread(void * arg);
void  syncthread(void *arg);
//C     extern void keythread(void *arg);
void  keythread(void *arg);
+/
/+
/* sdracq.c ------------------------------------------------------------------*/
//C     extern ulong sdraccuisition(sdrch_t *sdr, double *power);
ulong  sdraccuisition(sdrch_t *sdr, double *power);
//C     extern int checkacquisition(double *P, sdrch_t *sdr);
int  checkacquisition(double *P, sdrch_t *sdr);
//C     extern void pcorrelator(const char *data, int dtype, double ti, int n, double *freq, int nfreq, double crate, int m, cpx_t* codex, double *P);
void  pcorrelator(char *data, int dtype, double ti, int n, double *freq, int nfreq, double crate, int m, cpx_t *codex, double *P);
//C     extern double carrfsearch(const char *data, int dtype, double ti, double crate, int n, int m, int clen, short* code);
double  carrfsearch(char *data, int dtype, double ti, double crate, int n, int m, int clen, short *code);
+/
/+
/* sdrtrk.c ------------------------------------------------------------------*/
//C     extern ulong sdrtracking(sdrch_t *sdr, ulong buffloc, ulong cnt);
ulong  sdrtracking(sdrch_t *sdr, ulong buffloc, ulong cnt);
//C     extern void correlator(const char *data, int dtype, double ti, int n, double freq, double phi0, double crate, double coff, int* s, int ns, double *I, double *Q, double *remc, double *remp, short* codein, int coden);
void  correlator(char *data, int dtype, double ti, int n, double freq, double phi0, double crate, double coff, int *s, int ns, double *I, double *Q, double *remc, double *remp, short *codein, int coden);
//C     extern void cumsumcorr(double *I, double *Q, sdrtrk_t *trk, int flag1, int flag2);
void  cumsumcorr(double *I, double *Q, sdrtrk_t *trk, int flag1, int flag2);
//C     extern void pll(sdrch_t *sdr, sdrtrkprm_t *prm);
void  pll(sdrch_t *sdr, sdrtrkprm_t *prm);
//C     extern void dll(sdrch_t *sdr, sdrtrkprm_t *prm);
void  dll(sdrch_t *sdr, sdrtrkprm_t *prm);
//C     extern void setobsdata(sdrch_t *sdr, ulong buffloc, ulong cnt, sdrtrk_t *trk, int flag);
void  setobsdata(sdrch_t *sdr, ulong buffloc, ulong cnt, sdrtrk_t *trk, int flag);
+/
/+
/* sdrinit.c -----------------------------------------------------------------*/
//C     extern int readinifile(sdrini_t *ini);
int  readinifile(sdrini_t *ini);
//C     extern int chk_initvalue(sdrini_t *ini);
int  chk_initvalue(sdrini_t *ini);
//C     extern void openhandles(void);
void  openhandles();
//C     extern void closehandles(void);
void  closehandles();
//C     extern int initpltstruct(sdrplt_t *acq, sdrplt_t *trk,sdrch_t *sdr);
int  initpltstruct(sdrplt_t *acq, sdrplt_t *trk, sdrch_t *sdr);
//C     extern void quitpltstruct(sdrplt_t *acq, sdrplt_t *trk);
void  quitpltstruct(sdrplt_t *acq, sdrplt_t *trk);
//C     extern int initacqstruct(int sys, int ctype, sdracq_t *acq);
int  initacqstruct(int sys, int ctype, sdracq_t *acq);
//C     extern int inittrkprmstruct(sdrtrkprm_t *prm, int sw);
int  inittrkprmstruct(sdrtrkprm_t *prm, int sw);
//C     extern int inittrkstruct(int sys, int ctype, sdrtrk_t *trk);
int  inittrkstruct(int sys, int ctype, sdrtrk_t *trk);
//C     extern int initnavstruct(int sys, int ctype, sdrnav_t *nav);
int  initnavstruct(int sys, int ctype, sdrnav_t *nav);
//C     extern int initsdrch(int chno, int sys, int prn, int ctype, int dtype, int ftype, double f_sf, double f_if, sdrch_t *sdr);
int  initsdrch(int chno, int sys, int prn, int ctype, int dtype, int ftype, double f_sf, double f_if, sdrch_t *sdr);
//C     extern void freesdrch(sdrch_t *sdr);
void  freesdrch(sdrch_t *sdr);
+/
/+
/* sdrcmn.c ------------------------------------------------------------------*/
//C     extern void gettimeofday_init();
//void  gettimeofday_init(...);
//C     extern int gettimeofday(struct timeval *tv, void *tz_unused);
//int  gettimeofday(timeval *tv, void *tz_unused);
//C     extern void tic(void);
void  tic();
//C     extern void toc(void);
void  toc();
//C     extern void settimeout(struct timespec *timeout, int waitms);
//void  settimeout(timespec *timeout, int waitms);
//C     extern double log2(double n);
double  log2(double n);
//C     extern int calcfftnum(double x, int next);
int  calcfftnum(double x, int next);
//C     extern int calcfftnumreso(double reso, double ti);
int  calcfftnumreso(double reso, double ti);
//C     extern void *sdrmalloc(size_t size);
void * sdrmalloc(size_t size);
//C     extern void sdrfree(void *p);
void  sdrfree(void *p);
//C     extern cpx_t *cpxmalloc(int n);
cpx_t * cpxmalloc(int n);
//C     extern void cpxfree(cpx_t *cpx);
void  cpxfree(cpx_t *cpx);
//C     extern void cpxfft(cpx_t *cpx, int n);
void  cpxfft(cpx_t *cpx, int n);
//C     extern void cpxifft(cpx_t *cpx, int n);
void  cpxifft(cpx_t *cpx, int n);
//C     extern void cpxcpx(const short *I, const short *Q, double scale, int n, cpx_t *cpx);
void  cpxcpx(short *I, short *Q, double scale, int n, cpx_t *cpx);
//C     extern void cpxcpxf(const float *I, const float *Q, double scale, int n, cpx_t *cpx);
void  cpxcpxf(float *I, float *Q, double scale, int n, cpx_t *cpx);
//C     extern void cpxconv(cpx_t *cpxa, cpx_t *cpxb, int m, int n, int flagsum, double *conv);
void  cpxconv(cpx_t *cpxa, cpx_t *cpxb, int m, int n, int flagsum, double *conv);
//C     extern void cpxpspec(cpx_t *cpx, int n, int flagsum, double *pspec);
void  cpxpspec(cpx_t *cpx, int n, int flagsum, double *pspec);
//C     extern void dot_21(const short *a1, const short *a2, const short *b, int n, double *d1, double *d2);
void  dot_21(short *a1, short *a2, short *b, int n, double *d1, double *d2);
//C     extern void dot_22(const short *a1, const short *a2, const short *b1, const short *b2, int n, double *d1, double *d2);
void  dot_22(short *a1, short *a2, short *b1, short *b2, int n, double *d1, double *d2);
//C     extern void dot_23(const short *a1, const short *a2, const short *b1, const short *b2, const short *b3, int n, double *d1, double *d2);
void  dot_23(short *a1, short *a2, short *b1, short *b2, short *b3, int n, double *d1, double *d2);
//C     extern double mixcarr(const char *data, int dtype, double ti, int n, double freq, double phi0, short *I, short *Q);
double  mixcarr(char *data, int dtype, double ti, int n, double freq, double phi0, short *I, short *Q);
//C     extern void mulvcs(const char *data1, const short *data2, int n, short *out_);
void  mulvcs(char *data1, short *data2, int n, short *out_);
//C     extern void sumvf(const float *data1, const float *data2, int n, float *out_);
void  sumvf(float *data1, float *data2, int n, float *out_);
//C     extern void sumvd(const double *data1, const double *data2, int n, double *out_);
void  sumvd(double *data1, double *data2, int n, double *out_);
//C     extern int maxvi(const int *data, int n, int exinds, int exinde, int *ind);
int  maxvi(int *data, int n, int exinds, int exinde, int *ind);
//C     extern float maxvf(const float *data, int n, int exinds, int exinde, int *ind);
float  maxvf(float *data, int n, int exinds, int exinde, int *ind);
//C     extern double maxvd(const double *data, int n, int exinds, int exinde, int *ind);
double  maxvd(double *data, int n, int exinds, int exinde, int *ind);
//C     extern double meanvd(const double *data, int n, int exinds, int exinde);
double  meanvd(double *data, int n, int exinds, int exinde);
//C     extern double interp1(double *x, double *y, int n, double t);
double  interp1(double *x, double *y, int n, double t);
//C     extern void uint64todouble(ulong *data, ulong base, int n, double *out_);
void  uint64todouble(ulong *data, ulong base, int n, double *out_);
//C     extern void ind2sub(int ind, int nx, int ny, int *subx, int *suby);
void  ind2sub(int ind, int nx, int ny, int *subx, int *suby);
//C     extern void shiftright(void *dst, void *src, size_t size, int n);
void  shiftright(void *dst, void *src, size_t size, int n);
//C     extern void resdata(const char *data, int dtype, int n, int m, char *rdata);
void  resdata(char *data, int dtype, int n, int m, char *rdata);
//C     extern double rescode(const short *code, int len, double coff, int smax, double ci, int n, short *rcode);
double  rescode(short *code, int len, double coff, int smax, double ci, int n, short *rcode);
+/
/+
/* sdrcode.c -----------------------------------------------------------------*/
//C     extern short *gencode(int prn, int ctype, int *len, double *crate);
short * gencode(int prn, int ctype, int *len, double *crate);
+/
/+
/* sdrplot.c -----------------------------------------------------------------*/
//C     extern int updatepltini(int nx, int ny, int posx, int posy);
int  updatepltini(int nx, int ny, int posx, int posy);
//C     extern void setsdrplotprm(sdrplt_t *plt, int type, int nx, int ny, int skip, int abs, double s, int h, int w, int mh, int mw, int no);
void  setsdrplotprm(sdrplt_t *plt, int type, int nx, int ny, int skip, int abs, double s, int h, int w, int mh, int mw, int no);
//C     extern int initsdrplot(sdrplt_t *plt);
int  initsdrplot(sdrplt_t *plt);
//C     extern void quitsdrplot(sdrplt_t *plt);
void  quitsdrplot(sdrplt_t *plt);
//C     extern void setxrange(sdrplt_t *plt, double xmin, double xmax);
void  setxrange(sdrplt_t *plt, double xmin, double xmax);
//C     extern void setyrange(sdrplt_t *plt, double ymin, double ymax);
void  setyrange(sdrplt_t *plt, double ymin, double ymax);
//C     extern void setlabel(sdrplt_t *plt, char *xlabel, char *ylabel);
void  setlabel(sdrplt_t *plt, char *xlabel, char *ylabel);
//C     extern void settitle(sdrplt_t *plt, char *title);
void  settitle(sdrplt_t *plt, char *title);
//C     extern void ploty(FILE *fp, double *x, int n, int skip, double scale);
void  ploty(FILE *fp, double *x, int n, int skip, double scale);
//C     extern void plotxy(FILE *fp, double *x, double *y, int n, int skip, double scale);
void  plotxy(FILE *fp, double *x, double *y, int n, int skip, double scale);
//C     extern void plotsurfz(FILE *fp, double*z, int nx, int ny, int skip, double scale);
void  plotsurfz(FILE *fp, double *z, int nx, int ny, int skip, double scale);
//C     extern void plotbox(FILE *fp, double *x, double *y, int n, int skip, double scale);
void  plotbox(FILE *fp, double *x, double *y, int n, int skip, double scale);
//C     extern void plotthread(sdrplt_t *plt);
void  plotthread(sdrplt_t *plt);
//C     extern void plot(sdrplt_t *plt);
void  plot(sdrplt_t *plt);
+/
/+
/* sdrnav.c ------------------------------------------------------------------*/
//C     extern void sdrnavigation(sdrch_t *sdr, ulong buffloc, ulong cnt);
void  sdrnavigation(sdrch_t *sdr, ulong buffloc, ulong cnt);
//C     extern void bits2bin(int *bits, int nbits, int nbin, unsigned char *bin);
void  bits2bin(int *bits, int nbits, int nbin, ubyte *bin);
//C     extern int nav_decode_frame(const unsigned char *buff, eph_t *eph);
int  nav_decode_frame(ubyte *buff, eph_t *eph);
//C     extern int nav_checksync(int biti, double IP, double IPold, sdrnav_t *nav);
int  nav_checksync(int biti, double IP, double IPold, sdrnav_t *nav);
//C     extern int nav_checkbit(int biti, double IP, sdrnav_t *nav);
int  nav_checkbit(int biti, double IP, sdrnav_t *nav);
//C     extern void nav_decodefec(sdrnav_t *nav);
void  nav_decodefec(sdrnav_t *nav);
//C     extern int paritycheck(int *bits);
int  paritycheck(int *bits);
//C     extern int nav_paritycheck(sdrnav_t *nav);
int  nav_paritycheck(sdrnav_t *nav);
//C     extern int nav_findpreamble(sdrnav_t *nav);
int  nav_findpreamble(sdrnav_t *nav);
//C     extern int nav_decodenav(sdrnav_t *nav);
int  nav_decodenav(sdrnav_t *nav);
+/
/+
/* sdrout.c ------------------------------------------------------------------*/
//C     extern void createrinexopt(rnxopt_t *opt);
void  createrinexopt(rnxopt_t *opt);
//C     extern void sdrobs2obsd(sdrobs_t *sdrobs, int ns, obsd_t *out_);
void  sdrobs2obsd(sdrobs_t *sdrobs, int ns, obsd_t *out_);
//C     extern int createrinexobs(char *file, rnxopt_t *opt);
int  createrinexobs(char *file, rnxopt_t *opt);
//C     extern int writerinexobs(char *file, rnxopt_t *opt, obsd_t *obsd, int ns);
int  writerinexobs(char *file, rnxopt_t *opt, obsd_t *obsd, int ns);
//C     extern int createrinexnav(char *file, rnxopt_t *opt);
int  createrinexnav(char *file, rnxopt_t *opt);
//C     extern int writerinexnav(char *file, rnxopt_t *opt, eph_t *eph);
int  writerinexnav(char *file, rnxopt_t *opt, eph_t *eph);
//C     extern void tcpsvrstart(sdrsoc_t *soc);
void  tcpsvrstart(sdrsoc_t *soc);
//C     extern void tcpsvrclose(sdrsoc_t *soc);
void  tcpsvrclose(sdrsoc_t *soc);
//C     extern void sendrtcmnav(eph_t *eph, sdrsoc_t *soc);
void  sendrtcmnav(eph_t *eph, sdrsoc_t *soc);
//C     extern void sendrtcmobs(obsd_t *obsd, sdrsoc_t *soc, int nsat);
void  sendrtcmobs(obsd_t *obsd, sdrsoc_t *soc, int nsat);
+/
/+
/* sdrrcv.c ------------------------------------------------------------------*/
//C     extern int rcvinit(sdrini_t *ini);
int  rcvinit(sdrini_t *ini);
//C     extern int rcvquit(sdrini_t *ini);
int  rcvquit(sdrini_t *ini);
//C     extern int rcvgrabstart(sdrini_t *ini);
int  rcvgrabstart(sdrini_t *ini);
//C     extern int rcvgrabdata(sdrini_t *ini);
int  rcvgrabdata(sdrini_t *ini);
//C     extern int rcvgrabdata_file(sdrini_t *ini);
int  rcvgrabdata_file(sdrini_t *ini);
//C     extern int rcvgetbuff(sdrini_t *ini, ulong buffloc, int n, int ftype, int dtype, char *expbuf);
int  rcvgetbuff(sdrini_t *ini, ulong buffloc, int n, int ftype, int dtype, char *expbuf);
//C     extern void file_pushtomembuf(void);
void  file_pushtomembuf();
//C     extern void file_getbuff(ulong buffloc, int n, int ftype, int dtype, char *expbuf);
void  file_getbuff(ulong buffloc, int n, int ftype, int dtype, char *expbuf);
+/
/+
/* sdrspec.c -----------------------------------------------------------------*/
//C     extern void initsdrspecgui(sdrspec_t* sdrspecgui);
void  initsdrspecgui(sdrspec_t *sdrspecgui);
//C     extern void specthread(void * arg);
void  specthread(void *arg);
//C     extern int initspecpltstruct(sdrspec_t *spec);
int  initspecpltstruct(sdrspec_t *spec);
//C     extern void quitspecpltstruct(sdrspec_t *spec);
void  quitspecpltstruct(sdrspec_t *spec);
//C     extern void calchistgram(char *data, int dtype, int n, double *xI, double *yI, double *xQ, double *yQ);
void  calchistgram(char *data, int dtype, int n, double *xI, double *yI, double *xQ, double *yQ);
//C     extern void hanning(int n, float *win);
void  hanning(int n, float *win);
//C     extern int spectrumanalyzer(const char *data, int dtype, int n, double f_sf, int nfft, double *freq, double *pspec);
int  spectrumanalyzer(char *data, int dtype, int n, double f_sf, int nfft, double *freq, double *pspec);
+/
/* sdrlex.c ------------------------------------------------------------------*/
//C     #ifdef QZSLEX
//C     extern void lexthread(void *arg);*/
//C     #endif

/* sdrsaif.c */
//C     #ifdef QZSSAIF
//C     extern void sdrthread_qzssaif(void *arg);*/
//C     #endif

//C     #ifdef __cplusplus
//C     }
//C     #endif
//C     #endif /* SDR_H */

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
/+
BOOL QueryPerformanceCounter(
  LARGE_INTEGER *lpPerformanceCount   // カウンタの値
);

BOOL QueryPerformanceFrequency(
  LARGE_INTEGER *lpFrequency   // 現在の周波数
);
+/
/+
extern(Windows) DWORD GetPrivateProfileStringW(
  const(char)* lpAppName,        // セクション名
  const(char)* lpKeyName,        // キー名
  const(char)* lpDefault,        // 既定の文字列
  char* lpReturnedString,  // 情報が格納されるバッファ
  DWORD nSize,              // 情報バッファのサイズ
  const(char)* lpFileName        // .ini ファイルの名前
);

alias GetPrivateProfileString = GetPrivateProfileStringW;
+/
/+
DWORD GetFileAttributesW(
  LPCTSTR lpFileName   // ファイルまたはディレクトリの名前
);

alias GetFileAttributes = GetFileAttributesW;
+/
/+
size_t _beginthread( 
   void function(void*) start_address,
   uint stack_size,
   void *arglist 
);

size_t _beginthreadex( 
   void *security,
   uint stack_size,
   void function(void*) start_address,
   void *arglist,
   uint initflag,
   uint *thrdaddr 
);
+/
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

//int _pclose(FILE * _File);
//FILE* _popen(const(char)* _Command, const(char)* _Mode);

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