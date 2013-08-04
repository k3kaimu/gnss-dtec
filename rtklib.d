/* Converted to D from lib\rtklib\rtklib.h by htod */
module rtklib;
/*------------------------------------------------------------------------------
* rtklib.h : rtklib constants, types and function prototypes
*
*          Copyright (C) 2007-2013 by T.TAKASU, All rights reserved.
*
* options : -DENAGLO   enable GLONASS
*           -DENAGAL   enable Galileo
*           -DENAQZS   enable QZSS
*           -DENACMP   enable BeiDou
*           -DNFREQ=n  set number of obs codes/frequencies
*           -DNEXOBS=n set number of extended obs codes
*           -DMAXOBS=n set max number of obs data in an epoch
*           -DEXTLEX   enable QZSS LEX extension
*
* version : $Revision: 1.1 $ $Date: 2008/07/17 21:48:06 $
* history : 2007/01/13 1.0  rtklib ver.1.0.0
*           2007/03/20 1.1  rtklib ver.1.1.0
*           2008/07/15 1.2  rtklib ver.2.1.0
*           2008/10/19 1.3  rtklib ver.2.1.1
*           2009/01/31 1.4  rtklib ver.2.2.0
*           2009/04/30 1.5  rtklib ver.2.2.1
*           2009/07/30 1.6  rtklib ver.2.2.2
*           2009/12/25 1.7  rtklib ver.2.3.0
*           2010/07/29 1.8  rtklib ver.2.4.0
*           2011/05/27 1.9  rtklib ver.2.4.1
*           2013/03/28 1.10 rtklib ver.2.4.2
*-----------------------------------------------------------------------------*/
//C     #ifndef RTKLIB_H
//C     #define RTKLIB_H

//C     #include <windows.h>
import std.c.windows.windows;
//C     #include <time.h>
import std.c.time;
//C     #include <stdio.h>
import std.c.stdio;

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

/* constants -----------------------------------------------------------------*/
//C     #define ENAGLO
//C     #define ENAGAL
//C     #define ENAQZS

//C     #define VER_RTKLIB  "2.4.2"             /* library version */

//C     #define COPYRIGHT_RTKLIB             "Copyright (C) 2007-2013 by T.Takasu\nAll rights reserved."

//C     #define PI          3.1415926535897932  /* pi */
//C     #define D2R         (PI/180.0)          /* deg to rad */
//const PI = 3.1415926535897932;
//C     #define R2D         (180.0/PI)          /* rad to deg */
//C     #define CLIGHT      299792458.0         /* speed of light (m/s) */
//C     #define SC2RAD      3.1415926535898     /* semi-circle to radian (IS-GPS) */
const CLIGHT = 299792458.0;
//C     #define AU          149597870691.0      /* 1 AU (m) */
const SC2RAD = 3.1415926535898;
//C     #define AS2R        (D2R/3600.0)        /* arc sec to radian */
const AU = 149597870691.0;

//C     #define OMGE        7.2921151467E-5     /* earth angular velocity (IS-GPS) (rad/s) */

const OMGE = 7.2921151467E-5;
//C     #define RE_WGS84    6378137.0           /* earth semimajor axis (WGS84) (m) */
//C     #define FE_WGS84    (1.0/298.257223563) /* earth flattening (WGS84) */
const RE_WGS84 = 6378137.0;

//C     #define HION        350000.0            /* ionosphere height (m) */

const HION = 350000.0;
//C     #define MAXFREQ     7                   /* max NFREQ */

const MAXFREQ = 7;
//C     #define FREQ1       1.57542E9           /* L1/E1  frequency (Hz) */
//C     #define FREQ2       1.22760E9           /* L2     frequency (Hz) */
const FREQ1 = 1.57542E9;
//C     #define FREQ5       1.17645E9           /* L5/E5a frequency (Hz) */
const FREQ2 = 1.22760E9;
//C     #define FREQ6       1.27875E9           /* E6/LEX frequency (Hz) */
const FREQ5 = 1.17645E9;
//C     #define FREQ7       1.20714E9           /* E5b    frequency (Hz) */
const FREQ6 = 1.27875E9;
//C     #define FREQ8       1.191795E9          /* E5a+b  frequency (Hz) */
const FREQ7 = 1.20714E9;
//C     #define FREQ1_GLO   1.60200E9           /* GLONASS G1 base frequency (Hz) */
const FREQ8 = 1.191795E9;
//C     #define DFRQ1_GLO   0.56250E6           /* GLONASS G1 bias frequency (Hz/n) */
const FREQ1_GLO = 1.60200E9;
//C     #define FREQ2_GLO   1.24600E9           /* GLONASS G2 base frequency (Hz) */
const DFRQ1_GLO = 0.56250E6;
//C     #define DFRQ2_GLO   0.43750E6           /* GLONASS G2 bias frequency (Hz/n) */
const FREQ2_GLO = 1.24600E9;
//C     #define FREQ3_GLO   1.202025E9          /* GLONASS G3 frequency (Hz) */
const DFRQ2_GLO = 0.43750E6;
//C     #define FREQ2_CMP   1.561098E9          /* BeiDou B1 frequency (Hz) */
const FREQ3_GLO = 1.202025E9;
//C     #define FREQ7_CMP   1.20714E9           /* BeiDou B2 frequency (Hz) */
const FREQ2_CMP = 1.561098E9;
//C     #define FREQ6_CMP   1.26852E9           /* BeiDou B3 frequency (Hz) */
const FREQ7_CMP = 1.20714E9;

const FREQ6_CMP = 1.26852E9;
//C     #define EFACT_GPS   1.0                 /* error factor: GPS */
//C     #define EFACT_GLO   1.5                 /* error factor: GLONASS */
const EFACT_GPS = 1.0;
//C     #define EFACT_GAL   1.0                 /* error factor: Galileo */
const EFACT_GLO = 1.5;
//C     #define EFACT_QZS   1.0                 /* error factor: QZSS */
const EFACT_GAL = 1.0;
//C     #define EFACT_CMP   1.0                 /* error factor: BeiDou */
const EFACT_QZS = 1.0;
//C     #define EFACT_SBS   3.0                 /* error factor: SBAS */
const EFACT_CMP = 1.0;

const EFACT_SBS = 3.0;
//C     #define SYS_NONE    0x00                /* navigation system: none */
//C     #define SYS_GPS     0x01                /* navigation system: GPS */
const SYS_NONE = 0x00;
//C     #define SYS_SBS     0x02                /* navigation system: SBAS */
const SYS_GPS = 0x01;
//C     #define SYS_GLO     0x04                /* navigation system: GLONASS */
const SYS_SBS = 0x02;
//C     #define SYS_GAL     0x08                /* navigation system: Galileo */
const SYS_GLO = 0x04;
//C     #define SYS_QZS     0x10                /* navigation system: QZSS */
const SYS_GAL = 0x08;
//C     #define SYS_CMP     0x20                /* navigation system: BeiDou */
const SYS_QZS = 0x10;
//C     #define SYS_ALL     0xFF                /* navigation system: all */
const SYS_CMP = 0x20;

const SYS_ALL = 0xFF;


//C     #define TSYS_GPS    0                   /* time system: GPS time */
//C     #define TSYS_UTC    1                   /* time system: UTC */
const TSYS_GPS = 0;
//C     #define TSYS_GLO    2                   /* time system: GLONASS time */
const TSYS_UTC = 1;
//C     #define TSYS_GAL    3                   /* time system: Galileo time */
const TSYS_GLO = 2;
//C     #define TSYS_QZS    4                   /* time system: QZSS time */
const TSYS_GAL = 3;
//C     #define TSYS_CMP    5                   /* time system: BeiDou time */
const TSYS_QZS = 4;

const TSYS_CMP = 5;
//C     #ifndef NFREQ
//C     #define NFREQ       3                   /* number of carrier frequencies */
//C     #endif
const NFREQ = 3;
//C     #define NFREQGLO    2                   /* number of carrier frequencies of GLONASS */

const NFREQGLO = 2;
//C     #ifndef NEXOBS
//C     #define NEXOBS      0                   /* number of extended obs codes */
//C     #endif
const NEXOBS = 0;

//C     #define MINPRNGPS   1                   /* min satellite PRN number of GPS */
//C     #define MAXPRNGPS   32                  /* max satellite PRN number of GPS */
const MINPRNGPS = 1;
//C     #define NSATGPS     (MAXPRNGPS-MINPRNGPS+1) /* number of GPS satellites */
const MAXPRNGPS = 32;
const NSATGPS = (MAXPRNGPS-MINPRNGPS+1);
//C     #define NSYSGPS     1

const NSYSGPS = 1;
//C     #ifdef ENAGLO
//C     #define MINPRNGLO   1                   /* min satellite slot number of GLONASS */
//C     #define MAXPRNGLO   24                  /* max satellite slot number of GLONASS */
const MINPRNGLO = 1;
//C     #define NSATGLO     (MAXPRNGLO-MINPRNGLO+1) /* number of GLONASS satellites */
const MAXPRNGLO = 24;
const NSATGLO = (MAXPRNGLO-MINPRNGLO+1);
//C     #define NSYSGLO     1
//C     #else
const NSYSGLO = 1;
//C     #define MINPRNGLO   0
//C     #define MAXPRNGLO   0
//C     #define NSATGLO     0
//C     #define NSYSGLO     0
//C     #endif
//C     #ifdef ENAGAL
//C     #define MINPRNGAL   1                   /* min satellite PRN number of Galileo */
//C     #define MAXPRNGAL   27                  /* max satellite PRN number of Galileo */
const MINPRNGAL = 1;
//C     #define NSATGAL    (MAXPRNGAL-MINPRNGAL+1) /* number of Galileo satellites */
const MAXPRNGAL = 27;
const NSATGAL = (MAXPRNGAL-MINPRNGAL+1);
//C     #define NSYSGAL     1
//C     #else
const NSYSGAL = 1;
//C     #define MINPRNGAL   0
//C     #define MAXPRNGAL   0
//C     #define NSATGAL     0
//C     #define NSYSGAL     0
//C     #endif
//C     #ifdef ENAQZS
//C     #define MINPRNQZS   193                 /* min satellite PRN number of QZSS */
//C     #define MAXPRNQZS   195                 /* max satellite PRN number of QZSS */
const MINPRNQZS = 193;
//C     #define MINPRNQZS_S 183                 /* min satellite PRN number of QZSS SAIF */
const MAXPRNQZS = 195;
//C     #define MAXPRNQZS_S 185                 /* max satellite PRN number of QZSS SAIF */
const MINPRNQZS_S = 183;
//C     #define NSATQZS     (MAXPRNQZS-MINPRNQZS+1) /* number of QZSS satellites */
const MAXPRNQZS_S = 185;
const NSATQZS = (MAXPRNQZS-MINPRNQZS+1);
//C     #define NSYSQZS     1
//C     #else
const NSYSQZS = 1;
//C     #define MINPRNQZS   0
//C     #define MAXPRNQZS   0
//C     #define NSATQZS     0
//C     #define NSYSQZS     0
//C     #endif
//C     #ifdef ENACMP
//C     #define MINPRNCMP   1                   /* min satellite sat number of BeiDou */
//C     #define MAXPRNCMP   35                  /* max satellite sat number of BeiDou */
//C     #define NSATCMP     (MAXPRNCMP-MINPRNCMP+1) /* number of BeiDou satellites */
//C     #define NSYSCMP     1
//C     #else
//C     #define MINPRNCMP   0
//C     #define MAXPRNCMP   0
const MINPRNCMP = 0;
//C     #define NSATCMP     0
const MAXPRNCMP = 0;
//C     #define NSYSCMP     0
const NSATCMP = 0;
//C     #endif
const NSYSCMP = 0;
//C     #define NSYS        (NSYSGPS+NSYSGLO+NSYSGAL+NSYSQZS+NSYSCMP) /* number of systems */
const NSYS = (NSYSGPS+NSYSGLO+NSYSGAL+NSYSQZS+NSYSCMP);

//C     #define MINPRNSBS   120                 /* min satellite PRN number of SBAS */
//C     #define MAXPRNSBS   142                 /* max satellite PRN number of SBAS */
const MINPRNSBS = 120;
//C     #define NSATSBS     (MAXPRNSBS-MINPRNSBS+1) /* number of SBAS satellites */
const MAXPRNSBS = 142;
const NSATSBS = (MAXPRNSBS-MINPRNSBS+1);

//C     #define MAXSAT      (NSATGPS+NSATGLO+NSATGAL+NSATQZS+NSATCMP+NSATSBS)
                                        /* max satellite number (1 to MAXSAT) */
const MAXSAT =  (NSATGPS+NSATGLO+NSATGAL+NSATQZS+NSATCMP+NSATSBS);
//C     #ifndef MAXOBS
//C     #define MAXOBS      64                  /* max number of obs in an epoch */
//C     #endif
const MAXOBS = 64;
//C     #define MAXRCV      64                  /* max receiver number (1 to MAXRCV) */
//C     #define MAXOBSTYPE  64                  /* max number of obs type in RINEX */
const MAXRCV = 64;
//C     #define DTTOL       0.005               /* tolerance of time difference (s) */
const MAXOBSTYPE = 64;
//C     #if 0
const DTTOL = 0.005;
//C     #define MAXDTOE     10800.0             /* max time difference to ephem Toe (s) for GPS */
//C     #else
//C     #define MAXDTOE     7200.0              /* max time difference to ephem Toe (s) for GPS */
//C     #endif
const MAXDTOE = 7200.0;
//C     #define MAXDTOE_GLO 1800.0              /* max time difference to GLONASS Toe (s) */
//C     #define MAXDTOE_SBS 360.0               /* max time difference to SBAS Toe (s) */
const MAXDTOE_GLO = 1800.0;
//C     #define MAXDTOE_S   86400.0             /* max time difference to ephem toe (s) for other */
const MAXDTOE_SBS = 360.0;
//C     #define MAXGDOP     300.0               /* max GDOP */
const MAXDTOE_S = 86400.0;

const MAXGDOP = 300.0;
//C     #define MAXEXFILE   100                 /* max number of expanded files */
//C     #define MAXSBSAGEF  30.0                /* max age of SBAS fast correction (s) */
const MAXEXFILE = 100;
//C     #define MAXSBSAGEL  1800.0              /* max age of SBAS long term corr (s) */
const MAXSBSAGEF = 30.0;
//C     #define MAXSBSURA   8                   /* max URA of SBAS satellite */
const MAXSBSAGEL = 1800.0;
//C     #define MAXBAND     10                  /* max SBAS band of IGP */
const MAXSBSURA = 8;
//C     #define MAXNIGP     201                 /* max number of IGP in SBAS band */
const MAXBAND = 10;
//C     #define MAXNGEO     4                   /* max number of GEO satellites */
const MAXNIGP = 201;
//C     #define MAXCOMMENT  10                  /* max number of RINEX comments */
const MAXNGEO = 4;
//C     #define MAXSTRPATH  1024                /* max length of stream path */
const MAXCOMMENT = 10;
//C     #define MAXSTRMSG   1024                /* max length of stream message */
const MAXSTRPATH = 1024;
//C     #define MAXSTRRTK   8                   /* max number of stream in RTK server */
const MAXSTRMSG = 1024;
//C     #define MAXSBSMSG   32                  /* max number of SBAS msg in RTK server */
const MAXSTRRTK = 8;
//C     #define MAXSOLMSG   4096                /* max length of solution message */
const MAXSBSMSG = 32;
//C     #define MAXRAWLEN   4096                /* max length of receiver raw message */
const MAXSOLMSG = 4096;
//C     #define MAXERRMSG   4096                /* max length of error/warning message */
const MAXRAWLEN = 4096;
//C     #define MAXANT      64                  /* max length of station name/antenna type */
const MAXERRMSG = 4096;
//C     #define MAXSOLBUF   256                 /* max number of solution buffer */
const MAXANT = 64;
//C     #define MAXOBSBUF   128                 /* max number of observation data buffer */
const MAXSOLBUF = 256;
//C     #define MAXNRPOS    16                  /* max number of reference positions */
const MAXOBSBUF = 128;

const MAXNRPOS = 16;
//C     #define RNX2VER     2.10                /* RINEX ver.2 default output version */
//C     #define RNX3VER     3.00                /* RINEX ver.3 default output version */
const RNX2VER = 2.10;

const RNX3VER = 3.00;
//C     #define OBSTYPE_PR  0x01                /* observation type: pseudorange */
//C     #define OBSTYPE_CP  0x02                /* observation type: carrier-phase */
const OBSTYPE_PR = 0x01;
//C     #define OBSTYPE_DOP 0x04                /* observation type: doppler-freq */
const OBSTYPE_CP = 0x02;
//C     #define OBSTYPE_SNR 0x08                /* observation type: SNR */
const OBSTYPE_DOP = 0x04;
//C     #define OBSTYPE_ALL 0xFF                /* observation type: all */
const OBSTYPE_SNR = 0x08;

const OBSTYPE_ALL = 0xFF;
//C     #define FREQTYPE_L1 0x01                /* frequency type: L1/E1 */
//C     #define FREQTYPE_L2 0x02                /* frequency type: L2/B1 */
const FREQTYPE_L1 = 0x01;
//C     #define FREQTYPE_L5 0x04                /* frequency type: L5/E5a/L3 */
const FREQTYPE_L2 = 0x02;
//C     #define FREQTYPE_L6 0x08                /* frequency type: E6/LEX/B3 */
const FREQTYPE_L5 = 0x04;
//C     #define FREQTYPE_L7 0x10                /* frequency type: E5b/B2 */
const FREQTYPE_L6 = 0x08;
//C     #define FREQTYPE_L8 0x20                /* frequency type: E5(a+b) */
const FREQTYPE_L7 = 0x10;
//C     #define FREQTYPE_ALL 0xFF               /* frequency type: all */
const FREQTYPE_L8 = 0x20;

