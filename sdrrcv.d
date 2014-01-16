/*-------------------------------------------------------------------------------
* sdrrcv.c : SDR receiver functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;
import util.trace;
import stereo;
import sdrconfig;

import std.stdio,
       std.c.string;

import core.thread;
import std.functional;


/* sdr receiver initialization --------------------------------------------------
* receiver initialization, memory allocation, file open
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
void rcvinit(string file = __FILE__, size_t line = __LINE__)(ref sdrstat_t stat)
{
    alias fendType = Config.Receiver.fendType;

    traceln("called");

    static if(fendType == Fend.STEREO)
    {
        stereo_init();                                                      // stereo initialization
        if(Config.Receiver.confini) enforce(stereo_initconf() <! 0);       // stereo initialize configurations
        enforce(STEREO_GrabInit() <! 0);                                    // signal glab initialization
        stat.fendbuffsize = STEREO_DATABUFF_SIZE;                           // frontend buffer size
        stat.buff = new byte[stat.fendbuffsize * MEMBUFLEN];
    }
    else static if(fendType == Fend.FILESTEREO)
    {
        /* IF file open */
        stat.file = File(Config.Receiver.path, "rb");

        stat.fendbuffsize = STEREO_DATABUFF_SIZE;                // frontend buffer size
        stat.buff = new byte[stat.fendbuffsize * MEMBUFLEN];
    }
    else static if(fendType == Fend.GN3SV2 || fendType == Fend.GN3SV3)
    {
        enforce(gn3s_init() < 0);                                    /* GN3S initialization */
        stat.fendbuffsize = GN3S_BUFFSIZE;                           // frontend buffer size
        stat.buff = new  byte[stat.fendbuffsize * MEMBUFLEN];
    }
    else static if(fendType == Fend.FILE)
    {
        stat.fendbuffsize = FILE_BUFFSIZE;

        /* IF file open (FILE1) */
        foreach(i, fend; Config.Receiver.fends){
            stat.file[i] = File(fend.path, "rb");
            stat.buff[i] = new byte[stat.fendbuffsize * MEMBUFLEN * fend.dtype];
        }
    }
    else
        static assert(0);
}


/* stop front-end ---------------------------------------------------------------
* stop grabber of front end
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
void rcvquit(string file = __FILE__, size_t line = __LINE__)(ref sdrstat_t stat)
{
    alias fendType = Config.Receiver.fendType;

    traceln("called");

    static if(fendType == Fend.STEREO)
    {
         stereo_quit();
    }
    else static if(fendType == Fend.FILESTEREO)
    {
        stat.file.close();
    }
    else static if(fendType == Fend.GN3SV2 || fendType == Fend.GN3SV3)
    {
        gn3s_quit();
    }
    else static if(fendType == Fend.FILE)
    {
        foreach(i, fend; Config.Receiver.fends)
            stat.file[i].close();
    }
    else
        static assert(0);
}


/* start grabber ----------------------------------------------------------------
* start grabber of front end
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
void rcvgrabstart(string file = __FILE__, size_t line = __LINE__)(ref sdrstat_t stat)
{
    alias fendType = Config.Receiver.fendType;

    traceln("called");

    static if(fendType == Fend.STEREO)
    {
        enforce(STEREO_GrabStart() <! 0, "error: STEREO_GrabStart\n");
    }
    else static if(fendType == Fend.FILESTEREO)
    {
    }
    else static if(fendType == Fend.GN3SV2 || fendType == Fend.GN3SV3)
    {
    }
    else static if(fendType == Fend.FILE)
    {
    }
    else
        static assert(0);
}


/* grab current data ------------------------------------------------------------
* push data to memory buffer from front end
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
void rcvgrabdata(string file = __FILE__, size_t line = __LINE__)(ref sdrstat_t stat)
{
    alias fendType = Config.Receiver.fendType;

    traceln("called");

    static if(fendType == Fend.STEREO)
    {
        enforce(STEREO_RefillDataBuffer() <! 0, "error: STEREO Buffer overrun...");
        stereo_pushtomembuf(); /* copy to membuffer */
    }
    else static if(fendType == Fend.FILESTEREO)
    {
        stat.filestereo_pushtomembuf();  //copy to membuffer 
    }
    else static if(fendType == Fend.GN3SV2 || fendType == Fend.GN3SV3)
    {
        enforce(gn3s_pushtomembuf() <! 0, "error: GN3S Buffer overrun...");
    }
    else static if(fendType == Fend.FILE)
    {
        stat.file_pushtomembuf(); /* copy to membuffer */
    }
    else
        static assert(0);
}


