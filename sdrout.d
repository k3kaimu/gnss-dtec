/*-------------------------------------------------------------------------------
* sdrout.c : output observation data functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;

import core.thread;

import std.array,
       std.concurrency,
       std.conv,
       std.datetime,
       std.format,
       std.stdio,
       std.string;


/* set rinex option struct ------------------------------------------------------
* set value to rinex option struct (rtklib)
* args   : rnxopt_t *opt    I/O rinex option struct
* return : none
*------------------------------------------------------------------------------*/
void createrinexopt(string file = __FILE__, size_t line = __LINE__)(rnxopt_t* opt)
{
    traceln("called");

    /* rinex setting */
    opt.rnxver = 2.12;
    opt.navsys = SYS_GPS | SYS_QZS;

    /* signal type */
    /* now L1CA only */
    opt.nobs[0]=4;
    opt.tobs[0][0][] = "CA".toStringz[0 .. 3];
    opt.tobs[0][1][] = "LA".toStringz[0 .. 3];
    opt.tobs[0][2][] = "DA".toStringz[0 .. 3];
    opt.tobs[0][3][] = "SA".toStringz[0 .. 3];

    opt.exsats[0 .. MAXSAT] = 0;
}


/* convert sedobs to obsd struct ------------------------------------------------
* convert sdrobs struct to obsd struct(rtklib) for rinex/rtcm outputs
* args   : sdrobs_t *sdrobs I   rinex observation file name
*          int    ns        I   number of observed satellite
*          obsd_t *out_      O   obsd struct(rtklib)
* return : none
*------------------------------------------------------------------------------*/
void sdrobs2obsd(string file = __FILE__, size_t line = __LINE__)(sdrobs_t* sdrobs, int ns, obsd_t* out_)
{
    traceln("called");

    foreach(i; 0 .. ns) with(out_[i]){
        time = gpst2time(sdrobs.week,sdrobs.tow);
        rcv = 1;
        sat = sdrobs[i].sat.to!ubyte();
        time = gpst2time(sdrobs[i].week,sdrobs[i].tow);
        P[0] = sdrobs[i].P;
        L[0] = sdrobs[i].L;
        D[0] = sdrobs[i].D.to!float();
        SNR[0] = (sdrobs[i].S * 4 + 0.5).to!ubyte();
                    
        /* signal type */
        code[0] = 1;  /* L1C/A,E1C  (GPS,GLO,GAL,QZS,SBS) */
        code[1] = 20; /* L2 Z-track (GPS) */
        code[2] = 26; /* L5/E5aI+Q  (GPS,GAL,QZS,SBS) */
    }
}


/* create rinex observation data file -------------------------------------------
* create rinex observation data file
* args   : char   *file     I   rinex observation file name
*          rnxopt_t *opt    I   rinex option struct
* return : int                  status 0:okay -1:can't create file 
*------------------------------------------------------------------------------*/
int createrinexobs(string file = __FILE__, size_t line = __LINE__)(out string filename, rnxopt_t* opt)
{
    traceln("called");
    nav_t nav;

    // UTC time
    auto utc = Clock.currTime.toUTC;
    with(Clock.currTime.toUTC)
        filename = "%s/sdr_%04d%02d%02d%02d%02d%02d.obs".format(sdrini.rinexpath, year, month, day, hour, minute, second);


    /* write rinex header */
    auto file = File(filename, "w");
    outrnxobsh(file.getFP,opt,&nav);
    return 0;
}


/* write rinex observation data -------------------------------------------------
* write observation data to file in rinex format
* args   : char   *file     I   rinex observation file name
*          rnxopt_t *opt    I   rinex option struct
*          obsd_t *obsd     I   observation data struct
*          int    ns        I   number of observed satellite
* return : int                  status 0:okay -1:can't write file 
*------------------------------------------------------------------------------*/
int writerinexobs(string file = __FILE__, size_t line = __LINE__)(string filename, rnxopt_t* opt, obsd_t* obsd, int ns)
{
    traceln("called");
    File file = File(filename, "a");
    outrnxobsb(file.getFP,opt,obsd,ns,0);

    return 0;
}
/* create rinex navigation data file --------------------------------------------
* create rinex navigation data file
* args   : char   *file     I   rinex navigation file name
*          rnxopt_t *opt    I   rinex option struct
* return : int                  status 0:okay -1:can't create file 
*------------------------------------------------------------------------------*/
int createrinexnav(string file = __FILE__, size_t line = __LINE__)(out string filename, rnxopt_t* opt)
{
    traceln("called");
    nav_t nav;

    // UTC time
    with(Clock.currTime.toUTC)
        filename = "%s/sdr_%04d%02d%02d%02d%02d%02d.nav".format(sdrini.rinexpath, year, month, day, hour, minute, second);

    auto file = File(filename, "w");
    outrnxnavh(file.getFP, opt, &nav);

    return 0;
}
/* write rinex navigation data --------------------------------------------------
* write navigation data to file in rinex format
* args   : char   *file     I   rinex navigation file name
*          rnxopt_t *opt    I   rinex option struct
*          eph_t  *eph      I   ephemeris data struct
* return : int                  status 0:okay -1:can't write file 
*------------------------------------------------------------------------------*/
int writerinexnav(string file = __FILE__, size_t line = __LINE__)(string filename, rnxopt_t* opt, eph_t* eph)
{
    traceln("called");
    File file = File(filename, "a");
    
    outrnxnavb(file.getFP,opt,eph);
    writefln("sat=%d rinex output navigation data", eph.sat);
    return 0;
}


version(none):

