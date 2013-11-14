/*-------------------------------------------------------------------------------
* sdrout.c : data output functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/

import sdr;

import std.exception : enforce;
import std.math : abs;

/* sdr navigation data function --------------------------------------------------------
* decide navigation bit and decode navigation data
* args   : sdrch_t *sdr      I/O sdr channel struct
*          ulong buffloc  I   buffer location
*          ulong cnt      I   counter of sdr channel thread
* return : none
*------------------------------------------------------------------------------*/
void sdrnavigation(string file = __FILE__, size_t line = __LINE__)(sdrch_t *sdr, ulong buffloc, ulong cnt)
{
    traceln("called");
    scope(exit) traceln("return");
    
    traceln();

    /* navigation data */
    //if(sdr.ctype != CType.L2RCCM)
    immutable biti = cast(int)(cnt % sdr.nav.rate); /* bit location */

    traceln();

    /* navigation bit synclonaization */
    if (/*sdr.ctype != CType.L2RCCM && */!sdr.flagnavsync && cnt > 500){
        traceln();
        sdr.flagnavsync = nav_checksync(biti, sdr.trk.I[0], sdr.trk.oldI[0], &sdr.nav);
        traceln();
    }

    //if(sdr.ctype == CType.L2RCCM && cnt > 500)
    //    sdr.flagnavsync = true;

    traceln();

  //version(NavigationDecode){
    //if(sdr.ctype != CType.L2RCCM || true){
        /* preamble synclonaization */
        if (sdr.flagnavsync) {
            /+
            if (nav_checkbit(biti,sdr.trk.I[0],&sdr.nav)==false) { /* nav bit determination */
                SDRPRINTF("%s nav sync error!!\n",sdr.satstr);
            }
            +/
            /+
            if (sdr.nav.swnavsync) {
                /* decode FEC */
                nav_decodefec(&sdr.nav);

                /* finding preamble */      
                sdr.flagnavpre=nav_findpreamble(&sdr.nav);
                /* preamble is found */
                if (sdr.flagnavpre&&!sdr.flagfirstsf) {
                    /* set reference sample data */
                    sdr.nav.firstsf=buffloc;
                    sdr.nav.firstsfcnt=cnt;
                    SDRPRINTF("*** find preamble! %s %d %d ***\n",sdr.satstr,cast(int)cnt,sdr.nav.polarity);
                    sdr.flagfirstsf=true;
                }
            }
            /* decoding navigation data */
            if (sdr.flagnavpre&&sdr.nav.swnavsync) {
                if (cast(int)(cnt-sdr.nav.firstsfcnt)%(sdr.nav.flen*sdr.nav.rate)==0) {
                    immutable sfn = nav_decodenav(&sdr.nav);
                    sdr.nav.eph.sat=sdr.sat;
                    sdr.flagnavdec=true;
                    SDRPRINTF("%s sfn=%d tow:%.1f week=%d\n",sdr.satstr,sfn,sdr.nav.eph.tow,sdr.nav.eph.week);

                    /* set reference tow data */
                    if (cnt-sdr.nav.firstsfcnt==0) sdr.nav.firstsftow=sdr.nav.eph.tow;
                }
            }
            +/
        }
    //}
  //}
}


/* convert binary navigation bits to byte data ----------------------------------
* 
* args   : int    *bits     I   binary navigation bits (1 or -1)
*          int    nbits     I   number of navigation bits
*          int    nbin      I   number of byte data
*          ubyte *bin O byte data
* return : none
*------------------------------------------------------------------------------*/
void bits2bin(string file = __FILE__, size_t line = __LINE__)(int *bits, int nbits, int nbin, ubyte *bin)
{
    traceln("called");
    int i,j;
    ubyte b;
    for (i=0;i<nbin;i++) {
        b=0;
        for (j=0;j<8;j++) {
            if ((i*8+j)>=nbits) continue;
            b<<=1;
            if (bits[i*8+j]<0) b|=0x01;
        }
        bin[i]=b;
    }
}