const FREQTYPE_ALL = 0xFF;
//C     #define CODE_NONE   0                   /* obs code: none or unknown */
//C     #define CODE_L1C    1                   /* obs code: L1C/A,G1C/A,E1C (GPS,GLO,GAL,QZS,SBS) */
const CODE_NONE = 0;
//C     #define CODE_L1P    2                   /* obs code: L1P,G1P    (GPS,GLO) */
const CODE_L1C = 1;
//C     #define CODE_L1W    3                   /* obs code: L1 Z-track (GPS) */
const CODE_L1P = 2;
//C     #define CODE_L1Y    4                   /* obs code: L1Y        (GPS) */
const CODE_L1W = 3;
//C     #define CODE_L1M    5                   /* obs code: L1M        (GPS) */
const CODE_L1Y = 4;
//C     #define CODE_L1N    6                   /* obs code: L1codeless (GPS) */
const CODE_L1M = 5;
//C     #define CODE_L1S    7                   /* obs code: L1C(D)     (GPS,QZS) */
const CODE_L1N = 6;
//C     #define CODE_L1L    8                   /* obs code: L1C(P)     (GPS,QZS) */
const CODE_L1S = 7;
//C     #define CODE_L1E    9                   /* obs code: L1-SAIF    (QZS) */
const CODE_L1L = 8;
//C     #define CODE_L1A    10                  /* obs code: E1A        (GAL) */
const CODE_L1E = 9;
//C     #define CODE_L1B    11                  /* obs code: E1B        (GAL) */
const CODE_L1A = 10;
//C     #define CODE_L1X    12                  /* obs code: E1B+C,L1C(D+P) (GAL,QZS) */
const CODE_L1B = 11;
//C     #define CODE_L1Z    13                  /* obs code: E1A+B+C,L1SAIF (GAL,QZS) */
const CODE_L1X = 12;
//C     #define CODE_L2C    14                  /* obs code: L2C/A,G1C/A (GPS,GLO) */
const CODE_L1Z = 13;
//C     #define CODE_L2D    15                  /* obs code: L2 L1C/A-(P2-P1) (GPS) */
const CODE_L2C = 14;
//C     #define CODE_L2S    16                  /* obs code: L2C(M)     (GPS,QZS) */
const CODE_L2D = 15;
//C     #define CODE_L2L    17                  /* obs code: L2C(L)     (GPS,QZS) */
const CODE_L2S = 16;
//C     #define CODE_L2X    18                  /* obs code: L2C(M+L),B1I+Q (GPS,QZS,CMP) */
const CODE_L2L = 17;
//C     #define CODE_L2P    19                  /* obs code: L2P,G2P    (GPS,GLO) */
const CODE_L2X = 18;
//C     #define CODE_L2W    20                  /* obs code: L2 Z-track (GPS) */
const CODE_L2P = 19;
//C     #define CODE_L2Y    21                  /* obs code: L2Y        (GPS) */
const CODE_L2W = 20;
//C     #define CODE_L2M    22                  /* obs code: L2M        (GPS) */
const CODE_L2Y = 21;
//C     #define CODE_L2N    23                  /* obs code: L2codeless (GPS) */
const CODE_L2M = 22;
//C     #define CODE_L5I    24                  /* obs code: L5/E5aI    (GPS,GAL,QZS,SBS) */
const CODE_L2N = 23;
//C     #define CODE_L5Q    25                  /* obs code: L5/E5aQ    (GPS,GAL,QZS,SBS) */
const CODE_L5I = 24;
//C     #define CODE_L5X    26                  /* obs code: L5/E5aI+Q  (GPS,GAL,QZS,SBS) */
const CODE_L5Q = 25;
//C     #define CODE_L7I    27                  /* obs code: E5bI,B2I   (GAL,CMP) */
const CODE_L5X = 26;
//C     #define CODE_L7Q    28                  /* obs code: E5bQ,B2Q   (GAL,CMP) */
const CODE_L7I = 27;
//C     #define CODE_L7X    29                  /* obs code: E5bI+Q,B2I+Q (GAL,CMP) */
const CODE_L7Q = 28;
//C     #define CODE_L6A    30                  /* obs code: E6A        (GAL) */
const CODE_L7X = 29;
//C     #define CODE_L6B    31                  /* obs code: E6B        (GAL) */
const CODE_L6A = 30;
//C     #define CODE_L6C    32                  /* obs code: E6C        (GAL) */
const CODE_L6B = 31;
//C     #define CODE_L6X    33                  /* obs code: E6B+C,LEXS+L,B3I+Q (GAL,QZS,CMP) */
const CODE_L6C = 32;
//C     #define CODE_L6Z    34                  /* obs code: E6A+B+C    (GAL) */
const CODE_L6X = 33;
//C     #define CODE_L6S    35                  /* obs code: LEXS       (QZS) */
const CODE_L6Z = 34;
//C     #define CODE_L6L    36                  /* obs code: LEXL       (QZS) */
const CODE_L6S = 35;
//C     #define CODE_L8I    37                  /* obs code: E5(a+b)I   (GAL) */
const CODE_L6L = 36;
//C     #define CODE_L8Q    38                  /* obs code: E5(a+b)Q   (GAL) */
const CODE_L8I = 37;
//C     #define CODE_L8X    39                  /* obs code: E5(a+b)I+Q (GAL) */
const CODE_L8Q = 38;
//C     #define CODE_L2I    40                  /* obs code: B1I        (CMP) */
const CODE_L8X = 39;
//C     #define CODE_L2Q    41                  /* obs code: B1Q        (CMP) */
const CODE_L2I = 40;
//C     #define CODE_L6I    42                  /* obs code: B3I        (CMP) */
const CODE_L2Q = 41;
//C     #define CODE_L6Q    43                  /* obs code: B3Q        (CMP) */
const CODE_L6I = 42;
//C     #define CODE_L3I    44                  /* obs code: G3I        (GLO) */
const CODE_L6Q = 43;
//C     #define CODE_L3Q    45                  /* obs code: G3Q        (GLO) */
const CODE_L3I = 44;
//C     #define CODE_L3X    46                  /* obs code: G3I+Q      (GLO) */
const CODE_L3Q = 45;
//C     #define MAXCODE     46                  /* max number of obs code */
const CODE_L3X = 46;

const MAXCODE = 46;
//C     #define PMODE_SINGLE 0                  /* positioning mode: single */
//C     #define PMODE_DGPS   1                  /* positioning mode: DGPS/DGNSS */
const PMODE_SINGLE = 0;
//C     #define PMODE_KINEMA 2                  /* positioning mode: kinematic */
const PMODE_DGPS = 1;
//C     #define PMODE_STATIC 3                  /* positioning mode: static */
const PMODE_KINEMA = 2;
//C     #define PMODE_MOVEB  4                  /* positioning mode: moving-base */
const PMODE_STATIC = 3;
//C     #define PMODE_FIXED  5                  /* positioning mode: fixed */
const PMODE_MOVEB = 4;
//C     #define PMODE_PPP_KINEMA 6              /* positioning mode: PPP-kinemaric */
const PMODE_FIXED = 5;
//C     #define PMODE_PPP_STATIC 7              /* positioning mode: PPP-static */
const PMODE_PPP_KINEMA = 6;
//C     #define PMODE_PPP_FIXED 8               /* positioning mode: PPP-fixed */
const PMODE_PPP_STATIC = 7;

const PMODE_PPP_FIXED = 8;
//C     #define SOLF_LLH    0                   /* solution format: lat/lon/height */
//C     #define SOLF_XYZ    1                   /* solution format: x/y/z-ecef */
const SOLF_LLH = 0;
//C     #define SOLF_ENU    2                   /* solution format: e/n/u-baseline */
const SOLF_XYZ = 1;
//C     #define SOLF_NMEA   3                   /* solution format: NMEA-183 */
const SOLF_ENU = 2;
//C     #define SOLF_GSIF   4                   /* solution format: GSI-F1/2/3 */
const SOLF_NMEA = 3;

const SOLF_GSIF = 4;
//C     #define SOLQ_NONE   0                   /* solution status: no solution */
//C     #define SOLQ_FIX    1                   /* solution status: fix */
const SOLQ_NONE = 0;
//C     #define SOLQ_FLOAT  2                   /* solution status: float */
const SOLQ_FIX = 1;
//C     #define SOLQ_SBAS   3                   /* solution status: SBAS */
const SOLQ_FLOAT = 2;
//C     #define SOLQ_DGPS   4                   /* solution status: DGPS/DGNSS */
const SOLQ_SBAS = 3;
//C     #define SOLQ_SINGLE 5                   /* solution status: single */
const SOLQ_DGPS = 4;
//C     #define SOLQ_PPP    6                   /* solution status: PPP */
const SOLQ_SINGLE = 5;
//C     #define SOLQ_DR     7                   /* solution status: dead reconing */
const SOLQ_PPP = 6;
//C     #define MAXSOLQ     7                   /* max number of solution status */
const SOLQ_DR = 7;

const MAXSOLQ = 7;
//C     #define TIMES_GPST  0                   /* time system: gps time */
//C     #define TIMES_UTC   1                   /* time system: utc */
const TIMES_GPST = 0;
//C     #define TIMES_JST   2                   /* time system: jst */
const TIMES_UTC = 1;

const TIMES_JST = 2;
//C     #define IONOOPT_OFF 0                   /* ionosphere option: correction off */
//C     #define IONOOPT_BRDC 1                  /* ionosphere option: broadcast model */
const IONOOPT_OFF = 0;
//C     #define IONOOPT_SBAS 2                  /* ionosphere option: SBAS model */
const IONOOPT_BRDC = 1;
//C     #define IONOOPT_IFLC 3                  /* ionosphere option: L1/L2 or L1/L5 iono-free LC */
const IONOOPT_SBAS = 2;
//C     #define IONOOPT_EST 4                   /* ionosphere option: estimation */
const IONOOPT_IFLC = 3;
//C     #define IONOOPT_TEC 5                   /* ionosphere option: IONEX TEC model */
const IONOOPT_EST = 4;
//C     #define IONOOPT_QZS 6                   /* ionosphere option: QZSS broadcast model */
const IONOOPT_TEC = 5;
//C     #define IONOOPT_LEX 7                   /* ionosphere option: QZSS LEX ionospehre */
const IONOOPT_QZS = 6;
//C     #define IONOOPT_STEC 8                  /* ionosphere option: SLANT TEC model */
const IONOOPT_LEX = 7;

const IONOOPT_STEC = 8;
//C     #define TROPOPT_OFF 0                   /* troposphere option: correction off */
//C     #define TROPOPT_SAAS 1                  /* troposphere option: Saastamoinen model */
const TROPOPT_OFF = 0;
//C     #define TROPOPT_SBAS 2                  /* troposphere option: SBAS model */
const TROPOPT_SAAS = 1;
//C     #define TROPOPT_EST 3                   /* troposphere option: ZTD estimation */
const TROPOPT_SBAS = 2;
//C     #define TROPOPT_ESTG 4                  /* troposphere option: ZTD+grad estimation */
const TROPOPT_EST = 3;
//C     #define TROPOPT_COR 5                   /* troposphere option: ZTD correction */
const TROPOPT_ESTG = 4;
//C     #define TROPOPT_CORG 6                  /* troposphere option: ZTD+grad correction */
const TROPOPT_COR = 5;

const TROPOPT_CORG = 6;
//C     #define EPHOPT_BRDC 0                   /* ephemeris option: broadcast ephemeris */
//C     #define EPHOPT_PREC 1                   /* ephemeris option: precise ephemeris */
const EPHOPT_BRDC = 0;
//C     #define EPHOPT_SBAS 2                   /* ephemeris option: broadcast + SBAS */
const EPHOPT_PREC = 1;
//C     #define EPHOPT_SSRAPC 3                 /* ephemeris option: broadcast + SSR_APC */
const EPHOPT_SBAS = 2;
//C     #define EPHOPT_SSRCOM 4                 /* ephemeris option: broadcast + SSR_COM */
const EPHOPT_SSRAPC = 3;
//C     #define EPHOPT_LEX  5                   /* ephemeris option: QZSS LEX ephemeris */
const EPHOPT_SSRCOM = 4;

const EPHOPT_LEX = 5;
//C     #define ARMODE_OFF  0                   /* AR mode: off */
//C     #define ARMODE_CONT 1                   /* AR mode: continuous */
const ARMODE_OFF = 0;
//C     #define ARMODE_INST 2                   /* AR mode: instantaneous */
const ARMODE_CONT = 1;
//C     #define ARMODE_FIXHOLD 3                /* AR mode: fix and hold */
const ARMODE_INST = 2;
//C     #define ARMODE_PPPAR 4                  /* AR mode: PPP-AR */
const ARMODE_FIXHOLD = 3;
//C     #define ARMODE_PPPAR_ILS 5              /* AR mode: PPP-AR ILS */
const ARMODE_PPPAR = 4;
//C     #define ARMODE_WLNL 6                   /* AR mode: wide lane/narrow lane */
const ARMODE_PPPAR_ILS = 5;
//C     #define ARMODE_TCAR 7                   /* AR mode: triple carrier ar */
const ARMODE_WLNL = 6;

const ARMODE_TCAR = 7;
//C     #define SBSOPT_LCORR 1                  /* SBAS option: long term correction */
//C     #define SBSOPT_FCORR 2                  /* SBAS option: fast correction */
const SBSOPT_LCORR = 1;
//C     #define SBSOPT_ICORR 4                  /* SBAS option: ionosphere correction */
const SBSOPT_FCORR = 2;
//C     #define SBSOPT_RANGE 8                  /* SBAS option: ranging */
const SBSOPT_ICORR = 4;

const SBSOPT_RANGE = 8;
//C     #define STR_NONE     0                  /* stream type: none */
//C     #define STR_SERIAL   1                  /* stream type: serial */
const STR_NONE = 0;
//C     #define STR_FILE     2                  /* stream type: file */
const STR_SERIAL = 1;
//C     #define STR_TCPSVR   3                  /* stream type: TCP server */
const STR_FILE = 2;
//C     #define STR_TCPCLI   4                  /* stream type: TCP client */
const STR_TCPSVR = 3;
//C     #define STR_UDP      5                  /* stream type: UDP stream */
const STR_TCPCLI = 4;
//C     #define STR_NTRIPSVR 6                  /* stream type: NTRIP server */
const STR_UDP = 5;
//C     #define STR_NTRIPCLI 7                  /* stream type: NTRIP client */
const STR_NTRIPSVR = 6;
//C     #define STR_FTP      8                  /* stream type: ftp */
const STR_NTRIPCLI = 7;
//C     #define STR_HTTP     9                  /* stream type: http */
const STR_FTP = 8;

const STR_HTTP = 9;
//C     #define STRFMT_RTCM2 0                  /* stream format: RTCM 2 */
//C     #define STRFMT_RTCM3 1                  /* stream format: RTCM 3 */
const STRFMT_RTCM2 = 0;
//C     #define STRFMT_OEM4  2                  /* stream format: NovAtel OEMV/4 */
const STRFMT_RTCM3 = 1;
//C     #define STRFMT_OEM3  3                  /* stream format: NovAtel OEM3 */
const STRFMT_OEM4 = 2;
//C     #define STRFMT_UBX   4                  /* stream format: u-blox LEA-*T */
const STRFMT_OEM3 = 3;
//C     #define STRFMT_SS2   5                  /* stream format: NovAtel Superstar II */
const STRFMT_UBX = 4;
//C     #define STRFMT_CRES  6                  /* stream format: Hemisphere */
const STRFMT_SS2 = 5;
//C     #define STRFMT_STQ   7                  /* stream format: SkyTraq S1315F */
const STRFMT_CRES = 6;
//C     #define STRFMT_GW10  8                  /* stream format: Furuno GW10 */
const STRFMT_STQ = 7;
//C     #define STRFMT_JAVAD 9                  /* stream format: JAVAD GRIL/GREIS */
const STRFMT_GW10 = 8;
//C     #define STRFMT_NVS   10                 /* stream format: NVS NVC08C */
const STRFMT_JAVAD = 9;
//C     #define STRFMT_BINEX 11                 /* stream format: BINEX */
const STRFMT_NVS = 10;
//C     #define STRFMT_LEXR  12                 /* stream format: Furuno LPY-10000 */
const STRFMT_BINEX = 11;
//C     #define STRFMT_SIRF  13                 /* stream format: SiRF    (reserved) */
const STRFMT_LEXR = 12;
//C     #define STRFMT_RINEX 14                 /* stream format: RINEX */
const STRFMT_SIRF = 13;
//C     #define STRFMT_SP3   15                 /* stream format: SP3 */
const STRFMT_RINEX = 14;
//C     #define STRFMT_RNXCLK 16                /* stream format: RINEX CLK */
const STRFMT_SP3 = 15;
//C     #define STRFMT_SBAS  17                 /* stream format: SBAS messages */
const STRFMT_RNXCLK = 16;
//C     #define STRFMT_NMEA  18                 /* stream format: NMEA 0183 */
const STRFMT_SBAS = 17;
//C     #ifndef EXTLEX
const STRFMT_NMEA = 18;
//C     #define MAXRCVFMT    11                 /* max number of receiver format */
//C     #else
const MAXRCVFMT = 11;
//C     #define MAXRCVFMT    12
//C     #endif

//C     #define STR_MODE_R  0x1                 /* stream mode: read */
//C     #define STR_MODE_W  0x2                 /* stream mode: write */
const STR_MODE_R = 0x1;
//C     #define STR_MODE_RW 0x3                 /* stream mode: read/write */
const STR_MODE_W = 0x2;

const STR_MODE_RW = 0x3;
//C     #define GEOID_EMBEDDED    0             /* geoid model: embedded geoid */
//C     #define GEOID_EGM96_M150  1             /* geoid model: EGM96 15x15" */
const GEOID_EMBEDDED = 0;
//C     #define GEOID_EGM2008_M25 2             /* geoid model: EGM2008 2.5x2.5" */
const GEOID_EGM96_M150 = 1;
//C     #define GEOID_EGM2008_M10 3             /* geoid model: EGM2008 1.0x1.0" */
const GEOID_EGM2008_M25 = 2;
//C     #define GEOID_GSI2000_M15 4             /* geoid model: GSI geoid 2000 1.0x1.5" */
const GEOID_EGM2008_M10 = 3;

const GEOID_GSI2000_M15 = 4;
//C     #define COMMENTH    "%"                 /* comment line indicator for solution */
//C     #define MSG_DISCONN "$_DISCONNECT\r\n"  /* disconnect message */

//C     #define DLOPT_FORCE   0x01              /* download option: force download existing */
//C     #define DLOPT_KEEPCMP 0x02              /* download option: keep compressed file */
const DLOPT_FORCE = 0x01;
//C     #define DLOPT_HOLDERR 0x04              /* download option: hold on error file */
const DLOPT_KEEPCMP = 0x02;
//C     #define DLOPT_HOLDLST 0x08              /* download option: hold on listing file */
const DLOPT_HOLDERR = 0x04;

