//##& set waitTime 20000            // 10s
//##$ dmd -O -inline -gs -m64 -unittest -version=useFFTW -version=MAIN_IS_SDRMAIN_MAIN sdr sdrmain fec rtklib sdracq sdrcmn sdrcode sdrinit sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize util/numeric

//　-version=Dnative -debug=PrintBuffloc -version=TRACE -version=L2Develop -O -release -inline -version=L2Develop -version=useFFTW
/*
Change Log:
2013/07/18          単一スレッド化
2013/07/16 v2.0beta バッファ読み込みを、sdrスレッドが操るように修正

version指定一覧
+ Dnative               なるべくD言語ネイティブなプログラムにします。(外部のdllをなるべく触らないということ)
+ TRACE                 trace, traceln, traceflnが有効になります。
+ TRACE_CSV             csvOutputが有効になります。
+ MAIN_IS_SDRMAIN_MAIN  プログラムのmain関数は、sdrmain.dのmain関数になります。
+ NavigationDecode      航法メッセージを解読しようとします(L1CAのみ)
+ L2Develop             L2CM用のSDR開発のためのバージョン
+ useFFTW               FFTの計算にFFTWを使用します(デフォルトだと、std.numeric.Fftを使用します)

debug指定一覧
+ PrintBuffloc          すでにどれだけデータを読み込んだかを表示します。
*/

module sdr;
/*------------------------------------------------------------------------------
* sdr.h : constants, types and function prototypes

* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*-----------------------------------------------------------------------------*/
import std.complex;
import std.stdio;
import std.c.stdlib;
import std.c.math;
import std.math;
import std.array  : appender;
import std.traits : isSomeString;
import core.memory;
import std.datetime;
import core.stdc.time;
import std.string;

// time_tがいるらしいが、正直うざい
alias time_t = long;


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
              util.serialize,
              util.numeric;


// msgpack-d
version(Win64){
    pragma(lib, "msgpack_x64.lib");
}else version(Win32){
    pragma(lib, "msgpack.lib");
}else
    static assert(0);

/* FEC */
version(NavigationDecode){
    static assert(isVersion!"Win64");   // 64bitビルドの場合だけFFTWが使える
    pragma(lib, "libfec.a");            // この仕様はlinkerの問題.optlinkはクソ
    public import fec;
}

/* FFT */
static if(!isVersion!"Dnative"){
    static assert(isVersion!"Win64");   // 64bitビルドの場合だけFFTWが使える
    public import fftw;                 // これの仕様はlinkerの問題.optlinkはクソ
    pragma(lib, "libfftw3f-3.lib");
}


/**
航法システム(GNSS)の種類
*/
enum NavSystem
{
    GPS = 0x01,             /// Global Positioning System
    SBAS = 0x02,            /// Satellite-Based Augmentation System(エスバス)
    GLONASS = 0x04,         /// ロシア語:ГЛОНАСС - ГЛОбальная НАвигационная Спутниковая Система, ラテン文字転記: GLObal'naya NAvigationnaya Sputnikovaya Sistema(英語: Global Navigation Satellite System, グロナス)
    Galileo = 0x08,         /// EUのGNSS
    QZSS = 0x10,            /// Quasi-Zenith Satellite System(準天頂衛星システム)。日本向けのGNSSでJAXAが2010年に初号機「みちびき」を打ち上げた。現在はPRN:193のみ
    BeiDou = 0x20,          /// 北斗衛星導航系統(BeiDou Navigation Satellite System)は中華版GNSS
}


/* constants -----------------------------------------------------------------*/
immutable DPI = 2 * PI;             /// 2π
immutable D2R = PI / 180;           /// 1[degree] = D2R[radian]
immutable R2D = 180 / PI;           /// 1[radian] = R2D[degree]
immutable CLIGHT = 299792458.0;     /// 光速[m/s]。たしかに高速
//immutable ON = true;
//immutable OFF = false;
immutable CDIV = 32;
immutable CMASK = 0x1F;
immutable CSCALE = 1.0 /16.0;


