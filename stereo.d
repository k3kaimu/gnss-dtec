/*------------------------------------------------------------------------------
* stereo.h : NSL stereo functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
* Copyright (C) 2013 Nottingham Scientific Limited
*-----------------------------------------------------------------------------*/

import sdr;
import std.stdio;

import std.conv : to;
import std.exception : enforce;

import std.functional;
import core.thread;


/* constants -----------------------------------------------------------------*/
/* sterei confugration file path */
/*deprecated*/ immutable DEF_FW_FILENAME       = "../../src/rcv/stereo/conf/stereo_fx2fw.ihx";
/*deprecated*/ immutable DEF_FPGA_FILENAME     = "../../src/rcv/stereo/conf/stereo_fpga0125_intClk.bin";
/*deprecated*/ immutable DEF_SYNTH_FILENAME    = "../../src/rcv/stereo/conf/stereo_clksynth.cfg";
/*deprecated*/ immutable DEF_ADC_FILENAME      = "../../src/rcv/stereo/conf/stereo_adc.cfg";
/*deprecated*/ immutable DEF_MAX2769_FILENAME  = "../../src/rcv/stereo/conf/max2769.cfg";
/*deprecated*/ immutable DEF_MAX2112_FILENAME  = "../../src/rcv/stereo/conf/max2112_l2.cfg";
//immutable MAX_FILENAME_LEN = 256;

/* global variables -----------------------------------------------------------*/
string fx2lpFileName;
string fpgaFileName;
string max2769FileName;
string max2112FileName;
string synthFileName;
string adcFileName;
string dataFileName;

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
    fx2lpFileName = DEF_FW_FILENAME;
    fpgaFileName = DEF_FPGA_FILENAME;
    max2769FileName = DEF_MAX2769_FILENAME;
    max2112FileName = DEF_MAX2112_FILENAME;
    synthFileName = DEF_SYNTH_FILENAME;
    adcFileName = DEF_ADC_FILENAME;
}
/* stereo configuration function ------------------------------------------------
* load configuration file and setting
* args   : none
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int stereo_initconf() 
{
    writeln("STEREO configuration start...");

    /* FIRMWARE UPLOAD SECTION */
    if (!STEREO_IsConfigured()) {
        auto fwFileId = File(fx2lpFileName, "rt")
                        .tryExpr({writeln("error: Firmware file not present in folder: ", fx2lpFileName);});

        STEREO_LoadFirmware(fwFileId.getFP)
        .ifExpr!"a < 0"({writef("error: %s\n",STEREO_Perror().to!string());});

        Thread.sleep(dur!"seconds"(1));
    }

    /* FPGA CONFIGURATION SECTION */
    {
        auto fpgaFileId = File(fpgaFileName, "rb")
                         .tryExpr({writeln("error: Could not open FPGA configuration file: ", fpgaFileName);});

        auto binaryStream = new ubyte[1 << 20];

        fpgaFileId.rawRead(binaryStream).length
        .ifExpr!"a > 0"((size_t size){
            STEREO_SendFpga(binaryStream.ptr ,size.to!int())
            .ifExpr!"a < 0"({
                writeln("error: programming FPGA");
                writeln("error: ", STEREO_Perror().to!string());
            });
        });
    }

    /* LMK03033C CONFIGURATION SECTION */
    {
        synthConf_t synthConfResult = void;

        auto synthFileId = File(synthFileName, "rt")
                          .tryExpr({writeln("error: Could not open synthesizer configuration file: ", synthFileName);});
    
        STEREO_ConfigureSynth(synthFileId.getFP, &synthConfResult)
        .ifExpr!"a < 0"({writeln("error: ", STEREO_Perror().to!string());});
    }

    /* MAX2769 CONFIGURATION SECTION */
    {
        max2769Conf_t max2769res = void;

        auto max2769FileId = File(max2769FileName, "rt")
                            .tryExpr({writeln("error: Could not open 1st max2769 configuration file: ", max2769FileName);});
        
        STEREO_ConfigureMax2769(max2769FileId.getFP, &max2769res)
        .ifExpr!"a < 0"({writeln("error: ",STEREO_Perror().to!string);});
        
        STEREO_FprintfMax2769Conf(stdout.getFP, &max2769res);
    }
 
    /* MAX2112 CONFIGURATION SECTION */
    {
        max2112Conf_t max2112res = void;

        auto max2112FileId = File(max2112FileName, "rt")
                            .tryExpr({writeln("error: Could not open max2112 configuration file: ",max2112FileName);});
        
        STEREO_ConfigureMax2112(max2112FileId.getFP, &max2112res)
        .ifExpr!"a < 0"({writeln("error: ", STEREO_Perror().to!string());});

        STEREO_FprintfMax2112Conf(stdout.getFP, &max2112res);
    }

    /* ADC CONFIGURATION SECTION */
    {
        adcConf_t adcConfResult = void;

        auto adcFileId = File(adcFileName, "rt")
                        .tryExpr({writeln("error: Could not open adc configuration file: ", adcFileName);});

        STEREO_ConfigureAdc(adcFileId.getFP, &adcConfResult)
        .ifExpr!"a < 0"({writeln("error: ",STEREO_Perror().to!string());});

        STEREO_FprintfAdcConf(stdout.getFP, &adcConfResult);
    }

    writeln("STEREO configuration finished");

    return 0;
}