const DLOPT_HOLDLST = 0x08;
//C     #define P2_5        0.03125             /* 2^-5 */
//C     #define P2_6        0.015625            /* 2^-6 */
const P2_5 = 0.03125;
//C     #define P2_11       4.882812500000000E-04 /* 2^-11 */
const P2_6 = 0.015625;
//C     #define P2_15       3.051757812500000E-05 /* 2^-15 */
const P2_11 = 4.882812500000000E-04;
//C     #define P2_17       7.629394531250000E-06 /* 2^-17 */
const P2_15 = 3.051757812500000E-05;
//C     #define P2_19       1.907348632812500E-06 /* 2^-19 */
const P2_17 = 7.629394531250000E-06;
//C     #define P2_20       9.536743164062500E-07 /* 2^-20 */
const P2_19 = 1.907348632812500E-06;
//C     #define P2_21       4.768371582031250E-07 /* 2^-21 */
const P2_20 = 9.536743164062500E-07;
//C     #define P2_23       1.192092895507810E-07 /* 2^-23 */
const P2_21 = 4.768371582031250E-07;
//C     #define P2_24       5.960464477539063E-08 /* 2^-24 */
const P2_23 = 1.192092895507810E-07;
//C     #define P2_27       7.450580596923828E-09 /* 2^-27 */
const P2_24 = 5.960464477539063E-08;
//C     #define P2_29       1.862645149230957E-09 /* 2^-29 */
const P2_27 = 7.450580596923828E-09;
//C     #define P2_30       9.313225746154785E-10 /* 2^-30 */
const P2_29 = 1.862645149230957E-09;
//C     #define P2_31       4.656612873077393E-10 /* 2^-31 */
const P2_30 = 9.313225746154785E-10;
//C     #define P2_32       2.328306436538696E-10 /* 2^-32 */
const P2_31 = 4.656612873077393E-10;
//C     #define P2_33       1.164153218269348E-10 /* 2^-33 */
const P2_32 = 2.328306436538696E-10;
//C     #define P2_35       2.910383045673370E-11 /* 2^-35 */
const P2_33 = 1.164153218269348E-10;
//C     #define P2_38       3.637978807091710E-12 /* 2^-38 */
const P2_35 = 2.910383045673370E-11;
//C     #define P2_39       1.818989403545856E-12 /* 2^-39 */
const P2_38 = 3.637978807091710E-12;
//C     #define P2_40       9.094947017729280E-13 /* 2^-40 */
const P2_39 = 1.818989403545856E-12;
//C     #define P2_43       1.136868377216160E-13 /* 2^-43 */
const P2_40 = 9.094947017729280E-13;
//C     #define P2_48       3.552713678800501E-15 /* 2^-48 */
const P2_43 = 1.136868377216160E-13;
//C     #define P2_50       8.881784197001252E-16 /* 2^-50 */
const P2_48 = 3.552713678800501E-15;
//C     #define P2_55       2.775557561562891E-17 /* 2^-55 */
const P2_50 = 8.881784197001252E-16;

const P2_55 = 2.775557561562891E-17;
//C     #ifdef WIN32
//C     #define thread_t    HANDLE
//C     #define lock_t      CRITICAL_SECTION
alias HANDLE thread_t;
//C     #define initlock(f) InitializeCriticalSection(f)
alias CRITICAL_SECTION lock_t;
//C     #define lock(f)     EnterCriticalSection(f)
//C     #define unlock(f)   LeaveCriticalSection(f)
//C     #define FILEPATHSEP '\\'
//C     #else
//C     #define thread_t    pthread_t
//C     #define lock_t      pthread_mutex_t
//C     #define initlock(f) pthread_mutex_init(f,NULL)
//C     #define lock(f)     pthread_mutex_lock(f)
//C     #define unlock(f)   pthread_mutex_unlock(f)
//C     #define FILEPATHSEP '/'
//C     #endif

/* type definitions ----------------------------------------------------------*/

//C     typedef struct {        /* time struct */
//C         time_t time;        /* time (s) expressed by standard time_t */
//C         double sec;         /* fraction of second under 1 s */
//C     } gtime_t;
struct _N109
{
    time_t time;
    double sec;
}
extern (C):
alias _N109 gtime_t;

//C     typedef struct {        /* observation data record */
//C         gtime_t time;       /* receiver sampling time (GPST) */
//C         unsigned char sat,rcv; /* satellite/receiver number */
//C         unsigned char SNR [NFREQ+NEXOBS]; /* signal strength (0.25 dBHz) */
//C         unsigned char LLI [NFREQ+NEXOBS]; /* loss of lock indicator */
//C         unsigned char code[NFREQ+NEXOBS]; /* code indicator (CODE_???) */
//C         double L[NFREQ+NEXOBS]; /* observation data carrier-phase (cycle) */
//C         double P[NFREQ+NEXOBS]; /* observation data pseudorange (m) */
//C         float  D[NFREQ+NEXOBS]; /* observation data doppler frequency (Hz) */
//C     } obsd_t;
struct _N110
{
    gtime_t time;
    ubyte sat;
    ubyte rcv;
    ubyte [3]SNR;
    ubyte [3]LLI;
    ubyte [3]code;
    double [3]L;
    double [3]P;
    float [3]D;
}
alias _N110 obsd_t;

//C     typedef struct {        /* observation data */
//C         int n,nmax;         /* number of obervation data/allocated */
//C         obsd_t *data;       /* observation data records */
//C     } obs_t;
struct _N111
{
    int n;
    int nmax;
    obsd_t *data;
}
alias _N111 obs_t;

//C     typedef struct {        /* earth rotation parameter data type */
//C         double mjd;         /* mjd (days) */
//C         double xp,yp;       /* pole offset (rad) */
//C         double xpr,ypr;     /* pole offset rate (rad/day) */
//C         double ut1_utc;     /* ut1-utc (s) */
//C         double lod;         /* length of day (s/day) */
//C     } erpd_t;
struct _N112
{
    double mjd;
    double xp;
    double yp;
    double xpr;
    double ypr;
    double ut1_utc;
    double lod;
}
alias _N112 erpd_t;

//C     typedef struct {        /* earth rotation parameter type */
//C         int n,nmax;         /* number and max number of data */
//C         erpd_t *data;       /* earth rotation parameter data */
//C     } erp_t;
struct _N113
{
    int n;
    int nmax;
    erpd_t *data;
}
alias _N113 erp_t;

//C     typedef struct {        /* antenna parameter type */
//C         int sat;            /* satellite number (0:receiver) */
//C         char type[MAXANT];  /* antenna type */
//C         char code[MAXANT];  /* serial number or satellite code */
//C         gtime_t ts,te;      /* valid time start and end */
//C         double off[NFREQ][ 3]; /* phase center offset e/n/u or x/y/z (m) */
//C         double var[NFREQ][19]; /* phase center variation (m) */
                        /* el=90,85,...,0 or nadir=0,1,2,3,... (deg) */
//C     } pcv_t;
struct _N114
{
    int sat;
    char [64]type;
    char [64]code;
    gtime_t ts;
    gtime_t te;
    double [3][3]off;
    double [19][3]var;
}
alias _N114 pcv_t;

//C     typedef struct {        /* antenna parameters type */
//C         int n,nmax;         /* number of data/allocated */
//C         pcv_t *pcv;         /* antenna parameters data */
//C     } pcvs_t;
struct _N115
{
    int n;
    int nmax;
    pcv_t *pcv;
}
alias _N115 pcvs_t;

//C     typedef struct {        /* almanac type */
//C         int sat;            /* satellite number */
//C         int svh;            /* sv health (0:ok) */
//C         int svconf;         /* as and sv config */
//C         int week;           /* GPS/QZS: gps week, GAL: galileo week */
//C         gtime_t toa;        /* Toa */
                        /* SV orbit parameters */
//C         double A,e,i0,OMG0,omg,M0,OMGd;
//C         double toas;        /* Toa (s) in week */
//C         double f0,f1;       /* SV clock parameters (af0,af1) */
//C     } alm_t;
struct _N116
{
    int sat;
    int svh;
    int svconf;
    int week;
    gtime_t toa;
    double A;
    double e;
    double i0;
    double OMG0;
    double omg;
    double M0;
    double OMGd;
    double toas;
    double f0;
    double f1;
}
alias _N116 alm_t;

//C     typedef struct {        /* GPS/QZS/GAL broadcast ephemeris type */
//C         int sat;            /* satellite number */
//C         int iode,iodc;      /* IODE,IODC */
//C         int sva;            /* SV accuracy (URA index) */
//C         int svh;            /* SV health (0:ok) */
//C         int week;           /* GPS/QZS: gps week, GAL: galileo week */
//C         int code;           /* GPS/QZS: code on L2, GAL/CMP: data sources */
//C         int flag;           /* GPS/QZS: L2 P data flag, CMP: nav type */
//C         gtime_t toe,toc,ttr; /* Toe,Toc,T_trans */
                        /* SV orbit parameters */
//C         double A,e,i0,OMG0,omg,M0,deln,OMGd,idot;
//C         double crc,crs,cuc,cus,cic,cis;
//C         double toes;        /* Toe (s) in week */
//C         double fit;         /* fit interval (h) */
//C         double f0,f1,f2;    /* SV clock parameters (af0,af1,af2) */
//C         double tgd[4];      /* group delay parameters */
                        /* GPS/QZS:tgd[0]=TGD */
                        /* GAL    :tgd[0]=BGD E5a/E1,tgd[1]=BGD E5b/E1 */
                        /* CMP    :tgd[0]=BGD1,tgd[1]=BGD2 */
//C     	double tow;         /* time of week of ephemeris (s) (added for SDR) */
//C     	int cnt;            /* ephemeris decoded counter (added for SDR) */
//C     	int update;         /* ephemeris update flag (added for SDR) */
//C     } eph_t;
struct _N117
{
    int sat;
    int iode;
    int iodc;
    int sva;
    int svh;
    int week;
    int code;
    int flag;
    gtime_t toe;
    gtime_t toc;
    gtime_t ttr;
    double A;
    double e;
    double i0;
    double OMG0;
    double omg;
    double M0;
    double deln;
    double OMGd;
    double idot;
    double crc;
    double crs;
    double cuc;
    double cus;
    double cic;
    double cis;
    double toes;
    double fit;
    double f0;
    double f1;
    double f2;
    double [4]tgd;
    double tow;
    int cnt;
    int update;
}
alias _N117 eph_t;

//C     typedef struct {        /* GLONASS broadcast ephemeris type */
//C         int sat;            /* satellite number */
//C         int iode;           /* IODE (0-6 bit of tb field) */
//C         int frq;            /* satellite frequency number */
//C         int svh,sva,age;    /* satellite health, accuracy, age of operation */
//C         gtime_t toe;        /* epoch of epherides (gpst) */
//C         gtime_t tof;        /* message frame time (gpst) */
//C         double pos[3];      /* satellite position (ecef) (m) */
//C         double vel[3];      /* satellite velocity (ecef) (m/s) */
//C         double acc[3];      /* satellite acceleration (ecef) (m/s^2) */
//C         double taun,gamn;   /* SV clock bias (s)/relative freq bias */
//C         double dtaun;       /* delay between L1 and L2 (s) */
//C     } geph_t;
struct _N118
{
    int sat;
    int iode;
    int frq;
    int svh;
    int sva;
    int age;
    gtime_t toe;
    gtime_t tof;
    double [3]pos;
    double [3]vel;
    double [3]acc;
    double taun;
    double gamn;
    double dtaun;
}
alias _N118 geph_t;

//C     typedef struct {        /* precise ephemeris type */
//C         gtime_t time;       /* time (GPST) */
//C         int index;          /* ephemeris index for multiple files */
//C         double pos[MAXSAT][4]; /* satellite position/clock (ecef) (m|s) */
//C         float  std[MAXSAT][4]; /* satellite position/clock std (m|s) */
//C     } peph_t;
struct _N119
{
    gtime_t time;
    int index;
    double [4][109]pos;
    float [4][109]std;
}
alias _N119 peph_t;

//C     typedef struct {        /* precise clock type */
//C         gtime_t time;       /* time (GPST) */
//C         int index;          /* clock index for multiple files */
//C         double clk[MAXSAT][1]; /* satellite clock (s) */
//C         float  std[MAXSAT][1]; /* satellite clock std (s) */
//C     } pclk_t;
struct _N120
{
    gtime_t time;
    int index;
    double [1][109]clk;
    float [1][109]std;
}
alias _N120 pclk_t;

//C     typedef struct {        /* SBAS ephemeris type */
//C         int sat;            /* satellite number */
//C         gtime_t t0;         /* reference epoch time (GPST) */
//C         gtime_t tof;        /* time of message frame (GPST) */
//C         int sva;            /* SV accuracy (URA index) */
//C         int svh;            /* SV health (0:ok) */
//C         double pos[3];      /* satellite position (m) (ecef) */
//C         double vel[3];      /* satellite velocity (m/s) (ecef) */
//C         double acc[3];      /* satellite acceleration (m/s^2) (ecef) */
//C         double af0,af1;     /* satellite clock-offset/drift (s,s/s) */
//C     } seph_t;
struct _N121
{
    int sat;
    gtime_t t0;
    gtime_t tof;
    int sva;
    int svh;
    double [3]pos;
    double [3]vel;
    double [3]acc;
    double af0;
    double af1;
}
alias _N121 seph_t;

//C     typedef struct {        /* norad two line element data type */
//C         char name [32];     /* common name */
//C         char alias[32];     /* alias name */
//C         char satno[16];     /* satellilte catalog number */
//C         char satclass;      /* classification */
//C         char desig[16];     /* international designator */
//C         gtime_t epoch;      /* element set epoch (UTC) */
//C         double ndot;        /* 1st derivative of mean motion */
//C         double nddot;       /* 2st derivative of mean motion */
//C         double bstar;       /* B* drag term */
//C         int etype;          /* element set type */
//C         int eleno;          /* element number */
//C         double inc;         /* orbit inclination (deg) */
//C         double OMG;         /* right ascension of ascending node (deg) */
//C         double ecc;         /* eccentricity */
//C         double omg;         /* argument of perigee (deg) */
//C         double M;           /* mean anomaly (deg) */
//C         double n;           /* mean motion (rev/day) */
//C         int rev;            /* revolution number at epoch */
//C     } tled_t;
struct _N122
{
    char [32]name;
    char [32]alias_;
    char [16]satno;
    char satclass;
    char [16]desig;
    gtime_t epoch;
    double ndot;
    double nddot;
    double bstar;
    int etype;
    int eleno;
    double inc;
    double OMG;
    double ecc;
    double omg;
    double M;
    double n;
    int rev;
}
alias _N122 tled_t;

//C     typedef struct {        /* norad two line element type */
//C         int n,nmax;         /* number/max number of two line element data */
//C         tled_t *data;       /* norad two line element data */
//C     } tle_t;
struct _N123
{
    int n;
    int nmax;
    tled_t *data;
}
alias _N123 tle_t;

//C     typedef struct {        /* TEC grid type */
//C         gtime_t time;       /* epoch time (GPST) */
//C         int ndata[3];       /* TEC grid data size {nlat,nlon,nhgt} */
//C         double rb;          /* earth radius (km) */
//C         double lats[3];     /* latitude start/interval (deg) */
//C         double lons[3];     /* longitude start/interval (deg) */
//C         double hgts[3];     /* heights start/interval (km) */
//C         double *data;       /* TEC grid data (tecu) */
//C         float *rms;         /* RMS values (tecu) */
//C     } tec_t;
struct _N124
{
    gtime_t time;
    int [3]ndata;
    double rb;
    double [3]lats;
    double [3]lons;
    double [3]hgts;
    double *data;
    float *rms;
}
alias _N124 tec_t;

//C     typedef struct {        /* stec data type */
//C         gtime_t time;       /* time (GPST) */
//C         unsigned char sat;  /* satellite number */
//C         unsigned char slip; /* slip flag */
//C         float iono;         /* L1 ionosphere delay (m) */
//C         float rate;         /* L1 ionosphere rate (m/s) */
//C         float rms;          /* rms value (m) */
//C     } stecd_t;
struct _N125
{
    gtime_t time;
    ubyte sat;
    ubyte slip;
    float iono;
    float rate;
    float rms;
}
alias _N125 stecd_t;

//C     typedef struct {        /* stec grid type */
//C         double pos[2];      /* latitude/longitude (deg) */
//C         int index[MAXSAT];  /* search index */
//C         int n,nmax;         /* number of data */
//C         stecd_t *data;      /* stec data */
//C     } stec_t;
struct _N126
{
    double [2]pos;
    int [109]index;
    int n;
    int nmax;
    stecd_t *data;
}
alias _N126 stec_t;

//C     typedef struct {        /* zwd data type */
//C         gtime_t time;       /* time (GPST) */
//C         float zwd;          /* zenith wet delay (m) */
//C         float rms;          /* rms value (m) */
//C     } zwdd_t;
struct _N127
{
    gtime_t time;
    float zwd;
    float rms;
}
alias _N127 zwdd_t;

//C     typedef struct {        /* zwd grid type */
//C         float pos[2];       /* latitude,longitude (rad) */
//C         int n,nmax;         /* number of data */
//C         zwdd_t *data;       /* zwd data */
//C     } zwd_t;
struct _N128
{
    float [2]pos;
    int n;
    int nmax;
    zwdd_t *data;
}
alias _N128 zwd_t;

//C     typedef struct {        /* SBAS message type */
//C         int week,tow;       /* receiption time */
//C         int prn;            /* SBAS satellite PRN number */
//C         unsigned char msg[29]; /* SBAS message (226bit) padded by 0 */
//C     } sbsmsg_t;
struct _N129
{
    int week;
    int tow;
    int prn;
    ubyte [29]msg;
}
alias _N129 sbsmsg_t;

//C     typedef struct {        /* SBAS messages type */
//C         int n,nmax;         /* number of SBAS messages/allocated */
//C         sbsmsg_t *msgs;     /* SBAS messages */
//C     } sbs_t;
struct _N130
{
    int n;
    int nmax;
    sbsmsg_t *msgs;
}
alias _N130 sbs_t;

//C     typedef struct {        /* SBAS fast correction type */
//C         gtime_t t0;         /* time of applicability (TOF) */
//C         double prc;         /* pseudorange correction (PRC) (m) */
//C         double rrc;         /* range-rate correction (RRC) (m/s) */
//C         double dt;          /* range-rate correction delta-time (s) */
//C         int iodf;           /* IODF (issue of date fast corr) */
//C         short udre;         /* UDRE+1 */
//C         short ai;           /* degradation factor indicator */
//C     } sbsfcorr_t;
struct _N131
{
    gtime_t t0;
    double prc;
    double rrc;
    double dt;
    int iodf;
    short udre;
    short ai;
}
alias _N131 sbsfcorr_t;

//C     typedef struct {        /* SBAS long term satellite error correction type */
//C         gtime_t t0;         /* correction time */
//C         int iode;           /* IODE (issue of date ephemeris) */
//C         double dpos[3];     /* delta position (m) (ecef) */
//C         double dvel[3];     /* delta velocity (m/s) (ecef) */
//C         double daf0,daf1;   /* delta clock-offset/drift (s,s/s) */
//C     } sbslcorr_t;
struct _N132
{
    gtime_t t0;
    int iode;
    double [3]dpos;
    double [3]dvel;
    double daf0;
    double daf1;
}
alias _N132 sbslcorr_t;