/* front end setting */
enum Fend
{
    STEREO = 0,
    GN3SV2 = -1,
    GN3SV3 = 1,
    FILESTEREO,
    FILE
}


immutable size_t MEMBUFLEN = 5000;

enum FType
{
    Type1 = 1,
    Type2
}


enum DType
{
    I = 1,
    IQ = 2,
}

immutable size_t FILE_BUFFSIZE = 8192;
immutable NFFTTHREAD = 4;

struct Constant
{
    // this struct is used as name space
    @disable this();

    struct L1CA
    {
        // this struct is used as name space
        @disable this();

        struct Acquisition
        {
            // this struct is used as name space
            @disable this();

            enum INTG = 4;
            enum HBAND = 5000;
            enum STEP = 250;
            enum TH = 2.0;
            enum LENF = 10;
            enum FFTFRESO = 10;
            enum SLEEP = 2000;
        }


        struct Tracking
        {
            // this struct is used as name space
            @disable this();

            struct Parameter1
            {
                // this struct is used as name space
                @disable this();

                enum CDN = 3;
                enum CP = 12;
                enum DLLB = 1.0;
                enum PLLB = 20.0;
                enum FLLB = 250.0;
                enum DT = 0.001;
            }


            struct Parameter2
            {
                // this struct is used as name space
                @disable this();

                enum CDN = 3;
                enum CP = 12;
                enum DLLB = 0.5;
                enum PLLB = 20.0;
                enum FLLB = 50.0;
                enum DT = 0.001;
            }
        }


        struct Navigation
        {
            // this struct is used as name space
            @disable this();

            enum BITTH = 5;
            enum RATE = 20;
            enum FLEN = 300;
            enum ADDFLEN = 2;
            enum ADDPLEN = 2;
            enum PRELEN = 8;
        }


        enum LOOP_MS = 10;
        enum freq = 10.23e6 * 2 * 77;
    }


    struct L1SAIF
    {
        // this struct is used as name space
        @disable this();

        struct Acquisition
        {
            // this struct is used as name space
            @disable this();

            enum INTG = 4;
            enum HBAND = 5000;
            enum STEP = 250;
            enum TH = 2.0;
            enum LENF = 10;
            enum FFTFRESO = 10;
            enum SLEEP = 2000;
        }


        struct Tracking
        {
            // this struct is used as name space
            @disable this();

            struct Parameter1
            {
                // this struct is used as name space
                @disable this();

                enum CDN = 3;
                enum CP = 12;
                enum DLLB = 1.0;
                enum PLLB = 20.0;
                enum FLLB = 250.0;
                enum DT = 0.001;
            }


            struct Parameter2
            {
                // this struct is used as name space
                @disable this();

                enum CDN = 3;
                enum CP = 12;
                enum DLLB = 0.5;
                enum PLLB = 20.0;
                enum FLLB = 50.0;
                enum DT = 0.001;
            }
        }


        struct Navigation
        {
            // this struct is used as name space
            @disable this();

            enum BITTH = 5;
            enum RATE = 2;
            enum FLEN = 500;
            enum ADDFLEN = 12;
            enum ADDPLEN = 0;
            enum PRELEN = 8;
        }

        enum LOOP_MS = 10;
        enum freq = 10.23e6 * 2 * 77;
    }


    struct L2C
    {
        // this struct is used as name space
        @disable this();

        struct Acquisition
        {
            // this struct is used as name space
            @disable this();

            enum INTG = 1;
            enum HBAND = 4;
            enum STEP = 2;
            enum TH = 2.0;
            //enum LENF = 10;
            //enum FFTFRESO = 10;
            enum SLEEP = 2000;
        }


        struct Tracking
        {
            // this struct is used as name space
            @disable this();

            struct Parameter1
            {
                // this struct is used as name space
                @disable this();

                enum CDN = 3;
                enum CP = 12;
                enum DLLB = 0.5;
                enum PLLB = 20.0;
                enum FLLB = 250.0;
                enum DT = 0.001;
            }


