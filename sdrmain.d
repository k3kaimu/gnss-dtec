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

/* global variables -----------------------------------------------------------*/
//#ifdef GUI
//GCHandle hform;
//#endif
/* thread handle and mutex */
__gshared Tid hmainthread;
__gshared Tid hkeythread;
__gshared Tid hsyncthread;
__gshared Tid hspecthread;
__gshared Mutex hstopmtx;
__gshared Mutex hbuffmtx;
__gshared Mutex hreadmtx;
__gshared Mutex hfftmtx;
__gshared Mutex hpltmtx;
__gshared Mutex hobsmtx;
__gshared HANDLE hlexeve;
/* sdr structs */
__gshared sdrini_t sdrini;
__gshared sdrstat_t sdrstat;
__gshared sdrch_t sdrch[MAXSAT];
__gshared sdrspec_t sdrspec;


/* main function ----------------------------------------------------------------
* main entry point in CLI application  
* args   : none
* return : none
* note : This function is only used in CLI application 
*------------------------------------------------------------------------------*/
void main(string[] args)
{
    sdrini.readIniFile(args.length > 1 ? args[1] : "gnss-sdrcli.ini");
    //enforce(readinifile(&sdrini) >= 0);
    startsdr();
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
    int stop;

    /* mutexes and events */
    openhandles();
    scope(exit) closehandles();

    SDRPRINTF("GNSS-SDRLIB start!\n");
    
    checkInitValue(sdrini);

    /* receiver initialization */
    enforce(rcvinit(&sdrini) >= 0);
    scope(exit) rcvquit(&sdrini);

    /* initialize sdr channel struct */
    size_t sdrch_IniEndIdx;
    scope(exit) {
        foreach(i; 0 .. sdrch_IniEndIdx)
            freesdrch(&sdrch[i]);
    }

    foreach(i; 0 .. sdrini.nch){
        enforce(initsdrch(i+1, sdrini.sys[i], sdrini.sat[i], sdrini.ctype[i], sdrini.dtype[sdrini.ftype[i]-1], sdrini.ftype[i], sdrini.f_sf[sdrini.ftype[i]-1], sdrini.f_if[sdrini.ftype[i]-1],&sdrch[i]) >= 0);
        sdrch_IniEndIdx = i + 1;
    }

    hsyncthread = spawn(&syncthread);
    hkeythread = spawn(&keythread);
    foreach(i; 0 .. sdrini.nch){
        if (sdrch[i].sys == SYS_GPS && sdrch[i].ctype == CTYPE_L1CA)
            sdrch[i].hsdr = spawn(&sdrthread, i);
        else
            assert(0);
    }

    /* start grabber */
    enforce(rcvgrabstart(&sdrini) >= 0);

    tracing = false;
    
    /* data grabber loop */
    while (1) {
        synchronized(hstopmtx)
            stop = sdrstat.stopflag;
        if (stop) break;

        /* grab data */
        enforce(rcvgrabdata(&sdrini) >= 0);
    }
    tracing = true;

    foreach(e; Thread.getAll)
        if(e.name.startsWith("sdrchannel"))
            e.join();

    SDRPRINTF("GNSS-SDRLIB is finished!\n");
}
/* sdr termination --------------------------------------------------------------
* sdr termination process  
* args   : sdrini_t *ini    I   sdr init struct
* args   : int    stop      I   stop position in function 0: run all
* return : none
*------------------------------------------------------------------------------*/
void quitsdr(sdrini_t *ini, int stop)
{
    if (stop == 1) return;

    /* sdr termination */
    rcvquit(ini);
    if (stop == 2) return;

    /* free memory */
    //for (i=0;i<ini.nch;i++) freesdrch(&sdrch[i]);
    foreach(i; 0 .. ini.nch)
        freesdrch(&sdrch[i]);

    if (stop == 3) return;

    /* mutexes and events */
    closehandles();
    if (stop == 4) return;
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
    Thread.getThis.name = "sdrchannel_" ~ index.to!string();
    //sdrch_t *sdr = cast(sdrch_t*)arg; 
    sdrplt_t pltacq,plttrk;
    ulong buffloc = 0,bufflocnow = 0,cnt = 0,loopcnt = 0;
    int stop = 0,cntsw = 0, swsync, swreset;
    double *acqpower = null;

    /* plot setting */
    if (initpltstruct(&pltacq,&plttrk,sdr)<0) {
        sdrstat.stopflag=ON;
        stop=ON;
    }
    SDRPRINTF("**** %s sdr thread start! ****\n",sdr.satstr);
    Sleep(100);
    
    /* check the exit flag */
    synchronized(hstopmtx)
        stop = sdrstat.stopflag;
    
    while (!stop) {
        /* acquisition */
        if (!sdr.flagacq) {
            /* memory allocation */
            if (acqpower!=null) free(acqpower);
            acqpower=cast(double*)calloc(double.sizeof,sdr.acq.nfft*sdr.acq.nfreq);
            
            /* fft correlation */
            buffloc=sdracquisition(sdr,acqpower, cnt);
            
            /* plot aquisition result */
            if (sdr.flagacq&&sdrini.pltacq) {
                pltacq.z=acqpower;
                plot(&pltacq); 
            }
        }
        /* tracking */
        if (sdr.flagacq) {
            traceln("start tracking");
            bufflocnow = sdrtracking(sdr, buffloc, cnt);
            traceln("end tracking");
            if (sdr.flagtrk) {
                if (sdr.nav.swnavsync) cntsw = 0;
                if ((cntsw%sdr.trk.loopms)==0) swsync = ON;
                else swsync = OFF;
                if (((cntsw-1)%sdr.trk.loopms) == 0) swreset = ON;
                else swreset = OFF;
                
                /* correlation output accumulation */
                cumsumcorr(sdr.trk.I,sdr.trk.Q,&sdr.trk,sdr.flagnavsync,swreset);
                
                if (!sdr.flagnavsync) {
                    pll(sdr,&sdr.trk.prm1); /* PLL */
                    dll(sdr,&sdr.trk.prm1); /* DLL */
                }
                else if (swsync) {
                    pll(sdr,&sdr.trk.prm2); /* PLL */
                    dll(sdr,&sdr.trk.prm2); /* DLL */

                    /* calculate observation data */
                    synchronized(hobsmtx){
                        if (loopcnt%(SNSMOOTHMS/sdr.trk.loopms)==0)
                            setobsdata(sdr, buffloc, cnt, &sdr.trk, 1); /* SN smoothing */
                        else
                            setobsdata(sdr, buffloc, cnt, &sdr.trk, 0);
                    }

                    /* plot correator output */
/+
                    if (loopcnt%(cast(int)(plttrk.pltms/sdr.trk.loopms))==0&&sdrini.plttrk&&loopcnt>200) {
                        plttrk.x=sdr.trk.prm2.corrx;
                        memcpy(plttrk.y,sdr.trk.sumI,double.sizeof*(sdr.trk.ncorrp*2+1));
                        plotthread(&plttrk);
                    }
+/
                    loopcnt++;
                }

                writefln("carrier phase:%s, bufflocnow:%s, buffloc:%s", sdr.trk.L[0], bufflocnow, buffloc);

                /* LEX thread */
                if ((cntsw%LEXMS)==0) {
                    if (sdrini.nchL6 != 0 && sdr.sys == SYS_QZS && loopcnt > 2)
                        SetEvent(hlexeve);
                }

                if (sdr.no==1&&cnt%(1000*10)==0) SDRPRINTF("process %d sec...\n",cast(int)cnt/(1000));
                cnt++;
                cntsw++;
                buffloc+=sdr.currnsamp;
            }
        }
        sdr.trk.buffloc = buffloc;

        /* check the exit flag */
        synchronized(hstopmtx)
            stop = sdrstat.stopflag;
    }
    /* plot termination */
    quitpltstruct(&pltacq,&plttrk);

    if (sdr.flagacq) 
        SDRPRINTF("SDR channel %s thread finished! Delay=%d [ms]\n",sdr.satstr,cast(int)(bufflocnow-buffloc)/sdr.nsamp);
    else
        SDRPRINTF("SDR channel %s thread finished!\n",sdr.satstr);
}
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
            //for (i=nsat=0;i<sdrini.nch;i++) {
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
        oldreftow=reftow;
        reftow=3600*24*7;

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
            //for (j=0;j<MAXOBS;j++) {
            foreach(j; 0 .. MAXOBS){
                if (trk[i].tow[j]==reftow)
                    ind[i]=j;
            }       
        }

        /* decide reference satellite (most distant satellite) */
        maxcodei=0;
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
        diffsamp=trk[refi].cntout[ind[refi]]-sdrch[isat[refi]].nav.firstsfcnt;
        sampref=sdrch[isat[refi]].nav.firstsf+cast(ulong)(sdrch[isat[refi]].nsamp*(-cast(int)(PTIMING)+diffsamp)); /* reference sample */
        sampbase=trk[refi].codei[OBSINTERPN-1]-10*sdrch[isat[refi]].nsamp;
        samprefd=cast(double)(sampref-sampbase);            
        
        /* computation observation data */
        foreach(i; 0 .. nsat){
            obs[i].sat=sdrch[isat[i]].sat;
            obs[i].week=sdrch[isat[i]].nav.eph.week;
            obs[i].tow=reftow+cast(double)(PTIMING)/1000; 
            obs[i].P=CLIGHT*sdrch[isat[i]].ti*(cast(double)(codei[i]-sampref)-remcode[i]); /* pseudo range */

            /* uint64 to double for interp1 */
            uint64todouble(trk[i].codei.ptr,sampbase,OBSINTERPN,codeid.ptr);
            obs[i].L = interp1(codeid.ptr,trk[i].L.ptr,OBSINTERPN,samprefd);
            obs[i].D = interp1(codeid.ptr,trk[i].D.ptr,OBSINTERPN,samprefd);
            obs[i].S = trk[i].S[0];
        }
        out_.nsat=nsat;
        sdrobs2obsd(obs.ptr, nsat, out_.obsd);

        /* rinex obs output */
        if (sdrini.rinex) {
            if (writerinexobs(out_.rinexobs,&out_.opt,out_.obsd,out_.nsat)<0) {
                sdrstat.stopflag=ON; stop=ON;
            }
        }

        /* rtcm obs output */
        if (sdrini.rtcm&&out_.soc.flag) 
            sendrtcmobs(out_.obsd,&out_.soc,out_.nsat);
                
        /* navigation data output */
        foreach(i;0 .. sdrini.nch){
            if ((sdrch[i].nav.eph.update)&&(sdrch[i].nav.eph.cnt==3)) {
                sdrch[i].nav.eph.cnt=0;
                sdrch[i].nav.eph.update=OFF;

                /* rtcm nav output */
                if (sdrini.rtcm&&out_.soc.flag) 
                    sendrtcmnav(&sdrch[i].nav.eph,&out_.soc);
                
                /* rinex nav output */
                if (sdrini.rinex) {
                    if (writerinexnav(out_.rinexnav,&out_.opt,&sdrch[i].nav.eph)<0) {
                        sdrstat.stopflag=ON; stop=ON;
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