/* initialization of data expansion ---------------------------------------------
* initialization of data expansion
* args   : none
* return : none
*------------------------------------------------------------------------------*/
private byte[256] lut1;
private byte[2][256] lut2;

static this()
{
    byte[4] baseLUT1=[-3,-1,+1,+3]; /* 2bits */
    byte[8] baseLUT2=[+1,+3,+5,+7,-7,-5,-3,-1]; /* 3bits */

    //for (r=0;r<256;r++) {
    foreach(i; 0 .. 256){
        lut1[i]    = baseLUT1[((i>>6)&0x03)];
        lut2[i][0] = baseLUT2[((i>>3)&0x07)];
        lut2[i][1] = baseLUT2[((i   )&0x07)];
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
void stereo_exp(const(ubyte)* buf, size_t n, DType dtype, byte[] expbuf)
in{
    assert(n <= expbuf.length);
}
body{
    final switch (dtype) {
        /* front end 1 (max2769) */
        case DType.I:
            //for (i=0;i<n;i++) {
            foreach(i; 0 .. n)
                expbuf[i] = lut1[buf[i]];
            break;
        /* front end 2 (max2112) */
        case DType.IQ:
            //for (i=0;i<n;i++) {
            foreach(i; 0 .. n){
                expbuf[2*i  ] = lut2[buf[i]][0];
                expbuf[2*i+1] = lut2[buf[i]][1];
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
void stereo_getbuff(size_t buffloc, size_t n, DType dtype, byte[] expbuf)
{
    size_t membuffloc = buffloc%(MEMBUFLEN*STEREO_DATABUFF_SIZE);
    int nout = cast(int)((membuffloc+n)-(MEMBUFLEN*STEREO_DATABUFF_SIZE));

    //WaitForSingleObject(hbuffmtx,INFINITE);
    if (nout>0) {
        stereo_exp(cast(ubyte*)(&sdrstat.buff[membuffloc]), n-nout, dtype, expbuf);
        stereo_exp(cast(ubyte*)(&sdrstat.buff[0]), nout, dtype, expbuf[dtype*(n-nout) .. $]);
    } else {
        stereo_exp(cast(ubyte*)(&sdrstat.buff[membuffloc]), n, dtype, expbuf);
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
    memcpy(&sdrstat.buff[(sdrstat.buffloccnt%MEMBUFLEN)*STEREO_DATABUFF_SIZE], STEREO_dataBuffer, STEREO_DATABUFF_SIZE);
    //ReleaseMutex(hbuffmtx);

    //WaitForSingleObject(hreadmtx,INFINITE);
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
    nread = fread(&sdrstat.buff[(sdrstat.buffloccnt%MEMBUFLEN)*STEREO_DATABUFF_SIZE],1,STEREO_DATABUFF_SIZE,sdrini.fp1.getFP);
    //ReleaseMutex(hbuffmtx);

    if (nread < STEREO_DATABUFF_SIZE){
        sdrstat.stopflag=true;
        SDRPRINTF("end of file!\n");
    }

    //WaitForSingleObject(hreadmtx,INFINITE);
    sdrstat.buffloccnt++;
    //ReleaseMutex(hreadmtx);
}

/* STEREO library functions --------------------------------------------------*/
extern(C):

extern __gshared const uint STEREO_DATABUFF_SIZE;
extern __gshared ubyte* STEREO_dataBuffer;

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
