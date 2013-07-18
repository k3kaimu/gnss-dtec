/*------------------------------------------------------------------------------
* stereo.h : NSL stereo functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
* Copyright (C) 2013 Nottingham Scientific Limited
*-----------------------------------------------------------------------------*/

import sdr;
import std.c.stdio,
       std.c.string;

import std.conv : to;
import std.exception : enforce;

/* constants -----------------------------------------------------------------*/
/* sterei confugration file path */
immutable DEF_FW_FILENAME       = "../../src/rcv/stereo/conf/stereo_fx2fw.ihx";
immutable DEF_FPGA_FILENAME     = "../../src/rcv/stereo/conf/stereo_fpga0125_intClk.bin";
immutable DEF_SYNTH_FILENAME    = "../../src/rcv/stereo/conf/stereo_clksynth.cfg";
immutable DEF_ADC_FILENAME      = "../../src/rcv/stereo/conf/stereo_adc.cfg";
immutable DEF_MAX2769_FILENAME  = "../../src/rcv/stereo/conf/max2769.cfg";
immutable DEF_MAX2112_FILENAME  = "../../src/rcv/stereo/conf/max2112_e6.cfg";
immutable MAX_FILENAME_LEN = 256;

/* global variables -----------------------------------------------------------*/
__gshared char[MAX_FILENAME_LEN] fx2lpFileName;
__gshared char[MAX_FILENAME_LEN] fpgaFileName;
__gshared char[MAX_FILENAME_LEN] max2769FileName;
__gshared char[MAX_FILENAME_LEN] max2112FileName;
__gshared char[MAX_FILENAME_LEN] synthFileName;
__gshared char[MAX_FILENAME_LEN] adcFileName;
__gshared char[MAX_FILENAME_LEN] dataFileName;

/* type definition -----------------------------------------------------------*/
/* max2769 struct */
struct max2769Conf_t {
    uint confOne;
    uint confTwo;
    uint confThree;
    uint pllConf;
    uint nrDiv;
    uint fDiv;
    uint strm;
    uint clk;
    uint testOne;
    uint testTwo;
}

/* max2112 struct */
struct max2112Conf_t {
    ubyte[14] regValue;
}

/* synchronization struct */
struct synthConf_t {
    uint[8] r;
    uint r8, r9, r11, r13, r14, r15;
}

/* adc struct */
struct adcConf_t {
    ubyte[10] uiReg;
}