//C     typedef struct {        /* SBAS satellite correction type */
//C         int sat;            /* satellite number */
//C         sbsfcorr_t fcorr;   /* fast correction */
//C         sbslcorr_t lcorr;   /* long term correction */
//C     } sbssatp_t;
struct _N133
{
    int sat;
    sbsfcorr_t fcorr;
    sbslcorr_t lcorr;
}
alias _N133 sbssatp_t;

//C     typedef struct {        /* SBAS satellite corrections type */
//C         int iodp;           /* IODP (issue of date mask) */
//C         int nsat;           /* number of satellites */
//C         int tlat;           /* system latency (s) */
//C         sbssatp_t sat[MAXSAT]; /* satellite correction */
//C     } sbssat_t;
struct _N134
{
    int iodp;
    int nsat;
    int tlat;
    sbssatp_t [109]sat;
}
alias _N134 sbssat_t;

//C     typedef struct {        /* SBAS ionospheric correction type */
//C         gtime_t t0;         /* correction time */
//C         short lat,lon;      /* latitude/longitude (deg) */
//C         short give;         /* GIVI+1 */
//C         float delay;        /* vertical delay estimate (m) */
//C     } sbsigp_t;
struct _N135
{
    gtime_t t0;
    short lat;
    short lon;
    short give;
    float delay;
}
alias _N135 sbsigp_t;

//C     typedef struct {        /* IGP band type */
//C         short x;            /* longitude/latitude (deg) */
//C         const short *y;     /* latitudes/longitudes (deg) */
//C         unsigned char bits; /* IGP mask start bit */
//C         unsigned char bite; /* IGP mask end bit */
//C     } sbsigpband_t;
struct _N136
{
    short x;
    short *y;
    ubyte bits;
    ubyte bite;
}
alias _N136 sbsigpband_t;

//C     typedef struct {        /* SBAS ionospheric corrections type */
//C         int iodi;           /* IODI (issue of date ionos corr) */
//C         int nigp;           /* number of igps */
//C         sbsigp_t igp[MAXNIGP]; /* ionospheric correction */
//C     } sbsion_t;
struct _N137
{
    int iodi;
    int nigp;
    sbsigp_t [201]igp;
}
alias _N137 sbsion_t;

//C     typedef struct {        /* DGPS/GNSS correction type */
//C         gtime_t t0;         /* correction time */
//C         double prc;         /* pseudorange correction (PRC) (m) */
//C         double rrc;         /* range rate correction (RRC) (m/s) */
//C         int iod;            /* issue of data (IOD) */
//C         double udre;        /* UDRE */
//C     } dgps_t;
struct _N138
{
    gtime_t t0;
    double prc;
    double rrc;
    int iod;
    double udre;
}
alias _N138 dgps_t;

//C     typedef struct {        /* SSR correction type */
//C         gtime_t t0[5];      /* epoch time (GPST) {eph,clk,hrclk,ura,bias} */
//C         double udi[5];      /* SSR update interval (s) */
//C         int iod[5];         /* iod ssr {eph,clk,hrclk,ura,bias} */
//C         int iode;           /* issue of data */
//C         int ura;            /* URA indicator */
//C         int refd;           /* sat ref datum (0:ITRF,1:regional) */
//C         double deph [3];    /* delta orbit {radial,along,cross} (m) */
//C         double ddeph[3];    /* dot delta orbit {radial,along,cross} (m/s) */
//C         double dclk [3];    /* delta clock {c0,c1,c2} (m,m/s,m/s^2) */
//C         double hrclk;       /* high-rate clock corection (m) */
//C         float cbias[MAXCODE]; /* code biases (m) */
//C         unsigned char update; /* update flag (0:no update,1:update) */
//C     } ssr_t;
struct _N139
{
    gtime_t [5]t0;
    double [5]udi;
    int [5]iod;
    int iode;
    int ura;
    int refd;
    double [3]deph;
    double [3]ddeph;
    double [3]dclk;
    double hrclk;
    float [46]cbias;
    ubyte update;
}
alias _N139 ssr_t;

//C     typedef struct {        /* QZSS LEX message type */
//C         int prn;            /* satellite PRN number */
//C         int type;           /* message type */
//C         int alert;          /* alert flag */
//C         unsigned char stat; /* signal tracking status */
//C         unsigned char snr;  /* signal C/N0 (0.25 dBHz) */
//C         unsigned int ttt;   /* tracking time (ms) */
//C         unsigned char msg[212]; /* LEX message data part 1695 bits */
//C     } lexmsg_t;
struct _N140
{
    int prn;
    int type;
    int alert;
    ubyte stat;
    ubyte snr;
    uint ttt;
    ubyte [212]msg;
}
alias _N140 lexmsg_t;

//C     typedef struct {        /* QZSS LEX messages type */
//C         int n,nmax;         /* number of LEX messages and allocated */
//C         lexmsg_t *msgs;     /* LEX messages */
//C     } lex_t;
struct _N141
{
    int n;
    int nmax;
    lexmsg_t *msgs;
}
alias _N141 lex_t;

//C     typedef struct {        /* QZSS LEX ephemeris type */
//C         gtime_t toe;        /* epoch time (GPST) */
//C         gtime_t tof;        /* message frame time (GPST) */
//C         int sat;            /* satellite number */
//C         unsigned char health; /* signal health (L1,L2,L1C,L5,LEX) */
//C         unsigned char ura;  /* URA index */
//C         double pos[3];      /* satellite position (m) */
//C         double vel[3];      /* satellite velocity (m/s) */
//C         double acc[3];      /* satellite acceleration (m/s2) */
//C         double jerk[3];     /* satellite jerk (m/s3) */
//C         double af0,af1;     /* satellite clock bias and drift (s,s/s) */
//C         double tgd;         /* TGD */
//C         double isc[8];      /* ISC */
//C     } lexeph_t;
struct _N142
{
    gtime_t toe;
    gtime_t tof;
    int sat;
    ubyte health;
    ubyte ura;
    double [3]pos;
    double [3]vel;
    double [3]acc;
    double [3]jerk;
    double af0;
    double af1;
    double tgd;
    double [8]isc;
}
alias _N142 lexeph_t;

//C     typedef struct {        /* QZSS LEX ionosphere correction type */
//C         gtime_t t0;         /* epoch time (GPST) */
//C         double tspan;       /* valid time span (s) */
//C         double pos0[2];     /* reference position {lat,lon} (rad) */
//C         double coef[3][2];  /* coefficients lat x lon (3 x 2) */
//C     } lexion_t;
struct _N143
{
    gtime_t t0;
    double tspan;
    double [2]pos0;
    double [2][3]coef;
}
alias _N143 lexion_t;

//C     typedef struct {        /* navigation data type */
//C         int n,nmax;         /* number of broadcast ephemeris */
//C         int ng,ngmax;       /* number of glonass ephemeris */
//C         int ns,nsmax;       /* number of sbas ephemeris */
//C         int ne,nemax;       /* number of precise ephemeris */
//C         int nc,ncmax;       /* number of precise clock */
//C         int na,namax;       /* number of almanac data */
//C         int nt,ntmax;       /* number of tec grid data */
//C         int nn,nnmax;       /* number of stec grid data */
//C         eph_t *eph;         /* GPS/QZS/GAL ephemeris */
//C         geph_t *geph;       /* GLONASS ephemeris */
//C         seph_t *seph;       /* SBAS ephemeris */
//C         peph_t *peph;       /* precise ephemeris */
//C         pclk_t *pclk;       /* precise clock */
//C         alm_t *alm;         /* almanac data */
//C         tec_t *tec;         /* tec grid data */
//C         stec_t *stec;       /* stec grid data */
//C         erp_t  erp;         /* earth rotation parameters */
//C         double utc_gps[4];  /* GPS delta-UTC parameters {A0,A1,T,W} */
//C         double utc_glo[4];  /* GLONASS UTC GPS time parameters */
//C         double utc_gal[4];  /* Galileo UTC GPS time parameters */
//C         double utc_qzs[4];  /* QZS UTC GPS time parameters */
//C         double utc_cmp[4];  /* BeiDou UTC parameters */
//C         double utc_sbs[4];  /* SBAS UTC parameters */
//C         double ion_gps[8];  /* GPS iono model parameters {a0,a1,a2,a3,b0,b1,b2,b3} */
//C         double ion_gal[4];  /* Galileo iono model parameters {ai0,ai1,ai2,0} */
//C         double ion_qzs[8];  /* QZSS iono model parameters {a0,a1,a2,a3,b0,b1,b2,b3} */
//C         double ion_cmp[8];  /* BeiDou iono model parameters {a0,a1,a2,a3,b0,b1,b2,b3} */
//C         int leaps;          /* leap seconds (s) */
//C         double lam[MAXSAT][NFREQ]; /* carrier wave lengths (m) */
//C         double cbias[MAXSAT][3];   /* code bias (0:p1-p2,1:p1-c1,2:p2-c2) (m) */
//C         double wlbias[MAXSAT];     /* wide-lane bias (cycle) */
//C         double glo_cpbias[4];    /* glonass code-phase bias {1C,1P,2C,2P} (m) */
//C         char glo_fcn[MAXPRNGLO+1]; /* glonass frequency channel number + 8 */
//C         pcv_t pcvs[MAXSAT]; /* satellite antenna pcv */
//C         sbssat_t sbssat;    /* SBAS satellite corrections */
//C         sbsion_t sbsion[MAXBAND+1]; /* SBAS ionosphere corrections */
//C         dgps_t dgps[MAXSAT]; /* DGPS corrections */
//C         ssr_t ssr[MAXSAT];  /* SSR corrections */
//C         lexeph_t lexeph[MAXSAT]; /* LEX ephemeris */
//C         lexion_t lexion;    /* LEX ionosphere correction */
//C     } nav_t;
struct _N144
{
    int n;
    int nmax;
    int ng;
    int ngmax;
    int ns;
    int nsmax;
    int ne;
    int nemax;
    int nc;
    int ncmax;
    int na;
    int namax;
    int nt;
    int ntmax;
    int nn;
    int nnmax;
    eph_t *eph;
    geph_t *geph;
    seph_t *seph;
    peph_t *peph;
    pclk_t *pclk;
    alm_t *alm;
    tec_t *tec;
    stec_t *stec;
    erp_t erp;
    double [4]utc_gps;
    double [4]utc_glo;
    double [4]utc_gal;
    double [4]utc_qzs;
    double [4]utc_cmp;
    double [4]utc_sbs;
    double [8]ion_gps;
    double [4]ion_gal;
    double [8]ion_qzs;
    double [8]ion_cmp;
    int leaps;
    double [3][109]lam;
    double [3][109]cbias;
    double [109]wlbias;
    double [4]glo_cpbias;
    char [25]glo_fcn;
    pcv_t [109]pcvs;
    sbssat_t sbssat;
    sbsion_t [11]sbsion;
    dgps_t [109]dgps;
    ssr_t [109]ssr;
    lexeph_t [109]lexeph;
    lexion_t lexion;
}
alias _N144 nav_t;

//C     typedef struct {        /* station parameter type */
//C         char name   [MAXANT]; /* marker name */
//C         char marker [MAXANT]; /* marker number */
//C         char antdes [MAXANT]; /* antenna descriptor */
//C         char antsno [MAXANT]; /* antenna serial number */
//C         char rectype[MAXANT]; /* receiver type descriptor */
//C         char recver [MAXANT]; /* receiver firmware version */
//C         char recsno [MAXANT]; /* receiver serial number */
//C         int antsetup;       /* antenna setup id */
//C         int itrf;           /* ITRF realization year */
//C         int deltype;        /* antenna delta type (0:enu,1:xyz) */
//C         double pos[3];      /* station position (ecef) (m) */
//C         double del[3];      /* antenna position delta (e/n/u or x/y/z) (m) */
//C         double hgt;         /* antenna height (m) */
//C     } sta_t;
struct _N145
{
    char [64]name;
    char [64]marker;
    char [64]antdes;
    char [64]antsno;
    char [64]rectype;
    char [64]recver;
    char [64]recsno;
    int antsetup;
    int itrf;
    int deltype;
    double [3]pos;
    double [3]del;
    double hgt;
}
alias _N145 sta_t;

//C     typedef struct {        /* solution type */
//C         gtime_t time;       /* time (GPST) */
//C         double rr[6];       /* position/velocity (m|m/s) */
                        /* {x,y,z,vx,vy,vz} or {e,n,u,ve,vn,vu} */
//C         float  qr[6];       /* position variance/covariance (m^2) */
                        /* {c_xx,c_yy,c_zz,c_xy,c_yz,c_zx} or */
                        /* {c_ee,c_nn,c_uu,c_en,c_nu,c_ue} */
//C         double dtr[6];      /* receiver clock bias to time systems (s) */
//C         unsigned char type; /* type (0:xyz-ecef,1:enu-baseline) */
//C         unsigned char stat; /* solution status (SOLQ_???) */
//C         unsigned char ns;   /* number of valid satellites */
//C         float age;          /* age of differential (s) */
//C         float ratio;        /* AR ratio factor for valiation */
//C     } sol_t;
struct _N146
{
    gtime_t time;
    double [6]rr;
    float [6]qr;
    double [6]dtr;
    ubyte type;
    ubyte stat;
    ubyte ns;
    float age;
    float ratio;
}
alias _N146 sol_t;

//C     typedef struct {        /* solution buffer type */
//C         int n,nmax;         /* number of solution/max number of buffer */
//C         int cyclic;         /* cyclic buffer flag */
//C         int start,end;      /* start/end index */
//C         gtime_t time;       /* current solution time */
//C         sol_t *data;        /* solution data */
//C         double rb[3];       /* reference position {x,y,z} (ecef) (m) */
//C         unsigned char buff[MAXSOLMSG+1]; /* message buffer */
//C         int nb;             /* number of byte in message buffer */
//C     } solbuf_t;
struct _N147
{
    int n;
    int nmax;
    int cyclic;
    int start;
    int end;
    gtime_t time;
    sol_t *data;
    double [3]rb;
    ubyte [4097]buff;
    int nb;
}
alias _N147 solbuf_t;

//C     typedef struct {        /* solution status type */
//C         gtime_t time;       /* time (GPST) */
//C         unsigned char sat;  /* satellite number */
//C         unsigned char frq;  /* frequency (1:L1,2:L2,...) */
//C         float az,el;        /* azimuth/elevation angle (rad) */
//C         float resp;         /* pseudorange residual (m) */
//C         float resc;         /* carrier-phase residual (m) */
//C         unsigned char flag; /* flags: (vsat<<5)+(slip<<3)+fix */
//C         unsigned char snr;  /* signal strength (0.25 dBHz) */
//C         unsigned short lock;  /* lock counter */
//C         unsigned short outc;  /* outage counter */
//C         unsigned short slipc; /* slip counter */
//C         unsigned short rejc;  /* reject counter */
//C     } solstat_t;
struct _N148
{
    gtime_t time;
    ubyte sat;
    ubyte frq;
    float az;
    float el;
    float resp;
    float resc;
    ubyte flag;
    ubyte snr;
    ushort lock;
    ushort outc;
    ushort slipc;
    ushort rejc;
}
alias _N148 solstat_t;

//C     typedef struct {        /* solution status buffer type */
//C         int n,nmax;         /* number of solution/max number of buffer */
//C         solstat_t *data;    /* solution status data */
//C     } solstatbuf_t;
struct _N149
{
    int n;
    int nmax;
    solstat_t *data;
}
alias _N149 solstatbuf_t;

//C     typedef struct {        /* RTCM control struct type */
//C         int staid;          /* station id */
//C         int stah;           /* station health */
//C         int seqno;          /* sequence number for rtcm 2 or iods msm */
//C         int outtype;        /* output message type */
//C         gtime_t time;       /* message time */
//C         gtime_t time_s;     /* message start time */
//C         obs_t obs;          /* observation data (uncorrected) */
//C         nav_t nav;          /* satellite ephemerides */
//C         sta_t sta;          /* station parameters */
//C         dgps_t *dgps;       /* output of dgps corrections */
//C         ssr_t ssr[MAXSAT];  /* output of ssr corrections */
//C         char msg[128];      /* special message */
//C         char msgtype[256];  /* last message type */
//C         char msmtype[6][128]; /* msm signal types */
//C         int obsflag;        /* obs data complete flag (1:ok,0:not complete) */
//C         int ephsat;         /* update satellite of ephemeris */
//C         double cp[MAXSAT][NFREQ+NEXOBS]; /* carrier-phase measurement */
//C         unsigned char lock[MAXSAT][NFREQ+NEXOBS]; /* lock time */
//C         unsigned char loss[MAXSAT][NFREQ+NEXOBS]; /* loss of lock count */
//C         gtime_t lltime[MAXSAT][NFREQ+NEXOBS]; /* last lock time */
//C         int nbyte;          /* number of bytes in message buffer */ 
//C         int nbit;           /* number of bits in word buffer */ 
//C         int len;            /* message length (bytes) */
//C         unsigned char buff[1200]; /* message buffer */
//C         unsigned int word;  /* word buffer for rtcm 2 */
//C         unsigned int nmsg2[100]; /* message count of RTCM 2 (1-99:1-99,0:other) */
//C         unsigned int nmsg3[300]; /* message count of RTCM 3 (1-299:1001-1299,0:ohter) */
//C         char opt[256];      /* RTCM dependent options */
//C     } rtcm_t;
struct _N150
{
    int staid;
    int stah;
    int seqno;
    int outtype;
    gtime_t time;
    gtime_t time_s;
    obs_t obs;
    nav_t nav;
    sta_t sta;
    dgps_t *dgps;
    ssr_t [109]ssr;
    char [128]msg;
    char [256]msgtype;
    char [128][6]msmtype;
    int obsflag;
    int ephsat;
    double [3][109]cp;
    ubyte [3][109]lock;
    ubyte [3][109]loss;
    gtime_t [3][109]lltime;
    int nbyte;
    int nbit;
    int len;
    ubyte [1200]buff;
    uint word;
    uint [100]nmsg2;
    uint [300]nmsg3;
    char [256]opt;
}
alias _N150 rtcm_t;

//C     typedef struct {        /* rinex control struct type */
//C         gtime_t time;       /* message time */
//C         double ver;         /* rinex version */
//C         char   type;        /* rinex file type ('O','N',...) */
//C         int    sys;         /* navigation system */
//C         int    tsys;        /* time system */
//C         char   tobs[6][MAXOBSTYPE][4]; /* rinex obs types */
//C         obs_t  obs;         /* observation data */
//C         nav_t  nav;         /* navigation data */
//C         sta_t  sta;         /* station info */
//C         int    ephsat;      /* ephemeris satellite number */
//C         char   opt[256];    /* rinex dependent options */
//C     } rnxctr_t;
struct _N151
{
    gtime_t time;
    double ver;
    char type;
    int sys;
    int tsys;
    char [4][64][6]tobs;
    obs_t obs;
    nav_t nav;
    sta_t sta;
    int ephsat;
    char [256]opt;
}
alias _N151 rnxctr_t;

