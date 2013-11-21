/*------------------------------------------------------------------------------
* sdrmain.c : SDR main functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*-----------------------------------------------------------------------------*/
import sdr;

import std.c.string : memcpy;
import std.stdio;
import core.sync.mutex;
import std.concurrency;
import core.thread;
import std.algorithm;
import std.datetime;
import std.math;

/* global variables -----------------------------------------------------------*/
/* thread handle and mutex */

/* sdr structs */
sdrini_t sdrini;
sdrstat_t sdrstat;
sdrch_t sdrch[Constant.totalSatellites];
sdrspec_t sdrspec;

double l1ca_doppler;


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
version(MAIN_IS_SDRMAIN_MAIN){
    void main(string[] args)
    {
        //util.trace.tracing = false;

        import std.datetime : StopWatch;
        StopWatch sw;
        sw.start();

        sdrini.readIniFile(args.length > 1 ? args[1] : "gnss-sdrcli.ini");
        checkInitValue(sdrini);

        startsdr();

        sw.stop();
        writefln("total time = %s[ms]", sw.peek.msecs);
    }
}


/* sdr start --------------------------------------------------------------------
* start sdr function  
* args   : void   *arg      I   not used
* return : none
* note : This function is called as thread in GUI application and is called as
*        function in CLI application
*------------------------------------------------------------------------------*/
void startsdr()
{
    writeln("GNSS-SDRLIB start!");
    /* receiver initialization */
    enforce(rcvinit(&sdrini) >= 0);
    scope(exit) rcvquit(&sdrini);

    util.trace.tracing = false;
    enforce(sdrini.nch >= 1);
    enforce(initsdrch(1, sdrini.sys[0], sdrini.sat[0], sdrini.ctype[0], sdrini.dtype[sdrini.ftype[0]-1], sdrini.ftype[0], sdrini.f_sf[sdrini.ftype[0]-1], sdrini.f_if[sdrini.ftype[0]-1],&sdrch[0]) >= 0);
    enforce(/*sdrch[0].sys == SYS_GPS && */sdrch[0].ctype == CType.L1CA);
    sdrthread(0);   // start SDR

    if(sdrini.nch >= 2){
        //if(sdrini.ctype[1] != sdrini.ctype[0])
        //    l1ca_doppler = sdrini.f_if[0] + 1748;
        //l1ca_doppler = sdrini.f_if[0];

        sdrstat.buffloccnt = 0;
        sdrstat.stopflag = 0;
        rcvquit(&sdrini);
        enforce(rcvinit(&sdrini) >= 0);
        enforce(initsdrch(2, sdrini.sys[1], sdrini.sat[1], sdrini.ctype[1], sdrini.dtype[sdrini.ftype[1]-1], sdrini.ftype[1], sdrini.f_sf[sdrini.ftype[1]-1], sdrini.f_if[sdrini.ftype[1]-1],&sdrch[1]) >= 0);
        //enforce(/*sdrch[0].sys == SYS_GPS && */sdrch[1].ctype == CType.L2RCCM);
        //sdrthread_l2cm(1);
        util.trace.tracing = true;
        sdrthread(1);
    }

    SDRPRINTF("GNSS-SDRLIB is finished!\n");
}


