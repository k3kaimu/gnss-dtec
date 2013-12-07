/*-------------------------------------------------------------------------------
* sdrrcv.c : SDR receiver functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;

import std.stdio,
       std.c.string;

import core.thread;
import std.functional;

/* sdr receiver initialization --------------------------------------------------
* receiver initialization, memory allocation, file open
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int rcvinit(string file = __FILE__, size_t line = __LINE__)(sdrini_t *ini)
{
    traceln("called");
    sdrstat.buff = sdrstat.buff1 = sdrstat.buff2 = null;

    final switch (ini.fend) {
      /* NSL stereo */
      case Fend.STEREO:
        stereo_init();                                          // stereo initialization
        if(ini.confini) enforce(stereo_initconf() <! 0);        // stereo initialize configurations
        enforce(STEREO_GrabInit() <! 0);                        // signal glab initialization

        ini.fendbuffsize = STEREO_DATABUFF_SIZE;                // frontend buffer size
        ini.buffsize = to!int(STEREO_DATABUFF_SIZE*MEMBUFLEN);  // total buffer size

        sdrstat.buff = cast(byte*)malloc(ini.buffsize)
                       .enforce("error: failed to allocate memory for the buffer");
        break;

      /* STEREO Binary File */
      case Fend.FILESTEREO: 
        /* IF file open */
        ini.fp1 = File(ini.file1, "rb");

        ini.fendbuffsize = STEREO_DATABUFF_SIZE;                    // frontend buffer size
        ini.buffsize = to!int(STEREO_DATABUFF_SIZE * MEMBUFLEN);    // total buffer size 

        sdrstat.buff = cast(byte*)malloc(ini.buffsize)
                       .enforce("error: failed to allocate memory for the buffer");
        scope(failure) free(sdrstat.buff);
        break;

    version(none)
    {
      /* SiGe GN3S v2/v3 */
      case Fend.GN3SV2, Fend.GN3SV3:
        if (gn3s_init() < 0) return -1; /* GN3S initialization */

        ini.fendbuffsize = GN3S_BUFFSIZE;                           // frontend buffer size
        ini.buffsize = GN3S_BUFFSIZE * MEMBUFLEN;                   // total buffer size

        sdrstat.buff = cast(byte*)malloc(ini.buffsize)
                       .enforce("error: failed to allocate memory for the buffer");
        break;
    }

      /* File */
      case Fend.FILE:
        /* IF file open (FILE1) */
        ini.fp1 = File(ini.file1,"rb");
        enforce(ini.fp1.isOpen);

        if(ini.file2.length){
            ini.fp2 = File(ini.file2, "rb");
            enforce(ini.fp2.isOpen);
        }

        /* frontend buffer size */
        ini.fendbuffsize=FILE_BUFFSIZE;
        /* total buffer size */
        ini.buffsize=FILE_BUFFSIZE*MEMBUFLEN;

        /* memory allocation */
        if (ini.fp1.isOpen)
            sdrstat.buff1 = cast(byte*)malloc(ini.dtype[0]*ini.buffsize)
                            .enforce("error: failed to allocate memory for the buffer");
        
        scope(failure) 
            if(sdrstat.buff1 !is null)
                free(sdrstat.buff1);


        if (ini.fp2.isOpen)
            sdrstat.buff2 = cast(byte*)malloc(ini.dtype[1]*ini.buffsize)
                            .enforce("error: failed to allocate memory for the buffer");

        scope(failure)
            if(sdrstat.buff2 !is null)
                free(sdrstat.buff2);

        break;
    }

    /* FFT initialization */
    version(UseFFTW) fftwf_init_threads();

    return 0;
}


