module sdrconfig;

import core.time;
import std.typecons;

import sdr;


struct Config
{
    struct Receiver
    {
        enum fendType = Fend.FILE;

        real f_sf;
        real f_if;
        DType dtype;

      static if(fendType == Fend.STEREO)
      {
        bool doConfig;
      }
      else static if(fendType == Fend.FILE || fendType == Fend.FILESTEREO)
      {
        string path;
      }

        enum Receiver[] fends  = [
            {path: `D:\gpsData\l1rx.dat`, f_sf: 26e6, f_if: 6.5e6, dtype: DType.I},
            {path: `D:\gpsData\lbrx.dat`, f_sf: 26e6, f_if:0,      dtype: DType.IQ},
        ];
    }



    alias ChannelSetting = Tuple!(uint, "prn", NavSystem, "sys", FType[CType], "fends");

    enum channels = [
        ChannelSetting(193, NavSystem.QZSS, [CType.L1CA: FType.Type1, CType.L2RCCM: FType.Type2]),
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
    enum realSpeed = 0.95;
}
