//##& set waitTime 10000
//##$ dmd -run runSDR -O -inline -release -m64 -version=UseFFT -unittest test_setting sdrmain -ofsdrmain.exe

//　-version=Dnative -debug=PrintBuffloc -version=TRACE -version=L2Develop -O -release -inline -version=L2Develop -version=useFFTW
/*
version指定一覧
+ TRACE                 trace, traceln, traceflnが有効になります。
+ TRACE_CSV             csvOutputが有効になります。
+ NavigationDecode      航法メッセージを解読しようとします(L1CAのみ)
+ L2Develop             L2CM用のSDR開発のためのバージョン
+ UseFFTW               FFTの計算にFFTWを使用します(デフォルトだと、std.numeric.Fftを使用します)

debug指定一覧
+ PrintBuffloc          すでにどれだけデータを読み込んだかを表示します。
*/

/*------------------------------------------------------------------------------
* sdrmain.c : SDR main functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*-----------------------------------------------------------------------------*/
import sdr;
import sdrinit;
import sdrrcv;
import sdracq;
import sdrtrk;
import sdrplot;

import util.trace;

import std.c.string : memcpy;
import std.stdio;
import core.sync.mutex;
import std.concurrency;
import core.thread;
import std.algorithm;
import std.datetime;
import std.math;
import std.exception;
import std.conv;
import std.range;


/**
フロントエンドが吐く生データを解析して, コンソールやファイルにデータを出力する.

コマンドライン引数:
    ./sdr <ini_file_path>
        <ini_file_path>
            .iniファイルのパス
            コマンドライン引数に与えられていなければ, 同じディレクトリの`gnss-sdrcli.ini`になる

入力:
    ・iniファイル
        コマンドライン引数で指定する.指定されなければ`gnss-sdrcli.ini`が読み込まれる

    ・フロントエンドからの生データ
        iniファイルに記述されたパスのファイルを読み込む.
        Stereoが吐くバイナリは圧縮形式なので, Stereo付属のユーティリティで展開すること.

出力:
    ・SerializedData\(acq, or trk + 解析時刻の文字列表現).dat
        信号捕捉や信号追尾の結果のデータ.
        msgpackによってutil.serialized.PlotObjectがバイナリ化されている.
        本ライブラリ群付属のplotobj_to_csv.exeによってText, CSV, Gnuplotのコマンド列に変換可能である.

    ・Result\(L1 + 解析開始時刻の文字列表現).csv
        解析が完了した生データのサンプル数と, その時点での搬送波位相[cycle]
*/
void main(string[] args)
{
    import std.datetime : StopWatch;
    StopWatch sw;
    sw.start();

    auto sdrini = sdrini_t(args.length > 1 ? args[1] : "gnss-sdrcli.ini");
    sdrini.startsdr();

    sw.stop();
    writefln("total time = %s[ms]", sw.peek.msecs);
}


/* sdr start --------------------------------------------------------------------
* start sdr function  
* args   : void   *arg      I   not used
* return : none
* note : This function is called as thread in GUI application and is called as
*        function in CLI application
*------------------------------------------------------------------------------*/
void startsdr(ref sdrini_t ini)
{
    writeln("GNSS-SDRLIB start!");
    sdrstat_t stat;

    foreach(i; 0 .. ini.nch)
    {
        enforce(ini.rcvinit(stat) >= 0);
        auto sdrch = sdrch_t(ini, i);
        sdrch.sdrthread(ini, stat);
        //sdrch[i] = sdrch_t(ini, i);
        //sdrch[i].sdrthread(ini, stat);   // start SDR

        stat.buffloccnt = 0;
        stat.stopflag = 0;
        ini.rcvquit();

        if(ini.ctype[i] == CType.L2RCCM)
            l1ca_doppler = typeof(l1ca_doppler).nan;
    }

    writeln("GNSS-SDRLIB is finished!");
}