/* tcp/ip server theread --------------------------------------------------------
* create tcp/ip server thread
* args   : void   *arg      I   sdr socket struct
* return : none
*------------------------------------------------------------------------------*/
void tcpsvrthread(/*void* arg*/) 
{/+
    sdrsoc_t *soc=cast(sdrsoc_t*)arg;
    sockaddr_in srcAddr,dstAddr;
    int dstAddrSize= dstAddr.sizeof;
    WSADATA data;
    BOOL yes=1;

    if (WSAStartup(MAKEWORD(2,0),&data)!=0) {
        SDRPRINTF("error: tcp/ip WSAStartup() failed\n");
        return;
    }

    /* create socket */
    if ((soc.s_soc=socket(AF_INET,SOCK_STREAM,0))==INVALID_SOCKET) {
        SDRPRINTF("error: tcp/ip socket failed with %ld\n",WSAGetLastError());
        WSACleanup();
        return;
    }
    /* reuse port */
    setsockopt(soc.s_soc,SOL_SOCKET,SO_REUSEADDR,cast(char*)&yes,yes.sizeof);

    /* sockaddr_in struct */
    srcAddr.sin_port=htons(soc.port);
    srcAddr.sin_family=AF_INET;
    srcAddr.sin_addr.s_addr=htonl(INADDR_ANY);

    /* bind to the local address */
    if ((bind(soc.s_soc,cast(sockaddr*)&srcAddr,srcAddr.sizeof))==SOCKET_ERROR) {
        SDRPRINTF("error: tcp/ip bind failed with %d soc=%d\n",WSAGetLastError(),cast(int)soc.s_soc);
        WSACleanup();
        return;
    }

    /* listen */
    if ((listen(soc.s_soc,SOMAXCONN))==SOCKET_ERROR) {
        SDRPRINTF("error: tcp/ip listen failed with %d\n",WSAGetLastError());
        WSACleanup();
        return;
    }
    SDRPRINTF("Waiting for connection ...\n");
    while (1) {
        /* accept */
        if ((soc.c_soc=accept(soc.s_soc,cast(sockaddr*)&dstAddr,&dstAddrSize))==INVALID_SOCKET) {
            return;
        }
        SDRPRINTF("Connected from %s!\n", inet_ntoa(dstAddr.sin_addr));
        soc.flag=ON;
    }+/
}
/* start tcp server -------------------------------------------------------------
* create tcp/ip server thread
* args   : sdrsoc_t *soc    I   sdr socket struct
* return : none
*------------------------------------------------------------------------------*/
void tcpsvrstart(string file = __FILE__, size_t line = __LINE__)(sdrsoc_t *soc)
{
    traceln("called");
    //soc.hsoc = new Thread(() => tcpsvrthread(soc));
    //soc.hsoc.start();
    soc.hsoc = spawn(&tcpsvrthread);
}
/* stop tcp server --------------------------------------------------------------
* close tcp/ip sockets
* args   : sdrsoc_t *soc    I   sdr socket struct
* return : none
*------------------------------------------------------------------------------*/
void tcpsvrclose(string file = __FILE__, size_t line = __LINE__)(sdrsoc_t *soc)
{
    traceln("called");
    if (soc.s_soc!=0) {
        closesocket(soc.s_soc);
        //WaitForSingleObject(soc.hsoc,INFINITE);
        //soc.hsoc.join();
        //pragma(msg, "soc.hsoc.join()");

        ctTrace();
        pragma(msg, "    soc.hsoc.join()");
    }
    if (soc.c_soc!=0) closesocket(soc.c_soc);
    if (soc.flag==ON) WSACleanup();
}
/* send navigation data via tcp/ip ----------------------------------------------
* generate rtcm msm message and send via tcp/ip
* args   : eph_t  *eph      I   ephemeris data struct
*          sdrsoc_t *soc    I   sdr socket struct
* return : none
*------------------------------------------------------------------------------*/
void sendrtcmnav(string file = __FILE__, size_t line = __LINE__)(eph_t *eph, sdrsoc_t *soc)
{
    traceln("called");
    rtcm_t rtcm={0};
    init_rtcm(&rtcm);
    
    /* navigation */
    rtcm.ephsat=eph.sat;
    rtcm.nav.eph[rtcm.ephsat-1]=*eph;
    switch(satsys(eph.sat,null)) {
      case SYS_GPS:
        gen_rtcm3(&rtcm,1019,0);
        break;
      default:
        enforce(0);
        break;
    }
    /* tcp send */
    if (send(soc.c_soc,cast(char*)rtcm.buff,rtcm.nbyte,0)==SOCKET_ERROR) {
        soc.flag=OFF;
    } else {
        SDRPRINTF("sat=%d rtcm output navigation data\n",eph.sat);
    }
}
/* send observation data via tcp/ip ---------------------------------------------
* generate rtcm msm message and send via tcp/ip
* args   : obsd_t *obsd     I   observation data struct
*          sdrsoc_t *soc    I   sdr socket struct
*          int    n         I   number of observed satellite
* return : none
*------------------------------------------------------------------------------*/
void sendrtcmobs(string file = __FILE__, size_t line = __LINE__)(obsd_t *obsd, sdrsoc_t *soc, int nsat)
{
    traceln("called");
    rtcm_t rtcm={0};
    init_rtcm(&rtcm);

    /* observation */
    rtcm.time=obsd[0].time;
    rtcm.obs.n=nsat;
    rtcm.obs.data=obsd;

    /* GPS observations */
    gen_rtcm3(&rtcm,1077,0);
    if (send(soc.c_soc,cast(char*)rtcm.buff,rtcm.nbyte,0)==SOCKET_ERROR) {
        soc.flag=OFF;
    }
}
