/**---------------------------------------------------------------------------
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
module rtklib;

import core.sys.windows.windows;
import core.stdc.time;
import core.stdc.stdio;

import core.sync.mutex;

import std.concurrency,
       std.path;

/// constants ----------------------------------------------------------------
version = ENAGLO;
version = ENAGAL;
version = ENAQZS;

enum VER_RTKLIB =   "2.4.2";
enum COPYRIGHT_RTKLIB = "Copyright (C) 2007-2013 by T.Takasu\nAll rights reserved.";
enum PI =           3.1415926535897932; /// pi
enum D2R =          PI / 180;           /// deg to rad
enum R2D =          180.0 / PI;         /// rad to deg
enum CLIGHT =       299792458.0;        /// speed of light (m/s)
enum SC2RAD =       3.1415926535898;    /// semi-circle to radian (IS-GPS)
enum AU =           149597870691.0;     /// 1 AU (m)
enum AS2R =         D2R / 3600.0;       /// arc sec to radian

enum OMGE =         7.2921151467E-5;    /// earth angular velocity (IS-GPS) (rad/s)

enum RE_WGS84 =     6378137.0;          /// earth semimajor axis (WGS84) (m)
enum FE_WGS84 =     1.0 / 298.257223563;/// earth flattening (WGS84)

enum HION =         350000.0;           /// ionosphere height (m)

enum MAXFREQ =      7;                  /// max NFREQ
enum FREQ1 =        1.57542E9;          /// L1/E1  frequency (Hz)
enum FREQ2 =        1.22760E9;          /// L2     frequency (Hz)
enum FREQ5 =        1.17645E9;          /// L5/E5a frequency (Hz)
enum FREQ6 =        1.27875E9;          /// E6/LEX frequency (Hz)
enum FREQ7 =        1.20714E9;          /// E5b    frequency (Hz)
enum FREQ8 =        1.191795E9;         /// E5a+b  frequency (Hz)
enum FREQ1_GLO =    1.60200E9;          /// GLONASS G1 base frequency (Hz)
enum DFRQ1_GLO =    0.56250E6;          /// GLONASS G1 bias frequency (Hz/n)
enum FREQ2_GLO =    1.24600E9;          /// GLONASS G2 base frequency (Hz)
enum DFRQ2_GLO =    0.43750E6;          /// GLONASS G2 bias frequency (Hz/n)
enum FREQ3_GLO =    1.202025E9;         /// GLONASS G3 frequency (Hz)
enum FREQ2_CMP =    1.561098E9;         /// BeiDou B1 frequency (Hz)
enum FREQ7_CMP =    1.20714E9;          /// BeiDou B2 frequency (Hz)
enum FREQ6_CMP =    1.26852E9;          /// BeiDou B3 frequency (Hz)

enum EFACT_GPS =    1.0;                /// error factor: GPS
enum EFACT_GLO =    1.5;                /// error factor: GLONASS
enum EFACT_GAL =    1.0;                /// error factor: Galileo
enum EFACT_QZS =    1.0;                /// error factor: QZSS
enum EFACT_CMP =    1.0;                /// error factor: BeiDou
enum EFACT_SBS =    3.0;                /// error factor: SBAS

enum SYS_NONE =     0x00;               /// navigation system: none
enum SYS_GPS =      0x01;               /// navigation system: GPS
enum SYS_SBS =      0x02;               /// navigation system: SBAS
enum SYS_GLO =      0x04;               /// navigation system: GLONASS
enum SYS_GAL =      0x08;               /// navigation system: Galileo
enum SYS_QZS =      0x10;               /// navigation system: QZSS
enum SYS_CMP =      0x20;               /// navigation system: BeiDou
enum SYS_ALL =      0xFF;               /// navigation system: all

enum TSYS_GPS =     0;                  /// time system: GPS time
enum TSYS_UTC =     1;                  /// time system: UTC
enum TSYS_GLO =     2;                  /// time system: GLONASS time
enum TSYS_GAL =     3;                  /// time system: Galileo time
enum TSYS_QZS =     4;                  /// time system: QZSS time
enum TSYS_CMP =     5;                  /// time system: BeiDou time

static if(!is(typeof(NFREQ)))
enum NFREQ =        3;                  /// number of carrier frequencies
enum NFREQGLO =     2;                  /// number of carrier frequencies of GLONASS

static if(!is(typeof(NEXOBS)))
enum NEXOBS =       0;                  /// number of extended obs codes

enum MINPRNGPS =    1;                  /// min satellite PRN number of GPS
enum MAXPRNGPS =    32;                 /// max satellite PRN number of GPS
enum NSATGPS =      MAXPRNGPS-MINPRNGPS+1;  /// number of GPS satellites
enum NSYSGPS =      1;

version(ENAGLO){
enum MINPRNGLO =    1;                  /// min satellite slot number of GLONASS
enum MAXPRNGLO =    24;                 /// max satellite slot number of GLONASS
enum NSATGLO =      MAXPRNGLO-MINPRNGLO+1;  /// number of GLONASS satellites
enum NSYSGLO =      1;
}else{
enum MINPRNGLO =    0;
enum MAXPRNGLO =    0;
enum NSATGLO =      0;
enum NSYSGLO =      0;
}
version(ENAGAL){
enum MINPRNGAL =    1;                  /// min satellite PRN number of Galileo
enum MAXPRNGAL =    27;                 /// max satellite PRN number of Galileo
enum NSATGAL =      MAXPRNGAL-MINPRNGAL+1;  /// number of Galileo satellites
enum NSYSGAL =      1;
}else{
enum MINPRNGAL =    0;
enum MAXPRNGAL =    0;
enum NSATGAL =      0;
enum NSYSGAL =      0;
}
version(ENAQZS){
enum MINPRNQZS =    193;                /// min satellite PRN number of QZSS
enum MAXPRNQZS =    195;                /// max satellite PRN number of QZSS
enum MINPRNQZS_S =  183;                /// min satellite PRN number of QZSS SAIF
enum MAXPRNQZS_S =  185;                /// max satellite PRN number of QZSS SAIF
enum NSATQZS =      MAXPRNQZS-MINPRNQZS+1;  /// number of QZSS satellites
enum NSYSQZS =      1;
}else{
enum MINPRNQZS =    0;
enum MAXPRNQZS =    0;
enum NSATQZS =      0;
enum NSYSQZS =      0;
}
version(ENACMP){
enum MINPRNCMP =    1;                  /// min satellite sat number of BeiDou
enum MAXPRNCMP =    35;                 /// max satellite sat number of BeiDou
enum NSATCMP =      MAXPRNCMP-MINPRNCMP+1;  /// number of BeiDou satellites
enum NSYSCMP =      1;
}else{
enum MINPRNCMP =    0;
enum MAXPRNCMP =    0;
enum NSATCMP =      0;
enum NSYSCMP =      0;
}
enum NSYS =         NSYSGPS+NSYSGLO+NSYSGAL+NSYSQZS+NSYSCMP;    /// number of systems

enum MINPRNSBS =    120;                /// min satellite PRN number of SBAS
enum MAXPRNSBS =    142;                /// max satellite PRN number of SBAS
enum NSATSBS =      MAXPRNSBS-MINPRNSBS+1;  /// number of SBAS satellites

enum MAXSAT =       NSATGPS+NSATGLO+NSATGAL+NSATQZS+NSATCMP+NSATSBS;
                                        /// max satellite number (1 to MAXSAT)
static if(!is(typeof(MAXOBS)))
enum MAXOBS =       64;                 /// max number of obs in an epoch
enum MAXRCV =       64;                 /// max receiver number (1 to MAXRCV)
enum MAXOBSTYPE =   64;                 /// max number of obs type in RINEX
enum DTTOL =        0.005;              /// tolerance of time difference (s)
static if(0)
enum MAXDTOE =      10800.0;            /// max time difference to ephem Toe (s) for GPS
else
enum MAXDTOE =      7200.0;             /// max time difference to ephem Toe (s) for GPS
enum MAXDTOE_GLO =  1800.0;             /// max time difference to GLONASS Toe (s)
enum MAXDTOE_SBS =  360.0;              /// max time difference to SBAS Toe (s)
enum MAXDTOE_S =    86400.0;            /// max time difference to ephem toe (s) for other
enum MAXGDOP =      300.0;              /// max GDOP

enum MAXEXFILE =    100;                /// max number of expanded files
enum MAXSBSAGEF =   30.0;               /// max age of SBAS fast correction (s)
enum MAXSBSAGEL =   1800.0;             /// max age of SBAS long term corr (s)
enum MAXSBSURA =    8;                  /// max URA of SBAS satellite
enum MAXBAND =      10;                 /// max SBAS band of IGP
enum MAXNIGP =      201;                /// max number of IGP in SBAS band
enum MAXNGEO =      4;                  /// max number of GEO satellites
enum MAXCOMMENT =   10;                 /// max number of RINEX comments
enum MAXSTRPATH =   1024;               /// max length of stream path
enum MAXSTRMSG =    1024;               /// max length of stream message
enum MAXSTRRTK =    8;                  /// max number of stream in RTK server
enum MAXSBSMSG =    32;                 /// max number of SBAS msg in RTK server
enum MAXSOLMSG =    4096;               /// max length of solution message
enum MAXRAWLEN =    4096;               /// max length of receiver raw message
enum MAXERRMSG =    4096;               /// max length of error/warning message
enum MAXANT =       64;                 /// max length of station name/antenna type
enum MAXSOLBUF =    256;                /// max number of solution buffer
enum MAXOBSBUF =    128;                /// max number of observation data buffer
enum MAXNRPOS =     16;                 /// max number of reference positions

enum RNX2VER =      2.10;               /// RINEX ver.2 default output version
enum RNX3VER =      3.00;               /// RINEX ver.3 default output version

enum OBSTYPE_PR =   0x01;               /// observation type: pseudorange
enum OBSTYPE_CP =   0x02;               /// observation type: carrier-phase
enum OBSTYPE_DOP =  0x04;               /// observation type: doppler-freq
enum OBSTYPE_SNR =  0x08;               /// observation type: SNR
enum OBSTYPE_ALL =  0xFF;               /// observation type: all

enum FREQTYPE_L1 =  0x01;               /// frequency type: L1/E1
enum FREQTYPE_L2 =  0x02;               /// frequency type: L2/B1
enum FREQTYPE_L5 =  0x04;               /// frequency type: L5/E5a/L3
enum FREQTYPE_L6 =  0x08;               /// frequency type: E6/LEX/B3
enum FREQTYPE_L7 =  0x10;               /// frequency type: E5b/B2
enum FREQTYPE_L8 =  0x20;               /// frequency type: E5(a+b)
enum FREQTYPE_ALL = 0xFF;               /// frequency type: all

enum CODE_NONE =    0;                  /// obs code: none or unknown
enum CODE_L1C =     1;                  /// obs code: L1C/A,G1C/A,E1C (GPS,GLO,GAL,QZS,SBS)
enum CODE_L1P =     2;                  /// obs code: L1P,G1P    (GPS,GLO)
enum CODE_L1W =     3;                  /// obs code: L1 Z-track (GPS)
enum CODE_L1Y =     4;                  /// obs code: L1Y        (GPS)
enum CODE_L1M =     5;                  /// obs code: L1M        (GPS)
enum CODE_L1N =     6;                  /// obs code: L1codeless (GPS)
enum CODE_L1S =     7;                  /// obs code: L1C(D)     (GPS,QZS)
enum CODE_L1L =     8;                  /// obs code: L1C(P)     (GPS,QZS)
enum CODE_L1E =     9;                  /// obs code: L1-SAIF    (QZS)
enum CODE_L1A =     10;                 /// obs code: E1A        (GAL)
enum CODE_L1B =     11;                 /// obs code: E1B        (GAL)
enum CODE_L1X =     12;                 /// obs code: E1B+C,L1C(D+P) (GAL,QZS)
enum CODE_L1Z =     13;                 /// obs code: E1A+B+C,L1SAIF (GAL,QZS)
enum CODE_L2C =     14;                 /// obs code: L2C/A,G1C/A (GPS,GLO)
enum CODE_L2D =     15;                 /// obs code: L2 L1C/A-(P2-P1) (GPS)
enum CODE_L2S =     16;                 /// obs code: L2C(M)     (GPS,QZS)
enum CODE_L2L =     17;                 /// obs code: L2C(L)     (GPS,QZS)
enum CODE_L2X =     18;                 /// obs code: L2C(M+L),B1I+Q (GPS,QZS,CMP)
enum CODE_L2P =     19;                 /// obs code: L2P,G2P    (GPS,GLO)
enum CODE_L2W =     20;                 /// obs code: L2 Z-track (GPS)
enum CODE_L2Y =     21;                 /// obs code: L2Y        (GPS)
enum CODE_L2M =     22;                 /// obs code: L2M        (GPS)
enum CODE_L2N =     23;                 /// obs code: L2codeless (GPS)
enum CODE_L5I =     24;                 /// obs code: L5/E5aI    (GPS,GAL,QZS,SBS)
enum CODE_L5Q =     25;                 /// obs code: L5/E5aQ    (GPS,GAL,QZS,SBS)
enum CODE_L5X =     26;                 /// obs code: L5/E5aI+Q  (GPS,GAL,QZS,SBS)
enum CODE_L7I =     27;                 /// obs code: E5bI,B2I   (GAL,CMP)
enum CODE_L7Q =     28;                 /// obs code: E5bQ,B2Q   (GAL,CMP)
enum CODE_L7X =     29;                 /// obs code: E5bI+Q,B2I+Q (GAL,CMP)
enum CODE_L6A =     30;                 /// obs code: E6A        (GAL)
enum CODE_L6B =     31;                 /// obs code: E6B        (GAL)
enum CODE_L6C =     32;                 /// obs code: E6C        (GAL)
enum CODE_L6X =     33;                 /// obs code: E6B+C,LEXS+L,B3I+Q (GAL,QZS,CMP)
enum CODE_L6Z =     34;                 /// obs code: E6A+B+C    (GAL)
enum CODE_L6S =     35;                 /// obs code: LEXS       (QZS)
enum CODE_L6L =     36;                 /// obs code: LEXL       (QZS)
enum CODE_L8I =     37;                 /// obs code: E5(a+b)I   (GAL)
enum CODE_L8Q =     38;                 /// obs code: E5(a+b)Q   (GAL)
enum CODE_L8X =     39;                 /// obs code: E5(a+b)I+Q (GAL)
enum CODE_L2I =     40;                 /// obs code: B1I        (CMP)
enum CODE_L2Q =     41;                 /// obs code: B1Q        (CMP)
enum CODE_L6I =     42;                 /// obs code: B3I        (CMP)
enum CODE_L6Q =     43;                 /// obs code: B3Q        (CMP)
enum CODE_L3I =     44;                 /// obs code: G3I        (GLO)
enum CODE_L3Q =     45;                 /// obs code: G3Q        (GLO)
enum CODE_L3X =     46;                 /// obs code: G3I+Q      (GLO)
enum MAXCODE =      46;                 /// max number of obs code

enum PMODE_SINGLE = 0;                  /// positioning mode: single
enum PMODE_DGPS =   1;                  /// positioning mode: DGPS/DGNSS
enum PMODE_KINEMA = 2;                  /// positioning mode: kinematic
enum PMODE_STATIC = 3;                  /// positioning mode: static
enum PMODE_MOVEB =  4;                  /// positioning mode: moving-base
enum PMODE_FIXED =  5;                  /// positioning mode: fixed
enum PMODE_PPP_KINEMA = 6;              /// positioning mode: PPP-kinemaric
enum PMODE_PPP_STATIC = 7;              /// positioning mode: PPP-static
enum PMODE_PPP_FIXED =  8;              /// positioning mode: PPP-fixed

enum SOLF_LLH =     0;                  /// solution format: lat/lon/height
enum SOLF_XYZ =     1;                  /// solution format: x/y/z-ecef
enum SOLF_ENU =     2;                  /// solution format: e/n/u-baseline
enum SOLF_NMEA =    3;                  /// solution format: NMEA-183
enum SOLF_GSIF =    4;                  /// solution format: GSI-F1/2/3

enum SOLQ_NONE =    0;                  /// solution status: no solution
enum SOLQ_FIX =     1;                  /// solution status: fix
enum SOLQ_FLOAT =   2;                  /// solution status: float
enum SOLQ_SBAS =    3;                  /// solution status: SBAS
enum SOLQ_DGPS =    4;                  /// solution status: DGPS/DGNSS
enum SOLQ_SINGLE =  5;                  /// solution status: single
enum SOLQ_PPP =     6;                  /// solution status: PPP
enum SOLQ_DR =      7;                  /// solution status: dead reconing
enum MAXSOLQ =      7;                  /// max number of solution status

enum TIMES_GPST =   0;                  /// time system: gps time
enum TIMES_UTC =    1;                  /// time system: utc
enum TIMES_JST =    2;                  /// time system: jst

enum IONOOPT_OFF =  0;                  /// ionosphere option: correction off
enum IONOOPT_BRDC = 1;                  /// ionosphere option: broadcast model
enum IONOOPT_SBAS = 2;                  /// ionosphere option: SBAS model
enum IONOOPT_IFLC = 3;                  /// ionosphere option: L1/L2 or L1/L5 iono-free LC
enum IONOOPT_EST =  4;                  /// ionosphere option: estimation
enum IONOOPT_TEC =  5;                  /// ionosphere option: IONEX TEC model
enum IONOOPT_QZS =  6;                  /// ionosphere option: QZSS broadcast model
enum IONOOPT_LEX =  7;                  /// ionosphere option: QZSS LEX ionospehre
enum IONOOPT_STEC = 8;                  /// ionosphere option: SLANT TEC model

enum TROPOPT_OFF =  0;                  /// troposphere option: correction off
enum TROPOPT_SAAS = 1;                  /// troposphere option: Saastamoinen model
enum TROPOPT_SBAS = 2;                  /// troposphere option: SBAS model
enum TROPOPT_EST =  3;                  /// troposphere option: ZTD estimation
enum TROPOPT_ESTG = 4;                  /// troposphere option: ZTD+grad estimation
enum TROPOPT_COR =  5;                  /// troposphere option: ZTD correction
enum TROPOPT_CORG = 6;                  /// troposphere option: ZTD+grad correction

enum EPHOPT_BRDC =  0;                  /// ephemeris option: broadcast ephemeris
enum EPHOPT_PREC =  1;                  /// ephemeris option: precise ephemeris
enum EPHOPT_SBAS =  2;                  /// ephemeris option: broadcast + SBAS
enum EPHOPT_SSRAPC =    3;              /// ephemeris option: broadcast + SSR_APC
enum EPHOPT_SSRCOM =    4;              /// ephemeris option: broadcast + SSR_COM
enum EPHOPT_LEX =   5;                  /// ephemeris option: QZSS LEX ephemeris

enum ARMODE_OFF =   0;                  /// AR mode: off
enum ARMODE_CONT =  1;                  /// AR mode: continuous
enum ARMODE_INST =  2;                  /// AR mode: instantaneous
enum ARMODE_FIXHOLD =   3;              /// AR mode: fix and hold
enum ARMODE_PPPAR = 4;                  /// AR mode: PPP-AR
enum ARMODE_PPPAR_ILS = 5;              /// AR mode: PPP-AR ILS
enum ARMODE_WLNL =  6;                  /// AR mode: wide lane/narrow lane
enum ARMODE_TCAR =  7;                  /// AR mode: triple carrier ar

enum SBSOPT_LCORR = 1;                  /// SBAS option: long term correction
enum SBSOPT_FCORR = 2;                  /// SBAS option: fast correction
enum SBSOPT_ICORR = 4;                  /// SBAS option: ionosphere correction
enum SBSOPT_RANGE = 8;                  /// SBAS option: ranging

enum STR_NONE =     0;                  /// stream type: none
enum STR_SERIAL =   1;                  /// stream type: serial
enum STR_FILE =     2;                  /// stream type: file
enum STR_TCPSVR =   3;                  /// stream type: TCP server
enum STR_TCPCLI =   4;                  /// stream type: TCP client
enum STR_UDP =      5;                  /// stream type: UDP stream
enum STR_NTRIPSVR = 6;                  /// stream type: NTRIP server
enum STR_NTRIPCLI = 7;                  /// stream type: NTRIP client
enum STR_FTP =      8;                  /// stream type: ftp
enum STR_HTTP =     9;                  /// stream type: http

enum STRFMT_RTCM2 = 0;                  /// stream format: RTCM 2
enum STRFMT_RTCM3 = 1;                  /// stream format: RTCM 3
enum STRFMT_OEM4 =  2;                  /// stream format: NovAtel OEMV/4
enum STRFMT_OEM3 =  3;                  /// stream format: NovAtel OEM3
enum STRFMT_UBX =   4;                  /// stream format: u-blox LEA-*T
enum STRFMT_SS2 =   5;                  /// stream format: NovAtel Superstar II
enum STRFMT_CRES =  6;                  /// stream format: Hemisphere
enum STRFMT_STQ =   7;                  /// stream format: SkyTraq S1315F
enum STRFMT_GW10 =  8;                  /// stream format: Furuno GW10
enum STRFMT_JAVAD = 9;                  /// stream format: JAVAD GRIL/GREIS
enum STRFMT_NVS =   10;                 /// stream format: NVS NVC08C
enum STRFMT_BINEX = 11;                 /// stream format: BINEX
enum STRFMT_LEXR =  12;                 /// stream format: Furuno LPY-10000
enum STRFMT_SIRF =  13;                 /// stream format: SiRF    (reserved)
enum STRFMT_RINEX = 14;                 /// stream format: RINEX
enum STRFMT_SP3 =   15;                 /// stream format: SP3
enum STRFMT_RNXCLK =    16;             /// stream format: RINEX CLK
enum STRFMT_SBAS =  17;                 /// stream format: SBAS messages
enum STRFMT_NMEA =  18;                 /// stream format: NMEA 0183
static if(!is(typeof(EXTLEX)))
enum MAXRCVFMT =    11;                 /// max number of receiver format
else
enum MAXRCVFMT =    12;

enum STR_MODE_R =   0x1;                /// stream mode: read
enum STR_MODE_W =   0x2;                /// stream mode: write
enum STR_MODE_RW =  0x3;                /// stream mode: read/write

enum GEOID_EMBEDDED =       0;          /// geoid model: embedded geoid
enum GEOID_EGM96_M150 =     1;          /// geoid model: EGM96 15x15"
enum GEOID_EGM2008_M25 =    2;          /// geoid model: EGM2008 2.5x2.5"
enum GEOID_EGM2008_M10 =    3;          /// geoid model: EGM2008 1.0x1.0"
enum GEOID_GSI2000_M15 =    4;          /// geoid model: GSI geoid 2000 1.0x1.5"

enum COMMENTH =     "%";                /// comment line indicator for solution
enum MSG_DISCONN =  "$_DISCONNECT\r\n"; /// disconnect message

enum DLOPT_FORCE =      0x01;           /// download option: force download existing
enum DLOPT_KEEPCMP =    0x02;           /// download option: keep compressed file
enum DLOPT_HOLDERR =    0x04;           /// download option: hold on error file
enum DLOPT_HOLDLST =    0x08;           /// download option: hold on listing file

enum P2_5 =         0.03125;                /// 2^-5
enum P2_6 =         0.015625;               /// 2^-6
enum P2_11 =        4.882812500000000E-04;  /// 2^-11
enum P2_15 =        3.051757812500000E-05;  /// 2^-15
enum P2_17 =        7.629394531250000E-06;  /// 2^-17
enum P2_19 =        1.907348632812500E-06;  /// 2^-19
enum P2_20 =        9.536743164062500E-07;  /// 2^-20
enum P2_21 =        4.768371582031250E-07;  /// 2^-21
enum P2_23 =        1.192092895507810E-07;  /// 2^-23
enum P2_24 =        5.960464477539063E-08;  /// 2^-24
enum P2_27 =        7.450580596923828E-09;  /// 2^-27
enum P2_29 =        1.862645149230957E-09;  /// 2^-29
enum P2_30 =        9.313225746154785E-10;  /// 2^-30
enum P2_31 =        4.656612873077393E-10;  /// 2^-31
enum P2_32 =        2.328306436538696E-10;  /// 2^-32
enum P2_33 =        1.164153218269348E-10;  /// 2^-33
enum P2_35 =        2.910383045673370E-11;  /// 2^-35
enum P2_38 =        3.637978807091710E-12;  /// 2^-38
enum P2_39 =        1.818989403545856E-12;  /// 2^-39
enum P2_40 =        9.094947017729280E-13;  /// 2^-40
enum P2_43 =        1.136868377216160E-13;  /// 2^-43
enum P2_48 =        3.552713678800501E-15;  /// 2^-48
enum P2_50 =        8.881784197001252E-16;  /// 2^-50
enum P2_55 =        2.775557561562891E-17;  /// 2^-55

deprecated alias thread_t = std.concurrency.Tid;
deprecated alias lock_t = core.sync.mutex.Mutex;
deprecated void initlock(ref Mutex m){ m = new Mutex; }
deprecated void lock(Mutex m){ m.lock(); }
deprecated void unlock(Mutex m){ m.unlock(); }
enum FILEPATHPEP = std.path.dirSeparator;

extern(C):

/// type definitions ---------------------------------------------------------

struct gtime_t                          /// time struct
{
    time_t time;                        /// time (s) expressed by standard time_t
    double sec;                         /// fraction of second under 1 s
}

struct obsd_t                           /// observation data record
{
    gtime_t time;                       /// receiver sampling time (GPST)
    ubyte sat,rcv;                      /// satellite/receiver number
    ubyte[NFREQ+NEXOBS] SNR ;           /// signal strength (0.25 dBHz)
    ubyte[NFREQ+NEXOBS] LLI ;           /// loss of lock indicator
    ubyte[NFREQ+NEXOBS] code;           /// code indicator (CODE_???)
    double[NFREQ+NEXOBS] L;             /// observation data carrier-phase (cycle)
    double[NFREQ+NEXOBS] P;             /// observation data pseudorange (m)
    float[NFREQ+NEXOBS]  D;             /// observation data doppler frequency (Hz)
}

struct obs_t                            /// observation data
{
    int n,nmax;                         /// number of obervation data/allocated
    obsd_t* data;                       /// observation data records
}

struct erpd_t                           /// earth rotation parameter data type
{
    double mjd;                         /// mjd (days)
    double xp,yp;                       /// pole offset (rad)
    double xpr,ypr;                     /// pole offset rate (rad/day)
    double ut1_utc;                     /// ut1-utc (s)
    double lod;                         /// length of day (s/day)
}

struct erp_t                            /// earth rotation parameter type
{
    int n,nmax;                         /// number and max number of data
    erpd_t* data;                       /// earth rotation parameter data
}

struct pcv_t                            /// antenna parameter type
{
    int sat;                            /// satellite number (0:receiver)
    char[MAXANT] type;                  /// antenna type
    char[MAXANT] code;                  /// serial number or satellite code
    gtime_t ts,te;                      /// valid time start and end
    double[ 3][NFREQ] off;              /// phase center offset e/n/u or x/y/z (m)
    double[19][NFREQ] var;              /// phase center variation (m)
                                        /// el=90,85,...,0 or nadir=0,1,2,3,... (deg)
}

struct pcvs_t                           /// antenna parameters type
{
    int n,nmax;                         /// number of data/allocated
    pcv_t* pcv;                         /// antenna parameters data
}

struct alm_t                                            /// almanac type
{
    int sat;                            /// satellite number
    int svh;                            /// sv health (0:ok)
    int svconf;                         /// as and sv config
    int week;                           /// GPS/QZS: gps week, GAL: galileo week
    gtime_t toa;                        /// Toa
                                        /// SV orbit parameters
    double A,e,i0,OMG0,omg,M0,OMGd;
    double toas;                        /// Toa (s) in week
    double f0,f1;                       /// SV clock parameters (af0,af1)
}

struct eph_t                            /// GPS/QZS/GAL broadcast ephemeris type
{
    int sat;                            /// satellite number
    int iode,iodc;                      /// IODE,IODC
    int sva;                            /// SV accuracy (URA index)
    int svh;                            /// SV health (0:ok)
    int week;                           /// GPS/QZS: gps week, GAL: galileo week
    int code;                           /// GPS/QZS: code on L2, GAL/CMP: data sources
    int flag;                           /// GPS/QZS: L2 P data flag, CMP: nav type
    gtime_t toe,toc,ttr;                /// Toe,Toc,T_trans
                                        /// SV orbit parameters
    double A,e,i0,OMG0,omg,M0,deln,OMGd,idot;
    double crc,crs,cuc,cus,cic,cis;
    double toes;                        /// Toe (s) in week
    double fit;                         /// fit interval (h)
    double f0,f1,f2;                    /// SV clock parameters (af0,af1,af2)
    double[4] tgd;                      /// group delay parameters
                                        /// GPS/QZS:tgd[0]=TGD
                                        /// GAL    :tgd[0]=BGD E5a/E1,tgd[1]=BGD E5b/E1
                                        /// CMP    :tgd[0]=BGD1,tgd[1]=BGD2
    double tow;                         /// time of week of ephemeris (s) (added for SDR)
    int cnt;                            /// ephemeris decoded counter (added for SDR)
    int update;                         /// ephemeris update flag (added for SDR)
}

struct geph_t                           /// GLONASS broadcast ephemeris type
{
    int sat;                            /// satellite number
    int iode;                           /// IODE (0-6 bit of tb field)
    int frq;                            /// satellite frequency number
    int svh,sva,age;                    /// satellite health, accuracy, age of operation
    gtime_t toe;                        /// epoch of epherides (gpst)
    gtime_t tof;                        /// message frame time (gpst)
    double[3] pos;                      /// satellite position (ecef) (m)
    double[3] vel;                      /// satellite velocity (ecef) (m/s)
    double[3] acc;                      /// satellite acceleration (ecef) (m/s^2)
    double taun,gamn;                   /// SV clock bias (s)/relative freq bias
    double dtaun;                       /// delay between L1 and L2 (s)
}

struct peph_t                           /// precise ephemeris type
{
    gtime_t time;                       /// time (GPST)
    int index;                          /// ephemeris index for multiple files
    double[4][MAXSAT] pos;              /// satellite position/clock (ecef) (m|s)
    float[4][MAXSAT]  std;              /// satellite position/clock std (m|s)
}

struct pclk_t                           /// precise clock type
{
    gtime_t time;                       /// time (GPST)
    int index;                          /// clock index for multiple files
    double[1][MAXSAT] clk;              /// satellite clock (s)
    float[1][MAXSAT]  std;              /// satellite clock std (s)
}

struct seph_t                           /// SBAS ephemeris type
{
    int sat;                            /// satellite number
    gtime_t t0;                         /// reference epoch time (GPST)
    gtime_t tof;                        /// time of message frame (GPST)
    int sva;                            /// SV accuracy (URA index)
    int svh;                            /// SV health (0:ok)
    double[3] pos;                      /// satellite position (m) (ecef)
    double[3] vel;                      /// satellite velocity (m/s) (ecef)
    double[3] acc;                      /// satellite acceleration (m/s^2) (ecef)
    double af0,af1;                     /// satellite clock-offset/drift (s,s/s)
}

struct tled_t                           /// norad two line element data type
{
    char[32] name ;                     /// common name
    char[32] alias_;                    /// alias name
    char[16] satno;                     /// satellilte catalog number
    char satclass;                      /// classification
    char[16] desig;                     /// international designator
    gtime_t epoch;                      /// element set epoch (UTC)
    double ndot;                        /// 1st derivative of mean motion
    double nddot;                       /// 2st derivative of mean motion
    double bstar;                       /// B* drag term
    int etype;                          /// element set type
    int eleno;                          /// element number
    double inc;                         /// orbit inclination (deg)
    double OMG;                         /// right ascension of ascending node (deg)
    double ecc;                         /// eccentricity
    double omg;                         /// argument of perigee (deg)
    double M;                           /// mean anomaly (deg)
    double n;                           /// mean motion (rev/day)
    int rev;                            /// revolution number at epoch
}

struct tle_t                            /// norad two line element type
{
    int n,nmax;                         /// number/max number of two line element data
    tled_t* data;                       /// norad two line element data
}

struct tec_t                            /// TEC grid type
{
    gtime_t time;                       /// epoch time (GPST)
    int[3] ndata;                       /// TEC grid data size {nlat,nlon,nhgt}
    double rb;                          /// earth radius (km)
    double[3] lats;                     /// latitude start/interval (deg)
    double[3] lons;                     /// longitude start/interval (deg)
    double[3] hgts;                     /// heights start/interval (km)
    double* data;                       /// TEC grid data (tecu)
    float* rms;                         /// RMS values (tecu)
}

struct stecd_t                          /// stec data type
{
    gtime_t time;                       /// time (GPST)
    ubyte sat;                          /// satellite number
    ubyte slip;                         /// slip flag
    float iono;                         /// L1 ionosphere delay (m)
    float rate;                         /// L1 ionosphere rate (m/s)
    float rms;                          /// rms value (m)
}

struct stec_t                           /// stec grid type
{
    double[2] pos;                      /// latitude/longitude (deg)
    int[MAXSAT] index;                  /// search index
    int n,nmax;                         /// number of data
    stecd_t* data;                      /// stec data
}

struct zwdd_t                           /// zwd data type
{
    gtime_t time;                       /// time (GPST)
    float zwd;                          /// zenith wet delay (m)
    float rms;                          /// rms value (m)
}

struct zwd_t                            /// zwd grid type
{
    float[2] pos;                       /// latitude,longitude (rad)
    int n,nmax;                         /// number of data
    zwdd_t* data;                       /// zwd data
}

struct sbsmsg_t                         /// SBAS message type
{
    int week,tow;                       /// receiption time
    int prn;                            /// SBAS satellite PRN number
    ubyte[29] msg;                      /// SBAS message (226bit) padded by 0
};

struct sbs_t                            /// SBAS messages type
{
    int n,nmax;                         /// number of SBAS messages/allocated
    sbsmsg_t* msgs;                     /// SBAS messages
}

struct sbsfcorr_t                       /// SBAS fast correction type
{
    gtime_t t0;                         /// time of applicability (TOF)
    double prc;                         /// pseudorange correction (PRC) (m)
    double rrc;                         /// range-rate correction (RRC) (m/s)
    double dt;                          /// range-rate correction delta-time (s)
    int iodf;                           /// IODF (issue of date fast corr)
    short udre;                         /// UDRE+1
    short ai;                           /// degradation factor indicator
}

struct sbslcorr_t                       /// SBAS long term satellite error correction type
{
    gtime_t t0;                         /// correction time
    int iode;                           /// IODE (issue of date ephemeris)
    double[3] dpos;                     /// delta position (m) (ecef)
    double[3] dvel;                     /// delta velocity (m/s) (ecef)
    double daf0,daf1;                   /// delta clock-offset/drift (s,s/s)
}

struct sbssatp_t                        /// SBAS satellite correction type
{
    int sat;                            /// satellite number
    sbsfcorr_t fcorr;                   /// fast correction
    sbslcorr_t lcorr;                   /// long term correction
}

struct sbssat_t                         /// SBAS satellite corrections type
{
    int iodp;                           /// IODP (issue of date mask)
    int nsat;                           /// number of satellites
    int tlat;                           /// system latency (s)
    sbssatp_t[MAXSAT] sat;              /// satellite correction
}

struct sbsigp_t                         /// SBAS ionospheric correction type
{
    gtime_t t0;                         /// correction time
    short lat,lon;                      /// latitude/longitude (deg)
    short give;                         /// GIVI+1
    float delay;                        /// vertical delay estimate (m)
}

struct sbsigpband_t                     /// IGP band type
{
    short x;                            /// longitude/latitude (deg)
    const(short)* y;                    /// latitudes/longitudes (deg)
    ubyte bits;                         /// IGP mask start bit
    ubyte bite;                         /// IGP mask end bit
}

struct sbsion_t                         /// SBAS ionospheric corrections type
{
    int iodi;                           /// IODI (issue of date ionos corr)
    int nigp;                           /// number of igps
    sbsigp_t[MAXNIGP] igp;              /// ionospheric correction
}

struct dgps_t                           /// DGPS/GNSS correction type
{
    gtime_t t0;                         /// correction time
    double prc;                         /// pseudorange correction (PRC) (m)
    double rrc;                         /// range rate correction (RRC) (m/s)
    int iod;                            /// issue of data (IOD)
    double udre;                        /// UDRE
}

struct ssr_t                            /// SSR correction type
{
    gtime_t[5] t0;                      /// epoch time (GPST) {eph,clk,hrclk,ura,bias}
    double[5] udi;                      /// SSR update interval (s)
    int[5] iod;                         /// iod ssr {eph,clk,hrclk,ura,bias}
    int iode;                           /// issue of data
    int ura;                            /// URA indicator
    int refd;                           /// sat ref datum (0:ITRF,1:regional)
    double[3] deph;                     /// delta orbit {radial,along,cross} (m)
    double[3] ddeph;                    /// dot delta orbit {radial,along,cross} (m/s)
    double[3] dclk;                     /// delta clock {c0,c1,c2} (m,m/s,m/s^2)
    double hrclk;                       /// high-rate clock corection (m)
    float[MAXCODE] cbias;               /// code biases (m)
    ubyte update;                       /// update flag (0:no update,1:update)
}

struct lexmsg_t                         /// QZSS LEX message type
{
    int prn;                            /// satellite PRN number
    int type;                           /// message type
    int alert;                          /// alert flag
    ubyte stat;                         /// signal tracking status
    ubyte snr;                          /// signal C/N0 (0.25 dBHz)
    uint ttt;                           /// tracking time (ms)
    ubyte[212] msg;                     /// LEX message data part 1695 bits
}

struct lex_t                            /// QZSS LEX messages type
{
    int n,nmax;                         /// number of LEX messages and allocated
    lexmsg_t* msgs;                     /// LEX messages
}

struct lexeph_t                         /// QZSS LEX ephemeris type
{
    gtime_t toe;                        /// epoch time (GPST)
    gtime_t tof;                        /// message frame time (GPST)
    int sat;                            /// satellite number
    ubyte health;                       /// signal health (L1,L2,L1C,L5,LEX)
    ubyte ura;                          /// URA index
    double[3] pos;                      /// satellite position (m)
    double[3] vel;                      /// satellite velocity (m/s)
    double[3] acc;                      /// satellite acceleration (m/s2)
    double[3] jerk;                     /// satellite jerk (m/s3)
    double af0,af1;                     /// satellite clock bias and drift (s,s/s)
    double tgd;                         /// TGD
    double[8] isc;                      /// ISC
}

struct lexion_t                         /// QZSS LEX ionosphere correction type
{
    gtime_t t0;                         /// epoch time (GPST)
    double tspan;                       /// valid time span (s)
    double pos0[2];                     /// reference position {lat,lon} (rad)
    double coef[3][2];                  /// coefficients lat x lon (3 x 2)
}

struct nav_t                            /// navigation data type
{
    int n,nmax;                         /// number of broadcast ephemeris
    int ng,ngmax;                       /// number of glonass ephemeris
    int ns,nsmax;                       /// number of sbas ephemeris
    int ne,nemax;                       /// number of precise ephemeris
    int nc,ncmax;                       /// number of precise clock
    int na,namax;                       /// number of almanac data
    int nt,ntmax;                       /// number of tec grid data
    int nn,nnmax;                       /// number of stec grid data
    eph_t* eph;                         /// GPS/QZS/GAL ephemeris
    geph_t* geph;                       /// GLONASS ephemeris
    seph_t* seph;                       /// SBAS ephemeris
    peph_t* peph;                       /// precise ephemeris
    pclk_t* pclk;                       /// precise clock
    alm_t* alm;                         /// almanac data
    tec_t* tec;                         /// tec grid data
    stec_t* stec;                       /// stec grid data
    erp_t  erp;                         /// earth rotation parameters
    double[4] utc_gps;                  /// GPS delta-UTC parameters {A0,A1,T,W}
    double[4] utc_glo;                  /// GLONASS UTC GPS time parameters
    double[4] utc_gal;                  /// Galileo UTC GPS time parameters
    double[4] utc_qzs;                  /// QZS UTC GPS time parameters
    double[4] utc_cmp;                  /// BeiDou UTC parameters
    double[4] utc_sbs;                  /// SBAS UTC parameters
    double[8] ion_gps;                  /// GPS iono model parameters {a0,a1,a2,a3,b0,b1,b2,b3}
    double[4] ion_gal;                  /// Galileo iono model parameters {ai0,ai1,ai2,0}
    double[8] ion_qzs;                  /// QZSS iono model parameters {a0,a1,a2,a3,b0,b1,b2,b3}
    double[8] ion_cmp;                  /// BeiDou iono model parameters {a0,a1,a2,a3,b0,b1,b2,b3}
    int leaps;                          /// leap seconds (s)
    double[NFREQ][MAXSAT] lam;          /// carrier wave lengths (m)
    double[3][MAXSAT] cbias;            /// code bias (0:p1-p2,1:p1-c1,2:p2-c2) (m)
    double[MAXSAT] wlbias;              /// wide-lane bias (cycle)
    double[4] glo_cpbias;               /// glonass code-phase bias {1C,1P,2C,2P} (m)
    char[MAXPRNGLO+1] glo_fcn;          /// glonass frequency channel number + 8
    pcv_t[MAXSAT] pcvs;                 /// satellite antenna pcv
    sbssat_t sbssat;                    /// SBAS satellite corrections
    sbsion_t[MAXBAND+1] sbsion;         /// SBAS ionosphere corrections
    dgps_t[MAXSAT] dgps;                /// DGPS corrections
    ssr_t[MAXSAT] ssr;                  /// SSR corrections
    lexeph_t[MAXSAT] lexeph;            /// LEX ephemeris
    lexion_t lexion;                    /// LEX ionosphere correction
}

struct sta_t                            /// station parameter type
{
    char[MAXANT] name   ;               /// marker name
    char[MAXANT] marker ;               /// marker number
    char[MAXANT] antdes ;               /// antenna descriptor
    char[MAXANT] antsno ;               /// antenna serial number
    char[MAXANT] rectype;               /// receiver type descriptor
    char[MAXANT] recver ;               /// receiver firmware version
    char[MAXANT] recsno ;               /// receiver serial number
    int antsetup;                       /// antenna setup id
    int itrf;                           /// ITRF realization year
    int deltype;                        /// antenna delta type (0:enu,1:xyz)
    double[3] pos;                      /// station position (ecef) (m)
    double[3] del;                      /// antenna position delta (e/n/u or x/y/z) (m)
    double hgt;                         /// antenna height (m)
}

struct sol_t                            /// solution type
{
    gtime_t time;                       /// time (GPST)
    double[6] rr;                       /// position/velocity (m|m/s)
                                        /// {x,y,z,vx,vy,vz} or {e,n,u,ve,vn,vu}
    float[6]  qr;                       /// position variance/covariance (m^2)
                                        /// {c_xx,c_yy,c_zz,c_xy,c_yz,c_zx} or
                                        /// {c_ee,c_nn,c_uu,c_en,c_nu,c_ue}
    double[6] dtr;                      /// receiver clock bias to time systems (s)
    ubyte type;                         /// type (0:xyz-ecef,1:enu-baseline)
    ubyte stat;                         /// solution status (SOLQ_???)
    ubyte ns;                           /// number of valid satellites
    float age;                          /// age of differential (s)
    float ratio;                        /// AR ratio factor for valiation
}

struct solbuf_t                         /// solution buffer type
{
    int n,nmax;                         /// number of solution/max number of buffer
    int cyclic;                         /// cyclic buffer flag
    int start,end;                      /// start/end index
    gtime_t time;                       /// current solution time
    sol_t* data;                        /// solution data
    double[3] rb;                       /// reference position {x,y,z} (ecef) (m)
    ubyte[MAXSOLMSG+1] buff;            /// message buffer
    int nb;                             /// number of byte in message buffer
}

struct solstat_t                        /// solution status type
{
    gtime_t time;                       /// time (GPST)
    ubyte sat;                          /// satellite number
    ubyte frq;                          /// frequency (1:L1,2:L2,...)
    float az,el;                        /// azimuth/elevation angle (rad)
    float resp;                         /// pseudorange residual (m)
    float resc;                         /// carrier-phase residual (m)
    ubyte flag;                         /// flags: (vsat<<5)+(slip<<3)+fix
    ubyte snr;                          /// signal strength (0.25 dBHz)
    ushort lock;                        /// lock counter
    ushort outc;                        /// outage counter
    ushort slipc;                       /// slip counter
    ushort rejc;                        /// reject counter
}

struct solstatbuf_t                     /// solution status buffer type
{
    int n,nmax;                         /// number of solution/max number of buffer
    solstat_t* data;                    /// solution status data
}

struct rtcm_t                           /// RTCM control struct type
{
    int staid;                          /// station id
    int stah;                           /// station health
    int seqno;                          /// sequence number for rtcm 2 or iods msm
    int outtype;                        /// output message type
    gtime_t time;                       /// message time
    gtime_t time_s;                     /// message start time
    obs_t obs;                          /// observation data (uncorrected)
    nav_t nav;                          /// satellite ephemerides
    sta_t sta;                          /// station parameters
    dgps_t* dgps;                       /// output of dgps corrections
    ssr_t[MAXSAT] ssr;                  /// output of ssr corrections
    char[128] msg;                      /// special message
    char[256] msgtype;                  /// last message type
    char[128][6] msmtype;               /// msm signal types
    int obsflag;                        /// obs data complete flag (1:ok,0:not complete)
    int ephsat;                         /// update satellite of ephemeris
    double[NFREQ+NEXOBS][MAXSAT] cp;        /// carrier-phase measurement
    ubyte[NFREQ+NEXOBS][MAXSAT] lock;       /// lock time
    ubyte[NFREQ+NEXOBS][MAXSAT] loss;       /// loss of lock count
    gtime_t[NFREQ+NEXOBS][MAXSAT] lltime;   /// last lock time
    int nbyte;                          /// number of bytes in message buffer 
    int nbit;                           /// number of bits in word buffer 
    int len;                            /// message length (bytes)
    ubyte[1200] buff;                   /// message buffer
    uint word;                          /// word buffer for rtcm 2
    uint[100] nmsg2;                    /// message count of RTCM 2 (1-99:1-99,0:other)
    uint[300] nmsg3;                    /// message count of RTCM 3 (1-299:1001-1299,0:ohter)
    char[300] opt;                      /// RTCM dependent options
}

struct rnxctr_t                         /// rinex control struct type
{
    gtime_t time;                       /// message time
    double ver;                         /// rinex version
    char   type;                        /// rinex file type ('O','N',...)
    int    sys;                         /// navigation system
    int    tsys;                        /// time system
    char[4][MAXOBSTYPE][6]   tobs;      /// rinex obs types
    obs_t  obs;                         /// observation data
    nav_t  nav;                         /// navigation data
    sta_t  sta;                         /// station info
    int    ephsat;                      /// ephemeris satellite number
    char[256]   opt;                    /// rinex dependent options
}

struct url_t                            /// download url type
{
    char[32] type;                      /// data type
    char[1024] path;                    /// url path
    char[1024] dir;                     /// local directory
    double tint;                        /// time interval (s)
}

struct opt_t                            /// option type
{
    char* name;                         /// option name
    int format;                         /// option format (0:int,1:double,2:string,3:enum)
    void* var;                          /// pointer to option variable
    char* comment;                      /// option comment/enum labels/unit
}

struct exterr_t                         /// extended receiver error model
{
    int[4] ena;                         /// model enabled
    double[NFREQ*2][4] cerr;            /// code errors (m)
    double[NFREQ*2][4] perr;            /// carrier-phase errors (m)
    double[NFREQ] gpsglob;              /// gps-glonass h/w bias (m)
    double[NFREQ] gloicb ;              /// glonass interchannel bias (m/fn)
}

struct snrmask_t                        /// SNR mask type
{
    int[2] ena;                         /// enable flag {rover,base}
    double[9][NFREQ] mask;              /// mask (dBHz) at 5,10,...85 deg
}

struct prcopt_t                         /// processing options type
{
    int mode;                           /// positioning mode (PMODE_???)
    int soltype;                        /// solution type (0:forward,1:backward,2:combined)
    int nf;                             /// number of frequencies (1:L1,2:L1+L2,3:L1+L2+L5)
    int navsys;                         /// navigation system
    double elmin;                       /// elevation mask angle (rad)
    snrmask_t snrmask;                  /// SNR mask
    int sateph;                         /// satellite ephemeris/clock (EPHOPT_???)
    int modear;                         /// AR mode (0:off,1:continuous,2:instantaneous,3:fix and hold,4:ppp-ar)
    int glomodear;                      /// GLONASS AR mode (0:off,1:on,2:auto cal,3:ext cal)
    int maxout;                         /// obs outage count to reset bias
    int minlock;                        /// min lock count to fix ambiguity
    int minfix;                         /// min fix count to hold ambiguity
    int ionoopt;                        /// ionosphere option (IONOOPT_???)
    int tropopt;                        /// troposphere option (TROPOPT_???)
    int dynamics;                       /// dynamics model (0:none,1:velociy,2:accel)
    int tidecorr;                       /// earth tide correction (0:off,1:solid,2:solid+otl+pole)
    int niter;                          /// number of filter iteration
    int codesmooth;                     /// code smoothing window size (0:none)
    int intpref;                        /// interpolate reference obs (for post mission)
    int sbascorr;                       /// SBAS correction options
    int sbassatsel;                     /// SBAS satellite selection (0:all)
    int rovpos;                         /// rover position for fixed mode
    int refpos;                         /// base position for relative mode
                                        /// (0:pos in prcopt,  1:average of single pos,
                                        ///  2:read from file, 3:rinex header, 4:rtcm pos)
    double[NFREQ] eratio;               /// code/phase error ratio
    double[5] err;                      /// measurement error factor
                                        /// [0]:reserved
                                        /// [1-3]:error factor a/b/c of phase (m)
                                        /// [4]:doppler frequency (hz)
    double[3] std;                      /// initial-state std [0]bias,[1]iono [2]trop
    double[5] prn;                      /// process-noise std [0]bias,[1]iono [2]trop [3]acch [4]accv
    double sclkstab;                    /// satellite clock stability (sec/sec)
    double[4] thresar;                  /// AR validation threshold
    double elmaskar;                    /// elevation mask of AR for rising satellite (deg)
    double elmaskhold;                  /// elevation mask to hold ambiguity (deg)
    double thresslip;                   /// slip threshold of geometry-free phase (m)
    double maxtdiff;                    /// max difference of time (sec)
    double maxinno;                     /// reject threshold of innovation (m)
    double maxgdop;                     /// reject threshold of gdop
    double[2] baseline;                 /// baseline length constraint {const,sigma} (m)
    double[3] ru;                       /// rover position for fixed mode {x,y,z} (ecef) (m)
    double[3] rb;                       /// base position for relative mode {x,y,z} (ecef) (m)
    char[MAXANT][2] anttype;            /// antenna types {rover,base}
    double[3][2] antdel;                /// antenna delta {{rov_e,rov_n,rov_u},{ref_e,ref_n,ref_u}}
    pcv_t[2] pcvr;                      /// receiver antenna parameters {rov,base}
    ubyte[MAXSAT] exsats;               /// excluded satellites (1:excluded,2:included)
    char[256][2] rnxopt;                /// rinex options {rover,base}
    int[6]  posopt;                     /// positioning options
    int  syncsol;                       /// solution sync mode (0:off,1:on)
    double[6*11][2] odisp;              /// ocean tide loading parameters {rov,base}
    exterr_t exterr;                    /// extended receiver error model
}

struct solopt_t                         /// solution options type
{
    int posf;                           /// solution format (SOLF_???)
    int times;                          /// time system (TIMES_???)
    int timef;                          /// time format (0:sssss.s,1:yyyy/mm/dd hh:mm:ss.s)
    int timeu;                          /// time digits under decimal point
    int degf;                           /// latitude/longitude format (0:ddd.ddd,1:ddd mm ss)
    int outhead;                        /// output header (0:no,1:yes)
    int outopt;                         /// output processing options (0:no,1:yes)
    int datum;                          /// datum (0:WGS84,1:Tokyo)
    int height;                         /// height (0:ellipsoidal,1:geodetic)
    int geoid;                          /// geoid model (0:EGM96,1:JGD2000)
    int solstatic;                      /// solution of static mode (0:all,1:single)
    int sstat;                          /// solution statistics level (0:off,1:states,2:residuals)
    int trace;                          /// debug trace level (0:off,1-5:debug)
    double[2] nmeaintv;                 /// nmea output interval (s) (<0:no,0:all)
                                        /// nmeaintv[0]:gprmc,gpgga,nmeaintv[1]:gpgsv
    char[64] sep;                       /// field separator
    char[64] prog;                      /// program name
}

struct filopt_t                         /// file options type
{
    char[MAXSTRPATH] satantp;           /// satellite antenna parameters file
    char[MAXSTRPATH] rcvantp;           /// receiver antenna parameters file
    char[MAXSTRPATH] stapos ;           /// station positions file
    char[MAXSTRPATH] geoid  ;           /// external geoid data file
    char[MAXSTRPATH] iono   ;           /// ionosphere data file
    char[MAXSTRPATH] dcb    ;           /// dcb data file
    char[MAXSTRPATH] eop    ;           /// eop data file
    char[MAXSTRPATH] blq    ;           /// ocean tide loading blq file
    char[MAXSTRPATH] tempdir;           /// ftp/http temporaly directory
    char[MAXSTRPATH] geexe  ;           /// google earth exec file
    char[MAXSTRPATH] solstat;           /// solution statistics file
    char[MAXSTRPATH] trace  ;           /// debug trace file
}

struct rnxopt_t                         /// RINEX options type
{
    gtime_t ts,te;                      /// time start/end
    double tint;                        /// time interval (s)
    double tunit;                       /// time unit for multiple-session (s)
    double rnxver;                      /// RINEX version
    int navsys;                         /// navigation system
    int obstype;                        /// observation type
    int freqtype;                       /// frequency type
    char[64][6] mask;                   /// code mask {GPS,GLO,GAL,QZS,SBS,CMP}
    char[32] staid ;                    /// station id for rinex file name
    char[32] prog  ;                    /// program
    char[32] runby ;                    /// run-by
    char[64] marker;                    /// marker name
    char[32] markerno;                  /// marker number
    char[32] markertype;                /// marker type (ver.3)
    char[32][2] name;                   /// observer/agency
    char[32][3] rec ;                   /// receiver #/type/vers
    char[32][3] ant ;                   /// antenna #/type
    double[3] apppos;                   /// approx position x/y/z
    double[3] antdel;                   /// antenna delta h/e/n
    char[64][MAXCOMMENT] comment;       /// comments
    char[256] rcvopt;                   /// receiver dependent options
    ubyte[MAXSAT] exsats;               /// excluded satellites
    int scanobs;                        /// scan obs types
    int outiono;                        /// output iono correction
    int outtime;                        /// output time system correction
    int outleaps;                       /// output leap seconds
    int autopos;                        /// auto approx position
    gtime_t tstart;                     /// first obs time
    gtime_t tend;                       /// last obs time
    gtime_t trtcm;                      /// approx log start time for rtcm
    char[4][MAXOBSTYPE][6] tobs;        /// obs types {GPS,GLO,GAL,QZS,SBS,CMP}
    int[6] nobs;                        /// number of obs types {GPS,GLO,GAL,QZS,SBS,CMP}
}

struct ssat_t                           /// satellite status type
{
    ubyte sys;                          /// navigation system
    ubyte vs;                           /// valid satellite flag single
    double[2] azel[2];                     /// azimuth/elevation angles {az,el} (rad)
    double[NFREQ] resp;                 /// residuals of pseudorange (m)
    double[NFREQ] resc;                 /// residuals of carrier-phase (m)
    ubyte[NFREQ] vsat;                  /// valid satellite flag
    ubyte[NFREQ] snr ;                  /// signal strength (0.25 dBHz)
    ubyte[NFREQ] fix ;                  /// ambiguity fix flag (1:fix,2:float,3:hold)
    ubyte[NFREQ] slip;                  /// cycle-slip flag
    uint[NFREQ] lock ;                  /// lock counter of phase
    uint[NFREQ] outc ;                  /// obs outage counter of phase
    uint[NFREQ] slipc;                  /// cycle-slip counter
    uint[NFREQ] rejc ;                  /// reject counter
    double  gf;                         /// geometry-free phase L1-L2 (m)
    double  gf2;                        /// geometry-free phase L1-L5 (m)
    double  phw;                        /// phase windup (cycle)
    gtime_t[NFREQ][2] pt;               /// previous carrier-phase time
    double[NFREQ][2]  ph;               /// previous carrier-phase observable (cycle)
}

struct ambc_t                           /// ambiguity control type
{
    gtime_t[4] epoch;                   /// last epoch
    int fixcnt;                         /// fix counter
    char[MAXSAT] flags;                 /// fix flags
    double[4] n;                        /// number of epochs
    double[4] LC ;                      /// linear combination average
    double[4] LCv;                      /// linear combination variance
}

struct rtk_t                            /// RTK control/result type
{
    sol_t  sol;                         /// RTK solution
    double[6] rb;                       /// base position/velocity (ecef) (m|m/s)
    int nx,na;                          /// number of float states/fixed states
    double tt;                          /// time difference between current and previous (s)
    double* x,  P;                      /// float states and their covariance
    double* xa, Pa;                     /// fixed states and their covariance
    int nfix;                           /// number of continuous fixes of ambiguity
    ambc_t[MAXSAT] ambc;                /// ambibuity control
    ssat_t[MAXSAT] ssat;                /// satellite status
    int neb;                            /// bytes in error message buffer
    char[MAXERRMSG] errbuf;             /// error message buffer
    prcopt_t opt;                       /// processing options
}

struct raw_t                            /// receiver raw data control type
{
    gtime_t time;                       /// message time
    gtime_t tobs;                       /// observation data time
    obs_t obs;                          /// observation data
    obs_t obuf;                         /// observation data buffer
    nav_t nav;                          /// satellite ephemerides
    sta_t sta;                          /// station parameters
    int ephsat;                         /// sat number of update ephemeris (0:no satellite)
    sbsmsg_t sbsmsg;                    /// SBAS message
    char[256] msgtype;                  /// last message type
    ubyte[150][MAXSAT] subfrm;          /// subframe buffer (1-5)
    lexmsg_t lexmsg;                    /// LEX message
    double[NFREQ+NEXOBS][MAXSAT] lockt; /// lock time (s)
    double[MAXSAT] icpp,off;            /// carrier params for ss2
    double icpc;                        /// ditto
    double[MAXSAT] prCA,dpCA;           /// L1/CA pseudrange/doppler for javad
    ubyte[NFREQ+NEXOBS][MAXSAT] halfc;  /// half-cycle add flag
    char[MAXOBS] freqn;                 /// frequency number for javad
    int nbyte;                          /// number of bytes in message buffer 
    int len;                            /// message length (bytes)
    int iod;                            /// issue of data
    int tod;                            /// time of day (ms)
    int tbase;                          /// time base (0:gpst,1:utc(usno),2:glonass,3:utc(su)
    int flag;                           /// general purpose flag
    int outtype;                        /// output message type
    ubyte[MAXRAWLEN] buff;              /// message buffer
    char[256] opt;                      /// receiver dependent options
}

struct stream_t                         /// stream type
{
    int type;                           /// type (STR_???)
    int mode;                           /// mode (STR_MODE_?)
    int state;                          /// state (-1:error,0:close,1:open)
    uint inb,inr;                       /// input bytes/rate
    uint outb,outr;                     /// output bytes/rate
    uint tick,tact;                     /// tick/active tick
    uint inbt,outbt;                    /// input/output bytes at tick
    lock_t lock;                        /// lock flag
    void* port;                         /// type dependent port control struct
    char[MAXSTRPATH] path;              /// stream path
    char[MAXSTRMSG] msg ;               /// stream message
}

struct strconv_t                        /// stream converter type
{
    int itype,otype;                    /// input and output stream type
    int nmsg;                           /// number of output messages
    int[32] msgs;                       /// output message types
    double[32] tint;                    /// output message intervals (s)
    uint[32] tick;                      /// cycle tick of output message
    int[32] ephsat;                     /// satellites of output ephemeris
    int stasel;                         /// station info selection (0:remote,1:local)
    rtcm_t rtcm;                        /// rtcm input data buffer
    raw_t raw;                          /// raw  input data buffer
    rtcm_t out_;                        /// rtcm output data buffer
}

struct strsvr_t                         /// stream server type
{
    int state;                          /// server state (0:stop,1:running)
    int cycle;                          /// server cycle (ms)
    int buffsize;                       /// input/monitor buffer size (bytes)
    int nmeacycle;                      /// NMEA request cycle (ms) (0:no)
    int nstr;                           /// number of streams (1 input + (nstr-1) outputs
    int npb;                            /// data length in peek buffer (bytes)
    double[3] nmeapos;                  /// NMEA request position (ecef) (m)
    ubyte* buff;                        /// input buffers
    ubyte* pbuf;                        /// peek buffer
    uint tick;                          /// start tick
    stream_t[16] stream;                /// input/output streams
    strconv_t*[16] conv;                /// stream converter
    thread_t thread;         /// server thread
    lock_t lock;             /// lock flag
}

struct rtksvr_t                         /// RTK server type
{
    int state;                          /// server state (0:stop,1:running)
    int cycle;                          /// processing cycle (ms)
    int nmeacycle;                      /// NMEA request cycle (ms) (0:no req)
    int nmeareq;                        /// NMEA request (0:no,1:nmeapos,2:single sol)
    double[3] nmeapos;                  /// NMEA request position (ecef) (m)
    int buffsize;                       /// input buffer size (bytes)
    int[3] format;                      /// input format {rov,base,corr}
    solopt_t[2] solopt;                 /// output solution options {sol1,sol2}
    int navsel;                         /// ephemeris select (0:all,1:rover,2:base,3:corr)
    int nsbs;                           /// number of sbas message
    int nsol;                           /// number of solution buffer
    rtk_t rtk;                          /// RTK control/result struct
    int[3] nb ;                         /// bytes in input buffers {rov,base}
    int[2] nsb;                         /// bytes in soulution buffers
    int[3] npb;                         /// bytes in input peek buffers
    ubyte*[3] buff;                     /// input buffers {rov,base,corr}
    ubyte*[2] sbuf;                     /// output buffers {sol1,sol2}
    ubyte*[3] pbuf;                     /// peek buffers {rov,base,corr}
    sol_t[MAXSOLBUF] solbuf;            /// solution buffer
    uint[10][3] nmsg;                   /// input message counts
    raw_t[3]  raw ;                     /// receiver raw control {rov,base,corr}
    rtcm_t[3] rtcm;                     /// RTCM control {rov,base,corr}
    gtime_t[3] ftime;                   /// download time {rov,base,corr}
    char[MAXSTRPATH][3] files;          /// download paths {rov,base,corr}
    obs_t[MAXOBSBUF][3] obs;            /// observation data {rov,base,corr}
    nav_t nav;                          /// navigation data
    sbsmsg_t[MAXSBSMSG] sbsmsg;         /// SBAS message buffer
    stream_t[3] stream;                 /// streams {rov,base,corr,sol1,sol2,logr,logb,logc}
    stream_t* moni;                     /// monitor stream
    uint tick;                          /// start tick
    thread_t thread;                    /// server thread
    int cputime;                        /// CPU time (ms) for a processing cycle
    int prcout;                         /// missing observation data count
    lock_t lock;             /// lock flag
}


/// global variables ---------------------------------------------------------
__gshared extern{
const double* chisqr;           /// chi-sqr(n) table (alpha=0.001)
const double* lam_carr;         /// carrier wave length (m) {L1,L2,...}
const prcopt_t prcopt_default;   /// default positioning options
const solopt_t solopt_default;   /// default solution output options
const sbsigpband_t[8]* igpband1;/// SBAS IGP band 0-8
const sbsigpband_t[8]* igpband2;/// SBAS IGP band 9-10
const char*[] formatstrs;        /// stream format strings
opt_t* sysopts;                 /// system options table
}

/// satellites, systems, codes functions -------------------------------------
extern int  satno   (int sys, int prn);
extern int  satsys  (int sat, int* prn);
extern int  satid2no(const char* id);
extern void satno2id(int sat, char* id);
extern ubyte obs2code(const char* obs, int* freq);
extern char* code2obs(ubyte code, int* freq);
extern int  satexclude(int sat, int svh, const prcopt_t* opt);
extern int  testsnr(int base, int freq, double el, double snr,
                    const snrmask_t* mask);
extern void setcodepri(int sys, int freq, const char* pri);
extern int  getcodepri(int sys, ubyte code, const char* opt);

/// matrix and vector functions ----------------------------------------------
extern double* mat  (int n, int m);
extern int  *  imat (int n, int m);
extern double* zeros(int n, int m);
extern double* eye  (int n);
extern double dot (const double* a, const double* b, int n);
extern double norm(const double* a, int n);
extern void cross3(const double* a, const double* b, double* c);
extern int  normv3(const double* a, double* b);
extern void matcpy(double* A, const double* B, int n, int m);
extern void matmul(const char* tr, int n, int k, int m, double alpha,
                   const double* A, const double* B, double beta, double* C);
extern int  matinv(double* A, int n);
extern int  solve (const char* tr, const double* A, const double* Y, int n,
                   int m, double* X);
extern int  lsq   (const double* A, const double* y, int n, int m, double* x,
                   double* Q);
extern int  filter(double* x, double* P, const double* H, const double* v,
                   const double* R, int n, int m);
extern int  smoother(const double* xf, const double* Qf, const double* xb,
                     const double* Qb, int n, double* xs, double* Qs);
extern void matprint (const double* A, int n, int m, int p, int q);
extern void matfprint(const double* A, int n, int m, int p, int q, FILE* fp);

/// time and string functions ------------------------------------------------
extern double  str2num(const char* s, int i, int n);
extern int     str2time(const char* s, int i, int n, gtime_t* t);
extern void    time2str(gtime_t t, char* str, int n);
extern gtime_t epoch2time(const double* ep);
extern void    time2epoch(gtime_t t, double* ep);
extern gtime_t gpst2time(int week, double sec);
extern double  time2gpst(gtime_t t, int* week);
extern gtime_t gst2time(int week, double sec);
extern double  time2gst(gtime_t t, int* week);
extern gtime_t bdt2time(int week, double sec);
extern double  time2bdt(gtime_t t, int* week);
extern char  *  time_str(gtime_t t, int n);

extern gtime_t timeadd  (gtime_t t, double sec);
extern double  timediff (gtime_t t1, gtime_t t2);
extern gtime_t gpst2utc (gtime_t t);
extern gtime_t utc2gpst (gtime_t t);
extern gtime_t gpst2bdt (gtime_t t);
extern gtime_t bdt2gpst (gtime_t t);
extern gtime_t timeget  ();
extern void    timeset  (gtime_t t);
extern double  time2doy (gtime_t t);
extern double  utc2gmst (gtime_t t, double ut1_utc);

extern int adjgpsweek(int week);
extern uint tickget();
extern void sleepms(int ms);

extern int reppath(const char* path, char* rpath, gtime_t time, const char* rov,
                   const char* base);
extern int reppaths(const char* path, char* rpaths[], int nmax, gtime_t ts,
                    gtime_t te, const char* rov, const char* base);

/// coordinates transformation -----------------------------------------------
extern void ecef2pos(const double* r, double* pos);
extern void pos2ecef(const double* pos, double* r);
extern void ecef2enu(const double* pos, const double* r, double* e);
extern void enu2ecef(const double* pos, const double* e, double* r);
extern void covenu  (const double* pos, const double* P, double* Q);
extern void covecef (const double* pos, const double* Q, double* P);
extern void xyz2enu (const double* pos, double* E);
extern void eci2ecef(gtime_t tutc, const double* erpv, double* U, double* gmst);
extern void deg2dms (double deg, double* dms);
extern double dms2deg(const double* dms);

/// input and output functions -----------------------------------------------
extern void readpos(const char* file, const char* rcv, double* pos);
extern int  sortobs(obs_t* obs);
extern void uniqnav(nav_t* nav);
extern int  screent(gtime_t time, gtime_t ts, gtime_t te, double tint);
extern int  readnav(const char* file, nav_t* nav);
extern int  savenav(const char* file, const nav_t* nav);
extern void freeobs(obs_t* obs);
extern void freenav(nav_t* nav, int opt);
extern int  readblq(const char* file, const char* sta, double* odisp);
extern int  readerp(const char* file, erp_t* erp);
extern int  geterp (const erp_t* erp, gtime_t time, double* val);

/// debug trace functions ----------------------------------------------------
extern void traceopen(const char* file);
extern void traceclose();
extern void tracelevel(int level);
extern void trace    (int level, const char* format, ...);
extern void tracet   (int level, const char* format, ...);
extern void tracemat (int level, const double* A, int n, int m, int p, int q);
extern void traceobs (int level, const obsd_t* obs, int n);
extern void tracenav (int level, const nav_t* nav);
extern void tracegnav(int level, const nav_t* nav);
extern void tracehnav(int level, const nav_t* nav);
extern void tracepeph(int level, const nav_t* nav);
extern void tracepclk(int level, const nav_t* nav);
extern void traceb   (int level, const ubyte* p, int n);

/// platform dependent functions ---------------------------------------------
extern int execcmd(const char* cmd);
extern int expath (const char* path, char* paths[], int nmax);
extern void createdir(const char* path);

/// positioning models -------------------------------------------------------
extern double satwavelen(int sat, int frq, const nav_t* nav);
extern double satazel(const double* pos, const double* e, double* azel);
extern double geodist(const double* rs, const double* rr, double* e);
extern void dops(int ns, const double* azel, double elmin, double* dop);
extern void csmooth(obs_t* obs, int ns);

/// atmosphere models --------------------------------------------------------
extern double ionmodel(gtime_t t, const double* ion, const double* pos,
                       const double* azel);
extern double ionmapf(const double* pos, const double* azel);
extern double ionppp(const double* pos, const double* azel, double re,
                     double hion, double* pppos);
extern double tropmodel(gtime_t time, const double* pos, const double* azel,
                        double humi);
extern double tropmapf(gtime_t time, const double* pos, const double* azel,
                       double* mapfw);
extern int iontec(gtime_t time, const nav_t* nav, const double* pos,
                  const double* azel, int opt, double* delay, double* var);
extern void readtec(const char* file, nav_t* nav, int opt);
extern int ionocorr(gtime_t time, const nav_t* nav, int sat, const double* pos,
                    const double* azel, int ionoopt, double* ion, double* var);
extern int tropcorr(gtime_t time, const nav_t* nav, const double* pos,
                    const double* azel, int tropopt, double* trp, double* var);
extern void stec_read(const char* file, nav_t* nav);
extern int stec_grid(const nav_t* nav, const double* pos, int nmax, int* index,
                     double* dist);
extern int stec_data(stec_t* stec, gtime_t time, int sat, double* iono,
                     double* rate, double* rms, int* slip);
extern int stec_ion(gtime_t time, const nav_t* nav, int sat, const double* pos,
                    const double* azel, double* iono, double* rate, double* var,
                    int* brk);
extern void stec_free(nav_t* nav);

/// antenna models -----------------------------------------------------------
extern int  readpcv(const char* file, pcvs_t* pcvs);
extern pcv_t* searchpcv(int sat, const char* type, gtime_t time,
                        const pcvs_t* pcvs);
extern void antmodel(const pcv_t* pcv, const double* del, const double* azel,
                     int opt, double* dant);
extern void antmodel_s(const pcv_t* pcv, double nadir, double* dant);

/// earth tide models --------------------------------------------------------
extern void sunmoonpos(gtime_t tutc, const double* erpv, double* rsun,
                       double* rmoon, double* gmst);
extern void tidedisp(gtime_t tutc, const double* rr, int opt, const erp_t* erp,
                     const double* odisp, double* dr);

/// geiod models -------------------------------------------------------------
extern int opengeoid(int model, const char* file);
extern void closegeoid();
extern double geoidh(const double* pos);

/// datum transformation -----------------------------------------------------
extern int loaddatump(const char* file);
extern int tokyo2jgd(double* pos);
extern int jgd2tokyo(double* pos);

/// rinex functions ----------------------------------------------------------
extern int readrnx (const char* file, int rcv, const char* opt, obs_t* obs,
                    nav_t* nav, sta_t* sta);
extern int readrnxt(const char* file, int rcv, gtime_t ts, gtime_t te,
                    double tint, const char* opt, obs_t* obs, nav_t* nav,
                    sta_t* sta);
extern int readrnxc(const char* file, nav_t* nav);
extern int outrnxobsh(FILE* fp, const rnxopt_t* opt, const nav_t* nav);
extern int outrnxobsb(FILE* fp, const rnxopt_t* opt, const obsd_t* obs, int n,
                      int epflag);
extern int outrnxnavh (FILE* fp, const rnxopt_t* opt, const nav_t* nav);
extern int outrnxgnavh(FILE* fp, const rnxopt_t* opt, const nav_t* nav);
extern int outrnxhnavh(FILE* fp, const rnxopt_t* opt, const nav_t* nav);
extern int outrnxlnavh(FILE* fp, const rnxopt_t* opt, const nav_t* nav);
extern int outrnxqnavh(FILE* fp, const rnxopt_t* opt, const nav_t* nav);
extern int outrnxcnavh(FILE* fp, const rnxopt_t* opt, const nav_t* nav);
extern int outrnxnavb (FILE* fp, const rnxopt_t* opt, const eph_t* eph);
extern int outrnxgnavb(FILE* fp, const rnxopt_t* opt, const geph_t* geph);
extern int outrnxhnavb(FILE* fp, const rnxopt_t* opt, const seph_t* seph);
extern int uncompress(const char* file, char* uncfile);
extern int convrnx(int format, rnxopt_t* opt, const char* file, char** ofile);
extern int  init_rnxctr (rnxctr_t* rnx);
extern void free_rnxctr (rnxctr_t* rnx);
extern int  open_rnxctr (rnxctr_t* rnx, FILE* fp);
extern int  input_rnxctr(rnxctr_t* rnx, FILE* fp);

/// ephemeris and clock functions --------------------------------------------
extern double eph2clk (gtime_t time, const eph_t*  eph);
extern double geph2clk(gtime_t time, const geph_t* geph);
extern double seph2clk(gtime_t time, const seph_t* seph);
extern void eph2pos (gtime_t time, const eph_t*  eph,  double* rs, double* dts,
                     double* var);
extern void geph2pos(gtime_t time, const geph_t* geph, double* rs, double* dts,
                     double* var);
extern void seph2pos(gtime_t time, const seph_t* seph, double* rs, double* dts,
                     double* var);
extern int  peph2pos(gtime_t time, int sat, const nav_t* nav, int opt,
                     double* rs, double* dts, double* var);
extern void satantoff(gtime_t time, const double* rs, const pcv_t* pcv,
                      double* dant);
extern int  satpos(gtime_t time, gtime_t teph, int sat, int ephopt,
                   const nav_t* nav, double* rs, double* dts, double* var,
                   int* svh);
extern void satposs(gtime_t time, const obsd_t* obs, int n, const nav_t* nav,
                    int sateph, double* rs, double* dts, double* var, int* svh);
extern void readsp3(const char* file, nav_t* nav, int opt);
extern int  readsap(const char* file, gtime_t time, nav_t* nav);
extern int  readdcb(const char* file, nav_t* nav);
extern void alm2pos(gtime_t time, const alm_t* alm, double* rs, double* dts);

extern int tle_read(const char* file, tle_t* tle);
extern int tle_name_read(const char* file, tle_t* tle);
extern int tle_pos(gtime_t time, const char* name, const char* satno,
                   const char* desig, const tle_t* tle, const erp_t* erp,
                   double* rs);

/// receiver raw data functions ----------------------------------------------
extern uint getbitu(const ubyte* buff, int pos, int len);
extern int          getbits(const ubyte* buff, int pos, int len);
extern void setbitu(ubyte* buff, int pos, int len, uint data);
extern void setbits(ubyte* buff, int pos, int len, int data);
extern uint crc32  (const ubyte* buff, int len);
extern uint crc24q (const ubyte* buff, int len);
extern ushort crc16(const ubyte* buff, int len);
extern int decode_word (uint word, ubyte* data);
extern int decode_frame(const ubyte* buff, eph_t* eph, alm_t* alm,
                        double* ion, double* utc, int* leaps);

extern int init_raw   (raw_t* raw);
extern void free_raw  (raw_t* raw);
extern int input_raw  (raw_t* raw, int format, ubyte data);
extern int input_rawf (raw_t* raw, int format, FILE* fp);

extern int input_oem4  (raw_t* raw, ubyte data);
extern int input_oem3  (raw_t* raw, ubyte data);
extern int input_ubx   (raw_t* raw, ubyte data);
extern int input_ss2   (raw_t* raw, ubyte data);
extern int input_cres  (raw_t* raw, ubyte data);
extern int input_stq   (raw_t* raw, ubyte data);
extern int input_gw10  (raw_t* raw, ubyte data);
extern int input_javad (raw_t* raw, ubyte data);
extern int input_nvs   (raw_t* raw, ubyte data);
extern int input_bnx   (raw_t* raw, ubyte data);
extern int input_lexr  (raw_t* raw, ubyte data);
extern int input_oem4f (raw_t* raw, FILE* fp);
extern int input_oem3f (raw_t* raw, FILE* fp);
extern int input_ubxf  (raw_t* raw, FILE* fp);
extern int input_ss2f  (raw_t* raw, FILE* fp);
extern int input_cresf (raw_t* raw, FILE* fp);
extern int input_stqf  (raw_t* raw, FILE* fp);
extern int input_gw10f (raw_t* raw, FILE* fp);
extern int input_javadf(raw_t* raw, FILE* fp);
extern int input_nvsf  (raw_t* raw, FILE* fp);
extern int input_bnxf  (raw_t* raw, FILE* fp);
extern int input_lexrf (raw_t* raw, FILE* fp);

extern int gen_ubx (const char* msg, ubyte* buff);
extern int gen_stq (const char* msg, ubyte* buff);
extern int gen_nvs (const char* msg, ubyte* buff);
extern int gen_lexr(const char* msg, ubyte* buff);

/// rtcm functions -----------------------------------------------------------
extern int init_rtcm   (rtcm_t* rtcm);
extern void free_rtcm  (rtcm_t* rtcm);
extern int input_rtcm2 (rtcm_t* rtcm, ubyte data);
extern int input_rtcm3 (rtcm_t* rtcm, ubyte data);
extern int input_rtcm2f(rtcm_t* rtcm, FILE* fp);
extern int input_rtcm3f(rtcm_t* rtcm, FILE* fp);
extern int gen_rtcm2   (rtcm_t* rtcm, int type, int sync);
extern int gen_rtcm3   (rtcm_t* rtcm, int type, int sync);

/// solution functions -------------------------------------------------------
extern void initsolbuf(solbuf_t* solbuf, int cyclic, int nmax);
extern void freesolbuf(solbuf_t* solbuf);
extern void freesolstatbuf(solstatbuf_t* solstatbuf);
extern sol_t* getsol(solbuf_t* solbuf, int index);
extern int addsol(solbuf_t* solbuf, const sol_t* sol);
extern int readsol (char* files[], int nfile, solbuf_t* sol);
extern int readsolt(char* files[], int nfile, gtime_t ts, gtime_t te,
                    double tint, int qflag, solbuf_t* sol);
extern int readsolstat(char* files[], int nfile, solstatbuf_t* statbuf);
extern int readsolstatt(char* files[], int nfile, gtime_t ts, gtime_t te,
                        double tint, solstatbuf_t* statbuf);
extern int inputsol(ubyte data, gtime_t ts, gtime_t te, double tint,
                    int qflag, const solopt_t* opt, solbuf_t* solbuf);

extern int outprcopts(ubyte* buff, const prcopt_t* opt);
extern int outsolheads(ubyte* buff, const solopt_t* opt);
extern int outsols  (ubyte* buff, const sol_t* sol, const double* rb,
                     const solopt_t* opt);
extern int outsolexs(ubyte* buff, const sol_t* sol, const ssat_t* ssat,
                     const solopt_t* opt);
extern void outprcopt(FILE* fp, const prcopt_t* opt);
extern void outsolhead(FILE* fp, const solopt_t* opt);
extern void outsol  (FILE* fp, const sol_t* sol, const double* rb,
                     const solopt_t* opt);
extern void outsolex(FILE* fp, const sol_t* sol, const ssat_t* ssat,
                     const solopt_t* opt);
extern int outnmea_rmc(ubyte* buff, const sol_t* sol);
extern int outnmea_gga(ubyte* buff, const sol_t* sol);
extern int outnmea_gsa(ubyte* buff, const sol_t* sol,
                       const ssat_t* ssat);
extern int outnmea_gsv(ubyte* buff, const sol_t* sol,
                       const ssat_t* ssat);

/// google earth kml converter -----------------------------------------------
extern int convkml(const char* infile, const char* outfile, gtime_t ts,
                   gtime_t te, double tint, int qflg, double* offset,
                   int tcolor, int pcolor, int outalt, int outtime);

/// sbas functions -----------------------------------------------------------
extern int  sbsreadmsg (const char* file, int sel, sbs_t* sbs);
extern int  sbsreadmsgt(const char* file, int sel, gtime_t ts, gtime_t te,
                        sbs_t* sbs);
extern void sbsoutmsg(FILE* fp, sbsmsg_t* sbsmsg);
extern int  sbsdecodemsg(gtime_t time, int prn, const uint* words,
                         sbsmsg_t* sbsmsg);
extern int sbsupdatecorr(const sbsmsg_t* msg, nav_t* nav);
extern int sbssatcorr(gtime_t time, int sat, const nav_t* nav, double* rs,
                      double* dts, double* var);
extern int sbsioncorr(gtime_t time, const nav_t* nav, const double* pos,
                      const double* azel, double* delay, double* var);
extern double sbstropcorr(gtime_t time, const double* pos, const double* azel,
                          double* var);

/// options functions --------------------------------------------------------
extern opt_t* searchopt(const char* name, const opt_t* opts);
extern int str2opt(opt_t* opt, const char* str);
extern int opt2str(const opt_t* opt, char* str);
extern int opt2buf(const opt_t* opt, char* buff);
extern int loadopts(const char* file, opt_t* opts);
extern int saveopts(const char* file, const char* mode, const char* comment,
                    const opt_t* opts);
extern void resetsysopts();
extern void getsysopts(prcopt_t* popt, solopt_t* sopt, filopt_t* fopt);
extern void setsysopts(const prcopt_t* popt, const solopt_t* sopt,
                       const filopt_t* fopt);

/// stream data input and output functions -----------------------------------
extern void strinitcom();
extern void strinit  (stream_t* stream);
extern void strlock  (stream_t* stream);
extern void strunlock(stream_t* stream);
extern int  stropen  (stream_t* stream, int type, int mode, const char* path);
extern void strclose (stream_t* stream);
extern int  strread  (stream_t* stream, ubyte* buff, int n);
extern int  strwrite (stream_t* stream, ubyte* buff, int n);
extern void strsync  (stream_t* stream1, stream_t* stream2);
extern int  strstat  (stream_t* stream, char* msg);
extern void strsum   (stream_t* stream, int* inb, int* inr, int* outb, int* outr);
extern void strsetopt(const int* opt);
extern gtime_t strgettime(stream_t* stream);
extern void strsendnmea(stream_t* stream, const double* pos);
extern void strsendcmd(stream_t* stream, const char* cmd);
extern void strsettimeout(stream_t* stream, int toinact, int tirecon);
extern void strsetdir(const char* dir);
extern void strsetproxy(const char* addr);

/// integer ambiguity resolution ---------------------------------------------
extern int lambda(int n, int m, const double* a, const double* Q, double* F,
                  double* s);

/// standard positioning -----------------------------------------------------
extern int pntpos(const obsd_t* obs, int n, const nav_t* nav,
                  const prcopt_t* opt, sol_t* sol, double* azel,
                  ssat_t* ssat, char* msg);

/// precise positioning ------------------------------------------------------
extern void rtkinit(rtk_t* rtk, const prcopt_t* opt);
extern void rtkfree(rtk_t* rtk);
extern int  rtkpos (rtk_t* rtk, const obsd_t* obs, int nobs, const nav_t* nav);
extern int  rtkopenstat(const char* file, int level);
extern void rtkclosestat();

/// precise point positioning ------------------------------------------------
extern void pppos(rtk_t* rtk, const obsd_t* obs, int n, const nav_t* nav);
extern int pppamb(rtk_t* rtk, const obsd_t* obs, int n, const nav_t* nav,
                  const double* azel);
extern int pppnx(const prcopt_t* opt);
extern void pppoutsolstat(rtk_t* rtk, int level, FILE* fp);
extern void windupcorr(gtime_t time, const double* rs, const double* rr,
                       double* phw);

/// post-processing positioning ----------------------------------------------
extern int postpos(gtime_t ts, gtime_t te, double ti, double tu,
                   const prcopt_t* popt, const solopt_t* sopt,
                   const filopt_t* fopt, char** infile, int n, char* outfile,
                   const char* rov, const char* base);

/// stream server functions --------------------------------------------------
extern void strsvrinit (strsvr_t* svr, int nout);
extern int  strsvrstart(strsvr_t* svr, int* opts, int* strs, char** paths,
                        strconv_t** conv, const char* cmd,
                        const double* nmeapos);
extern void strsvrstop (strsvr_t* svr, const char* cmd);
extern void strsvrstat (strsvr_t* svr, int* stat, int* byte_, int* bps, char* msg);
extern strconv_t* strconvnew(int itype, int otype, const char* msgs, int staid,
                             int stasel, const char* opt);
extern void strconvfree(strconv_t* conv);

/// rtk server functions -----------------------------------------------------
extern int  rtksvrinit  (rtksvr_t* svr);
extern void rtksvrfree  (rtksvr_t* svr);
extern int  rtksvrstart (rtksvr_t* svr, int cycle, int buffsize, int* strs,
                         char** paths, int* formats, int navsel, char** cmds,
                         char** rcvopts, int nmeacycle, int nmeareq,
                         const double* nmeapos, prcopt_t* prcopt,
                         solopt_t* solopt, stream_t* moni);
extern void rtksvrstop  (rtksvr_t* svr, char** cmds);
extern int  rtksvropenstr(rtksvr_t* svr, int index, int str, const char* path,
                          const solopt_t* solopt);
extern void rtksvrclosestr(rtksvr_t* svr, int index);
extern void rtksvrlock  (rtksvr_t* svr);
extern void rtksvrunlock(rtksvr_t* svr);
extern int  rtksvrostat (rtksvr_t* svr, int type, gtime_t* time, int* sat,
                         double* az, double* el, int** snr, int* vsat);
extern void rtksvrsstat (rtksvr_t* svr, int* sstat, char* msg);

/// downloader functions -----------------------------------------------------
extern int dl_readurls(const char* file, char** types, int ntype, url_t* urls,
                       int nmax);
extern int dl_readstas(const char* file, char** stas, int nmax);
extern int dl_exec(gtime_t ts, gtime_t te, double ti, int seqnos, int seqnoe,
                   const url_t* urls, int nurl, char** stas, int nsta,
                   const char* dir, const char* usr, const char* pwd,
                   const char* proxy, int opts, char* msg, FILE* fp);
extern void dl_test(gtime_t ts, gtime_t te, double ti, const url_t* urls,
                    int nurl, char** stas, int nsta, const char* dir,
                    int ncol, int datefmt, FILE* fp);

/// application defined functions --------------------------------------------
extern int showmsg(char* format,...);
extern void settspan(gtime_t ts, gtime_t te);
extern void settime(gtime_t time);

/// qzss lex functions -------------------------------------------------------
extern int lexupdatecorr(const lexmsg_t* msg, nav_t* nav, gtime_t* tof);
extern int lexreadmsg(const char* file, int sel, lex_t* lex);
extern void lexoutmsg(FILE* fp, const lexmsg_t* msg);
extern int lexconvbin(int type, int format, const char* infile,
                      const char* outfile);
extern int lexeph2pos(gtime_t time, int sat, const nav_t* nav, double* rs,
                      double* dts, double* var);
extern int lexioncorr(gtime_t time, const nav_t* nav, const double* pos,
                      const double* azel, double* delay, double* var);