/* decode navigation data subframe 1 --------------------------------------------
*
* args   : ubyte *buff I navigation data frame
*          sdreph_t *eph    I/O ephemeris message
* return : int                  subframe id
*------------------------------------------------------------------------------*/
static int decode_subfrm1(string file = __FILE__, size_t line = __LINE__)(ubyte *buff, eph_t *eph)
{
    traceln("called");
    double toc;
    int i=60,week,iodc0,iodc1;
    int oldiodc=eph.iodc;

    eph.tow   =getbitu(buff,30,17)*6.0;        /* transmission time of subframe */
    week       =getbitu(buff,i,10)+1024;  i+=10;
    eph.code  =getbitu(buff,i, 2);       i+= 2;
    eph.sva   =getbitu(buff,i, 4);       i+= 4;   /* ura index */
    eph.svh   =getbitu(buff,i, 6);       i+= 6;
    iodc0      =getbitu(buff,i, 2);       i+= 8;
    eph.flag  =getbitu(buff,i, 1);       i+=106;
    eph.tgd[0]=getbits(buff,i, 8) * (2.0L ^^ -31); i+=14;
    iodc1      =getbitu(buff,i, 8);       i+= 8;
    toc        =getbitu(buff,i,16) * 16.0;  i+=22;
    eph.f2    =getbits(buff,i, 8) * (2.0L ^^ -55); i+= 8;
    eph.f1    =getbits(buff,i,16) * (2.0L ^^ -43); i+=22;
    eph.f0    =getbits(buff,i,22) * (2.0L ^^ -31);
    
    eph.iodc=(iodc0<<8)+iodc1;
    eph.week=adjgpsweek(week);
    eph.ttr=gpst2time(eph.week,eph.tow);
    eph.toc=gpst2time(eph.week,toc);
    
    /* ephemeris update flag */
    if (oldiodc-eph.iodc!=0)
        eph.update=true;

    /* subframe counter */
    if (eph.cnt==3) eph.cnt=0; /* reset */
    eph.cnt++;
    
    return 1;
}


/* decode navigation data subframe 2 --------------------------------------------
*
* args   : ubyte *buff I navigation data frame
*          sdreph_t *eph    I/O ephemeris message
* return : int                  subframe id
*------------------------------------------------------------------------------*/
int decode_subfrm2(string file = __FILE__, size_t line = __LINE__)(ubyte *buff, eph_t *eph)
{
    traceln("called");
    double sqrtA;
    int i=60;
    int oldiode=eph.iode;
    int M00,M01,e0,e1,sqrtA0,sqrtA1;

    eph.tow =getbitu(buff,30,17)*6.0; /* transmission time of subframe */
    eph.iode=getbitu(buff,i, 8);              i+= 8;
    eph.crs =getbits(buff,i,16)*(2.0L^^-5);         i+=22;
    eph.deln=getbits(buff,i,16)*(2.0L^^-43)*SC2RAD; i+=16;
    M00      =getbitu(buff,i,8);               i+=14;
    M01      =getbitu(buff,i,24);              i+=30;
    eph.cuc =getbits(buff,i,16)*(2.0L^^-29);        i+=16;
    e0       =getbitu(buff,i,8);               i+=14;
    e1       =getbitu(buff,i,24);              i+=30;
    eph.cus =getbits(buff,i,16)*(2.0L^^-29);        i+=16;
    sqrtA0   =getbitu(buff,i,8);               i+=14;
    sqrtA1   =getbitu(buff,i,24);              i+=30;
    eph.toes=getbitu(buff,i,16)*16.0;         i+=16;
    eph.fit =getbitu(buff,i, 1);
    
    eph.M0=(cast(int)(M00<<24)+M01)*(2.0L^^-31)*SC2RAD;
    eph.e=((e0<<24)+e1)*(2.0L^^-33);
    sqrtA=(cast(uint)(sqrtA0<<24)+sqrtA1)*(2.0L^^-19);
    eph.A=sqrtA*sqrtA;
    
    /* ephemeris update flag */
    if (oldiode-eph.iode!=0)
        eph.update=true;
    
    /* subframe counter */
    if (eph.cnt==3) eph.cnt=0; /* reset */
    eph.cnt++;
    
    return 2;
}