/* sdr channel thread -----------------------------------------------------------
* sdr channel thread for signal acquisition and tracking  
* args   : void   *arg      I   sdr channel struct
* return : none
* note : This thread handles the acquisition and tracking of one of the signals. 
*        The thread is created at startsdr function.
*------------------------------------------------------------------------------*/
void sdrthread(size_t index)
{
    sdrch_t* sdr = &(sdrch[index]);
    sdrplt_t pltacq,plttrk;
    size_t buffloc = 0, cnt = 0,loopcnt = 0;
    int cntsw = 0, swsync, swreset;
    double *acqpower = null;

    immutable resultLFileName = `Result\` ~ sdr.ctype.to!string() ~ "_" ~ sdr.satstr ~ "_" ~ Clock.currTime.toISOString() ~ ".csv";
    File resultLFile = File(resultLFileName, "w");
    resultLFile.writeln("buffloc, remcode[chip], carrierPhase[cycle], pll_carrErr, pll_carNco, pll_carrfreq, dll_codeErr, dll_codeNco, dll_codefreq, IP, QP, IE, QE, IL, QL,");

    /* plot setting */
    initpltstruct(&pltacq,&plttrk,sdr);
    //enforce(initpltstruct(&pltacq,&plttrk,sdr) !< 0);

    SDRPRINTF("**** %s sdr thread start! ****\n",sdr.satstr);

    /* check the exit flag */
    bool isStopped()
    {
        return sdrstat.stopflag != 0;
    }

    
    while (!isStopped()) {
        /* acquisition */
        if (!sdr.flagacq) {
            StopWatch sw;
            sw.start();

            /* memory allocation */
            if (acqpower != null) free(acqpower);
            acqpower = cast(double*)calloc(double.sizeof, sdr.acq.nfft * sdr.acq.nfreq).enforce();
            
            /* fft correlation */
            buffloc = sdracquisition(sdr, acqpower, buffloc);
            sw.stop();
            writefln("AcqTime: %s[us]", sw.peek.usecs);


            /* plot aquisition result */
            if (sdr.flagacq && sdrini.pltacq) {
                pltacq.z=acqpower;
                plot(&pltacq, "acq_" ~ sdr.satstr ~ "_" ~ sdr.ctype.to!string()); 
            }
        }
        /* tracking */
        if (sdr.flagacq) {
            immutable bufflocnow = sdrtracking(sdr, buffloc, cnt);

            if (sdr.flagtrk) {
                if (sdr.nav.swnavsync) cntsw = 0;
                if ((cntsw%sdr.trk.loopms)==0) swsync = true;
                else swsync = false;

                if (((cntsw-1)%sdr.trk.loopms) == 0) swreset = true;
                else swreset = false;
                
                /* correlation output accumulation */
                cumsumcorr(sdr.trk.I, sdr.trk.Q, &sdr.trk, sdr.flagnavsync, swreset);
                
                if (!sdr.flagnavsync) {
                    pll(sdr,&sdr.trk.prm1); /* PLL */
                    dll(sdr,&sdr.trk.prm1); /* DLL */
                }
                else/* if (swsync) */{
                    pll(sdr,&sdr.trk.prm2); /* PLL */
                    dll(sdr,&sdr.trk.prm2); /* DLL */

                    /* calculate observation data */
                    if (loopcnt%(Constant.Observation.SNSMOOTHMS/sdr.trk.loopms)==0)
                        setobsdata(sdr, buffloc, cnt, &sdr.trk, 1); /* SN smoothing */
                    else
                        setobsdata(sdr, buffloc, cnt, &sdr.trk, 0);

                    /* plot correator output */
                    if (loopcnt%(cast(int)(plttrk.pltms/sdr.trk.loopms))==0&&sdrini.plttrk&&loopcnt>200) {
                        plttrk.x=sdr.trk.prm2.corrx;
                        memcpy(plttrk.y,sdr.trk.sumI,double.sizeof*(sdr.trk.ncorrp*2+1));
                        plotthread(&plttrk, "trk_" ~ sdr.satstr ~ "_");
                    }
                }

                loopcnt++;

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

                //if(!sdr.flagnavsync || swsync)
                    resultLFile.writefln("%s, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f, %.9f,%.9f,%.9f,%.9f,%.9f,",
                                          buffloc, sdr.trk.remcode, sdr.trk.L[0], sdr.trk.carrErr, sdr.trk.carrNco, sdr.trk.carrfreq,
                                          sdr.trk.codeErr, sdr.trk.codeNco, sdr.trk.codefreq,
                                          sdr.trk.sumI[0], sdr.trk.sumQ[0],
                                          sdr.trk.sumI[sdr.trk.prm1.ne], sdr.trk.sumQ[sdr.trk.prm1.ne],
                                          sdr.trk.sumI[sdr.trk.prm1.nl], sdr.trk.sumQ[sdr.trk.prm1.nl]);

                if (/*sdr.no==1&&*/cnt%(1000*10)==0) SDRPRINTF("process %d sec...\n",cast(int)cnt/(1000));
                cnt++;
                cntsw++;
            }
            buffloc = bufflocnow;
        }
        sdr.trk.buffloc = buffloc;
    }
    /* plot termination */
    quitpltstruct(&pltacq,&plttrk);

    SDRPRINTF("SDR channel %s thread finished!\n",sdr.satstr);
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
