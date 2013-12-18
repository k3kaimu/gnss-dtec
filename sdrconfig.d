module sdrconfig;


import core.time;
import std.typecons;

import sdr;


struct Config
{
    enum useFFTW = false;
    enum trace = false;
    enum traceCSV = false;

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
      else static if(fendType == Fend.FILE)
      {
        string path;
      }


      static if(fendType == Fend.FILE)
      {
        enum Receiver[] fends  = [
            {path: `C:\gps_data\2013_09_26\15_45\l1rx.dat`, f_sf: 26e6, f_if: 6.5e6, dtype: DType.I},
            {path: `C:\gps_data\2013_09_26\15_45\lbrx.dat`, f_sf: 26e6, f_if: 0,     dtype: DType.IQ},
        ];
      }
      else static if(fendType == Fend.FILESTEREO)
      {
        enum path = `C:\gps_data\2013_12_09\splitted_5min.dat`;
        enum Receiver[] fends = [
            {f_sf: 26e6, f_if: 6.5e6, dtype: DType.I},
            {f_sf: 26e6, f_if: 0,     dtype: DType.IQ},
        ];
      }
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
    enum readSpeed = 0.95;
}