//C     typedef struct {        /* download url type */
//C         char type[32];      /* data type */
//C         char path[1024];    /* url path */
//C         char dir [1024];    /* local directory */
//C         double tint;        /* time interval (s) */
//C     } url_t;
struct _N152
{
    char [32]type;
    char [1024]path;
    char [1024]dir;
    double tint;
}
alias _N152 url_t;

//C     typedef struct {        /* option type */
//C         char *name;         /* option name */
//C         int format;         /* option format (0:int,1:double,2:string,3:enum) */
//C         void *var;          /* pointer to option variable */
//C         char *comment;      /* option comment/enum labels/unit */
//C     } opt_t;
struct _N153
{
    char *name;
    int format;
    void *var;
    char *comment;
}
alias _N153 opt_t;

//C     typedef struct {        /* extended receiver error model */
//C         int ena[4];         /* model enabled */
//C         double cerr[4][NFREQ*2]; /* code errors (m) */
//C         double perr[4][NFREQ*2]; /* carrier-phase errors (m) */
//C         double gpsglob[NFREQ]; /* gps-glonass h/w bias (m) */
//C         double gloicb [NFREQ]; /* glonass interchannel bias (m/fn) */
//C     } exterr_t;
struct _N154
{
    int [4]ena;
    double [6][4]cerr;
    double [6][4]perr;
    double [3]gpsglob;
    double [3]gloicb;
}
alias _N154 exterr_t;

//C     typedef struct {        /* SNR mask type */
//C         int ena[2];         /* enable flag {rover,base} */
//C         double mask[NFREQ][9]; /* mask (dBHz) at 5,10,...85 deg */
//C     } snrmask_t;
struct _N155
{
    int [2]ena;
    double [9][3]mask;
}
alias _N155 snrmask_t;

//C     typedef struct {        /* processing options type */
//C         int mode;           /* positioning mode (PMODE_???) */
//C         int soltype;        /* solution type (0:forward,1:backward,2:combined) */
//C         int nf;             /* number of frequencies (1:L1,2:L1+L2,3:L1+L2+L5) */
//C         int navsys;         /* navigation system */
//C         double elmin;       /* elevation mask angle (rad) */
//C         snrmask_t snrmask;  /* SNR mask */
//C         int sateph;         /* satellite ephemeris/clock (EPHOPT_???) */
//C         int modear;         /* AR mode (0:off,1:continuous,2:instantaneous,3:fix and hold,4:ppp-ar) */
//C         int glomodear;      /* GLONASS AR mode (0:off,1:on,2:auto cal,3:ext cal) */
//C         int maxout;         /* obs outage count to reset bias */
//C         int minlock;        /* min lock count to fix ambiguity */
//C         int minfix;         /* min fix count to hold ambiguity */
//C         int ionoopt;        /* ionosphere option (IONOOPT_???) */
//C         int tropopt;        /* troposphere option (TROPOPT_???) */
//C         int dynamics;       /* dynamics model (0:none,1:velociy,2:accel) */
//C         int tidecorr;       /* earth tide correction (0:off,1:solid,2:solid+otl+pole) */
//C         int niter;          /* number of filter iteration */
//C         int codesmooth;     /* code smoothing window size (0:none) */
//C         int intpref;        /* interpolate reference obs (for post mission) */
//C         int sbascorr;       /* SBAS correction options */
//C         int sbassatsel;     /* SBAS satellite selection (0:all) */
//C         int rovpos;         /* rover position for fixed mode */
//C         int refpos;         /* base position for relative mode */
                        /* (0:pos in prcopt,  1:average of single pos, */
                        /*  2:read from file, 3:rinex header, 4:rtcm pos) */
//C         double eratio[NFREQ]; /* code/phase error ratio */
//C         double err[5];      /* measurement error factor */
                        /* [0]:reserved */
                        /* [1-3]:error factor a/b/c of phase (m) */
                        /* [4]:doppler frequency (hz) */
//C         double std[3];      /* initial-state std [0]bias,[1]iono [2]trop */
//C         double prn[5];      /* process-noise std [0]bias,[1]iono [2]trop [3]acch [4]accv */
//C         double sclkstab;    /* satellite clock stability (sec/sec) */
//C         double thresar[4];  /* AR validation threshold */
//C         double elmaskar;    /* elevation mask of AR for rising satellite (deg) */
//C         double elmaskhold;  /* elevation mask to hold ambiguity (deg) */
//C         double thresslip;   /* slip threshold of geometry-free phase (m) */
//C         double maxtdiff;    /* max difference of time (sec) */
//C         double maxinno;     /* reject threshold of innovation (m) */
//C         double maxgdop;     /* reject threshold of gdop */
//C         double baseline[2]; /* baseline length constraint {const,sigma} (m) */
//C         double ru[3];       /* rover position for fixed mode {x,y,z} (ecef) (m) */
//C         double rb[3];       /* base position for relative mode {x,y,z} (ecef) (m) */
//C         char anttype[2][MAXANT]; /* antenna types {rover,base} */
//C         double antdel[2][3]; /* antenna delta {{rov_e,rov_n,rov_u},{ref_e,ref_n,ref_u}} */
//C         pcv_t pcvr[2];      /* receiver antenna parameters {rov,base} */
//C         unsigned char exsats[MAXSAT]; /* excluded satellites (1:excluded,2:included) */
//C         char rnxopt[2][256]; /* rinex options {rover,base} */
//C         int  posopt[6];     /* positioning options */
//C         int  syncsol;       /* solution sync mode (0:off,1:on) */
//C         double odisp[2][6*11]; /* ocean tide loading parameters {rov,base} */
//C         exterr_t exterr;    /* extended receiver error model */
//C     } prcopt_t;
struct _N156
{
    int mode;
    int soltype;
    int nf;
    int navsys;
    double elmin;
    snrmask_t snrmask;
    int sateph;
    int modear;
    int glomodear;
    int maxout;
    int minlock;
    int minfix;
    int ionoopt;
    int tropopt;
    int dynamics;
    int tidecorr;
    int niter;
    int codesmooth;
    int intpref;
    int sbascorr;
    int sbassatsel;
    int rovpos;
    int refpos;
    double [3]eratio;
    double [5]err;
    double [3]std;
    double [5]prn;
    double sclkstab;
    double [4]thresar;
    double elmaskar;
    double elmaskhold;
    double thresslip;
    double maxtdiff;
    double maxinno;
    double maxgdop;
    double [2]baseline;
    double [3]ru;
    double [3]rb;
    char [64][2]anttype;
    double [3][2]antdel;
    pcv_t [2]pcvr;
    ubyte [109]exsats;
    char [256][2]rnxopt;
    int [6]posopt;
    int syncsol;
    double [66][2]odisp;
    exterr_t exterr;
}
alias _N156 prcopt_t;

//C     typedef struct {        /* solution options type */
//C         int posf;           /* solution format (SOLF_???) */
//C         int times;          /* time system (TIMES_???) */
//C         int timef;          /* time format (0:sssss.s,1:yyyy/mm/dd hh:mm:ss.s) */
//C         int timeu;          /* time digits under decimal point */
//C         int degf;           /* latitude/longitude format (0:ddd.ddd,1:ddd mm ss) */
//C         int outhead;        /* output header (0:no,1:yes) */
//C         int outopt;         /* output processing options (0:no,1:yes) */
//C         int datum;          /* datum (0:WGS84,1:Tokyo) */
//C         int height;         /* height (0:ellipsoidal,1:geodetic) */
//C         int geoid;          /* geoid model (0:EGM96,1:JGD2000) */
//C         int solstatic;      /* solution of static mode (0:all,1:single) */
//C         int sstat;          /* solution statistics level (0:off,1:states,2:residuals) */
//C         int trace;          /* debug trace level (0:off,1-5:debug) */
//C         double nmeaintv[2]; /* nmea output interval (s) (<0:no,0:all) */
                        /* nmeaintv[0]:gprmc,gpgga,nmeaintv[1]:gpgsv */
//C         char sep[64];       /* field separator */
//C         char prog[64];      /* program name */
//C     } solopt_t;
struct _N157
{
    int posf;
    int times;
    int timef;
    int timeu;
    int degf;
    int outhead;
    int outopt;
    int datum;
    int height;
    int geoid;
    int solstatic;
    int sstat;
    int trace;
    double [2]nmeaintv;
    char [64]sep;
    char [64]prog;
}
alias _N157 solopt_t;

//C     typedef struct {        /* file options type */
//C         char satantp[MAXSTRPATH]; /* satellite antenna parameters file */
//C         char rcvantp[MAXSTRPATH]; /* receiver antenna parameters file */
//C         char stapos [MAXSTRPATH]; /* station positions file */
//C         char geoid  [MAXSTRPATH]; /* external geoid data file */
//C         char iono   [MAXSTRPATH]; /* ionosphere data file */
//C         char dcb    [MAXSTRPATH]; /* dcb data file */
//C         char eop    [MAXSTRPATH]; /* eop data file */
//C         char blq    [MAXSTRPATH]; /* ocean tide loading blq file */
//C         char tempdir[MAXSTRPATH]; /* ftp/http temporaly directory */
//C         char geexe  [MAXSTRPATH]; /* google earth exec file */
//C         char solstat[MAXSTRPATH]; /* solution statistics file */
//C         char trace  [MAXSTRPATH]; /* debug trace file */
//C     } filopt_t;
struct _N158
{
    char [1024]satantp;
    char [1024]rcvantp;
    char [1024]stapos;
    char [1024]geoid;
    char [1024]iono;
    char [1024]dcb;
    char [1024]eop;
    char [1024]blq;
    char [1024]tempdir;
    char [1024]geexe;
    char [1024]solstat;
    char [1024]trace;
}
alias _N158 filopt_t;

//C     typedef struct {        /* RINEX options type */
//C         gtime_t ts,te;      /* time start/end */
//C         double tint;        /* time interval (s) */
//C         double tunit;       /* time unit for multiple-session (s) */
//C         double rnxver;      /* RINEX version */
//C         int navsys;         /* navigation system */
//C         int obstype;        /* observation type */
//C         int freqtype;       /* frequency type */
//C         char mask[6][64];   /* code mask {GPS,GLO,GAL,QZS,SBS,CMP} */
//C         char staid [32];    /* station id for rinex file name */
//C         char prog  [32];    /* program */
//C         char runby [32];    /* run-by */
//C         char marker[64];    /* marker name */
//C         char markerno[32];  /* marker number */
//C         char markertype[32]; /* marker type (ver.3) */
//C         char name[2][32];   /* observer/agency */
//C         char rec [3][32];   /* receiver #/type/vers */
//C         char ant [3][32];   /* antenna #/type */
//C         double apppos[3];   /* approx position x/y/z */
//C         double antdel[3];   /* antenna delta h/e/n */
//C         char comment[MAXCOMMENT][64]; /* comments */
//C         char rcvopt[256];   /* receiver dependent options */
//C         unsigned char exsats[MAXSAT]; /* excluded satellites */
//C         int scanobs;        /* scan obs types */
//C         int outiono;        /* output iono correction */
//C         int outtime;        /* output time system correction */
//C         int outleaps;       /* output leap seconds */
//C         int autopos;        /* auto approx position */
//C         gtime_t tstart;     /* first obs time */
//C         gtime_t tend;       /* last obs time */
//C         gtime_t trtcm;      /* approx log start time for rtcm */
//C         char tobs[6][MAXOBSTYPE][4]; /* obs types {GPS,GLO,GAL,QZS,SBS,CMP} */
//C         int nobs[6];        /* number of obs types {GPS,GLO,GAL,QZS,SBS,CMP} */
//C     } rnxopt_t;
struct _N159
{
    gtime_t ts;
    gtime_t te;
    double tint;
    double tunit;
    double rnxver;
    int navsys;
    int obstype;
    int freqtype;
    char [64][6]mask;
    char [32]staid;
    char [32]prog;
    char [32]runby;
    char [64]marker;
    char [32]markerno;
    char [32]markertype;
    char [32][2]name;
    char [32][3]rec;
    char [32][3]ant;
    double [3]apppos;
    double [3]antdel;
    char [64][10]comment;
    char [256]rcvopt;
    ubyte [109]exsats;
    int scanobs;
    int outiono;
    int outtime;
    int outleaps;
    int autopos;
    gtime_t tstart;
    gtime_t tend;
    gtime_t trtcm;
    char [4][64][6]tobs;
    int [6]nobs;
}
alias _N159 rnxopt_t;

//C     typedef struct {        /* satellite status type */
//C         unsigned char sys;  /* navigation system */
//C         unsigned char vs;   /* valid satellite flag single */
//C         double azel[2];     /* azimuth/elevation angles {az,el} (rad) */
//C         double resp[NFREQ]; /* residuals of pseudorange (m) */
//C         double resc[NFREQ]; /* residuals of carrier-phase (m) */
//C         unsigned char vsat[NFREQ]; /* valid satellite flag */
//C         unsigned char snr [NFREQ]; /* signal strength (0.25 dBHz) */
//C         unsigned char fix [NFREQ]; /* ambiguity fix flag (1:fix,2:float,3:hold) */
//C         unsigned char slip[NFREQ]; /* cycle-slip flag */
//C         unsigned int lock [NFREQ]; /* lock counter of phase */
//C         unsigned int outc [NFREQ]; /* obs outage counter of phase */
//C         unsigned int slipc[NFREQ]; /* cycle-slip counter */
//C         unsigned int rejc [NFREQ]; /* reject counter */
//C         double  gf;         /* geometry-free phase L1-L2 (m) */
//C         double  gf2;        /* geometry-free phase L1-L5 (m) */
//C         double  phw;        /* phase windup (cycle) */
//C         gtime_t pt[2][NFREQ]; /* previous carrier-phase time */
//C         double  ph[2][NFREQ]; /* previous carrier-phase observable (cycle) */
//C     } ssat_t;
struct _N160
{
    ubyte sys;
    ubyte vs;
    double [2]azel;
    double [3]resp;
    double [3]resc;
    ubyte [3]vsat;
    ubyte [3]snr;
    ubyte [3]fix;
    ubyte [3]slip;
    uint [3]lock;
    uint [3]outc;
    uint [3]slipc;
    uint [3]rejc;
    double gf;
    double gf2;
    double phw;
    gtime_t [3][2]pt;
    double [3][2]ph;
}
alias _N160 ssat_t;

//C     typedef struct {        /* ambiguity control type */
//C         gtime_t epoch[4];   /* last epoch */
//C         int fixcnt;         /* fix counter */
//C         char flags[MAXSAT]; /* fix flags */
//C         double n[4];        /* number of epochs */
//C         double LC [4];      /* linear combination average */
//C         double LCv[4];      /* linear combination variance */
//C     } ambc_t;
struct _N161
{
    gtime_t [4]epoch;
    int fixcnt;
    char [109]flags;
    double [4]n;
    double [4]LC;
    double [4]LCv;
}
alias _N161 ambc_t;

//C     typedef struct {        /* RTK control/result type */
//C         sol_t  sol;         /* RTK solution */
//C         double rb[6];       /* base position/velocity (ecef) (m|m/s) */
//C         int nx,na;          /* number of float states/fixed states */
//C         double tt;          /* time difference between current and previous (s) */
//C         double *x, *P;      /* float states and their covariance */
//C         double *xa,*Pa;     /* fixed states and their covariance */
//C         int nfix;           /* number of continuous fixes of ambiguity */
//C         ambc_t ambc[MAXSAT]; /* ambibuity control */
//C         ssat_t ssat[MAXSAT]; /* satellite status */
//C         int neb;            /* bytes in error message buffer */
//C         char errbuf[MAXERRMSG]; /* error message buffer */
//C         prcopt_t opt;       /* processing options */
//C     } rtk_t;
struct _N162
{
    sol_t sol;
    double [6]rb;
    int nx;
    int na;
    double tt;
    double *x;
    double *P;
    double *xa;
    double *Pa;
    int nfix;
    ambc_t [109]ambc;
    ssat_t [109]ssat;
    int neb;
    char [4096]errbuf;
    prcopt_t opt;
}
alias _N162 rtk_t;

//C     typedef struct {        /* receiver raw data control type */
//C         gtime_t time;       /* message time */
//C         gtime_t tobs;       /* observation data time */
//C         obs_t obs;          /* observation data */
//C         obs_t obuf;         /* observation data buffer */
//C         nav_t nav;          /* satellite ephemerides */
//C         sta_t sta;          /* station parameters */
//C         int ephsat;         /* sat number of update ephemeris (0:no satellite) */
//C         sbsmsg_t sbsmsg;    /* SBAS message */
//C         char msgtype[256];  /* last message type */
//C         unsigned char subfrm[MAXSAT][150];  /* subframe buffer (1-5) */
//C         lexmsg_t lexmsg;    /* LEX message */
//C         double lockt[MAXSAT][NFREQ+NEXOBS]; /* lock time (s) */
//C         double icpp[MAXSAT],off[MAXSAT],icpc; /* carrier params for ss2 */
//C         double prCA[MAXSAT],dpCA[MAXSAT]; /* L1/CA pseudrange/doppler for javad */
//C         unsigned char halfc[MAXSAT][NFREQ+NEXOBS]; /* half-cycle add flag */
//C         char freqn[MAXOBS]; /* frequency number for javad */
//C         int nbyte;          /* number of bytes in message buffer */ 
//C         int len;            /* message length (bytes) */
//C         int iod;            /* issue of data */
//C         int tod;            /* time of day (ms) */
//C         int tbase;          /* time base (0:gpst,1:utc(usno),2:glonass,3:utc(su) */
//C         int flag;           /* general purpose flag */
//C         int outtype;        /* output message type */
//C         unsigned char buff[MAXRAWLEN]; /* message buffer */
//C         char opt[256];      /* receiver dependent options */
//C     } raw_t;
struct _N163
{
    gtime_t time;
    gtime_t tobs;
    obs_t obs;
    obs_t obuf;
    nav_t nav;
    sta_t sta;
    int ephsat;
    sbsmsg_t sbsmsg;
    char [256]msgtype;
    ubyte [150][109]subfrm;
    lexmsg_t lexmsg;
    double [3][109]lockt;
    double [109]icpp;
    double [109]off;
    double icpc;
    double [109]prCA;
    double [109]dpCA;
    ubyte [3][109]halfc;
    char [64]freqn;
    int nbyte;
    int len;
    int iod;
    int tod;
    int tbase;
    int flag;
    int outtype;
    ubyte [4096]buff;
    char [256]opt;
}
alias _N163 raw_t;