/* grab current data from file --------------------------------------------------
* push data to memory buffer from IF file
* args   : sdrini_t *ini    I   sdr initialization struct
* return : int                  status 0:okay -1:failure
*------------------------------------------------------------------------------*/
int rcvgrabdata_file(string file = __FILE__, size_t line = __LINE__)(ref sdrstat_t stat)
{
    alias fendType = Config.Receiver.fendType;

    traceln("called");

    static if(fendType == Fend.FILESTEREO)
    {
        filestereo_pushtomembuf(); /* copy to membuffer */
    }
    static if(fendType == Fend.FILE)
    {
        stat.file_pushtomembuf(); /* copy to membuffer */
    }
    else
        static assert(0);
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
void rcvgetbuff(ref sdrstat_t stat, size_t buffloc, size_t n, FType ftype, DType dtype, byte[] expbuf)
{
    traceln("called");

    bool needNewBuffer()
    {
        return stat.fendbuffsize * stat.buffloccnt < n + buffloc;
    }


    if(expbuf !is null){
        while(needNewBuffer())
            stat.rcvgrabdata();

        alias fendType = Config.Receiver.fendType;

        traceln("called");

        static if(fendType == Fend.STEREO)
        {
            stereo_getbuff(buffloc, n, dtype, expbuf);
        }
        else static if(fendType == Fend.FILESTEREO)
        {
            stat.stereo_getbuff(buffloc, n.to!int(), dtype, expbuf);
        }
        else static if(fendType == Fend.GN3SV2)
        {
            gn3s_getbuff_v2(buffloc, n, dtype, expbuf);
        }
        else static if(fendType == Fend.GN3SV3)
        {
            gn3s_getbuff_v3(buffloc, n, dtype, expbuf);
        }
        else static if(fendType == Fend.FILE)
        {
            stat.file_getbuff(buffloc, n, ftype, dtype, expbuf);
        }
        else
            static assert(0);
    }
}


/* push data to memory buffer ---------------------------------------------------
* post-processing function: push data to memory buffer
* args   : none
* return : none
*------------------------------------------------------------------------------*/
static if(Config.Receiver.fendType == Fend.FILE)
void file_pushtomembuf(string file = __FILE__, size_t line = __LINE__)(ref sdrstat_t stat)
{
    traceln("called");

    foreach(i, fend; Config.Receiver.fends){
        immutable nread = fread(&stat.buff[i][(stat.buffloccnt % MEMBUFLEN) * fend.dtype * FILE_BUFFSIZE], 1, fend.dtype * FILE_BUFFSIZE, stat.file[i].getFP);
        enforceEx!BufferEmpty(nread <! fend.dtype * MEMBUFLEN);
    }

    stat.buffloccnt++;
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
static if(Config.Receiver.fendType == Fend.FILE)
void file_getbuff(string file = __FILE__, size_t line = __LINE__)(ref sdrstat_t stat, size_t buffloc, size_t n, FType ftype, DType dtype, byte[] expbuf)
in{
    static if(Config.Receiver.fends.length == 1)
        assert(ftype == FType.Type1);
}
body{
    traceln("called");
    size_t membuffloc = (buffloc * dtype) % (MEMBUFLEN * dtype * FILE_BUFFSIZE);
    
    n *= dtype;
    immutable ptrdiff_t nout = membuffloc + n - MEMBUFLEN * dtype * FILE_BUFFSIZE;

    if(ftype == FType.Type1){
        if(nout > 0){
            expbuf[0 .. n-nout] = stat.buff[0][membuffloc .. membuffloc + n-nout];
            expbuf[n-nout .. n] = stat.buff[0][0 .. nout];
        }else
            expbuf[0 .. n] = stat.buff[0][membuffloc  .. membuffloc + n];
    }

    static if(Config.Receiver.fends.length > 1)
    if(ftype == FType.Type2){
        if (nout > 0){
            expbuf[0 .. n-nout] = stat.buff[1][membuffloc .. membuffloc + n-nout];
            expbuf[n-nout .. n] = stat.buff[1][0 .. nout];
        }else
            expbuf[0 .. n] = stat.buff[1][membuffloc  .. membuffloc + n];
    }
}


/**
D言語的なインターフェイスを持つsdrstat_tのラッパー


*/
struct StateReader
{
    this(sdrstat_t* state, FType ftype)
    {
        this._ftype = ftype;
        this._dtype = ftype.dtype;
        this._state = state;
    }


    T[] copy(T)(T[] buf)
    if(is(T == byte) || is(T == ubyte))
    {
        byte[] _buf = cast(byte[])buf;
        rcvgetbuff(*this._state, this.pos, _buf.length / this._dtype, this._ftype, this._dtype, _buf);
        return buf;
    }


    void consume(size_t n)
    {
        _totalReadBufSize += n;
    }


    size_t pos() @property
    {
        return _totalReadBufSize;
    }


  //private:
    sdrstat_t* _state;
    size_t _totalReadBufSize;
    FType _ftype;
    DType _dtype;
}