/* sdr channel thread -----------------------------------------------------------
* sdr channel thread for signal acquisition and tracking  
* args   : void   *arg      I   sdr channel struct
* return : none
* note : This thread handles the acquisition and tracking of one of the signals. 
*        The thread is created at startsdr function.
*------------------------------------------------------------------------------*/
void sdrthread(ref sdrch_t sdr, ref sdrini_t ini, ref sdrstat_t stat)
{
    sdrplt_t pltacq, plttrk;
    size_t buffloc, cnt, loopcnt;
    int cntsw, swsync, swreset;

    immutable resultLFileName = `Result\` ~ sdr.ctype.to!string() ~ "_" ~ sdr.satstr ~ "_" ~ Clock.currTime.toISOString() ~ ".csv";
    auto resultLFile = File(resultLFileName, "w");
    resultLFile.writeln("buffloc, remcode[chip], carrierPhase[cycle], pll_carrErr, pll_carNco, pll_carrfreq, dll_codeErr, dll_codeNco, dll_codefreq, SNR, IP, QP, IE, QE, IL, QL,");

    /* plot setting */
    sdr.initpltstruct(ini, pltacq, plttrk);
    //enforce(initpltstruct(&pltacq,&plttrk,sdr) !< 0);

    writefln("**** %s sdr thread start! ****", sdr.satstr);

    /* check the exit flag */
    bool isStopped()
    {
        return stat.stopflag != 0;
    }

    
    while (!isStopped()) {
        /* acquisition */
        if (!sdr.flagacq) {

            cnt = 0;
            loopcnt = 0;
            cntsw = 0;
            swsync = 0;
            swreset = 0;
            
            /* fft correlation */
            auto acqPower = sdr.sdracquisition(ini, stat, buffloc);

            /* plot aquisition result */
            if (sdr.flagacq && ini.pltacq) {
                {
                    auto p = pltacq.z;
                    foreach(e; acqPower)
                        p.put(e);
                }
                plot(&pltacq, "acq_" ~ sdr.satstr ~ "_" ~ sdr.ctype.to!string()); 
            }
        }
        /* tracking */
        if (sdr.flagacq) {
            immutable bufflocnow = sdr.sdrtracking(ini, stat, buffloc, cnt);

            if (sdr.flagtrk) {
                if (sdr.nav.swnavsync) cntsw = 0;
                if ((cntsw%sdr.trk.loopms)==0) swsync = true;
                else swsync = false;

                if (((cntsw-1)%sdr.trk.loopms) == 0) swreset = true;
                else swreset = false;
                
                /* correlation output accumulation */
                sdr.trk.cumsumcorr(sdr.flagnavsync, swreset);
                
                if (!sdr.flagnavsync) {
                    sdr.pll(sdr.trk.prm1); /* PLL */
                    sdr.dll(sdr.trk.prm1); /* DLL */
                }
                else /*if (swsync) */{
                    sdr.pll(sdr.trk.prm2); /* PLL */
                    sdr.dll(sdr.trk.prm2); /* DLL */

                    /* calculate observation data */
                    if (loopcnt%(Constant.Observation.SNSMOOTHMS/sdr.trk.loopms)==0)
                        sdr.setobsdata(buffloc, cnt, 1); /* SN smoothing */
                    else
                        sdr.setobsdata(buffloc, cnt, 0);

                    /* plot correator output */
                    if (loopcnt%(cast(int)(plttrk.pltms/sdr.trk.loopms))==0&&ini.plttrk&&loopcnt>200) {
                        plttrk.x[] = sdr.trk.prm2.corrx[];
                        plttrk.y[0 .. sdr.trk.sumI.length] = sdr.trk.sumI[];
                        plotthread(&plttrk, "trk_" ~ sdr.satstr ~ "_");
                    }
                }

                ++loopcnt;

                if(loopcnt > 1000 && isNaN(l1ca_doppler))
                {
                    assert(sdr.ctype == CType.L1CA);
                    l1ca_doppler = sdr.trk.carrfreq;
                    writeln("doppler find");
                    
                    version(L2Develop) return;
                }

                (sdr.nav.swnavsync) && tracefln("sdr.nav.swnavsync is ON on %s", buffloc);
                (cntsw) && tracefln("cntsw is ON on %s", buffloc);
                (swreset) && tracefln("swreset is ON on %s", buffloc);
                (sdr.flagnavsync) && tracefln("sdr.flagnavsync is ON on %s", buffloc);
                (swsync) && tracefln("swsync is ON on %s", buffloc);

                if(swsync)
                    resultLFile.writefln("%s, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f,",
                                          buffloc, sdr.trk.remcode, sdr.trk.L[0], sdr.trk.carrErr, sdr.trk.carrNco, sdr.trk.carrfreq,
                                          sdr.trk.codeErr, sdr.trk.codeNco, sdr.trk.codefreq,
                                          sdr.trk.S[0],
                                          sdr.trk.sumI[0], sdr.trk.sumQ[0],
                                          sdr.trk.sumI[sdr.trk.prm1.ne], sdr.trk.sumQ[sdr.trk.prm1.ne],
                                          sdr.trk.sumI[sdr.trk.prm1.nl], sdr.trk.sumQ[sdr.trk.prm1.nl]);

                if (/*sdr.no==1&&*/cnt%(1000*10)==0) writefln("process %s sec...", cast(int)cnt/(1000));
                cnt++;
                cntsw++;
            }
            buffloc = bufflocnow;
        }
        sdr.trk.buffloc = buffloc;
    }
    /* plot termination */
    ini.quitpltstruct(pltacq, plttrk);

    writefln("SDR channel %s thread finished!", sdr.satstr);
}


version(none):

/* synchronization thread -------------------------------------------------------
* synchronization thread for pseudo range computation  
* args   : void   *arg      I   not used
* return : none
* note : this thread collects all data of sdr channel thread and compute pseudo
*        range at every output timing.
*------------------------------------------------------------------------------*/
void syncthread()
{
    int nsat,mini=int.max, stop=0,refi;
    int[MAXOBS] isat;
    int[MAXSAT] ind;
    ulong sampref,sampbase, diffsamp,cnt=0,maxcodei;
    ulong[MAXSAT] codei;
    double codeid[OBSINTERPN];
    double remcode[MAXSAT];
    double samprefd,reftow=0,oldreftow;
    sdrobs_t obs[MAXSAT];
    sdrout_t out_={0};
    sdrtrk_t trk[MAXSAT]={0};

    /* start tcp server */
    if (sdrini.rtcm) {
        out_.soc.port=sdrini.rtcmport;
        tcpsvrstart(&out_.soc);
        Sleep(500);
    }

    /* rinex output setting */
    if (sdrini.rinex) {
        createrinexopt(&out_.opt);
        if ((createrinexobs(out_.rinexobs,&out_.opt)<0)|| 
            (createrinexnav(out_.rinexnav,&out_.opt)<0)) {
                sdrstat.stopflag=ON; stop=ON;
        }
    }

    out_.obsd=cast(obsd_t *)calloc(MAXSAT,obsd_t.sizeof);
    
    while (!stop) {
        synchronized(hstopmtx)
            stop=sdrstat.stopflag;

        /* copy all tracking data */
        synchronized(hobsmtx){
            nsat = 0;
            foreach(i; 0 .. sdrini.nch){
                if (sdrch[i].flagnavdec&&sdrch[i].nav.eph.week!=0) {
                    memcpy(&trk[nsat],&sdrch[i].trk,sdrch[i].trk.sizeof);          
                    isat[nsat]=i;
                    nsat++;
                }
            }
        }
        
        /* find minimum tow channel (nearest satellite) */
        oldreftow = reftow;
        reftow = 3600*24*7;

        foreach(i; 0 .. nsat){
            if (trk[i].tow[isat[0]]<reftow)
                reftow=trk[i].tow[isat[0]];
        }
        /* output timing check */
        if (nsat==0||oldreftow==reftow||(cast(int)(reftow*100)%(sdrini.outms/10))!=0) {
            continue;
        }

        /* select same timing index  */
        foreach(i; 0 .. nsat){
            foreach(j; 0 .. MAXOBS){
                if (trk[i].tow[j]==reftow)
                    ind[i]=j;
            }       
        }

        /* decide reference satellite (most distant satellite) */
        maxcodei = 0;
        refi=0;
        foreach(i; 0 .. nsat){
            codei[i]=trk[i].codei[ind[i]];
            remcode[i]=trk[i].remcodeout[ind[i]];
            if (trk[i].codei[ind[i]]>maxcodei){
                refi=i;
                maxcodei=trk[i].codei[ind[i]];
            }
        }

        /* reference satellite */
        diffsamp = trk[refi].cntout[ind[refi]]-sdrch[isat[refi]].nav.firstsfcnt;
        sampref = sdrch[isat[refi]].nav.firstsf+cast(ulong)(sdrch[isat[refi]].nsamp*(-cast(int)(PTIMING)+diffsamp)); /* reference sample */
        sampbase = trk[refi].codei[OBSINTERPN-1]-10*sdrch[isat[refi]].nsamp;
        samprefd = cast(double)(sampref-sampbase);
        
        /* computation observation data */
        foreach(i; 0 .. nsat){
            obs[i].sat=sdrch[isat[i]].sat;
            obs[i].week=sdrch[isat[i]].nav.eph.week;
            obs[i].tow=reftow+cast(double)(PTIMING)/1000; 
            obs[i].P = CLIGHT * sdrch[isat[i]].ti * (cast(double)(codei[i]-sampref) - remcode[i]); /* pseudo range */

            /* uint64 to double for interp1 */
            uint64todouble(trk[i].codei.ptr,sampbase,OBSINTERPN,codeid.ptr);
            obs[i].L = interp1(codeid.ptr, trk[i].L.ptr, OBSINTERPN, samprefd);
            obs[i].D = interp1(codeid.ptr, trk[i].D.ptr, OBSINTERPN, samprefd);
            obs[i].S = trk[i].S[0];
        }
        out_.nsat = nsat;
        sdrobs2obsd(obs.ptr, nsat, out_.obsd);

        /* rinex obs output */
        if (sdrini.rinex) {
            if (writerinexobs(out_.rinexobs, &out_.opt, out_.obsd, out_.nsat) < 0) {
                sdrstat.stopflag = ON; stop = ON;
            }
        }

        /* rtcm obs output */
        if (sdrini.rtcm && out_.soc.flag) 
            sendrtcmobs(out_.obsd,&out_.soc,out_.nsat);
                
        /* navigation data output */
        foreach(i;0 .. sdrini.nch){
            if ((sdrch[i].nav.eph.update)&&(sdrch[i].nav.eph.cnt==3)) {
                sdrch[i].nav.eph.cnt = 0;
                sdrch[i].nav.eph.update = OFF;

                /* rtcm nav output */
                if (sdrini.rtcm&&out_.soc.flag) 
                    sendrtcmnav(&sdrch[i].nav.eph,&out_.soc);
                
                /* rinex nav output */
                if (sdrini.rinex) {
                    if (writerinexnav(out_.rinexnav,&out_.opt,&sdrch[i].nav.eph)<0) {
                        sdrstat.stopflag = ON; stop = ON;
                    }
                }
            }
        }
    }
    /* thread termination */
    free(out_.obsd);
    tcpsvrclose(&out_.soc);
    SDRPRINTF("SDR syncthread finished!\n");
}


/* keyboard thread --------------------------------------------------------------
* keyboard thread for program termination  
* args   : void   *arg      I   not used
* return : none
* note : this thread is only created in CLI application
*------------------------------------------------------------------------------*/
void keythread() 
{
    int stop = 0,c;

    do {
        c = getchar();
        switch(c) {
            case 'q':
            case 'Q':
                synchronized(hstopmtx)
                    sdrstat.stopflag = 1;
                break;

            default:
                SDRPRINTF("press 'q' to exit...\n");
                break;
        }
        synchronized(hstopmtx)
            stop = sdrstat.stopflag;

    } while (!stop);
}