            struct Parameter2
            {
                // this struct is used as name space
                @disable this();

                enum CDN = 3;
                enum CP = 12;
                enum DLLB = 0.5;
                enum PLLB = 20.0;
                enum FLLB = 50.0;
                enum DT = 0.001;
            }
        }


        struct Navigation
        {
            // this struct is used as name space
            @disable this();

            enum BITTH = 5;
            enum RATE = 20;
            enum FLEN = 300;
            enum ADDFLEN = 2;
            enum ADDPLEN = 2;
            enum PRELEN = 8;
        }


        enum LOOP_MS = 10;
        enum freq = 10.23e6 * 2 * 60;
    }


/+
    struct Tracking{
        // this struct is used as name space
        @disable this();

        struct Parameter1
        {
            // this struct is used as name space
            @disable this();

            enum CDN = 3;
            enum CP = 12;
            enum DLLB = 1.0;
            enum PLLB = 20.0;
            enum FLLB = 250.0;
            enum DT = 0.001;
        }


        struct Parameter2
        {
            // this struct is used as name space
            @disable this();

            enum CDN = 3;
            enum CP = 12;
            enum DLLB = 0.5;
            enum PLLB = 20.0;
            enum FLLB = 50.0;
            enum DT = 0.001;
        }
    }
+/


    struct Observation
    {
        // this struct is used as name space
        @disable this();

        enum PTIMING = 68.802;
        enum OBSINTERPN = 8;
        enum SNSMOOTHMS = 100;
    }


    struct CodeGeneration
    {
        // this struct is used as name space
        @disable this();

        enum MAXGPSSATNO = 210;
        enum MAXGALSATNO = 50;
        enum MAXCMPSATNO = 37;
    }


    static
    auto get(string name)(CType ctype)
    {
        switch(ctype)
        {
          case CType.L1CA:
            return mixin("L1CA." ~ name);
          case CType.L1SAIF:
            return mixin("L1SAIF." ~ name);
          case CType.L2RCCM:{
            static if(name == "Acquisition.LENF" || name == "Acquisition.FFTFRESO")
                goto default;
            else
                return mixin("L2C." ~ name);
          }

          default:
            enforce(0);
        }

        assert(0);
    }


    enum TRKCN = 8;
    enum LOOP_MS_L1CA = 10;
    enum LOOP_MS_SBAS = 2;
    enum LOOP_MS_LEX = 4;


    /* RTKLIB */
    private import rtklib;

    enum totalSatellites = MAXSAT;


    struct GPS
    {
        /// this struct is used as a name space
        @disable this();

        struct PRN
        {
            /// this struct is used as a name space
            @disable this();

            enum min = MINPRNGPS;
            enum max = MAXPRNGPS;
        }

        enum totalSatellites = NSATGPS;
    }


    struct GLONASS
    {
        /// this struct is used as a name space
        @disable this();

        struct PRN
        {
            /// this struct is used as a name space
            @disable this();

            enum min = MINPRNGLO;
            enum max = MAXPRNGLO;
        }

        enum totalSatellites = NSATGLO;
    }


    struct Galileo
    {
        /// this struct is used as a name space
        @disable this();

        struct PRN
        {
            /// this struct is used as a name space
            @disable this();

            enum min = MINPRNGAL;
            enum max = MAXPRNGAL;
        }

        enum totalSatellites = NSATGAL;
    }


    struct QZSS
    {
        /// this struct is used as a name space
        @disable this();

        struct PRN
        {
            /// this struct is used as a name space
            @disable this();

            enum min = MINPRNQZS;
            enum max = MAXPRNQZS;
        }

        enum totalSatellites = NSATQZS;
    }


    struct BeiDou
    {
        /// this struct is used as a name space
        @disable this();

        struct PRN
        {
            /// this struct is used as a name space
            @disable this();

            enum min = MINPRNCMP;
            enum max = MAXPRNCMP;
        }

        enum totalSatellites = NSATCMP;
    }