/* decode navigation data subframe 3 --------------------------------------------
*
* args   : ubyte *buff I navigation data frame
*          sdreph_t *eph    I/O ephemeris message
* return : int                  subframe id
*------------------------------------------------------------------------------*/
int decode_subfrm3(string file = __FILE__, size_t line = __LINE__)(ubyte *buff, eph_t *eph)
{
    traceln("called");
    int i=60,iode;
    int oldiode=eph.iode;
    int OMG00,OMG01,i00,i01,omg0,omg1;

    eph.tow =getbitu(buff,30,17)*6.0; /* transmission time of subframe */
    eph.cic =getbits(buff,i,16)*(2.0L^^-29);        i+=16;
    OMG00    =getbitu(buff,i,8);               i+=14;
    OMG01    =getbitu(buff,i,24);              i+=30;
    eph.cis =getbits(buff,i,16)*(2.0L^^-29);        i+=16;
    i00      =getbitu(buff,i,8);               i+=14;
    i01      =getbitu(buff,i,24);              i+=30;
    eph.crc =getbits(buff,i,16)*(2.0L^^-5);         i+=16;
    omg0     =getbitu(buff,i,8);               i+=14;
    omg1     =getbitu(buff,i,24);              i+=30;
    eph.OMGd=getbits(buff,i,24)*(2.0L^^-43)*SC2RAD; i+=30;
    iode     =getbitu(buff,i, 8);              i+= 8;
    eph.idot=getbits(buff,i,14)*(2.0L^^-43)*SC2RAD;
    
    eph.OMG0=(cast(int)(OMG00<<24)+OMG01)*(2.0L^^-31)*SC2RAD;
    eph.i0=(cast(int)(i00<<24)+i01)*(2.0L^^-31)*SC2RAD;
    eph.omg =(cast(int)(omg0<<24)+omg1)*(2.0L^^-31)*SC2RAD;

    /* ephemeris update flag */
    if (oldiode-iode!=0)
        eph.update=true;
   
    /* subframe counter */
    if (eph.cnt==3) eph.cnt=0; /* reset */
    eph.cnt++;
    
    return 3;
}


/* decode navigation data subframe 4 --------------------------------------------
*
* args   : ubyte *buff I navigation data frame
*          sdreph_t *eph    I/O ephemeris message
* return : int                  subframe id
*------------------------------------------------------------------------------*/
int decode_subfrm4(string file = __FILE__, size_t line = __LINE__)(ubyte *buff, eph_t *eph)
{
    traceln("called");
    eph.tow =getbitu(buff,30,17)*6.0; /* transmission time of subframe */
    
    return 4;
}


/* decode navigation data subframe 5 --------------------------------------------
*
* args   : ubyte *buff I navigation data frame
*          sdreph_t *eph    I/O ephemeris message
* return : int                  subframe id
*------------------------------------------------------------------------------*/
int decode_subfrm5(string file = __FILE__, size_t line = __LINE__)(ubyte *buff, eph_t *eph)
{
    traceln("called");
    eph.tow =getbitu(buff,30,17)*6.0; /* transmission time of subframe */
    
    return 5;
}


/* decode navigation data frame -------------------------------------------------
* decode navigation data frame and extract ephemeris
* args   : ubyte *buff I navigation data frame
*          sdreph_t *eph    I/O ephemeris message
* return : int                  status (0:no valid, 1-5:subframe id)
*------------------------------------------------------------------------------*/
int nav_decode_frame(string file = __FILE__, size_t line = __LINE__)(ubyte *buff, eph_t *eph)
{
    traceln("called");
    int id=getbitu(buff,49,3); /* subframe ID */
    
    switch (id) {
        case 1: return decode_subfrm1(buff,eph);
        case 2: return decode_subfrm2(buff,eph);
        case 3: return decode_subfrm3(buff,eph);
        case 4: return decode_subfrm4(buff,eph);
        case 5: return decode_subfrm5(buff,eph);
        default:
            enforce(0);
    }
    return id;
}


/* navigation data bit synchronization ------------------------------------------
* checking synchronization of navigation bit   
* args   : int    biti      I   current bit index
*          double IP        I   correlation output (IP data)
*          double oldIP     I   previous correlation output
*          sdrnav_t *nav    I/O navigation struct
* return : int                  1:synchronization 0: not synchronization
*------------------------------------------------------------------------------*/
bool nav_checksync(string file = __FILE__, size_t line = __LINE__)(int biti, double IP, double IPold, sdrnav_t *nav)
{
    traceln("called");
    int maxi;
    if (IPold*IP<0) {
        nav.bitsync[biti]+=1;
        maxi=maxvi(nav.bitsync,nav.rate,-1,-1,&nav.bitind);
        if (maxi>nav.bitth) {
            nav.bitind--; /* minus 1 index */
            if (nav.bitind<0) nav.bitind=nav.rate-1;
            return true;
        }
    }
    return false;
}


