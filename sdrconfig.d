module sdrconfig;


import core.time;
import std.typecons;

import sdr;

real f_if_STEREO_L1() @property
{
    real n = 0b000000000111100;
    real r = 0b01010111110100111110;

    real f = (n + r / (1 << 20)) * 26.0e6;
    return 2 * 77 * 10.23e6 - f;
}


real f_if_STEREO_L2() @property
{
      real n = 0b101111;
      real r = 0b00110111001000110111;

      real f = (n + r / (1 << 20)) * 26.0e6;
    return 2 * 60 * 10.23e6 - f;
}


struct Config
{
    enum useFFTW = true;
    enum trace = false;
    enum traceCSV = false;

    struct Receiver
    {
        enum fendType = Fend.FILESTEREO;

        real f_sf;
        real f_if;
        DType dtype;

      static if(fendType == Fend.STEREO)
      {
        bool doConfig;
      }
      else static if(fendType == Fend.FILE)
      {
        string path;
      }


      static if(fendType == Fend.FILE)
      {
        enum Receiver[] fends  = [
            {path: `D:\gpsData\l1rx.dat`, f_sf: 26e6, f_if: f_if_STEREO_L1, dtype: DType.I},
            {path: `D:\gpsData\lbrx.dat`, f_sf: 26e6, f_if: f_if_STEREO_L2, dtype: DType.IQ},
        ];
      }
      else static if(fendType == Fend.FILESTEREO)
      {
        enum path = `F:\20130108_stereo_v25-win64-beta\bin\2013_1209_1516.dat`;
        enum Receiver[] fends = [
            {f_sf: 26e6, f_if: f_if_STEREO_L1, dtype: DType.I},
            {f_sf: 26e6, f_if: f_if_STEREO_L2, dtype: DType.IQ},
        ];
      }
    }



    struct ChannelConfig
    {
        NavSystem sys;
        uint prn;
        FType[CType] fends;
        real l1DopplerFreq = real.nan;
    }


    enum channels = [
        ChannelConfig(NavSystem.GPS,    5, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,    7, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   12, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   15, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   17, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   24, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   27, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   29, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   31, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.QZSS, 193, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
    ];


    struct Plot
    {
        enum acq = false;
        enum trk = false;
    }


    struct Output
    {
        enum interval = dur!"msecs"(100);

        enum rinex = false;
        //enum rinexDirPath = `rinex`;

        enum rtcm = false;
        //enum rtcmPort = 9999;

        enum lex = false;
        //enum lexPort = 9998;
    }


    enum spectrum = false;
    enum readSpeed = 0.95;
}
