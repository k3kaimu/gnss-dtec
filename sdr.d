//##& set waitTime 10000            // 10s
//##$ dmd -m64 -unittest -O -release -inline -version=MAIN_IS_SDRMAIN_MAIN sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrmain sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize

//　-version=Dnative -debug=PrintBuffloc -version=TRACE  -O -release -inline  -version=NavigationDecode -version=L2Develop -version=useFFTW
/*
Change Log:
2013/07/18          単一スレッド化
2013/07/16 v2.0beta バッファ読み込みを、sdrスレッドが操るように修正

version指定一覧
+ Dnative               なるべくD言語ネイティブなプログラムにします。(外部のdllをなるべく触らないということ)
+ TRACE                 trace, traceln, traceflnが有効になります。
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
import std.format : formattedWrite;
import std.array  : appender;
import std.traits : isSomeString;
import core.memory;


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


// msgpack-d
pragma(lib, "msgpack_x64.lib");


/* FEC */
//pragma(lib, "libfec.a");
//public import fec;

/* FFT */
static if(!isVersion!"Dnative"){
    public import fftw;
    pragma(lib, "libfftw3f-3.lib");
}


enum NavSystem
{
    GPS = 0x01,
    SBAS = 0x02,
    GLONASS = 0x04,
    Galileo = 0x08,
    QZSS = 0x10,
    BeiDou = 0x20,
}


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
immutable NFFTTHREAD = 4;

struct Constant{
    // this struct is used as name space
    @disable this();
    @disable this(this);

    struct L1CA{
        // this struct is used as name space
        @disable this();

        struct Acquisition{
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


        struct Navigation{
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


    struct L1SAIF{
        // this struct is used as name space
        @disable this();

        struct Acquisition{
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


        struct Navigation{
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


    struct L2CM{
        struct Acquisition{
            // this struct is used as name space
            @disable this();

            enum INTG = 4;
            enum HBAND = 40;
            enum STEP = 2;
            enum TH = 2.0;
            //enum LENF = 10;
            //enum FFTFRESO = 10;
            enum SLEEP = 2000;
        }

        enum LOOP_MS = 10;
        enum freq = 10.23e6 * 2 * 60;
    }

    struct Tracking{
        // this struct is used as name space
        @disable this();

        struct Parameter1{
            // this struct is used as name space
            @disable this();

            enum CDN = 3;
            enum CP = 12;
            enum DLLB = 1.0;
            enum PLLB = 20.0;
            enum FLLB = 250.0;
            enum DT = 0.001;
        }


        struct Parameter2{
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

    struct Observation{
        // this struct is used as name space
        @disable this();

        enum PTIMING = 68.802;
        enum OBSINTERPN = 8;
        enum SNSMOOTHMS = 100;
    }


    struct CodeGeneration{
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
          case CType.L2CM:{
            static if(name == "Acquisition.LENF" || name == "Acquisition.FFTFRESO" || (name.length >= 10 && name[0 .. 10] == "Navigation") )
                goto default;
            else
                return mixin("L2CM." ~ name);
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


    struct GPS{
        // this struct is used as name space
        @disable this();

        struct PRN{
            // this struct is used as name space
            @disable this();

            enum min = MINPRNGPS;
            enum max = MAXPRNGPS;
        }

        enum totalSatellites = NSATGPS;
    }


    struct GLONASS{
        // this struct is used as name space
        @disable this();

        struct PRN{
            // this struct is used as name space
            @disable this();

            enum min = MINPRNGLO;
            enum max = MAXPRNGLO;
        }

        enum totalSatellites = NSATGLO;
    }


    struct Galileo{
        // this struct is used as name space
        @disable this();

        struct PRN{
            // this struct is used as name space
            @disable this();

            enum min = MINPRNGAL;
            enum max = MAXPRNGAL;
        }

        enum totalSatellites = NSATGAL;
    }


    struct QZSS{
        // this struct is used as name space
        @disable this();

        struct PRN{
            // this struct is used as name space
            @disable this();

            enum min = MINPRNQZS;
            enum max = MAXPRNQZS;
        }

        enum totalSatellites = NSATQZS;
    }


    struct BeiDou{
        // this struct is used as name space
        @disable this();

        struct PRN{
            // this struct is used as name space
            @disable this();

            enum min = MINPRNCMP;
            enum max = MAXPRNCMP;
        }

        enum totalSatellites = NSATCMP;
    }


    struct SBAS{
        // this struct is used as name space
        @disable this();

        struct PRN{
            // this struct is used as name space
            @disable this();

            enum min = MINPRNSBS;
            enum max = MAXPRNSBS;
        }

        enum totalSatellites = NSATSBS;
    }
}

public import rtklib : eph_t, obsd_t, rnxopt_t;


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
    string title;
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
      case NavSystem.QZSS:      return GPS.totalSatellites + GLONASS.totalSatellites + Galileo.totalSatellites + prn - BeiDou.PRN.min+ 1;
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
        case NavSystem.GPS:     return "G%02d".formattedString(prn - Constant.GPS.PRN.min + 1);
        case NavSystem.GLONASS: return "R%02d".formattedString(prn - Constant.GLONASS.PRN.min + 1);
        case NavSystem.Galileo: return "E%02d".formattedString(prn - Constant.Galileo.PRN.min + 1);
        case NavSystem.QZSS:    return "J%02d".formattedString(prn - Constant.QZSS.PRN.min + 1);
        case NavSystem.BeiDou:  return "C%02d".formattedString(prn - Constant.BeiDou.PRN.min + 1);
        case NavSystem.SBAS:    return "%03d".formattedString(prn);
    }

    assert(0);
}