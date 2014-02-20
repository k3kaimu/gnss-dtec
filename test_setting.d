
        module sdrconfig;


        import core.time;
        import std.typecons;

        import sdr;


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
                    {path: `C:\gps_data\2013_09_26\15_45\l1rx.dat`, f_sf: 26e6, f_if: 6.5e6, dtype: DType.I},
                    {path: `C:\gps_data\2013_09_26\15_45\lbrx.dat`, f_sf: 26e6, f_if: 0,     dtype: DType.IQ},
                ];
              }
              else static if(fendType == Fend.FILESTEREO)
              {
                enum path = `F:\20130108_stereo_v25-win64-beta\bin\2013_1209_1516.dat`;
                enum Receiver[] fends = [
                    {f_sf: 26e6, f_if: 6.5e6, dtype: DType.I},
                    {f_sf: 26e6, f_if: 0,     dtype: DType.IQ},
                ];
              }

                enum startBuffloc = 1098240000000;
                enum endBuffloc = 2315040000000;
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
    