/* navigation data bit decision -------------------------------------------------
* navigation data bit is determined using accumulated IP data
* args   : int    biti      I   current bit index
*          double IP        I   correlation output (IP data)
*          sdrnav_t *nav    I/O navigation struct
* return : int                  synchronization status 1:sync 0: not sync
*------------------------------------------------------------------------------*/
int nav_checkbit(string file = __FILE__, size_t line = __LINE__)(int biti, double IP, sdrnav_t *nav)
{
    traceln("called");
    int diffi=biti-nav.bitind;
    int syncflag=true;
    nav.swnavreset=false;
    nav.swnavsync=false;
    if (diffi==1||diffi==-nav.rate+1) {
        nav.bitIP=IP; /* reset */
        nav.swnavreset=true;
    } else {
        nav.bitIP+=IP; /* cumsum */
        if (nav.bitIP*IP<0) syncflag=false;
    }

    /* sync */
    if (diffi==0) {
        if (nav.bitIP<0) nav.bit=-1;
        else nav.bit=1;

        /* set bit*/
        memcpy(&nav.fbits[0],&nav.fbits[1],int.sizeof*(nav.flen+nav.addflen-1)); /* shift to left */
        nav.fbits[nav.flen+nav.addflen-1]=nav.bit; /* add last */
        nav.swnavsync=true;
    }
    return syncflag;
}


