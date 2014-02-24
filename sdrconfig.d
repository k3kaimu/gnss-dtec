// Written in the D programming language.
/**
Authors: Kazuki Komatsu
License: Kazuki Komatsu - NYSL
*/
module sdrconfig;


import core.time;
import std.typecons;

import sdr;

/**
STEREOのL1の中間周波数。
CTFEable
*/
real f_if_STEREO_L1() @property
{
    real n = 0b000000000111100;
    real r = 0b01010111110100111110;

    real f = (n + r / (1 << 20)) * 26.0e6;
    return 2 * 77 * 10.23e6 - f;
}


/**
STEREOのLBandにおける、L2に設定した場合の中間周波数。
もちろんCTFEable
*/
real f_if_STEREO_L2() @property
{
      real n = 0b101111;
      real r = 0b00110111001000110111;

      real f = (n + r / (1 << 20)) * 26.0e6;
    return 2 * 60 * 10.23e6 - f;
}


/**
各種設定
*/
struct Config
{
    enum useFFTW = true;    /// FFTの計算にFFTWを使用するかどうか
    enum trace = false;     /// ログをstdoutに出力するかどうか
    enum traceCSV = false;  /// CSV形式のログを出力するかどうか

    struct Receiver
    {
        // フロントエンドの種類
        enum fendType = Fend.FILESTEREO;

        real f_sf;      // サンプリング周波数
        real f_if;      // 中間周波数
        DType dtype;    // IQ or I-only

      static if(fendType == Fend.STEREO)
      {
        bool doConfig;  // STEREOの初期設定を行うかどうか
      }
      else static if(fendType == Fend.FILE)
      {
        string path;    // データファイルへのパス
      }


      static if(fendType == Fend.FILE)
      {
        // フロントエンドの設定
        enum Receiver[] fends  = [
            {path: `D:\gpsData\l1rx.dat`,
             f_sf: 26e6,
             f_if: f_if_STEREO_L1,
             dtype: DType.I},

            {path: `D:\gpsData\lbrx.dat`,
             f_sf: 26e6,
             f_if: f_if_STEREO_L2,
             dtype: DType.IQ},
        ];
      }
      else static if(fendType == Fend.FILESTEREO)
      {
        // フロントエンドの設定
        enum path = `E:\20130108_stereo_v25-win64-beta\bin\2013_1209_1516.dat`;
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


    // 対象の衛星についての設定
    enum channels = [
        ChannelConfig(NavSystem.GPS,    5, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,    7, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   12, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   15, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   17, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   24, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   27, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   29, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.GPS,   31, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
        ChannelConfig(NavSystem.QZSS, 193, [CType.L1CA:   FType.Type1,
                                            CType.L2RCCM: FType.Type2]),
    ];


    struct Plot
    {
        enum acq = false;   // 補足情報を描画するかどうか(未対応)
        enum trk = false;   // 追尾情報を描画するかどうか(未対応)
    }


    struct Output
    {
        enum interval = dur!"msecs"(100);   // RINEX出力のインターバル？
                                            // よく覚えてない
                                            // 未対応

        enum rinex = false;                 // RINEX出力するかどうか
        //enum rinexDirPath = `rinex`;

        enum rtcm = false;                  // RTCM出力するかどうか
        //enum rtcmPort = 9999;

        enum lex = false;                   // LEX、よくわかっていない
        //enum lexPort = 9998;
    }


    enum spectrum = false;
    enum readSpeed = 0.95;
}