//C     typedef struct {        /* stream type */
//C         int type;           /* type (STR_???) */
//C         int mode;           /* mode (STR_MODE_?) */
//C         int state;          /* state (-1:error,0:close,1:open) */
//C         unsigned int inb,inr;   /* input bytes/rate */
//C         unsigned int outb,outr; /* output bytes/rate */
//C         unsigned int tick,tact; /* tick/active tick */
//C         unsigned int inbt,outbt; /* input/output bytes at tick */
//C         lock_t lock;        /* lock flag */
//C         void *port;         /* type dependent port control struct */
//C         char path[MAXSTRPATH]; /* stream path */
//C         char msg [MAXSTRMSG];  /* stream message */
//C     } stream_t;
struct _N164
{
    int type;
    int mode;
    int state;
    uint inb;
    uint inr;
    uint outb;
    uint outr;
    uint tick;
    uint tact;
    uint inbt;
    uint outbt;
    CRITICAL_SECTION lock;
    void *port;
    char [1024]path;
    char [1024]msg;
}
alias _N164 stream_t;

//C     typedef struct {        /* stream converter type */
//C         int itype,otype;    /* input and output stream type */
//C         int nmsg;           /* number of output messages */
//C         int msgs[32];       /* output message types */
//C         double tint[32];    /* output message intervals (s) */
//C         unsigned int tick[32]; /* cycle tick of output message */
//C         int ephsat[32];     /* satellites of output ephemeris */
//C         int stasel;         /* station info selection (0:remote,1:local) */
//C         rtcm_t rtcm;        /* rtcm input data buffer */
//C         raw_t raw;          /* raw  input data buffer */
//C         rtcm_t out;         /* rtcm output data buffer */
//C     } strconv_t;
struct _N165
{
    int itype;
    int otype;
    int nmsg;
    int [32]msgs;
    double [32]tint;
    uint [32]tick;
    int [32]ephsat;
    int stasel;
    rtcm_t rtcm;
    raw_t raw;
    rtcm_t out_;
}
alias _N165 strconv_t;

//C     typedef struct {        /* stream server type */
//C         int state;          /* server state (0:stop,1:running) */
//C         int cycle;          /* server cycle (ms) */
//C         int buffsize;       /* input/monitor buffer size (bytes) */
//C         int nmeacycle;      /* NMEA request cycle (ms) (0:no) */
//C         int nstr;           /* number of streams (1 input + (nstr-1) outputs */
//C         int npb;            /* data length in peek buffer (bytes) */
//C         double nmeapos[3];  /* NMEA request position (ecef) (m) */
//C         unsigned char *buff; /* input buffers */
//C         unsigned char *pbuf; /* peek buffer */
//C         unsigned int tick;  /* start tick */
//C         stream_t stream[16]; /* input/output streams */
//C         strconv_t *conv[16]; /* stream converter */
//C         thread_t thread;    /* server thread */
//C         lock_t lock;        /* lock flag */
//C     } strsvr_t;
struct _N166
{
    int state;
    int cycle;
    int buffsize;
    int nmeacycle;
    int nstr;
    int npb;
    double [3]nmeapos;
    ubyte *buff;
    ubyte *pbuf;
    uint tick;
    stream_t [16]stream;
    strconv_t *[16]conv;
    HANDLE thread;
    CRITICAL_SECTION lock;
}
alias _N166 strsvr_t;

//C     typedef struct {        /* RTK server type */
//C         int state;          /* server state (0:stop,1:running) */
//C         int cycle;          /* processing cycle (ms) */
//C         int nmeacycle;      /* NMEA request cycle (ms) (0:no req) */
//C         int nmeareq;        /* NMEA request (0:no,1:nmeapos,2:single sol) */
//C         double nmeapos[3];  /* NMEA request position (ecef) (m) */
//C         int buffsize;       /* input buffer size (bytes) */
//C         int format[3];      /* input format {rov,base,corr} */
//C         solopt_t solopt[2]; /* output solution options {sol1,sol2} */
//C         int navsel;         /* ephemeris select (0:all,1:rover,2:base,3:corr) */
//C         int nsbs;           /* number of sbas message */
//C         int nsol;           /* number of solution buffer */
//C         rtk_t rtk;          /* RTK control/result struct */
//C         int nb [3];         /* bytes in input buffers {rov,base} */
//C         int nsb[2];         /* bytes in soulution buffers */
//C         int npb[3];         /* bytes in input peek buffers */
//C         unsigned char *buff[3]; /* input buffers {rov,base,corr} */
//C         unsigned char *sbuf[2]; /* output buffers {sol1,sol2} */
//C         unsigned char *pbuf[3]; /* peek buffers {rov,base,corr} */
//C         sol_t solbuf[MAXSOLBUF]; /* solution buffer */
//C         unsigned int nmsg[3][10]; /* input message counts */
//C         raw_t  raw [3];     /* receiver raw control {rov,base,corr} */
//C         rtcm_t rtcm[3];     /* RTCM control {rov,base,corr} */
//C         gtime_t ftime[3];   /* download time {rov,base,corr} */
//C         char files[3][MAXSTRPATH]; /* download paths {rov,base,corr} */
//C         obs_t obs[3][MAXOBSBUF]; /* observation data {rov,base,corr} */
//C         nav_t nav;          /* navigation data */
//C         sbsmsg_t sbsmsg[MAXSBSMSG]; /* SBAS message buffer */
//C         stream_t stream[8]; /* streams {rov,base,corr,sol1,sol2,logr,logb,logc} */
//C         stream_t *moni;     /* monitor stream */
//C         unsigned int tick;  /* start tick */
//C         thread_t thread;    /* server thread */
//C         int cputime;        /* CPU time (ms) for a processing cycle */
//C         int prcout;         /* missing observation data count */
//C         lock_t lock;        /* lock flag */
//C     } rtksvr_t;
struct _N167
{
    int state;
    int cycle;
    int nmeacycle;
    int nmeareq;
    double [3]nmeapos;
    int buffsize;
    int [3]format;
    solopt_t [2]solopt;
    int navsel;
    int nsbs;
    int nsol;
    rtk_t rtk;
    int [3]nb;
    int [2]nsb;
    int [3]npb;
    ubyte *[3]buff;
    ubyte *[2]sbuf;
    ubyte *[3]pbuf;
    sol_t [256]solbuf;
    uint [10][3]nmsg;
    raw_t [3]raw;
    rtcm_t [3]rtcm;
    gtime_t [3]ftime;
    char [1024][3]files;
    obs_t [128][3]obs;
    nav_t nav;
    sbsmsg_t [32]sbsmsg;
    stream_t [8]stream;
    stream_t *moni;
    uint tick;
    HANDLE thread;
    int cputime;
    int prcout;
    CRITICAL_SECTION lock;
}
alias _N167 rtksvr_t;

/+
/* global variables ----------------------------------------------------------*/
//C     extern const double chisqr[];           /* chi-sqr(n) table (alpha=0.001) */
extern const double []chisqr;
//C     extern const double lam_carr[];         /* carrier wave length (m) {L1,L2,...} */
extern const double []lam_carr;
//C     extern const prcopt_t prcopt_default;   /* default positioning options */
extern const prcopt_t prcopt_default;
//C     extern const solopt_t solopt_default;   /* default solution output options */
extern const solopt_t solopt_default;
//C     extern const sbsigpband_t igpband1[][8]; /* SBAS IGP band 0-8 */
extern const sbsigpband_t [8][]igpband1;
//C     extern const sbsigpband_t igpband2[][5]; /* SBAS IGP band 9-10 */
extern const sbsigpband_t [5][]igpband2;
//C     extern const char *formatstrs[];        /* stream format strings */
extern char *[]formatstrs;
//C     extern opt_t sysopts[];                 /* system options table */
extern opt_t []sysopts;

/* satellites, systems, codes functions --------------------------------------*/
//C     extern int  satno   (int sys, int prn);
int  satno(int sys, int prn);
//C     extern int  satsys  (int sat, int *prn);
int  satsys(int sat, int *prn);
//C     extern int  satid2no(const char *id);
int  satid2no(char *id);
//C     extern void satno2id(int sat, char *id);
void  satno2id(int sat, char *id);
//C     extern unsigned char obs2code(const char *obs, int *freq);
ubyte  obs2code(char *obs, int *freq);
//C     extern char *code2obs(unsigned char code, int *freq);
char * code2obs(ubyte code, int *freq);
//C     extern int  satexclude(int sat, int svh, const prcopt_t *opt);
int  satexclude(int sat, int svh, prcopt_t *opt);
//C     extern int  testsnr(int base, int freq, double el, double snr,
//C                         const snrmask_t *mask);
int  testsnr(int base, int freq, double el, double snr, snrmask_t *mask);
//C     extern void setcodepri(int sys, int freq, const char *pri);
void  setcodepri(int sys, int freq, char *pri);
//C     extern int  getcodepri(int sys, unsigned char code, const char *opt);
int  getcodepri(int sys, ubyte code, char *opt);

/* matrix and vector functions -----------------------------------------------*/
//C     extern double *mat  (int n, int m);
double * mat(int n, int m);
//C     extern int    *imat (int n, int m);
int * imat(int n, int m);
//C     extern double *zeros(int n, int m);
double * zeros(int n, int m);
//C     extern double *eye  (int n);
double * eye(int n);
//C     extern double dot (const double *a, const double *b, int n);
double  dot(double *a, double *b, int n);
//C     extern double norm(const double *a, int n);
double  norm(double *a, int n);
//C     extern void cross3(const double *a, const double *b, double *c);
void  cross3(double *a, double *b, double *c);
//C     extern int  normv3(const double *a, double *b);
int  normv3(double *a, double *b);
//C     extern void matcpy(double *A, const double *B, int n, int m);
void  matcpy(double *A, double *B, int n, int m);
//C     extern void matmul(const char *tr, int n, int k, int m, double alpha,
//C                        const double *A, const double *B, double beta, double *C);
void  matmul(char *tr, int n, int k, int m, double alpha, double *A, double *B, double beta, double *C);
//C     extern int  matinv(double *A, int n);
int  matinv(double *A, int n);
//C     extern int  solve (const char *tr, const double *A, const double *Y, int n,
//C                        int m, double *X);
int  solve(char *tr, double *A, double *Y, int n, int m, double *X);
//C     extern int  lsq   (const double *A, const double *y, int n, int m, double *x,
//C                        double *Q);
int  lsq(double *A, double *y, int n, int m, double *x, double *Q);
//C     extern int  filter(double *x, double *P, const double *H, const double *v,
//C                        const double *R, int n, int m);
int  filter(double *x, double *P, double *H, double *v, double *R, int n, int m);
//C     extern int  smoother(const double *xf, const double *Qf, const double *xb,
//C                          const double *Qb, int n, double *xs, double *Qs);
int  smoother(double *xf, double *Qf, double *xb, double *Qb, int n, double *xs, double *Qs);
//C     extern void matprint (const double *A, int n, int m, int p, int q);
void  matprint(double *A, int n, int m, int p, int q);
//C     extern void matfprint(const double *A, int n, int m, int p, int q, FILE *fp);
void  matfprint(double *A, int n, int m, int p, int q, FILE *fp);

/* time and string functions -------------------------------------------------*/
//C     extern double  str2num(const char *s, int i, int n);
double  str2num(char *s, int i, int n);
//C     extern int     str2time(const char *s, int i, int n, gtime_t *t);
int  str2time(char *s, int i, int n, gtime_t *t);
//C     extern void    time2str(gtime_t t, char *str, int n);
void  time2str(gtime_t t, char *str, int n);
//C     extern gtime_t epoch2time(const double *ep);
gtime_t  epoch2time(double *ep);
//C     extern void    time2epoch(gtime_t t, double *ep);
void  time2epoch(gtime_t t, double *ep);
//C     extern gtime_t gpst2time(int week, double sec);
gtime_t  gpst2time(int week, double sec);
//C     extern double  time2gpst(gtime_t t, int *week);
double  time2gpst(gtime_t t, int *week);
//C     extern gtime_t gst2time(int week, double sec);
gtime_t  gst2time(int week, double sec);
//C     extern double  time2gst(gtime_t t, int *week);
double  time2gst(gtime_t t, int *week);
//C     extern gtime_t bdt2time(int week, double sec);
gtime_t  bdt2time(int week, double sec);
//C     extern double  time2bdt(gtime_t t, int *week);
double  time2bdt(gtime_t t, int *week);
//C     extern char    *time_str(gtime_t t, int n);
char * time_str(gtime_t t, int n);

//C     extern gtime_t timeadd  (gtime_t t, double sec);
gtime_t  timeadd(gtime_t t, double sec);
//C     extern double  timediff (gtime_t t1, gtime_t t2);
double  timediff(gtime_t t1, gtime_t t2);
//C     extern gtime_t gpst2utc (gtime_t t);
gtime_t  gpst2utc(gtime_t t);
//C     extern gtime_t utc2gpst (gtime_t t);
gtime_t  utc2gpst(gtime_t t);
//C     extern gtime_t gpst2bdt (gtime_t t);
gtime_t  gpst2bdt(gtime_t t);
//C     extern gtime_t bdt2gpst (gtime_t t);
gtime_t  bdt2gpst(gtime_t t);
//C     extern gtime_t timeget  (void);
gtime_t  timeget();
//C     extern void    timeset  (gtime_t t);
void  timeset(gtime_t t);
//C     extern double  time2doy (gtime_t t);
double  time2doy(gtime_t t);
//C     extern double  utc2gmst (gtime_t t, double ut1_utc);
double  utc2gmst(gtime_t t, double ut1_utc);

//C     extern int adjgpsweek(int week);
int  adjgpsweek(int week);
//C     extern unsigned int tickget(void);
uint  tickget();
//C     extern void sleepms(int ms);
void  sleepms(int ms);

//C     extern int reppath(const char *path, char *rpath, gtime_t time, const char *rov,
//C                        const char *base);
int  reppath(char *path, char *rpath, gtime_t time, char *rov, char *base);
//C     extern int reppaths(const char *path, char *rpaths[], int nmax, gtime_t ts,
//C                         gtime_t te, const char *rov, const char *base);
int  reppaths(char *path, char **rpaths, int nmax, gtime_t ts, gtime_t te, char *rov, char *base);

/* coordinates transformation ------------------------------------------------*/
//C     extern void ecef2pos(const double *r, double *pos);
void  ecef2pos(double *r, double *pos);
//C     extern void pos2ecef(const double *pos, double *r);
void  pos2ecef(double *pos, double *r);
//C     extern void ecef2enu(const double *pos, const double *r, double *e);
void  ecef2enu(double *pos, double *r, double *e);
//C     extern void enu2ecef(const double *pos, const double *e, double *r);
void  enu2ecef(double *pos, double *e, double *r);
//C     extern void covenu  (const double *pos, const double *P, double *Q);
void  covenu(double *pos, double *P, double *Q);
//C     extern void covecef (const double *pos, const double *Q, double *P);
void  covecef(double *pos, double *Q, double *P);
//C     extern void xyz2enu (const double *pos, double *E);
void  xyz2enu(double *pos, double *E);
//C     extern void eci2ecef(gtime_t tutc, const double *erpv, double *U, double *gmst);
void  eci2ecef(gtime_t tutc, double *erpv, double *U, double *gmst);
//C     extern void deg2dms (double deg, double *dms);
void  deg2dms(double deg, double *dms);
//C     extern double dms2deg(const double *dms);
double  dms2deg(double *dms);

/* input and output functions ------------------------------------------------*/
//C     extern void readpos(const char *file, const char *rcv, double *pos);
void  readpos(char *file, char *rcv, double *pos);
//C     extern int  sortobs(obs_t *obs);
int  sortobs(obs_t *obs);
//C     extern void uniqnav(nav_t *nav);
void  uniqnav(nav_t *nav);
//C     extern int  screent(gtime_t time, gtime_t ts, gtime_t te, double tint);
int  screent(gtime_t time, gtime_t ts, gtime_t te, double tint);
//C     extern int  readnav(const char *file, nav_t *nav);
int  readnav(char *file, nav_t *nav);
//C     extern int  savenav(const char *file, const nav_t *nav);
int  savenav(char *file, nav_t *nav);
//C     extern void freeobs(obs_t *obs);
void  freeobs(obs_t *obs);
//C     extern void freenav(nav_t *nav, int opt);
void  freenav(nav_t *nav, int opt);
//C     extern int  readblq(const char *file, const char *sta, double *odisp);
int  readblq(char *file, char *sta, double *odisp);
//C     extern int  readerp(const char *file, erp_t *erp);
int  readerp(char *file, erp_t *erp);
//C     extern int  geterp (const erp_t *erp, gtime_t time, double *val);
int  geterp(erp_t *erp, gtime_t time, double *val);

/* debug trace functions -----------------------------------------------------*/
//C     extern void traceopen(const char *file);
void  traceopen(char *file);
//C     extern void traceclose(void);
void  traceclose();
//C     extern void tracelevel(int level);
void  tracelevel(int level);
//C     extern void trace    (int level, const char *format, ...);
void  trace(int level, char *format,...);
//C     extern void tracet   (int level, const char *format, ...);
void  tracet(int level, char *format,...);
//C     extern void tracemat (int level, const double *A, int n, int m, int p, int q);
void  tracemat(int level, double *A, int n, int m, int p, int q);
//C     extern void traceobs (int level, const obsd_t *obs, int n);
void  traceobs(int level, obsd_t *obs, int n);
//C     extern void tracenav (int level, const nav_t *nav);
void  tracenav(int level, nav_t *nav);
//C     extern void tracegnav(int level, const nav_t *nav);
void  tracegnav(int level, nav_t *nav);
//C     extern void tracehnav(int level, const nav_t *nav);
void  tracehnav(int level, nav_t *nav);
//C     extern void tracepeph(int level, const nav_t *nav);
void  tracepeph(int level, nav_t *nav);
//C     extern void tracepclk(int level, const nav_t *nav);
void  tracepclk(int level, nav_t *nav);
//C     extern void traceb   (int level, const unsigned char *p, int n);
void  traceb(int level, ubyte *p, int n);

/* platform dependent functions ----------------------------------------------*/
//C     extern int execcmd(const char *cmd);
int  execcmd(char *cmd);
//C     extern int expath (const char *path, char *paths[], int nmax);
int  expath(char *path, char **paths, int nmax);
//C     extern void createdir(const char *path);
void  createdir(char *path);

