/*-------------------------------------------------------------------------------
* sdrfunc.c : SDR plot functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;

import core.thread;

import std.stdio;
import std.c.math;
import std.c.string;
import std.process;

/* global variables -----------------------------------------------------------*/
__gshared Thread hpltthread; /* plot thread handle */

/* modify gnuplot ini file ------------------------------------------------------
* modify gnuplot ini file to set window size and position
* args   : int    nx        I   window width (pixel)
*          int    ny        I   window height (pixel)
*          int    posx      I   window x position (pixel)
*          int    posy      I   window y position (pixel)
* return : none
*------------------------------------------------------------------------------*/
int updatepltini(string file = __FILE__, size_t line = __LINE__)(int nx, int ny, int posx, int posy)
{
    traceln("called");
    char[] apppath1 = new char[1024],
           apppath2 = new char[1024];
    
    SHGetFolderPath(null, CSIDL_APPDATA, null, 0,apppath1.ptr);

    //strcat(apppath1.ptr,"\\gnuplot.ini".ptr);
    immutable gpini1Path = apppath1.to!string() ~ `\gnuplot.ini`;
    writeln(gpini1Path);
    File file1 = File(gpini1Path, "w");
    enforce(file1.isOpen);
    //fp1 = fopen(apppath1.ptr,"w".ptr).enforce();
    //scope(failure) fclose(fp1);
    
    file1.writeln("set terminal windows");
    //fprintf(fp1,"set terminal windows\n".ptr);
    //fflush(fp1);
    //fclose(fp1);

    SHGetFolderPath(null, CSIDL_APPDATA, null, 0, apppath2.ptr);
    immutable gpini2Path = apppath1.to!string() ~ `\wgnuplot.ini`;
    writeln(gpini2Path);
    File file2 = File(gpini2Path, "w");
    file2.writeln("[WGNUPLOT]");
    file2.writefln("TextOrigin=263 200");
    file2.writefln("TextSize=1393 790");
    file2.writefln("TextMinimized=0");
    file2.writefln("TextFont=Arial,14");
    file2.writefln("TextWrap=1");
    file2.writefln("TextLines=400");
    file2.writefln("SysColors=0");
    file2.writefln("GraphOrigin=%d %d",posx,posy);
    file2.writefln("GraphSize=%d %d",nx,ny);
    //static assert(0);

    //strcat(apppath2.ptr,"\\wgnuplot.ini".ptr);
    //fp2=fopen(apppath2.ptr,"w".ptr).enforce();
    //scope(failure) fclose(fp2);

    //fprintf(fp2,"[WGNUPLOT]\n".ptr);
    //fprintf(fp2,"TextOrigin=263 200\n".ptr);
    //fprintf(fp2,"TextSize=1393 790\n".ptr);
    //fprintf(fp2,"TextMinimized=0\n".ptr);
    //fprintf(fp2,"TextFont=Arial,14\n".ptr);
    //fprintf(fp2,"TextWrap=1\n".ptr);
    //fprintf(fp2,"TextLines=400\n".ptr);
    //fprintf(fp2,"SysColors=0\n".ptr);
    //fprintf(fp2,"GraphOrigin=%d %d\n".ptr,posx,posy);
    //fprintf(fp2,"GraphSize=%d %d\n".ptr,nx,ny);
    //fflush(fp2);
    //fclose(fp2);
    return 0;
}
/* set plot parameter -----------------------------------------------------------
* set plot parameter to plot struct
* args   : sdrplt_t *plt    I   sdr plot struct
*          int    type      I   plot type (PLT_Y/PLT_XY/...)
*          int    nx        I   number of x data
*          int    ny        I   number of y data
*          int    skip      I   number of skip data (0: plot all data)
*          int    abs       I   absolute value plotting flag (0:normal 1:absolute)
*          double s         I   scale factor of y/z data
*          int    h         I   plot window height (pixel)
*          int    w         I   plot window width (pixel)
*          int    mh        I   plot window margin height (pixel)
*          int    mw        I   plot window margin width (pixel)
*          int    no        I   plot window number
* return : none
*------------------------------------------------------------------------------*/
void setsdrplotprm(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, int type, int nx, int ny, int skip, int abs, double s, int h, int w, int mh, int mw, int no)
{
    traceln("called");
    plt.type=type;
    plt.nx=nx;
    plt.ny=ny;
    plt.skip=skip;
    plt.flagabs=abs;
    plt.scale=s;
    plt.plth=h;
    plt.pltw=w;
    plt.pltmh=mh;
    plt.pltmw=mw;  
    plt.pltno=no;
}
/* initialization of plot struct ------------------------------------------------
* allocate memory and open pipe
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
*------------------------------------------------------------------------------*/
int initsdrplot(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt)
{
    traceln("called");
    int xi,yi;
    int posx,posy;

    /* memory allocation */
    switch (plt.type) {
        case PLT_Y:
            plt.y = cast(double*)malloc(double.sizeof *plt.ny).enforce();
            scope(failure) free(plt.y);

            break;
        case PLT_XY:
            plt.x = cast(double*)malloc(double.sizeof * plt.nx).enforce();
            scope(failure) free(plt.x);

            plt.y = cast(double*)malloc(double.sizeof * plt.nx).enforce();
            scope(failure) free(plt.y);

            break;
        case PLT_SURFZ:
            plt.z = cast(double*)malloc(double.sizeof * plt.nx * plt.ny).enforce();
            scope(failure) free(plt.z);

            break;
        default:
            break;
    }
    /* figure position */
    xi=(plt.pltno-1)%PLT_WN;
    yi=(plt.pltno-1-xi)/PLT_WN;
    posx=plt.pltmw+xi*plt.pltw;
    posy=plt.pltmh+yi*plt.plth;

    //WaitForSingleObject(hpltmtx,INFINITE);
    synchronized(hpltmtx){

        /* update config file */
        if ((updatepltini(plt.pltw,plt.plth,posx,posy)<0)){
            SDRPRINTF("error: updatepltini\n"); return -1;
        }

        /* pipe open */
        plt.pipe = pipe();
        plt.processId = spawnProcess(`gnuplot\\gnuplot.exe`, pipe.readEnd);
        plt.fp = plt.pipe.writeEnd;

        Sleep(200);
    }
    //ReleaseMutex(hpltmtx);
//#ifdef GUI
//    /* hide window */
//    plt.hw=FindWindow(null,"c:\\Windows\\system32\\cmd.exe");
//    ShowWindow(plt.hw,SW_HIDE);
//#endif
    return 0;
}
/* quit plot function -----------------------------------------------------------
* close pipe handle and free memory
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
*------------------------------------------------------------------------------*/
void quitsdrplot(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt)
{
    traceln("called");
    /* pipe close */
    //if (plt.fp!=null)_pclose(plt.fp); plt.fp=null;
    if(plt.fp.isOpen) plt.fp.close();
    if(plt.processId !is null){
        kill(plt.processId);
        plt.processId.destroy();
        plt.processId = null;
    }


    if (plt.x!=null) free(plt.x); plt.x=null;
    if (plt.y!=null) free(plt.y); plt.y=null;
    if (plt.z!=null) free(plt.z); plt.z=null;
}
/* gnuplot set x axis range -----------------------------------------------------
* set x axis range
* args   : sdrplt_t *plt    I   sdr plot struct
*          double *xmin     I   minimum value in x-axis
*          double *xmax     I   maximum value in x-axis
* return : none
*------------------------------------------------------------------------------*/
void setxrange(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, double xmin, double xmax)
{
    traceln("called");
    plt.fp.writefln("set xr[%.1f:%.1f]",xmin,xmax);
    plt.fp.flush();
    //fprintf(plt.fp,"set xr[%.1f:%.1f]\n",xmin,xmax);
    //fflush(plt.fp);
}
/* gnuplot set y axis range -----------------------------------------------------
* set y axis range
* args   : sdrplt_t *plt    I   sdr plot struct
*          double *ymin     I   minimum value in y-axis
*          double *ymax     I   maximum value in y-axis
* return : none
*------------------------------------------------------------------------------*/
void setyrange(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, double ymin, double ymax)
{
    traceln("called");
    plt.fp.writefln("set yr[%.1f:%.1f]",ymin,ymax);
    plt.fp.flush();
    //fprintf(plt.fp,"set yr[%.1f:%.1f]\n",ymin,ymax);
    //fflush(plt.fp);
}
/* gnuplot set labels -----------------------------------------------------------
* set labels in x and y axes
* args   : sdrplt_t *plt    I   sdr plot struct
*          char   *xlabel   I   x-axis label string
*          char   *ylabel   I   y-axis label string
* return : none
*------------------------------------------------------------------------------*/
void setlabel(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, string xlabel, string ylabel)
{
    traceln("called");
    with(*plt){
        fp.writefln("set xl '%s'", xlabel);
        fp.writefln("set yl '%s'", ylabel);
        fp.flush();
    }
    //fprintf(plt.fp,"set xl '%s'\n",xlabel);
    //fprintf(plt.fp,"set yl '%s'\n",ylabel);
    //fflush(plt.fp);
}
/* gnuplot set title ------------------------------------------------------------
* set title in figure
* args   : sdrplt_t *plt    I   sdr plot struct
*          char   *title    I   title string
* return : none
*------------------------------------------------------------------------------*/
void settitle(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, string title)
{
    traceln("called");
    //fprintf(plt.fp,"set title '%s'\n",title);
    //fflush(plt.fp);
    plt.fp.writefln("set title '%s'", title);
}
/* plot 1D function -------------------------------------------------------------
* gnuplot plot 1D data function
* args   : FILE   *fp       I   gnuplot pipe handle
*          double *y        I   y data
*          int    n         I   number of input data
*          int    skip      I   number of skip data (0: plot all data)
*          double scale     I   scale factor of y data
* return : none
*------------------------------------------------------------------------------*/
void ploty(string file = __FILE__, size_t line = __LINE__)(File fp, double *y, int n, int skip, double scale)
{
    traceln("called");
    int i;
    fp.writeln("set grid");
    fp.writeln("unset key");
    fp.writeln("plot '-' with lp lw 1 pt 6 ps 2");
    //fprintf(fp, "set grid\n");
    //fprintf(fp, "unset key\n");
    //fprintf(fp, "plot '-' with lp lw 1 pt 6 ps 2\n");
    for(i=0;i<n;i+=(skip+1))
        fp.writefln("%.3f", y[i] * scale);
        //fprintf(fp,"%.3f\n",y[i]*scale);
    fp.writeln("e");
    fp.flush();
    //fprintf(fp,"e\n");
    //fflush(fp);
}
/* plot 2D function -------------------------------------------------------------
* gnuplot plot 2D data function
* args   : FILE   *fp       I   gnuplot pipe handle
*          double *x        I   x data
*          double *y        I   y data
*          int    n         I   number of input data
*          int    skip      I   number of skip data (0: plot all data)
*          double scale     I   scale factor of y data
* return : none
*------------------------------------------------------------------------------*/
void plotxy(string file = __FILE__, size_t line = __LINE__)(File fp, double *x, double *y, int n, int skip, double scale)
{
    traceln("called");
    int i;
    fp.writeln("set grid");
    fp.writeln("unset key");
    fp.writeln("plot '-' with p pt 6 ps 2");
    //fprintf(fp, "set grid\n");
    //fprintf(fp, "unset key\n");
    //fprintf(fp, "plot '-' with p pt 6 ps 2\n");
    for(i=0;i<n;i+=(skip+1))
        fp.writefln("%.3f\t%.3f", x[i], y[i] * scale);
        //fprintf(fp,"%.3f\t%.3f\n",x[i],y[i]*scale);
    fp.writeln("e");
    fp.flush();
    //fprintf(fp,"e\n"); 
    //fflush(fp);
}
/* plot surface function --------------------------------------------------------
* gnuplot plot 3D surface data function
* args   : FILE   *fp       I   gnuplot pipe handle
*          double *z        I   2D array of z value
*          int    nx        I   number of x data
*          int    ny        I   number of y data
*          int    skip      I   number of skip data (0: plot all data)
*          double scale     I   scale factor of z data
* return : none
*------------------------------------------------------------------------------*/
void plotsurfz(string file = __FILE__, size_t line = __LINE__)(File fp, double*z, int nx, int ny, int skip, double scale)
{
    traceln("called");
    int i,j;
    fp.writeln("unset key");
    fp.writeln("splot '-' with pm3d");
    //fprintf(fp, "unset key\n");
    //fprintf(fp, "splot '-' with pm3d\n");
    for(i=0;i<ny;i+=(skip+1)) {
        for(j=0;j<nx;j+=(skip+1))
            fp.writefln("%.3f", z[j*ny+i]);
            //fprintf(fp,"%.3f\n",z[j*ny+i]);
        //fprintf(fp,"\n");
        fp.writeln();
    }
    fp.writeln("e");
    fp.flush();
    //fprintf(fp,"e\n");
    //fflush(fp);
}
/* plot boxes function ----------------------------------------------------------
* gnuplot plot boxes function
* args   : FILE   *fp       I   gnuplot pipe handle
*          double *x        I   x data
*          double *y        I   y data
*          int    n         I   number of input data
*          int    skip      I   number of skip data (0: plot all data)
*          double scale     I   scale factor of y data
* return : none
*------------------------------------------------------------------------------*/
void plotbox(string file = __FILE__, size_t line = __LINE__)(File fp, double *x, double *y, int n, int skip, double scale)
{
    traceln("called");
    int i;
    fp.writeln("set grid");
    fp.writeln("unset key");
    fp.writeln("set boxwidth 0.95");
    fp.writeln(`set style fill solid border lc rgb "black"`);
    fp.writeln("plot '-' with boxes");
    //fprintf(fp, "set grid\n");
    //fprintf(fp, "unset key\n");
    //fprintf(fp, "set boxwidth 0.95\n");
    //fprintf(fp, "set style fill solid border lc rgb \"black\"\n");
    //fprintf(fp, "plot '-' with boxes\n");
    for(i=0;i<n;i+=(skip+1))
        fp.writefln("%.3f\t%.3f", x[i], y[i] * scale);
        //fprintf(fp,"%.3f\t%.3f\n",x[i],y[i]*scale);
    fp.writeln("e");
    fp.flush();
    //fprintf(fp,"e\n"); 
    //fflush(fp);
}
/* plot function/thread ---------------------------------------------------------
* gnuplot plot function/thread called from plot/plotthread
* args   : void   *arg      I   sdr plot struct
* return : none
*------------------------------------------------------------------------------*/
void plotgnuplot(void *arg)
{
    int i;
    sdrplt_t *plt = cast(sdrplt_t*)arg; /* input plt struct */
    
    /* selection of plot type */
    switch (plt.type) {
        case PLT_Y: /* 1D plot */
            if (plt.flagabs)
                for (i=0;i<plt.ny;i++) plt.y[i]=fabs(plt.y[i]);
            ploty(plt.fp,plt.y,plt.ny,plt.skip,plt.scale);
            break;
        case PLT_XY: /* 2D plot*/
            if (plt.flagabs)
                for (i=0;i<plt.nx;i++) plt.y[i]=fabs(plt.y[i]);
            plotxy(plt.fp,plt.x,plt.y,plt.nx,plt.skip,plt.scale);
            break;
        case PLT_SURFZ: /* 3D surface plot */
            if (plt.flagabs)
                for (i=0;i<plt.nx*plt.ny;i++) plt.z[i]=fabs(plt.z[i]);
            plotsurfz(plt.fp,plt.z,plt.nx,plt.ny,plt.skip,plt.scale);
            break;
        case PLT_BOX: /* box plot */
            plotbox(plt.fp,plt.x,plt.y,plt.nx,plt.skip,plt.scale);
            break;
        default:
            break;
    }
}
/* plot (thread version) --------------------------------------------------------
* gnuplot plot function (thread version)
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
* note : thread version don't waits drawing graphs
*------------------------------------------------------------------------------*/
void plotthread(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt)
{
    traceln("called");
    //WaitForSingleObject(hpltmtx,INFINITE);
    synchronized(hpltmtx){
        hpltthread = new Thread(() => plotgnuplot(plt));
        hpltthread.start();
    }
    //ReleaseMutex(hpltmtx);
}
/* plot (function version) ------------------------------------------------------
* gnuplot plot function (function version)
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
* note : function version waits drawing graphs
*------------------------------------------------------------------------------*/
void plot(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt)
{
    traceln("called");
    //WaitForSingleObject(hpltmtx,INFINITE);  
    plotgnuplot(plt);
    //ReleaseMutex(hpltmtx);
}