/* stereo initialization --------------------------------------------------------
* search front end and initialization
* args   : none
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int stereo_init() 
{
    int ret;
    
    /* initiarize option strings */
    stereo_initoptions();
    
    ret=STEREO_InitLibrary();
    if (ret!=0) {
        SDRPRINTF("error: initialising Stereo driver\n"); return -1;
    }

    if (!STEREO_IsConnected()) {
        SDRPRINTF("error: STEREO does not appear to be connected\n"); return -1;
    }
    return 0;
}
/* stop front-end ---------------------------------------------------------------
* stop grabber of front end
* args   : none
* return : none
*------------------------------------------------------------------------------*/
void stereo_quit() 
{
    STEREO_GrabStop(); /* stop and clean the grabber */
    STEREO_GrabClean();
    STEREO_QuitLibrary();
}
/* stereo initialization of file oprions ----------------------------------------
* stereo initialization of file oprions
* args   : none
* return : none
*------------------------------------------------------------------------------*/
void stereo_initoptions() 
{
    strcpy(fx2lpFileName.ptr,DEF_FW_FILENAME.ptr);
    strcpy(fpgaFileName.ptr,DEF_FPGA_FILENAME.ptr);
    strcpy(max2769FileName.ptr,DEF_MAX2769_FILENAME.ptr);
    strcpy(max2112FileName.ptr,DEF_MAX2112_FILENAME.ptr);
    strcpy(synthFileName.ptr,DEF_SYNTH_FILENAME.ptr);
    strcpy(adcFileName.ptr,DEF_ADC_FILENAME.ptr);
}
/* stereo configuration function ------------------------------------------------
* load configuration file and setting
* args   : none
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int stereo_initconf() 
{
    int ret=0, length;
    FILE* fwFileId, fpgaFileId, synthFileId, max2769FileId, max2112FileId, adcFileId;
    max2769Conf_t max2769res;
    max2112Conf_t max2112res;
    synthConf_t synthConfResult;
    adcConf_t adcConfResult;
    ubyte* binaryStream;

    SDRPRINTF("STEREO configuration start...\n");

    /* FIRMWARE UPLOAD SECTION */
    if (!STEREO_IsConfigured()) {
        fwFileId=fopen(fx2lpFileName.ptr,"rt".ptr);
        if (null==fwFileId) {
            SDRPRINTF("error: Firmware file not present in folder: %s\n",fx2lpFileName); return -1;
        }
        ret=STEREO_LoadFirmware(fwFileId);
        if (ret<0) {
            SDRPRINTF("error: %s\n",STEREO_Perror().to!string());
        }
        if (null!=fwFileId) {
            fclose(fwFileId);
        }
        Sleep(1000);
    }

    /* FPGA CONFIGURATION SECTION */
    fpgaFileId=fopen(fpgaFileName.ptr,"rb".ptr);
    if (null==fpgaFileId) {
        SDRPRINTF("error: Could not open FPGA configuration file: %s\n",fpgaFileName); return -1;
    }
    binaryStream=cast(ubyte*)malloc(1<<20).enforce();
    scope(failure) free(binaryStream);

    length=cast(int)fread(binaryStream,1,1<<20,fpgaFileId);
    if (length>0) {
        ret=STEREO_SendFpga(binaryStream,length);
        if (ret<0) {
            SDRPRINTF("error: programming FPGA\n");
        }
    }
    free(binaryStream);
    if (ret<0) {
        SDRPRINTF("error: %s\n",STEREO_Perror().to!string());
    }
    if(null!=fpgaFileId) {
        fclose(fpgaFileId);
    }
    /* LMK03033C CONFIGURATION SECTION */
    synthFileId=fopen(synthFileName.ptr,"rt".ptr);
    if (null==synthFileId) {
        SDRPRINTF("error: Could not open synthesizer configuration file: %s\n",synthFileName); return -1;
    }
    ret=STEREO_ConfigureSynth(synthFileId,&synthConfResult);
    if (ret<0) {
        SDRPRINTF("error: %s\n",STEREO_Perror().to!string());
    }
    if(null!=synthFileId) {
        fclose(synthFileId);
    }
    
    /* MAX2769 CONFIGURATION SECTION */
    max2769FileId=fopen(max2769FileName.ptr,"rt".ptr);
    if (null==max2769FileId) {
        SDRPRINTF("error: Could not open 1st max2769 configuration file: %s\n",max2769FileName); return -1;
    }
    ret=STEREO_ConfigureMax2769(max2769FileId,&max2769res);
    if (ret<0) {
        SDRPRINTF("error: %s\n",STEREO_Perror().to!string);
    }
    if(null!=max2769FileId) {
        fclose(max2769FileId);
    }
    STEREO_FprintfMax2769Conf(stdout,&max2769res);
 
    /* MAX2112 CONFIGURATION SECTION */
    max2112FileId=fopen(max2112FileName.ptr,"rt".ptr);
    if (null==max2112FileId) {
        SDRPRINTF("error: Could not open max2112 configuration file: %s\n",max2112FileName); return -1;
    }
    ret=STEREO_ConfigureMax2112(max2112FileId,&max2112res);
    if (ret<0) {
        SDRPRINTF("error: %s\n", STEREO_Perror().to!string());
    }
    if(null!=max2112FileId) {
        fclose(max2112FileId);
    }
    STEREO_FprintfMax2112Conf(stdout,&max2112res);

    /* ADC CONFIGURATION SECTION */
    adcFileId=fopen(adcFileName.ptr,"rt".ptr);
    if (null==adcFileId) {
        SDRPRINTF("error: Could not open adc configuration file: %s\n",adcFileName); return -1;
    }
    ret=STEREO_ConfigureAdc(adcFileId,&adcConfResult);
    if (ret<0) {
        SDRPRINTF("error: %s\n",STEREO_Perror().to!string());
    }
    if(null!=adcFileId) {
        fclose(adcFileId);
    }
    STEREO_FprintfAdcConf(stdout,&adcConfResult);

    SDRPRINTF("STEREO configuration finished\n");
    
    return 0;
}
/* initialization of data expansion ---------------------------------------------
* initialization of data expansion
* args   : none
* return : none
*------------------------------------------------------------------------------*/
byte[256] lut1;
byte[2][256] lut2;
void stereo_exp_init()
{
    byte[4] BASELUT1=[-3,-1,+1,+3]; /* 2bits */
    byte[8] BASELUT2=[+1,+3,+5,+7,-7,-5,-3,-1]; /* 3bits */
    ubyte r; 
    ubyte tmp;

    for (r=0;r<256;r++) {
        tmp = r;
        lut1[r]   =BASELUT1[((tmp>>6)&0x03)];
        lut2[r][0]=BASELUT2[((tmp>>3)&0x07)];
        lut2[r][1]=BASELUT2[((tmp   )&0x07)];
    }
}
/* data expansion to binary (stereo)  -------------------------------------------
* get current data buffer from memory buffer
* args   : char   *buf      I   memory buffer
*          int    n         I   number of grab data
*          int    dtype     I   data type (DTYPEI or DTYPEIQ)
*          char   *expbuff  O   extracted data buffer
* return : none
*------------------------------------------------------------------------------*/
void stereo_exp(const(byte)* buf, size_t n, DType dtype, byte[] expbuf)
{
    int i;
    if (!lut1[0]||!lut2[0][0]) stereo_exp_init();

    final switch (dtype) {
        /* front end 1 (max2769) */
        case DType.I:
            for (i=0;i<n;i++) {
                expbuf[i]=lut1[buf[i]];
            }
            break;
        /* front end 2 (max2112) */
        case DType.IQ:
            for (i=0;i<n;i++) {
                expbuf[2*i  ]=lut2[buf[i]][0];
                expbuf[2*i+1]=lut2[buf[i]][1];
            }
            break;
    }
}
/* get current data buffer (stereo) ---------------------------------------------
* get current data buffer from memory buffer
* args   : ulong buffloc I   buffer location
*          int    n         I   number of grab data
*          int    dtype     I   data type (DTYPEI or DTYPEIQ)
*          char   *expbuff  O   extracted data buffer
* return : none
*------------------------------------------------------------------------------*/
void stereo_getbuff(ulong buffloc, size_t n, DType dtype, byte[] expbuf)
{
    ulong membuffloc=buffloc%(MEMBUFLEN*STEREO_DATABUFF_SIZE);
    int nout = cast(int)((membuffloc+n)-(MEMBUFLEN*STEREO_DATABUFF_SIZE));

    //WaitForSingleObject(hbuffmtx,INFINITE);
    synchronized(hbuffmtx){
        if (nout>0) {
            stereo_exp(&sdrstat.buff[membuffloc],n-nout,dtype,expbuf);
            stereo_exp(&sdrstat.buff[0],nout,dtype,expbuf[dtype*(n-nout) .. $]);
        } else {
            stereo_exp(&sdrstat.buff[membuffloc],n,dtype,expbuf);
        }
    }
    //ReleaseMutex(hbuffmtx);
}
/* push data to memory buffer ---------------------------------------------------
* push data to memory buffer from front end
* args   : none
* return : none
*------------------------------------------------------------------------------*/
void stereo_pushtomembuf() 
{
    //WaitForSingleObject(hbuffmtx,INFINITE);
    synchronized(hbuffmtx)
        memcpy(&sdrstat.buff[(sdrstat.buffloccnt%MEMBUFLEN)*STEREO_DATABUFF_SIZE],STEREO_dataBuffer.ptr,STEREO_DATABUFF_SIZE);
    //ReleaseMutex(hbuffmtx);

    //WaitForSingleObject(hreadmtx,INFINITE);
    synchronized(hreadmtx)
        sdrstat.buffloccnt++;
    //ReleaseMutex(hreadmtx);
}
/* push data to memory buffer ---------------------------------------------------
* push data to memory buffer from stereo binary IF file
* args   : none
* return : none
*------------------------------------------------------------------------------*/
void filestereo_pushtomembuf() 
{
    size_t nread;

    //WaitForSingleObject(hbuffmtx,INFINITE);
    synchronized(hbuffmtx)
        nread = fread(&sdrstat.buff[(sdrstat.buffloccnt%MEMBUFLEN)*STEREO_DATABUFF_SIZE],1,STEREO_DATABUFF_SIZE,sdrini.fp1.getFP);
    //ReleaseMutex(hbuffmtx);

    if (nread<STEREO_DATABUFF_SIZE) {
        sdrstat.stopflag=ON;
        SDRPRINTF("end of file!\n");
    }

    //WaitForSingleObject(hreadmtx,INFINITE);
    synchronized(hreadmtx)
        sdrstat.buffloccnt++;
    //ReleaseMutex(hreadmtx);
}