/* positioning models --------------------------------------------------------*/
//C     extern double satwavelen(int sat, int frq, const nav_t *nav);
double  satwavelen(int sat, int frq, nav_t *nav);
//C     extern double satazel(const double *pos, const double *e, double *azel);
double  satazel(double *pos, double *e, double *azel);
//C     extern double geodist(const double *rs, const double *rr, double *e);
double  geodist(double *rs, double *rr, double *e);
//C     extern void dops(int ns, const double *azel, double elmin, double *dop);
void  dops(int ns, double *azel, double elmin, double *dop);
//C     extern void csmooth(obs_t *obs, int ns);
void  csmooth(obs_t *obs, int ns);

/* atmosphere models ---------------------------------------------------------*/
//C     extern double ionmodel(gtime_t t, const double *ion, const double *pos,
//C                            const double *azel);
double  ionmodel(gtime_t t, double *ion, double *pos, double *azel);
//C     extern double ionmapf(const double *pos, const double *azel);
double  ionmapf(double *pos, double *azel);
//C     extern double ionppp(const double *pos, const double *azel, double re,
//C                          double hion, double *pppos);
double  ionppp(double *pos, double *azel, double re, double hion, double *pppos);
//C     extern double tropmodel(gtime_t time, const double *pos, const double *azel,
//C                             double humi);
double  tropmodel(gtime_t time, double *pos, double *azel, double humi);
//C     extern double tropmapf(gtime_t time, const double *pos, const double *azel,
//C                            double *mapfw);
double  tropmapf(gtime_t time, double *pos, double *azel, double *mapfw);
//C     extern int iontec(gtime_t time, const nav_t *nav, const double *pos,
//C                       const double *azel, int opt, double *delay, double *var);
int  iontec(gtime_t time, nav_t *nav, double *pos, double *azel, int opt, double *delay, double *var);
//C     extern void readtec(const char *file, nav_t *nav, int opt);
void  readtec(char *file, nav_t *nav, int opt);
//C     extern int ionocorr(gtime_t time, const nav_t *nav, int sat, const double *pos,
//C                         const double *azel, int ionoopt, double *ion, double *var);
int  ionocorr(gtime_t time, nav_t *nav, int sat, double *pos, double *azel, int ionoopt, double *ion, double *var);
//C     extern int tropcorr(gtime_t time, const nav_t *nav, const double *pos,
//C                         const double *azel, int tropopt, double *trp, double *var);
int  tropcorr(gtime_t time, nav_t *nav, double *pos, double *azel, int tropopt, double *trp, double *var);
//C     extern void stec_read(const char *file, nav_t *nav);
void  stec_read(char *file, nav_t *nav);
//C     extern int stec_grid(const nav_t *nav, const double *pos, int nmax, int *index,
//C                          double *dist);
int  stec_grid(nav_t *nav, double *pos, int nmax, int *index, double *dist);
//C     extern int stec_data(stec_t *stec, gtime_t time, int sat, double *iono,
//C                          double *rate, double *rms, int *slip);
int  stec_data(stec_t *stec, gtime_t time, int sat, double *iono, double *rate, double *rms, int *slip);
//C     extern int stec_ion(gtime_t time, const nav_t *nav, int sat, const double *pos,
//C                         const double *azel, double *iono, double *rate, double *var,
//C                         int *brk);
int  stec_ion(gtime_t time, nav_t *nav, int sat, double *pos, double *azel, double *iono, double *rate, double *var, int *brk);
//C     extern void stec_free(nav_t *nav);
void  stec_free(nav_t *nav);

/* antenna models ------------------------------------------------------------*/
//C     extern int  readpcv(const char *file, pcvs_t *pcvs);
int  readpcv(char *file, pcvs_t *pcvs);
//C     extern pcv_t *searchpcv(int sat, const char *type, gtime_t time,
//C                             const pcvs_t *pcvs);
pcv_t * searchpcv(int sat, char *type, gtime_t time, pcvs_t *pcvs);
//C     extern void antmodel(const pcv_t *pcv, const double *del, const double *azel,
//C                          int opt, double *dant);
void  antmodel(pcv_t *pcv, double *del, double *azel, int opt, double *dant);
//C     extern void antmodel_s(const pcv_t *pcv, double nadir, double *dant);
void  antmodel_s(pcv_t *pcv, double nadir, double *dant);

/* earth tide models ---------------------------------------------------------*/
//C     extern void sunmoonpos(gtime_t tutc, const double *erpv, double *rsun,
//C                            double *rmoon, double *gmst);
void  sunmoonpos(gtime_t tutc, double *erpv, double *rsun, double *rmoon, double *gmst);
//C     extern void tidedisp(gtime_t tutc, const double *rr, int opt, const erp_t *erp,
//C                          const double *odisp, double *dr);
void  tidedisp(gtime_t tutc, double *rr, int opt, erp_t *erp, double *odisp, double *dr);

/* geiod models --------------------------------------------------------------*/
//C     extern int opengeoid(int model, const char *file);
int  opengeoid(int model, char *file);
//C     extern void closegeoid(void);
void  closegeoid();
//C     extern double geoidh(const double *pos);
double  geoidh(double *pos);

/* datum transformation ------------------------------------------------------*/
//C     extern int loaddatump(const char *file);
int  loaddatump(char *file);
//C     extern int tokyo2jgd(double *pos);
int  tokyo2jgd(double *pos);
//C     extern int jgd2tokyo(double *pos);
int  jgd2tokyo(double *pos);

/* rinex functions -----------------------------------------------------------*/
//C     extern int readrnx (const char *file, int rcv, const char *opt, obs_t *obs,
//C                         nav_t *nav, sta_t *sta);
int  readrnx(char *file, int rcv, char *opt, obs_t *obs, nav_t *nav, sta_t *sta);
//C     extern int readrnxt(const char *file, int rcv, gtime_t ts, gtime_t te,
//C                         double tint, const char *opt, obs_t *obs, nav_t *nav,
//C                         sta_t *sta);
int  readrnxt(char *file, int rcv, gtime_t ts, gtime_t te, double tint, char *opt, obs_t *obs, nav_t *nav, sta_t *sta);
//C     extern int readrnxc(const char *file, nav_t *nav);
int  readrnxc(char *file, nav_t *nav);
//C     extern int outrnxobsh(FILE *fp, const rnxopt_t *opt, const nav_t *nav);
int  outrnxobsh(FILE *fp, rnxopt_t *opt, nav_t *nav);
//C     extern int outrnxobsb(FILE *fp, const rnxopt_t *opt, const obsd_t *obs, int n,
//C                           int epflag);
int  outrnxobsb(FILE *fp, rnxopt_t *opt, obsd_t *obs, int n, int epflag);
//C     extern int outrnxnavh (FILE *fp, const rnxopt_t *opt, const nav_t *nav);
int  outrnxnavh(FILE *fp, rnxopt_t *opt, nav_t *nav);
//C     extern int outrnxgnavh(FILE *fp, const rnxopt_t *opt, const nav_t *nav);
int  outrnxgnavh(FILE *fp, rnxopt_t *opt, nav_t *nav);
//C     extern int outrnxhnavh(FILE *fp, const rnxopt_t *opt, const nav_t *nav);
int  outrnxhnavh(FILE *fp, rnxopt_t *opt, nav_t *nav);
//C     extern int outrnxlnavh(FILE *fp, const rnxopt_t *opt, const nav_t *nav);
int  outrnxlnavh(FILE *fp, rnxopt_t *opt, nav_t *nav);
//C     extern int outrnxqnavh(FILE *fp, const rnxopt_t *opt, const nav_t *nav);
int  outrnxqnavh(FILE *fp, rnxopt_t *opt, nav_t *nav);
//C     extern int outrnxcnavh(FILE *fp, const rnxopt_t *opt, const nav_t *nav);
int  outrnxcnavh(FILE *fp, rnxopt_t *opt, nav_t *nav);
//C     extern int outrnxnavb (FILE *fp, const rnxopt_t *opt, const eph_t *eph);
int  outrnxnavb(FILE *fp, rnxopt_t *opt, eph_t *eph);
//C     extern int outrnxgnavb(FILE *fp, const rnxopt_t *opt, const geph_t *geph);
int  outrnxgnavb(FILE *fp, rnxopt_t *opt, geph_t *geph);
//C     extern int outrnxhnavb(FILE *fp, const rnxopt_t *opt, const seph_t *seph);
int  outrnxhnavb(FILE *fp, rnxopt_t *opt, seph_t *seph);
//C     extern int uncompress(const char *file, char *uncfile);
int  uncompress(char *file, char *uncfile);
//C     extern int convrnx(int format, rnxopt_t *opt, const char *file, char **ofile);
int  convrnx(int format, rnxopt_t *opt, char *file, char **ofile);
//C     extern int  init_rnxctr (rnxctr_t *rnx);
int  init_rnxctr(rnxctr_t *rnx);
//C     extern void free_rnxctr (rnxctr_t *rnx);
void  free_rnxctr(rnxctr_t *rnx);
//C     extern int  open_rnxctr (rnxctr_t *rnx, FILE *fp);
int  open_rnxctr(rnxctr_t *rnx, FILE *fp);
//C     extern int  input_rnxctr(rnxctr_t *rnx, FILE *fp);
int  input_rnxctr(rnxctr_t *rnx, FILE *fp);

/* ephemeris and clock functions ---------------------------------------------*/
//C     extern double eph2clk (gtime_t time, const eph_t  *eph);
double  eph2clk(gtime_t time, eph_t *eph);
//C     extern double geph2clk(gtime_t time, const geph_t *geph);
double  geph2clk(gtime_t time, geph_t *geph);
//C     extern double seph2clk(gtime_t time, const seph_t *seph);
double  seph2clk(gtime_t time, seph_t *seph);
//C     extern void eph2pos (gtime_t time, const eph_t  *eph,  double *rs, double *dts,
//C                          double *var);
void  eph2pos(gtime_t time, eph_t *eph, double *rs, double *dts, double *var);
//C     extern void geph2pos(gtime_t time, const geph_t *geph, double *rs, double *dts,
//C                          double *var);
void  geph2pos(gtime_t time, geph_t *geph, double *rs, double *dts, double *var);
//C     extern void seph2pos(gtime_t time, const seph_t *seph, double *rs, double *dts,
//C                          double *var);
void  seph2pos(gtime_t time, seph_t *seph, double *rs, double *dts, double *var);
//C     extern int  peph2pos(gtime_t time, int sat, const nav_t *nav, int opt,
//C                          double *rs, double *dts, double *var);
int  peph2pos(gtime_t time, int sat, nav_t *nav, int opt, double *rs, double *dts, double *var);
//C     extern void satantoff(gtime_t time, const double *rs, const pcv_t *pcv,
//C                           double *dant);
void  satantoff(gtime_t time, double *rs, pcv_t *pcv, double *dant);
//C     extern int  satpos(gtime_t time, gtime_t teph, int sat, int ephopt,
//C                        const nav_t *nav, double *rs, double *dts, double *var,
//C                        int *svh);
int  satpos(gtime_t time, gtime_t teph, int sat, int ephopt, nav_t *nav, double *rs, double *dts, double *var, int *svh);
//C     extern void satposs(gtime_t time, const obsd_t *obs, int n, const nav_t *nav,
//C                         int sateph, double *rs, double *dts, double *var, int *svh);
void  satposs(gtime_t time, obsd_t *obs, int n, nav_t *nav, int sateph, double *rs, double *dts, double *var, int *svh);
//C     extern void readsp3(const char *file, nav_t *nav, int opt);
void  readsp3(char *file, nav_t *nav, int opt);
//C     extern int  readsap(const char *file, gtime_t time, nav_t *nav);
int  readsap(char *file, gtime_t time, nav_t *nav);
//C     extern int  readdcb(const char *file, nav_t *nav);
int  readdcb(char *file, nav_t *nav);
//C     extern void alm2pos(gtime_t time, const alm_t *alm, double *rs, double *dts);
void  alm2pos(gtime_t time, alm_t *alm, double *rs, double *dts);

//C     extern int tle_read(const char *file, tle_t *tle);
int  tle_read(char *file, tle_t *tle);
//C     extern int tle_name_read(const char *file, tle_t *tle);
int  tle_name_read(char *file, tle_t *tle);
//C     extern int tle_pos(gtime_t time, const char *name, const char *satno,
//C                        const char *desig, const tle_t *tle, const erp_t *erp,
//C                        double *rs);
int  tle_pos(gtime_t time, char *name, char *satno, char *desig, tle_t *tle, erp_t *erp, double *rs);

/* receiver raw data functions -----------------------------------------------*/
//C     extern unsigned int getbitu(const unsigned char *buff, int pos, int len);
uint  getbitu(ubyte *buff, int pos, int len);
//C     extern int          getbits(const unsigned char *buff, int pos, int len);
int  getbits(ubyte *buff, int pos, int len);
//C     extern void setbitu(unsigned char *buff, int pos, int len, unsigned int data);
void  setbitu(ubyte *buff, int pos, int len, uint data);
//C     extern void setbits(unsigned char *buff, int pos, int len, int data);
void  setbits(ubyte *buff, int pos, int len, int data);
//C     extern unsigned int crc32  (const unsigned char *buff, int len);
uint  crc32(ubyte *buff, int len);
//C     extern unsigned int crc24q (const unsigned char *buff, int len);
uint  crc24q(ubyte *buff, int len);
//C     extern unsigned short crc16(const unsigned char *buff, int len);
ushort  crc16(ubyte *buff, int len);
//C     extern int decode_word (unsigned int word, unsigned char *data);
int  decode_word(uint word, ubyte *data);
//C     extern int decode_frame(const unsigned char *buff, eph_t *eph, alm_t *alm,
//C                             double *ion, double *utc, int *leaps);
int  decode_frame(ubyte *buff, eph_t *eph, alm_t *alm, double *ion, double *utc, int *leaps);

//C     extern int init_raw   (raw_t *raw);
int  init_raw(raw_t *raw);
//C     extern void free_raw  (raw_t *raw);
void  free_raw(raw_t *raw);
//C     extern int input_raw  (raw_t *raw, int format, unsigned char data);
int  input_raw(raw_t *raw, int format, ubyte data);
//C     extern int input_rawf (raw_t *raw, int format, FILE *fp);
int  input_rawf(raw_t *raw, int format, FILE *fp);

//C     extern int input_oem4  (raw_t *raw, unsigned char data);
int  input_oem4(raw_t *raw, ubyte data);
//C     extern int input_oem3  (raw_t *raw, unsigned char data);
int  input_oem3(raw_t *raw, ubyte data);
//C     extern int input_ubx   (raw_t *raw, unsigned char data);
int  input_ubx(raw_t *raw, ubyte data);
//C     extern int input_ss2   (raw_t *raw, unsigned char data);
int  input_ss2(raw_t *raw, ubyte data);
//C     extern int input_cres  (raw_t *raw, unsigned char data);
int  input_cres(raw_t *raw, ubyte data);
//C     extern int input_stq   (raw_t *raw, unsigned char data);
int  input_stq(raw_t *raw, ubyte data);
//C     extern int input_gw10  (raw_t *raw, unsigned char data);
int  input_gw10(raw_t *raw, ubyte data);
//C     extern int input_javad (raw_t *raw, unsigned char data);
int  input_javad(raw_t *raw, ubyte data);
//C     extern int input_nvs   (raw_t *raw, unsigned char data);
int  input_nvs(raw_t *raw, ubyte data);
//C     extern int input_bnx   (raw_t *raw, unsigned char data);
int  input_bnx(raw_t *raw, ubyte data);
//C     extern int input_lexr  (raw_t *raw, unsigned char data);
int  input_lexr(raw_t *raw, ubyte data);
//C     extern int input_oem4f (raw_t *raw, FILE *fp);
int  input_oem4f(raw_t *raw, FILE *fp);
//C     extern int input_oem3f (raw_t *raw, FILE *fp);
int  input_oem3f(raw_t *raw, FILE *fp);
//C     extern int input_ubxf  (raw_t *raw, FILE *fp);
int  input_ubxf(raw_t *raw, FILE *fp);
//C     extern int input_ss2f  (raw_t *raw, FILE *fp);
int  input_ss2f(raw_t *raw, FILE *fp);
//C     extern int input_cresf (raw_t *raw, FILE *fp);
int  input_cresf(raw_t *raw, FILE *fp);
//C     extern int input_stqf  (raw_t *raw, FILE *fp);
int  input_stqf(raw_t *raw, FILE *fp);
//C     extern int input_gw10f (raw_t *raw, FILE *fp);
int  input_gw10f(raw_t *raw, FILE *fp);
//C     extern int input_javadf(raw_t *raw, FILE *fp);
int  input_javadf(raw_t *raw, FILE *fp);
//C     extern int input_nvsf  (raw_t *raw, FILE *fp);
int  input_nvsf(raw_t *raw, FILE *fp);
//C     extern int input_bnxf  (raw_t *raw, FILE *fp);
int  input_bnxf(raw_t *raw, FILE *fp);
//C     extern int input_lexrf (raw_t *raw, FILE *fp);
int  input_lexrf(raw_t *raw, FILE *fp);

//C     extern int gen_ubx (const char *msg, unsigned char *buff);
int  gen_ubx(char *msg, ubyte *buff);
//C     extern int gen_stq (const char *msg, unsigned char *buff);
int  gen_stq(char *msg, ubyte *buff);
//C     extern int gen_nvs (const char *msg, unsigned char *buff);
int  gen_nvs(char *msg, ubyte *buff);
//C     extern int gen_lexr(const char *msg, unsigned char *buff);
int  gen_lexr(char *msg, ubyte *buff);

/* rtcm functions ------------------------------------------------------------*/
//C     extern int init_rtcm   (rtcm_t *rtcm);
int  init_rtcm(rtcm_t *rtcm);
//C     extern void free_rtcm  (rtcm_t *rtcm);
void  free_rtcm(rtcm_t *rtcm);
//C     extern int input_rtcm2 (rtcm_t *rtcm, unsigned char data);
int  input_rtcm2(rtcm_t *rtcm, ubyte data);
//C     extern int input_rtcm3 (rtcm_t *rtcm, unsigned char data);
int  input_rtcm3(rtcm_t *rtcm, ubyte data);
//C     extern int input_rtcm2f(rtcm_t *rtcm, FILE *fp);
int  input_rtcm2f(rtcm_t *rtcm, FILE *fp);
//C     extern int input_rtcm3f(rtcm_t *rtcm, FILE *fp);
int  input_rtcm3f(rtcm_t *rtcm, FILE *fp);
//C     extern int gen_rtcm2   (rtcm_t *rtcm, int type, int sync);
int  gen_rtcm2(rtcm_t *rtcm, int type, int sync);
//C     extern int gen_rtcm3   (rtcm_t *rtcm, int type, int sync);
int  gen_rtcm3(rtcm_t *rtcm, int type, int sync);