/* stop front-end ---------------------------------------------------------------
* stop grabber of front end
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int rcvquit(string file = __FILE__, size_t line = __LINE__)(sdrini_t* ini)
{
    traceln("called");
    final switch (ini.fend) {
      /* NSL stereo */
      case Fend.STEREO: 
         stereo_quit();
        break;

      /* STEREO Binary File */
      case Fend.FILESTEREO: 
        if (ini.fp1.isOpen)
            ini.fp1.close();
        break;

    version(none){
      /* SiGe GN3S v2/v3 */
      case Fend.GN3SV2, Fend.GN3SV3:
        gn3s_quit();
        break;
    }

      /* File */
      case Fend.FILE:
        traceln();
        if (ini.fp1.isOpen)/+ fclose(ini.fp1); ini.fp1=null;+/
            ini.fp1.close();
        if (ini.fp2.isOpen)/+ fclose(ini.fp2); ini.fp2=null;+/
            ini.fp2.close();
        traceln();
        break;
    }
    traceln();
    /* free memory */
    if (null!=sdrstat.buff) { free(sdrstat.buff);  sdrstat.buff=null; }
    if (null!=sdrstat.buff1) { free(sdrstat.buff1); sdrstat.buff1=null; }
    if (null!=sdrstat.buff2) { free(sdrstat.buff2); sdrstat.buff2=null; }
    traceln();
    return 0;
}


/* start grabber ----------------------------------------------------------------
* start grabber of front end
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int rcvgrabstart(string file = __FILE__, size_t line = __LINE__)(sdrini_t *ini)
{
    traceln("called");
    final switch (ini.fend){
      /* NSL stereo */
      case Fend.STEREO: 
        if(STEREO_GrabStart() < 0){
            writeln("error: STEREO_GrabStart\n");
            return -1;
        }
        break;

      /* STEREO Binary File */
      case Fend.FILESTEREO: 
        break;

    version(none)
    {
      /* SiGe GN3S v2/v3 */
      case Fend.GN3SV2:
      case Fend.GN3SV3:
        break;
    }

      /* File */
      case Fend.FILE: 
        break;
    }

    return 0;
}


/* grab current data ------------------------------------------------------------
* push data to memory buffer from front end
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int rcvgrabdata(string file = __FILE__, size_t line = __LINE__)(sdrini_t *ini)
{
    traceln("called");
    final switch (ini.fend){
      /* NSL stereo */
      case Fend.STEREO:
        if(STEREO_RefillDataBuffer() < 0){
            writeln("error: STEREO Buffer overrun...");
            return -1;
        }

        stereo_pushtomembuf(); /* copy to membuffer */
        break;

      /* STEREO Binary File */
      case Fend.FILESTEREO:
        filestereo_pushtomembuf();  //copy to membuffer 
        break;

    version(none)
    {
      /* SiGe GN3S v2/v3 */
      case Fend.GN3SV2:
      case Fend.GN3SV3:
        if (gn3s_pushtomembuf()<0) {
            writeln("error: GN3S Buffer overrun...");
            return -1;
        }
        break;
    }

      /* File */
      case Fend.FILE:
        file_pushtomembuf(); /* copy to membuffer */
        break;
    }
    return 0;
}


/* grab current data from file --------------------------------------------------
* push data to memory buffer from IF file
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int rcvgrabdata_file(string file = __FILE__, size_t line = __LINE__)(sdrini_t *ini)
{
    traceln("called");
    final switch (ini.fend) {

      case Fend.STEREO:
        enforce(0);
        return -1;

      /* STEREO Binary File */
      case Fend.FILESTEREO: 
        filestereo_pushtomembuf(); /* copy to membuffer */
        break;

    version(none)
    {
      case Fend.GN3SV2:
      case Fend.GN3SV3:
        enforce(0);
        return -1;
    }
      
      /* File */
      case Fend.FILE:
        file_pushtomembuf(); /* copy to membuffer */
        break;
    }
    return 0;
}