/* STEREO library functions --------------------------------------------------*/
extern(C):

extern __gshared const uint STEREO_DATABUFF_SIZE;
extern __gshared ubyte[] STEREO_dataBuffer;

int STEREO_InitLibrary();
void STEREO_QuitLibrary();
char* STEREO_Perror();
void STEREO_LibusbError( int err );
int STEREO_LoadFirmware( FILE *fid );
int STEREO_IsConfigured();
int STEREO_IsConnected();
int STEREO_ConfigureMax2769(FILE *fid, max2769Conf_t *pResult);
void STEREO_FprintfMax2769Conf( FILE *fid, max2769Conf_t *pResult);
int STEREO_ConfigureMax2112(FILE *fid, max2112Conf_t *pResult);
void STEREO_FprintfMax2112Conf( FILE *fid, max2112Conf_t *pResult);
int  STEREO_SendFpga(ubyte *bitArray, int length) ;
int  STEREO_ConfigureSynth(FILE *fid, synthConf_t *pConfResult);
int STEREO_ConfigureAdc( FILE* fid, adcConf_t *pConfResult );
void STEREO_FprintfAdcConf( FILE *fid, adcConf_t *pResult);
int STEREO_GrabInit();
int STEREO_GrabStart();
int STEREO_RefillDataBuffer();
int STEREO_GrabStop();
void STEREO_GrabClean();