/* solution functions --------------------------------------------------------*/
//C     extern void initsolbuf(solbuf_t *solbuf, int cyclic, int nmax);
void  initsolbuf(solbuf_t *solbuf, int cyclic, int nmax);
//C     extern void freesolbuf(solbuf_t *solbuf);
void  freesolbuf(solbuf_t *solbuf);
//C     extern void freesolstatbuf(solstatbuf_t *solstatbuf);
void  freesolstatbuf(solstatbuf_t *solstatbuf);
//C     extern sol_t *getsol(solbuf_t *solbuf, int index);
sol_t * getsol(solbuf_t *solbuf, int index);
//C     extern int addsol(solbuf_t *solbuf, const sol_t *sol);
int  addsol(solbuf_t *solbuf, sol_t *sol);
//C     extern int readsol (char *files[], int nfile, solbuf_t *sol);
int  readsol(char **files, int nfile, solbuf_t *sol);
//C     extern int readsolt(char *files[], int nfile, gtime_t ts, gtime_t te,
//C                         double tint, int qflag, solbuf_t *sol);
int  readsolt(char **files, int nfile, gtime_t ts, gtime_t te, double tint, int qflag, solbuf_t *sol);
//C     extern int readsolstat(char *files[], int nfile, solstatbuf_t *statbuf);
int  readsolstat(char **files, int nfile, solstatbuf_t *statbuf);
//C     extern int readsolstatt(char *files[], int nfile, gtime_t ts, gtime_t te,
//C                             double tint, solstatbuf_t *statbuf);
int  readsolstatt(char **files, int nfile, gtime_t ts, gtime_t te, double tint, solstatbuf_t *statbuf);
//C     extern int inputsol(unsigned char data, gtime_t ts, gtime_t te, double tint,
//C                         int qflag, const solopt_t *opt, solbuf_t *solbuf);
int  inputsol(ubyte data, gtime_t ts, gtime_t te, double tint, int qflag, solopt_t *opt, solbuf_t *solbuf);

//C     extern int outprcopts(unsigned char *buff, const prcopt_t *opt);
int  outprcopts(ubyte *buff, prcopt_t *opt);
//C     extern int outsolheads(unsigned char *buff, const solopt_t *opt);
int  outsolheads(ubyte *buff, solopt_t *opt);
//C     extern int outsols  (unsigned char *buff, const sol_t *sol, const double *rb,
//C                          const solopt_t *opt);
int  outsols(ubyte *buff, sol_t *sol, double *rb, solopt_t *opt);
//C     extern int outsolexs(unsigned char *buff, const sol_t *sol, const ssat_t *ssat,
//C                          const solopt_t *opt);
int  outsolexs(ubyte *buff, sol_t *sol, ssat_t *ssat, solopt_t *opt);
//C     extern void outprcopt(FILE *fp, const prcopt_t *opt);
void  outprcopt(FILE *fp, prcopt_t *opt);
//C     extern void outsolhead(FILE *fp, const solopt_t *opt);
void  outsolhead(FILE *fp, solopt_t *opt);
//C     extern void outsol  (FILE *fp, const sol_t *sol, const double *rb,
//C                          const solopt_t *opt);
void  outsol(FILE *fp, sol_t *sol, double *rb, solopt_t *opt);
//C     extern void outsolex(FILE *fp, const sol_t *sol, const ssat_t *ssat,
//C                          const solopt_t *opt);
void  outsolex(FILE *fp, sol_t *sol, ssat_t *ssat, solopt_t *opt);
//C     extern int outnmea_rmc(unsigned char *buff, const sol_t *sol);
int  outnmea_rmc(ubyte *buff, sol_t *sol);
//C     extern int outnmea_gga(unsigned char *buff, const sol_t *sol);
int  outnmea_gga(ubyte *buff, sol_t *sol);
//C     extern int outnmea_gsa(unsigned char *buff, const sol_t *sol,
//C                            const ssat_t *ssat);
int  outnmea_gsa(ubyte *buff, sol_t *sol, ssat_t *ssat);
//C     extern int outnmea_gsv(unsigned char *buff, const sol_t *sol,
//C                            const ssat_t *ssat);
int  outnmea_gsv(ubyte *buff, sol_t *sol, ssat_t *ssat);

/* google earth kml converter ------------------------------------------------*/
//C     extern int convkml(const char *infile, const char *outfile, gtime_t ts,
//C                        gtime_t te, double tint, int qflg, double *offset,
//C                        int tcolor, int pcolor, int outalt, int outtime);
int  convkml(char *infile, char *outfile, gtime_t ts, gtime_t te, double tint, int qflg, double *offset, int tcolor, int pcolor, int outalt, int outtime);

/* sbas functions ------------------------------------------------------------*/
//C     extern int  sbsreadmsg (const char *file, int sel, sbs_t *sbs);
int  sbsreadmsg(char *file, int sel, sbs_t *sbs);
//C     extern int  sbsreadmsgt(const char *file, int sel, gtime_t ts, gtime_t te,
//C                             sbs_t *sbs);
int  sbsreadmsgt(char *file, int sel, gtime_t ts, gtime_t te, sbs_t *sbs);
//C     extern void sbsoutmsg(FILE *fp, sbsmsg_t *sbsmsg);
void  sbsoutmsg(FILE *fp, sbsmsg_t *sbsmsg);
//C     extern int  sbsdecodemsg(gtime_t time, int prn, const unsigned int *words,
//C                              sbsmsg_t *sbsmsg);
int  sbsdecodemsg(gtime_t time, int prn, uint *words, sbsmsg_t *sbsmsg);
//C     extern int sbsupdatecorr(const sbsmsg_t *msg, nav_t *nav);
int  sbsupdatecorr(sbsmsg_t *msg, nav_t *nav);
//C     extern int sbssatcorr(gtime_t time, int sat, const nav_t *nav, double *rs,
//C                           double *dts, double *var);
int  sbssatcorr(gtime_t time, int sat, nav_t *nav, double *rs, double *dts, double *var);
//C     extern int sbsioncorr(gtime_t time, const nav_t *nav, const double *pos,
//C                           const double *azel, double *delay, double *var);
int  sbsioncorr(gtime_t time, nav_t *nav, double *pos, double *azel, double *delay, double *var);
//C     extern double sbstropcorr(gtime_t time, const double *pos, const double *azel,
//C                               double *var);
double  sbstropcorr(gtime_t time, double *pos, double *azel, double *var);

/* options functions ---------------------------------------------------------*/
//C     extern opt_t *searchopt(const char *name, const opt_t *opts);
opt_t * searchopt(char *name, opt_t *opts);
//C     extern int str2opt(opt_t *opt, const char *str);
int  str2opt(opt_t *opt, char *str);
//C     extern int opt2str(const opt_t *opt, char *str);
int  opt2str(opt_t *opt, char *str);
//C     extern int opt2buf(const opt_t *opt, char *buff);
int  opt2buf(opt_t *opt, char *buff);
//C     extern int loadopts(const char *file, opt_t *opts);
int  loadopts(char *file, opt_t *opts);
//C     extern int saveopts(const char *file, const char *mode, const char *comment,
//C                         const opt_t *opts);
int  saveopts(char *file, char *mode, char *comment, opt_t *opts);
//C     extern void resetsysopts(void);
void  resetsysopts();
//C     extern void getsysopts(prcopt_t *popt, solopt_t *sopt, filopt_t *fopt);
void  getsysopts(prcopt_t *popt, solopt_t *sopt, filopt_t *fopt);
//C     extern void setsysopts(const prcopt_t *popt, const solopt_t *sopt,
//C                            const filopt_t *fopt);
void  setsysopts(prcopt_t *popt, solopt_t *sopt, filopt_t *fopt);

/* stream data input and output functions ------------------------------------*/
//C     extern void strinitcom(void);
void  strinitcom();
//C     extern void strinit  (stream_t *stream);
void  strinit(stream_t *stream);
//C     extern void strlock  (stream_t *stream);
void  strlock(stream_t *stream);
//C     extern void strunlock(stream_t *stream);
void  strunlock(stream_t *stream);
//C     extern int  stropen  (stream_t *stream, int type, int mode, const char *path);
int  stropen(stream_t *stream, int type, int mode, char *path);
//C     extern void strclose (stream_t *stream);
void  strclose(stream_t *stream);
//C     extern int  strread  (stream_t *stream, unsigned char *buff, int n);
int  strread(stream_t *stream, ubyte *buff, int n);
//C     extern int  strwrite (stream_t *stream, unsigned char *buff, int n);
int  strwrite(stream_t *stream, ubyte *buff, int n);
//C     extern void strsync  (stream_t *stream1, stream_t *stream2);
void  strsync(stream_t *stream1, stream_t *stream2);
//C     extern int  strstat  (stream_t *stream, char *msg);
int  strstat(stream_t *stream, char *msg);
//C     extern void strsum   (stream_t *stream, int *inb, int *inr, int *outb, int *outr);
void  strsum(stream_t *stream, int *inb, int *inr, int *outb, int *outr);
//C     extern void strsetopt(const int *opt);
void  strsetopt(int *opt);
//C     extern gtime_t strgettime(stream_t *stream);
gtime_t  strgettime(stream_t *stream);
//C     extern void strsendnmea(stream_t *stream, const double *pos);
void  strsendnmea(stream_t *stream, double *pos);
//C     extern void strsendcmd(stream_t *stream, const char *cmd);
void  strsendcmd(stream_t *stream, char *cmd);
//C     extern void strsettimeout(stream_t *stream, int toinact, int tirecon);
void  strsettimeout(stream_t *stream, int toinact, int tirecon);
//C     extern void strsetdir(const char *dir);
void  strsetdir(char *dir);
//C     extern void strsetproxy(const char *addr);
void  strsetproxy(char *addr);

/* integer ambiguity resolution ----------------------------------------------*/
//C     extern int lambda(int n, int m, const double *a, const double *Q, double *F,
//C                       double *s);
int  lambda(int n, int m, double *a, double *Q, double *F, double *s);

/* standard positioning ------------------------------------------------------*/
//C     extern int pntpos(const obsd_t *obs, int n, const nav_t *nav,
//C                       const prcopt_t *opt, sol_t *sol, double *azel,
//C                       ssat_t *ssat, char *msg);
int  pntpos(obsd_t *obs, int n, nav_t *nav, prcopt_t *opt, sol_t *sol, double *azel, ssat_t *ssat, char *msg);

/* precise positioning -------------------------------------------------------*/
//C     extern void rtkinit(rtk_t *rtk, const prcopt_t *opt);
void  rtkinit(rtk_t *rtk, prcopt_t *opt);
//C     extern void rtkfree(rtk_t *rtk);
void  rtkfree(rtk_t *rtk);
//C     extern int  rtkpos (rtk_t *rtk, const obsd_t *obs, int nobs, const nav_t *nav);
int  rtkpos(rtk_t *rtk, obsd_t *obs, int nobs, nav_t *nav);
//C     extern int  rtkopenstat(const char *file, int level);
int  rtkopenstat(char *file, int level);
//C     extern void rtkclosestat(void);
void  rtkclosestat();

/* precise point positioning -------------------------------------------------*/
//C     extern void pppos(rtk_t *rtk, const obsd_t *obs, int n, const nav_t *nav);
void  pppos(rtk_t *rtk, obsd_t *obs, int n, nav_t *nav);
//C     extern int pppamb(rtk_t *rtk, const obsd_t *obs, int n, const nav_t *nav,
//C                       const double *azel);
int  pppamb(rtk_t *rtk, obsd_t *obs, int n, nav_t *nav, double *azel);
//C     extern int pppnx(const prcopt_t *opt);
int  pppnx(prcopt_t *opt);
//C     extern void pppoutsolstat(rtk_t *rtk, int level, FILE *fp);
void  pppoutsolstat(rtk_t *rtk, int level, FILE *fp);
//C     extern void windupcorr(gtime_t time, const double *rs, const double *rr,
//C                            double *phw);
void  windupcorr(gtime_t time, double *rs, double *rr, double *phw);

/* post-processing positioning -----------------------------------------------*/
//C     extern int postpos(gtime_t ts, gtime_t te, double ti, double tu,
//C                        const prcopt_t *popt, const solopt_t *sopt,
//C                        const filopt_t *fopt, char **infile, int n, char *outfile,
//C                        const char *rov, const char *base);
int  postpos(gtime_t ts, gtime_t te, double ti, double tu, prcopt_t *popt, solopt_t *sopt, filopt_t *fopt, char **infile, int n, char *outfile, char *rov, char *base);

/* stream server functions ---------------------------------------------------*/
//C     extern void strsvrinit (strsvr_t *svr, int nout);
void  strsvrinit(strsvr_t *svr, int nout);
//C     extern int  strsvrstart(strsvr_t *svr, int *opts, int *strs, char **paths,
//C                             strconv_t **conv, const char *cmd,
//C                             const double *nmeapos);
int  strsvrstart(strsvr_t *svr, int *opts, int *strs, char **paths, strconv_t **conv, char *cmd, double *nmeapos);
//C     extern void strsvrstop (strsvr_t *svr, const char *cmd);
void  strsvrstop(strsvr_t *svr, char *cmd);
//C     extern void strsvrstat (strsvr_t *svr, int *stat, int *byte, int *bps, char *msg);
void  strsvrstat(strsvr_t *svr, int *stat, int *byte_, int *bps, char *msg);
//C     extern strconv_t *strconvnew(int itype, int otype, const char *msgs, int staid,
//C                                  int stasel, const char *opt);
strconv_t * strconvnew(int itype, int otype, char *msgs, int staid, int stasel, char *opt);
//C     extern void strconvfree(strconv_t *conv);
void  strconvfree(strconv_t *conv);

/* rtk server functions ------------------------------------------------------*/
//C     extern int  rtksvrinit  (rtksvr_t *svr);
int  rtksvrinit(rtksvr_t *svr);
//C     extern void rtksvrfree  (rtksvr_t *svr);
void  rtksvrfree(rtksvr_t *svr);
//C     extern int  rtksvrstart (rtksvr_t *svr, int cycle, int buffsize, int *strs,
//C                              char **paths, int *formats, int navsel, char **cmds,
//C                              char **rcvopts, int nmeacycle, int nmeareq,
//C                              const double *nmeapos, prcopt_t *prcopt,
//C                              solopt_t *solopt, stream_t *moni);
int  rtksvrstart(rtksvr_t *svr, int cycle, int buffsize, int *strs, char **paths, int *formats, int navsel, char **cmds, char **rcvopts, int nmeacycle, int nmeareq, double *nmeapos, prcopt_t *prcopt, solopt_t *solopt, stream_t *moni);
//C     extern void rtksvrstop  (rtksvr_t *svr, char **cmds);
void  rtksvrstop(rtksvr_t *svr, char **cmds);
//C     extern int  rtksvropenstr(rtksvr_t *svr, int index, int str, const char *path,
//C                               const solopt_t *solopt);
int  rtksvropenstr(rtksvr_t *svr, int index, int str, char *path, solopt_t *solopt);
//C     extern void rtksvrclosestr(rtksvr_t *svr, int index);
void  rtksvrclosestr(rtksvr_t *svr, int index);
//C     extern void rtksvrlock  (rtksvr_t *svr);
void  rtksvrlock(rtksvr_t *svr);
//C     extern void rtksvrunlock(rtksvr_t *svr);
void  rtksvrunlock(rtksvr_t *svr);
//C     extern int  rtksvrostat (rtksvr_t *svr, int type, gtime_t *time, int *sat,
//C                              double *az, double *el, int **snr, int *vsat);
int  rtksvrostat(rtksvr_t *svr, int type, gtime_t *time, int *sat, double *az, double *el, int **snr, int *vsat);
//C     extern void rtksvrsstat (rtksvr_t *svr, int *sstat, char *msg);
void  rtksvrsstat(rtksvr_t *svr, int *sstat, char *msg);

/* downloader functions ------------------------------------------------------*/
//C     extern int dl_readurls(const char *file, char **types, int ntype, url_t *urls,
//C                            int nmax);
int  dl_readurls(char *file, char **types, int ntype, url_t *urls, int nmax);
//C     extern int dl_readstas(const char *file, char **stas, int nmax);
int  dl_readstas(char *file, char **stas, int nmax);
//C     extern int dl_exec(gtime_t ts, gtime_t te, double ti, int seqnos, int seqnoe,
//C                        const url_t *urls, int nurl, char **stas, int nsta,
//C                        const char *dir, const char *usr, const char *pwd,
//C                        const char *proxy, int opts, char *msg, FILE *fp);
int  dl_exec(gtime_t ts, gtime_t te, double ti, int seqnos, int seqnoe, url_t *urls, int nurl, char **stas, int nsta, char *dir, char *usr, char *pwd, char *proxy, int opts, char *msg, FILE *fp);
//C     extern void dl_test(gtime_t ts, gtime_t te, double ti, const url_t *urls,
//C                         int nurl, char **stas, int nsta, const char *dir,
//C                         int ncol, int datefmt, FILE *fp);
void  dl_test(gtime_t ts, gtime_t te, double ti, url_t *urls, int nurl, char **stas, int nsta, char *dir, int ncol, int datefmt, FILE *fp);

/* application defined functions ---------------------------------------------*/
//C     extern int showmsg(char *format,...);
int  showmsg(char *format,...);
//C     extern void settspan(gtime_t ts, gtime_t te);
void  settspan(gtime_t ts, gtime_t te);
//C     extern void settime(gtime_t time);
void  settime(gtime_t time);

/* qzss lex functions --------------------------------------------------------*/
//C     extern int lexupdatecorr(const lexmsg_t *msg, nav_t *nav, gtime_t *tof);
int  lexupdatecorr(lexmsg_t *msg, nav_t *nav, gtime_t *tof);
//C     extern int lexreadmsg(const char *file, int sel, lex_t *lex);
int  lexreadmsg(char *file, int sel, lex_t *lex);
//C     extern void lexoutmsg(FILE *fp, const lexmsg_t *msg);
void  lexoutmsg(FILE *fp, lexmsg_t *msg);
//C     extern int lexconvbin(int type, int format, const char *infile,
//C                           const char *outfile);
int  lexconvbin(int type, int format, char *infile, char *outfile);
//C     extern int lexeph2pos(gtime_t time, int sat, const nav_t *nav, double *rs,
//C                           double *dts, double *var);
int  lexeph2pos(gtime_t time, int sat, nav_t *nav, double *rs, double *dts, double *var);
//C     extern int lexioncorr(gtime_t time, const nav_t *nav, const double *pos,
//C                           const double *azel, double *delay, double *var);
int  lexioncorr(gtime_t time, nav_t *nav, double *pos, double *azel, double *delay, double *var);

//C     #ifdef __cplusplus
//C     }
//C     #endif
//C     #endif /* RTKLIB_H */
+/