    struct SBAS
    {
        /// this struct is used as a name space
        @disable this();

        struct PRN
        {
            /// this struct is used as a name space
            @disable this();

            enum min = MINPRNSBS;
            enum max = MAXPRNSBS;
        }

        enum totalSatellites = NSATSBS;
    }
}

public import rtklib : eph_t, obsd_t, rnxopt_t, gtime_t;


enum CType
{
    L1CA = 1,
    L1CP,
    L1CD,
    L1CO,
    L2CM,
    L2CL,
    L2RCCM,     // CM + 0-padding CL(つまり、CLコードを0にしたRCコード)
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
    NavSystem[] sys;
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
    size_t buffloccnt;
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
    size_t buffloc;
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
    //Tid hsdr;
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
    int nsamp;              // PRNコード一周期のサンプル数
    int nsampchip;          // PRNコード1チップのサンプル数
    int currnsamp;          // 現在のnsamp
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
    double[] xrange;
    double[] yrange;
    string xlabel;
    string ylabel;
    double[] xvalue;
    double[] yvalue;
    string title;
    string otherSetting;
}


struct sdrsoc_t
{
    //Tid hsoc;
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


/**
次の2つのコードは等しくなります。

Example:
-------
version(Test)
    someCodeA();
else
    someCodeB();
-------

Example:
-------
static if(isVersion!"Test")
    someCodeA();
else
    someCodeB();
-------

次のような場合に有用になります。

Example:
-------
version(Test){}else
    someCodeC();
-------

Example:
-------
static if(!isVersion!Test)
    someCodeC();
-------
*/
template isVersion(string vname)
{
    mixin(`version(` ~ vname ~ `){ enum isVersion = true; } else { enum isVersion = false; }`);
}


/**
指定されたデバッグモードでコンパイルされているかどうか判定します。
modeが空の場合、コンパイラオプションでは-debugに相当します。
*/
template isDebugMode(string mode)
{
    enum bool isDebugMode = (){
        bool b;

        static if(mode.length == 0)
        {
            debug
                b = true;
        }else
        {
            mixin(q{
                debug(%s)
                    b = true;
            }.formattedString(mode));
        }

        return b;
    }();
}


/**
第一引数が、指定された区間に属するかどうか判定します。
*/
bool isInInterval(string prd, T, U...)(T value, U borders)
if(prd.length == U.length && prd.length > 0)
{
    bool b = true;

    static string genPredicate(char exp) pure nothrow @safe
    {
        switch(exp){
            case '[': return "borders[i] <= value";
            case '(': return "borders[i] < value";
            case ')': return "value < borders[i]";
            case ']': return "value <= borders[i]";
            default:  assert(0);
        }
    }

    foreach(i, Unused; U)
        b = b && mixin(genPredicate(prd[i]));

    return b;
}

///
unittest
{
    assert(isInInterval!"["(5, 0));     // 5 は 0以上であるか -> true
    assert(!isInInterval!"("(5, 5));    // 5 は 5より大きい   -> false
    assert(!isInInterval!")"(5, 5));    // 5 は 5未満である  -> false
    assert(isInInterval!"]"(5, 5));     // 5 は 5以下である  -> true

    foreach(e; 0 .. 10)
        assert(e.isInInterval!"[)"(0, 10));

    assert(!10.isInInterval!"[)"(0, 10));
    assert(!10.isInInterval!"[)]"(0, 11, 0));
}


alias SDRPRINTF = writef;


auto malloc(size_t size) nothrow
{
    return GC.malloc(size);
}


void free(void* p) nothrow
{
    GC.free(p);
}


void* calloc(size_t n, size_t size) nothrow
{
    return GC.calloc(n * size);
}


ushort MAKEWORD(ubyte bLow, ubyte bHigh) pure nothrow @safe
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


bool isValidPRN(int prn, NavSystem sys) pure nothrow @safe
{
    final switch(sys){
      case NavSystem.GPS:       return prn.isInInterval!"[]"(Constant.GPS.PRN.min, Constant.GPS.PRN.max);
      case NavSystem.GLONASS:   return prn.isInInterval!"[]"(Constant.GLONASS.PRN.min, Constant.GLONASS.PRN.max);
      case NavSystem.Galileo:   return prn.isInInterval!"[]"(Constant.Galileo.PRN.min, Constant.Galileo.PRN.max);
      case NavSystem.QZSS:      return prn.isInInterval!"[]"(Constant.QZSS.PRN.min, Constant.QZSS.PRN.max);
      case NavSystem.BeiDou:    return prn.isInInterval!"[]"(Constant.BeiDou.PRN.min, Constant.BeiDou.PRN.max);
      case NavSystem.SBAS:      return prn.isInInterval!"[]"(Constant.SBAS.PRN.min, Constant.SBAS.PRN.max);
    }
    assert(0);
}


// rtklibからの輸入
int satno(NavSystem sys, int prn) pure nothrow @safe
in{
    assert(prn.isValidPRN(sys));
}
body{
    with(Constant) final switch (sys) {
      case NavSystem.GPS:       return prn - GPS.PRN.min + 1;
      case NavSystem.GLONASS:   return GPS.totalSatellites + prn - GLONASS.PRN.min + 1;
      case NavSystem.Galileo:   return GPS.totalSatellites + GLONASS.totalSatellites + prn - Galileo.PRN.min + 1;
      case NavSystem.QZSS:      return GPS.totalSatellites + GLONASS.totalSatellites + Galileo.totalSatellites + prn - QZSS.PRN.min + 1;
      case NavSystem.BeiDou:    return GPS.totalSatellites + GLONASS.totalSatellites + Galileo.totalSatellites + QZSS.totalSatellites + prn - BeiDou.PRN.min + 1;
      case NavSystem.SBAS:      return GPS.totalSatellites + GLONASS.totalSatellites + Galileo.totalSatellites + QZSS.totalSatellites + BeiDou.totalSatellites + prn - SBAS.PRN.min + 1;
    }
    assert(0);
}


// rtklibからの輸入
NavSystem satsys(int sat, out int prn)
in{
    assert(0 < sat && sat < Constant.totalSatellites);
}
body{
    with(Constant){
        if(sat <= GPS.totalSatellites){
            prn = sat + GPS.PRN.min - 1;
            return NavSystem.GPS;
        }

        sat -= GPS.totalSatellites;
        
        if(sat <= GLONASS.totalSatellites){
            prn = sat + GLONASS.PRN.min - 1;
            return NavSystem.GLONASS;
        }

        sat -= GLONASS.totalSatellites;

        if(sat <= Galileo.totalSatellites){
            prn = sat + Galileo.PRN.min - 1;
            return NavSystem.Galileo;
        }

        sat -= Galileo.totalSatellites;

        if(sat <= QZSS.totalSatellites){
            prn = sat + QZSS.PRN.min - 1;
            return NavSystem.QZSS;
        }

        sat -= QZSS.totalSatellites;

        if(sat <=  BeiDou.totalSatellites){
            prn = sat + BeiDou.PRN.min - 1;
            return NavSystem.BeiDou;
        }

        sat -= BeiDou.totalSatellites;

        if(sat <= SBAS.totalSatellites){
            prn = sat + SBAS.PRN.min - 1;
            return NavSystem.SBAS;
        }

        enforce(0);
        assert(0);
    }
}


// rtklibからの輸入
string satno2Id(int sat)
{
    int prn = void;
    final switch (satsys(sat, prn)) {
        case NavSystem.GPS:     return "G%02d".format(prn - Constant.GPS.PRN.min + 1);
        case NavSystem.GLONASS: return "R%02d".format(prn - Constant.GLONASS.PRN.min + 1);
        case NavSystem.Galileo: return "E%02d".format(prn - Constant.Galileo.PRN.min + 1);
        case NavSystem.QZSS:    return "J%02d".format(prn - Constant.QZSS.PRN.min + 1);
        case NavSystem.BeiDou:  return "C%02d".format(prn - Constant.BeiDou.PRN.min + 1);
        case NavSystem.SBAS:    return "%03d".format(prn);
    }

    assert(0);
}


// rtklibからの輸入
/* crc-24q parity --------------------------------------------------------------
* compute crc-24q parity for sbas, rtcm3
* args   : unsigned char *buff I data
*          int    len    I      data length (bytes)
* return : crc-24Q parity
* notes  : see reference [2] A.4.3.3 Parity
*-----------------------------------------------------------------------------*/
uint crc24q(in ubyte* buff, int len)
{
    uint crc=0;

    immutable static shared uint[] tbl_CRC24Q = [
        0x000000,0x864CFB,0x8AD50D,0x0C99F6,0x93E6E1,0x15AA1A,0x1933EC,0x9F7F17,
        0xA18139,0x27CDC2,0x2B5434,0xAD18CF,0x3267D8,0xB42B23,0xB8B2D5,0x3EFE2E,
        0xC54E89,0x430272,0x4F9B84,0xC9D77F,0x56A868,0xD0E493,0xDC7D65,0x5A319E,
        0x64CFB0,0xE2834B,0xEE1ABD,0x685646,0xF72951,0x7165AA,0x7DFC5C,0xFBB0A7,
        0x0CD1E9,0x8A9D12,0x8604E4,0x00481F,0x9F3708,0x197BF3,0x15E205,0x93AEFE,
        0xAD50D0,0x2B1C2B,0x2785DD,0xA1C926,0x3EB631,0xB8FACA,0xB4633C,0x322FC7,
        0xC99F60,0x4FD39B,0x434A6D,0xC50696,0x5A7981,0xDC357A,0xD0AC8C,0x56E077,
        0x681E59,0xEE52A2,0xE2CB54,0x6487AF,0xFBF8B8,0x7DB443,0x712DB5,0xF7614E,
        0x19A3D2,0x9FEF29,0x9376DF,0x153A24,0x8A4533,0x0C09C8,0x00903E,0x86DCC5,
        0xB822EB,0x3E6E10,0x32F7E6,0xB4BB1D,0x2BC40A,0xAD88F1,0xA11107,0x275DFC,
        0xDCED5B,0x5AA1A0,0x563856,0xD074AD,0x4F0BBA,0xC94741,0xC5DEB7,0x43924C,
        0x7D6C62,0xFB2099,0xF7B96F,0x71F594,0xEE8A83,0x68C678,0x645F8E,0xE21375,
        0x15723B,0x933EC0,0x9FA736,0x19EBCD,0x8694DA,0x00D821,0x0C41D7,0x8A0D2C,
        0xB4F302,0x32BFF9,0x3E260F,0xB86AF4,0x2715E3,0xA15918,0xADC0EE,0x2B8C15,
        0xD03CB2,0x567049,0x5AE9BF,0xDCA544,0x43DA53,0xC596A8,0xC90F5E,0x4F43A5,
        0x71BD8B,0xF7F170,0xFB6886,0x7D247D,0xE25B6A,0x641791,0x688E67,0xEEC29C,
        0x3347A4,0xB50B5F,0xB992A9,0x3FDE52,0xA0A145,0x26EDBE,0x2A7448,0xAC38B3,
        0x92C69D,0x148A66,0x181390,0x9E5F6B,0x01207C,0x876C87,0x8BF571,0x0DB98A,
        0xF6092D,0x7045D6,0x7CDC20,0xFA90DB,0x65EFCC,0xE3A337,0xEF3AC1,0x69763A,
        0x578814,0xD1C4EF,0xDD5D19,0x5B11E2,0xC46EF5,0x42220E,0x4EBBF8,0xC8F703,
        0x3F964D,0xB9DAB6,0xB54340,0x330FBB,0xAC70AC,0x2A3C57,0x26A5A1,0xA0E95A,
        0x9E1774,0x185B8F,0x14C279,0x928E82,0x0DF195,0x8BBD6E,0x872498,0x016863,
        0xFAD8C4,0x7C943F,0x700DC9,0xF64132,0x693E25,0xEF72DE,0xE3EB28,0x65A7D3,
        0x5B59FD,0xDD1506,0xD18CF0,0x57C00B,0xC8BF1C,0x4EF3E7,0x426A11,0xC426EA,
        0x2AE476,0xACA88D,0xA0317B,0x267D80,0xB90297,0x3F4E6C,0x33D79A,0xB59B61,
        0x8B654F,0x0D29B4,0x01B042,0x87FCB9,0x1883AE,0x9ECF55,0x9256A3,0x141A58,
        0xEFAAFF,0x69E604,0x657FF2,0xE33309,0x7C4C1E,0xFA00E5,0xF69913,0x70D5E8,
        0x4E2BC6,0xC8673D,0xC4FECB,0x42B230,0xDDCD27,0x5B81DC,0x57182A,0xD154D1,
        0x26359F,0xA07964,0xACE092,0x2AAC69,0xB5D37E,0x339F85,0x3F0673,0xB94A88,
        0x87B4A6,0x01F85D,0x0D61AB,0x8B2D50,0x145247,0x921EBC,0x9E874A,0x18CBB1,
        0xE37B16,0x6537ED,0x69AE1B,0xEFE2E0,0x709DF7,0xF6D10C,0xFA48FA,0x7C0401,
        0x42FA2F,0xC4B6D4,0xC82F22,0x4E63D9,0xD11CCE,0x575035,0x5BC9C3,0xDD8538
    ];
    
    foreach(e; buff[0 .. len]) crc = ( (crc << 8) &0xFFFFFF) ^ tbl_CRC24Q[(crc >> 16) ^ e];
    return crc;
}

// rtklibからの輸入
/* extract unsigned/signed bits ------------------------------------------------
* extract unsigned/signed bits from byte data
* args   : unsigned char *buff I byte data
*          int    pos    I      bit position from start of data (bits)
*          int    len    I      bit length (bits) (len<=32)
* return : extracted unsigned/signed bits
*-----------------------------------------------------------------------------*/
uint getbitu(in ubyte* buff, int pos, int len)
{
    uint bits;
    foreach(i; pos .. pos + len) bits = (bits << 1) + ((buff[i / 8] >> (7 - i % 8)) & 1u);
    return bits;
}

/// ditto
int getbits(in ubyte* buff, int pos, int len)
{
    uint bits = getbitu(buff,pos,len);
    if (len<=0||32<=len||!(bits&(1u<<(len-1)))) return cast(int)bits;
    return cast(int)(bits|(~0u<<len)); /* extend sign */
}


/* adjust gps week number ------------------------------------------------------
* adjust gps week number using cpu time
* args   : int   week       I   not-adjusted gps week number
* return : adjusted gps week number
*-----------------------------------------------------------------------------*/
int adjgpsweek(int week)
{
    int w;
    time2gpst(utc2gpst(timeget()),&w);
    if (w<1560) w=1560; /* use 2009/12/1 if time is earlier than 2009/12/1 */
    return week+(w-week+512)/1024*1024;
}

/* time to gps time ------------------------------------------------------------
* convert gtime_t struct to week and tow in gps time
* args   : gtime_t t        I   gtime_t struct
*          int    *week     IO  week number in gps time (NULL: no output)
* return : time of week in gps time (s)
*-----------------------------------------------------------------------------*/
double time2gpst(gtime_t t, int *week)
{
    gtime_t t0 = epoch2time(gpst0.ptr);
    time_t sec = t.time - t0.time;
    int w = cast(int)(sec/(86400*7));
    
    if (week) *week=w;
    return cast(double)(sec-w*86400*7) + t.sec;
}

/* utc to gpstime --------------------------------------------------------------
* convert utc to gpstime considering leap seconds
* args   : gtime_t t        I   time expressed in utc
* return : time expressed in gpstime
* notes  : ignore slight time offset under 100 ns
*-----------------------------------------------------------------------------*/
gtime_t utc2gpst(gtime_t t)
{
    int i;
    
    for (i=0;i<leaps.length;i++) {
        if (timediff(t,epoch2time(leaps[i].ptr))>=0.0) return timeadd(t,-leaps[i][6]);
    }
    return t;
}

gtime_t timeget()
{
    enum double timeoffset_ = 0.0;        /* time offset (s) */

    double ep[6] = 0;

    auto time = Clock.currTime;

    ep[0] = time.year; ep[1] = time.month;  ep[2] = time.day;
    ep[3] = time.hour; ep[4] = time.minute; ep[5] = time.second + time.fracSec.msecs * 1E-3;

    return timeadd(epoch2time(ep.ptr), timeoffset_);
}

gtime_t epoch2time(in double *ep)
{
    immutable int[] doy = [1,32,60,91,121,152,182,213,244,274,305,335];
    gtime_t time={0};
    int days,sec,year=cast(int)ep[0],mon=cast(int)ep[1],day=cast(int)ep[2];
    
    if (year<1970||2099<year||mon<1||12<mon) return time;
    
    /* leap year if year%4==0 in 1901-2099 */
    days = (year-1970)*365+(year-1969)/4+doy[mon-1]+day-2+(year%4==0&&mon>=3?1:0);
    sec = cast(int)std.math.floor(cast(real)ep[5]);
    time.time = cast(int)(cast(time_t)days*86400+cast(int)ep[3]*3600+cast(int)ep[4]*60+sec);
    time.sec = ep[5] - sec;
    return time;
}

immutable double[] gpst0 = [1980,1, 6,0,0,0]; /* gps time reference */

immutable double[7][] leaps = [ /* leap seconds [y,m,d,h,m,s,utc-gpst,...} */
    [2012,7,1,0,0,0,-16],
    [2009,1,1,0,0,0,-15],
    [2006,1,1,0,0,0,-14],
    [1999,1,1,0,0,0,-13],
    [1997,7,1,0,0,0,-12],
    [1996,1,1,0,0,0,-11],
    [1994,7,1,0,0,0,-10],
    [1993,7,1,0,0,0, -9],
    [1992,7,1,0,0,0, -8],
    [1991,1,1,0,0,0, -7],
    [1990,1,1,0,0,0, -6],
    [1988,1,1,0,0,0, -5],
    [1985,7,1,0,0,0, -4],
    [1983,7,1,0,0,0, -3],
    [1982,7,1,0,0,0, -2],
    [1981,7,1,0,0,0, -1]
];


/* time difference -------------------------------------------------------------
* difference between gtime_t structs
* args   : gtime_t t1,t2    I   gtime_t structs
* return : time difference (t1-t2) (s)
*-----------------------------------------------------------------------------*/
double timediff(gtime_t t1, gtime_t t2)
{
    return difftime(t1.time,t2.time)+t1.sec-t2.sec;
}


/* add time --------------------------------------------------------------------
* add time to gtime_t struct
* args   : gtime_t t        I   gtime_t struct
*          double sec       I   time to add (s)
* return : gtime_t struct (t+sec)
*-----------------------------------------------------------------------------*/
extern gtime_t timeadd(gtime_t t, double sec)
{
    double tt;
    
    t.sec+=sec; tt=std.math.floor(t.sec); t.time+=cast(int)tt; t.sec-=tt;
    return t;
}

/* gps time to time ------------------------------------------------------------
* convert week and tow in gps time to gtime_t struct
* args   : int    week      I   week number in gps time
*          double sec       I   time of week in gps time (s)
* return : gtime_t struct
*-----------------------------------------------------------------------------*/
gtime_t gpst2time(int week, double sec)
{
    gtime_t t = epoch2time(gpst0.ptr);
    
    if (sec < -1E9 || 1E9 < sec) sec = 0.0;
    t.time += 86400 * 7 * week + cast(int)sec;
    t.sec = sec - cast(int)sec;
    return t;
}

// semi-circle to radian
alias SC2RAD = std.math.PI;