/* decode foward error correction -----------------------------------------------
* args   : sdrnav_t *nav    I/O navigation struct
* return : none
*------------------------------------------------------------------------------*/
void nav_decodefec(string file = __FILE__, size_t line = __LINE__)(sdrnav_t *nav)
{
    traceln("called");
    int i,j;
    ubyte enc[Constant.L1SAIF.Navigation.FLEN + Constant.L1SAIF.Navigation.ADDFLEN];
    ubyte dec[32];
    int dec2[Constant.L1SAIF.Navigation.FLEN/2];

    /* L1CA */
    if (nav.ctype==CType.L1CA) {
        /* FEC is not used */
        memcpy(nav.fbitsdec,nav.fbits,int.sizeof*(nav.flen+nav.addflen));
    }
    /* L1SAIF */
    /* !!!! this doesn't work well :-( */
    if (nav.ctype==CType.L1SAIF) {
        /* 1/2 convolutional code */
        init_viterbi27_port(nav.fec,0);
        for (i=0;i<enc.length;i++) enc[i]=(nav.fbits[i]==1)? 0:255;
        update_viterbi27_blk_port(nav.fec,enc.ptr,(nav.flen+nav.addflen)/2);
        chainback_viterbi27_port(nav.fec,dec.ptr,nav.flen/2,0);
        for (i=0;i<32;i++) {
            for (j=0;j<8;j++) {
                dec2[8*i+j]=((dec[i]<<j)&0x80)>>7;
                nav.fbitsdec[8*i+j]=(dec2[8*i+j]==0)?1:-1;
                if (8*i+j==Constant.L1SAIF.Navigation.FLEN/2-1) {
                    break;
                }
            }
        }
    }
}
/* parity check -----------------------------------------------------------------
* parity checking function
* args   : int    *bits     I   navigation bits (2+30 bits)
* return : int                  1:okay 0: wrong parity
*------------------------------------------------------------------------------*/
int paritycheck(string file = __FILE__, size_t line = __LINE__)(int *bits)
{
    traceln("called");
    int i,stat=0;
    int pbits[6];

    /* calculate parity bits*/
    pbits[0]=bits[0]*bits[2]*bits[3]*bits[4]*bits[6]*bits[7 ]*bits[11]*bits[12]*bits[13]*bits[14]*bits[15]*bits[18]*bits[19]*bits[21]*bits[24];
    pbits[1]=bits[1]*bits[3]*bits[4]*bits[5]*bits[7]*bits[8 ]*bits[12]*bits[13]*bits[14]*bits[15]*bits[16]*bits[19]*bits[20]*bits[22]*bits[25];
    pbits[2]=bits[0]*bits[2]*bits[4]*bits[5]*bits[6]*bits[8 ]*bits[9 ]*bits[13]*bits[14]*bits[15]*bits[16]*bits[17]*bits[20]*bits[21]*bits[23];
    pbits[3]=bits[1]*bits[3]*bits[5]*bits[6]*bits[7]*bits[9 ]*bits[10]*bits[14]*bits[15]*bits[16]*bits[17]*bits[18]*bits[21]*bits[22]*bits[24];
    pbits[4]=bits[1]*bits[2]*bits[4]*bits[6]*bits[7]*bits[8 ]*bits[10]*bits[11]*bits[15]*bits[16]*bits[17]*bits[18]*bits[19]*bits[22]*bits[23]*bits[25];
    pbits[5]=bits[0]*bits[4]*bits[6]*bits[7]*bits[9]*bits[10]*bits[11]*bits[12]*bits[14]*bits[16]*bits[20]*bits[23]*bits[24]*bits[25];

    for (i=0;i<6;i++) stat+=(pbits[i]-bits[26+i]);
    if (stat==0) return 1; /* parity is matched */

    return 0;
}
/* parity check -----------------------------------------------------------------
* parity checking navigation frame data (10 words)
* args   : sdrnav_t *nav    I/O navigation struct
* return : int                  1:okay 0: wrong parity
*------------------------------------------------------------------------------*/
int nav_paritycheck(string file = __FILE__, size_t line = __LINE__)(sdrnav_t *nav)
{
    traceln("called");
    int i,j,stat=0,crc;
    int *bits;
    ubyte bin[29];
    ubyte pbin[3];

    /* copy */
    bits=cast(int*)malloc(int.sizeof*(nav.flen+nav.addplen)).enforce();
    scope(failure) free(bits);

    memcpy(bits,nav.fbitsdec,int.sizeof*(nav.flen+nav.addplen));

    /* L1CA parity check */
    if (nav.ctype==CType.L1CA) {
        /* chacking all words */
        for (i=0;i<10;i++) {
            /* bit inversion */
            if (bits[i*30+1]==-1) {
                for (j=2;j<26;j++) 
                    bits[i*30+j]*=-1;
            }
            stat+=paritycheck(&bits[i*30]);
        }
        /* all parities are correct */
        if (stat==10) {
            free(bits);
            return 1;
        }
    }
    
    /* L1-SBAS/SAIF parity check */
    /* !!!! this doesn't work well :-( */
    if (nav.ctype==CType.L1SAIF||CType.L1SBAS) {
        bits2bin(&bits[0],226,29,bin.ptr);
        bits2bin(&bits[226],24,3,pbin.ptr);
    
        /* compute CRC24 */
        crc=crc24q(bin.ptr,29);

        if (crc==getbitu(pbin.ptr,0,24)) {
            free(bits);
            return 1;
        }
    }
    free(bits);
    return 0;
}
/* find preamble bits ----------------------------------------------------------
* search preamble bits from navigation data bits
* args   : sdrnav_t *nav    I/O navigation struct
* return : int                  1:found 0: not found
*------------------------------------------------------------------------------*/
int nav_findpreamble(string file = __FILE__, size_t line = __LINE__)(sdrnav_t *nav)
{
    traceln("called");
    int i,corr=0;

    /* corrleation */
    for (i=0;i<nav.prelen;i++)
        corr+=(nav.fbitsdec[nav.addplen+i]*nav.prebits[i]);

    if (abs(corr)==nav.prelen) { /* preamble matched */
        nav.polarity=corr>0?1:-1; /* set bit polarity */
        /* parity check */
        if(nav_paritycheck(nav)){
            return 1;
        }
    }

    return 0;
}
/* decode navigation data -------------------------------------------------------
* decode GPS navigation frame
* args   : sdrnav_t *nav    I/O navigation struct
* return : int                  decoded subframe number (1-5)
*------------------------------------------------------------------------------*/
int nav_decodenav(string file = __FILE__, size_t line = __LINE__)(sdrnav_t *nav)
{
    traceln("called");
    int i,j,nbin,sfn=0;
    ubyte *bin;
    
    /* decoding L1CA navigation data */
    if (nav.ctype==CType.L1CA) {
        /* bit inversion */
        for (i=0;i<10;i++) {
            if (nav.fbitsdec[i*30+1]==-1) {
                for (j=2;j<26;j++) 
                    nav.fbitsdec[i*30+j]*=-1;
            }
        }

        nbin=nav.flen/8+1; /* binary length */
        bin = cast(ubyte*)malloc(ubyte.sizeof*nbin);
        bits2bin(&nav.fbitsdec[nav.addflen],nav.flen,nbin,bin);
        
        /* decode nav data */
        sfn=nav_decode_frame(bin,&nav.eph);
        if (sfn<1||sfn>5)
            SDRPRINTF("error: nav subframe number sfn=%d\n",sfn);

        free(bin);
    }
    
    /* decoding L1-SBAS/SAIF navigation data */
    if (nav.ctype==CType.L1SAIF||CType.L1SBAS) {

    }   
    return sfn;
}