/* grab current buffer ----------------------------------------------------------
* get current data buffer from memory buffer
* args   : sdrini_t *ini    I   sdr initialization struct
*          ulong buffloc I   buffer location
*          int    n         I   number of grab data 
*          int    ftype     I   front end type (FType.Type1 or FType.Type2)
*          int    dtype     I   data type (DTYPEI or DTYPEIQ)
*          char   *expbuff  O   extracted data buffer
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int rcvgetbuff(sdrini_t *ini, size_t buffloc, size_t n, FType ftype, DType dtype, byte[] expbuf)
{
    traceln("called");

    bool needNewBuffer()
    {
        return sdrini.fendbuffsize * sdrstat.buffloccnt < n + buffloc;
    }


    if(expbuf !is null){
        while(needNewBuffer())
            enforce(rcvgrabdata(&sdrini) >= 0);

        final switch (ini.fend) {
          /* NSL stereo */
          case Fend.STEREO: 
            stereo_getbuff(buffloc,n,dtype,expbuf);
            break;

          /* STEREO Binary File */
          case Fend.FILESTEREO: 
            stereo_getbuff(buffloc, n.to!int(), dtype, expbuf);
            break;

        version(none)
        {
          /* SiGe GN3S v2 */
          case Fend.GN3SV2:
            gn3s_getbuff_v2(buffloc,n,dtype,expbuf);
            break;
          /* SiGe GN3S v3 */
          case Fend.GN3SV3:
            gn3s_getbuff_v3(buffloc,n,dtype,expbuf);
            break;
        }

          /* File */
          case Fend.FILE:
            file_getbuff(buffloc, n, ftype, dtype, expbuf);
            break;
        }
    }

    debug(PrintBuffloc){
        static size_t lastBuffloc = 0;
        writefln("buffloc: %s, diff: %s", buffloc, cast(ptrdiff_t)buffloc - cast(ptrdiff_t)lastBuffloc);
        lastBuffloc = buffloc;
    }

    return 0;
}


/* push data to memory buffer ---------------------------------------------------
* post-processing function: push data to memory buffer
* args   : none
* return : none
*------------------------------------------------------------------------------*/
void file_pushtomembuf(string file = __FILE__, size_t line = __LINE__)() 
{
    traceln("called");
    size_t nread1,nread2;

    if(sdrini.fp1.isOpen) nread1=fread(&sdrstat.buff1[(sdrstat.buffloccnt%MEMBUFLEN)*sdrini.dtype[0]*FILE_BUFFSIZE],1,sdrini.dtype[0]*FILE_BUFFSIZE,sdrini.fp1.getFP);
    if(sdrini.fp2.isOpen) nread2=fread(&sdrstat.buff2[(sdrstat.buffloccnt%MEMBUFLEN)*sdrini.dtype[1]*FILE_BUFFSIZE],1,sdrini.dtype[1]*FILE_BUFFSIZE,sdrini.fp2.getFP);

    if ((sdrini.fp1.isOpen && nread1 < sdrini.dtype[0] * FILE_BUFFSIZE)||(sdrini.fp2.isOpen && nread2 < sdrini.dtype[1] * FILE_BUFFSIZE)) {
        sdrstat.stopflag = true;
        writeln("end of file!");
    }

    sdrstat.buffloccnt++;
}


/* get current data buffer from IF file -----------------------------------------
* post-processing function: get current data buffer from memory buffer
* args   : ulong buffloc I   buffer location
*          int    n         I   number of grab data 
*          int    ftype     I   front end type (FType.Type1 or FType.Type2)
*          int    dtype     I   data type (DTYPEI or DTYPEIQ)
*          char   *expbuff  O   extracted data buffer
* return : none
*------------------------------------------------------------------------------*/
void file_getbuff(string file = __FILE__, size_t line = __LINE__)(size_t buffloc, size_t n, FType ftype, DType dtype, byte[] expbuf)
{
    traceln("called");
    size_t membuffloc = (buffloc * dtype) % (MEMBUFLEN * dtype * FILE_BUFFSIZE);
    
    n *= dtype;
    immutable ptrdiff_t nout = membuffloc + n - MEMBUFLEN * dtype * FILE_BUFFSIZE;
    
    if(ftype == FType.Type1){
        if(nout > 0){
            expbuf[0 .. n-nout] = sdrstat.buff1[membuffloc .. membuffloc + n-nout];
            expbuf[n-nout .. n] = sdrstat.buff1[0 .. nout];
        }else
            expbuf[0 .. n] = sdrstat.buff1[membuffloc  .. membuffloc + n];
    }
    
    if(ftype==FType.Type2){
        if (nout>0){
            expbuf[0 .. n-nout] = sdrstat.buff2[membuffloc .. membuffloc + n-nout];
            expbuf[n-nout .. n] = sdrstat.buff2[0 .. nout];
        }else
            expbuf[0 .. n] = sdrstat.buff2[membuffloc  .. membuffloc + n];
    }
}
