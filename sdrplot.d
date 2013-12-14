/*-------------------------------------------------------------------------------
* sdrfunc.c : SDR plot functions
*
* Copyright (C) 2013 Taro Suzuki <gnsssdrlib@gmail.com>
*------------------------------------------------------------------------------*/
import sdr;
import util.trace;
import util.serialize;

import core.thread;


import std.c.math;
import std.c.string;
import std.datetime;
import std.process;
import std.stdio;
import std.typecons;
import std.exception;

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
    static assert(0);
    version(none){
        traceln("called");
        File file1 = File("gnuplot/gnuplot.ini", "w");
        enforce(file1.isOpen);
        
        file1.writeln("set terminal windows");


        File file2 = File("gnuplot/wgnuplot.ini", "w");
        file2.writeln("[WGNUPLOT]");
        file2.writefln("TextOrigin=263 200");
        file2.writefln("TextSize=1393 790");
        file2.writefln("TextMinimized=0");
        file2.writefln("TextFont=Arial,14");
        file2.writefln("TextWrap=1");
        file2.writefln("TextLines=400");
        file2.writefln("SysColors=0");
        file2.writefln("GraphOrigin=%d %d", posx, posy);
        file2.writefln("GraphSize=%d %d", nx, ny);
        return 0;
    }
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
void setsdrplotprm(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, PlotType type, int nx, int ny, int skip, Flag!"doAbs" abs, double s, int h, int w, int mh, int mw, int no)
{
    traceln("called");

    plt.type = type;
    plt.nx = nx;
    plt.ny = ny;
    plt.skip = skip;
    plt.flagabs = abs == Flag!"abs".yes;
    plt.scale = s;
    plt.plth = h;
    plt.pltw = w;
    plt.pltmh = mh;
    plt.pltmw = mw;
    plt.pltno = no;
}


/* initialization of plot struct ------------------------------------------------
* allocate memory and open pipe
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
*------------------------------------------------------------------------------*/
void initsdrplot(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt)
{
    traceln("called");
    int xi,yi;
    int posx,posy;

    /* memory allocation */
    switch (plt.type) {
      case PlotType.Y:
        plt.y = new double[plt.ny];
        break;

      case PlotType.XY:
        plt.x = new double[plt.nx];
        plt.y = new double[plt.nx];
        break;

      case PlotType.SurfZ:
        plt.z = new double[](plt.ny * plt.nx);
        break;

      default:
        break;
    }
    /* figure position */
    xi = (plt.pltno-1) % Constant.Plot.WN;
    yi = (plt.pltno-1-xi) / Constant.Plot.WN;
    posx = plt.pltmw + xi * plt.pltw;
    posy = plt.pltmh + yi * plt.plth;
}


/* quit plot function -----------------------------------------------------------
* close pipe handle and free memory
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
*------------------------------------------------------------------------------*/
void quitsdrplot(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt)
{}


/* gnuplot set x axis range -----------------------------------------------------
* set x axis range
* args   : sdrplt_t *plt    I   sdr plot struct
*          double *xmin     I   minimum value in x-axis
*          double *xmax     I   maximum value in x-axis
* return : none
*------------------------------------------------------------------------------*/
void setxrange(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, double xmin, double xmax)
{
    //static assert(0);
    version(none){
        traceln("called");
        plt.fp.writefln("set xr[%.1f:%.1f]",xmin,xmax);
        plt.fp.flush();
    }else
        plt.xrange = [xmin, xmax];
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
    //static assert(0);
    version(none){
        traceln("called");
        plt.fp.writefln("set yr[%.1f:%.1f]",ymin,ymax);
        plt.fp.flush();
    }else
        plt.yrange = [ymin, ymax];
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
    //static assert(0);
    version(none){
        traceln("called");
        with(*plt){
            fp.writefln("set xl '%s'", xlabel);
            fp.writefln("set yl '%s'", ylabel);
            fp.flush();
        }
    }else{
        plt.xlabel = xlabel;
        plt.ylabel = ylabel;
    }
}


/* gnuplot set title ------------------------------------------------------------
* set title in figure
* args   : sdrplt_t *plt    I   sdr plot struct
*          char   *title    I   title string
* return : none
*------------------------------------------------------------------------------*/
void settitle(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, string title)
{
    //static assert(0);
    version(none){
        traceln("called");
        plt.fp.writefln("set title '%s'", title);
        plt.fp.flush();
    }else
        plt.title = title;
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
    static assert(0);
    version(none){
        traceln("called");
        int i;
        fp.writeln("set grid");
        fp.writeln("unset key");
        fp.writeln("plot '-' with lp lw 1 pt 6 ps 2");

        for(i=0;i<n;i+=(skip+1))
            fp.writefln("%.3f", y[i] * scale);

        fp.writeln("e");
        fp.flush();
    }
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
    static assert(0);
    version(none){
        traceln("called");
        int i;
        fp.writeln("set grid");
        fp.writeln("unset key");
        fp.writeln("plot '-' with p pt 6 ps 2");

        for(i=0;i<n;i+=(skip+1)){
            fp.writefln("%.3f\t%.3f", x[i], y[i] * scale);
        }

        fp.writeln("e");
        fp.flush();
    }
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
    static assert(0);
    version(none){
        traceln("called");
        int i,j;
        fp.writeln("unset key");
        fp.writeln("splot '-' with pm3d");

        for(i=0;i<ny;i+=(skip+1)) {
            for(j=0;j<nx;j+=(skip+1))
                fp.writefln("%.3f", z[j*ny+i]);
            fp.writeln();
        }
        fp.writeln("e");
        fp.flush();
    }
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
    static assert(0);
    version(none){
        traceln("called");
        int i;
        fp.writeln("set grid");
        fp.writeln("unset key");
        fp.writeln("set boxwidth 0.95");
        fp.writeln(`set style fill solid border lc rgb "black"`);
        fp.writeln("plot '-' with boxes");

        for(i=0;i<n;i+=(skip+1))
            fp.writefln("%.3f\t%.3f", x[i], y[i] * scale);

        fp.writeln("e");
        fp.flush();
    }
}


/* plot function/thread ---------------------------------------------------------
* gnuplot plot function/thread called from plot/plotthread
* args   : void   *arg      I   sdr plot struct
* return : none
*------------------------------------------------------------------------------*/
void plotgnuplot()(void *arg)
{
    static assert(0);
    version(none){
        int i;
        sdrplt_t *plt = cast(sdrplt_t*)arg; /* input plt struct */
        
        /* selection of plot type */
        final switch (plt.type) {
            case PlotType.Y: /* 1D plot */
                if (plt.flagabs)
                    for (i=0;i<plt.ny;i++) plt.y[i]=fabs(plt.y[i]);
                ploty(plt.fp,plt.y,plt.ny,plt.skip,plt.scale);
                break;
            case PlotType.XY: /* 2D plot*/
                if (plt.flagabs)
                    for (i=0;i<plt.nx;i++) plt.y[i]=fabs(plt.y[i]);
                plotxy(plt.fp,plt.x,plt.y,plt.nx,plt.skip,plt.scale);
                break;
            case PlotType.SurfZ: /* 3D surface plot */
                if (plt.flagabs)
                    for (i=0;i<plt.nx*plt.ny;i++) plt.z[i]=fabs(plt.z[i]);
                plotsurfz(plt.fp,plt.z,plt.nx,plt.ny,plt.skip,plt.scale);
                break;
            case PlotType.Box: /* box plot */
                plotbox(plt.fp,plt.x,plt.y,plt.nx,plt.skip,plt.scale);
                break;
        }
    }
}


/* plot (thread version) --------------------------------------------------------
* gnuplot plot function (thread version)
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
* note : thread version don't waits drawing graphs
*------------------------------------------------------------------------------*/
void plotthread(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, string initial)
{
    
    traceln("called");

    PlotObject obj;
    obj.nx = plt.nx;
    obj.ny = plt.ny;

    final switch(plt.type){
        case PlotType.Y: /* 1D plot */
            obj.y = plt.y[0 .. plt.ny];
            break;

        case PlotType.XY: /* 2D plot*/
            obj.x = plt.x[0 .. plt.nx];
            obj.y = plt.y[0 .. plt.nx];
            break;

        case PlotType.SurfZ: /* 3D surface plot */
            obj.z = plt.z[0 .. plt.nx * plt.ny];
            break;

        case PlotType.Box: /* box plot */
            obj.x = plt.x[0 .. plt.nx];
            obj.y = plt.y[0 .. plt.nx];
            break;
    }

    obj.type = plt.type;
    obj.skip = plt.skip;
    obj.flagabs = plt.flagabs;
    obj.scale = plt.scale;
    obj.pltno = plt.pltno;
    obj.xrange = plt.xrange;
    obj.yrange = plt.yrange;
    obj.xlabel = plt.xlabel;
    obj.ylabel = plt.ylabel;
    obj.xvalue = plt.xvalue;
    obj.yvalue = plt.yvalue;
    obj.title = plt.title;
    obj.otherSetting = plt.otherSetting;

    immutable fileName = `SerializedData\` ~ initial ~ "_" ~ Clock.currTime.toISOString() ~ ".dat";
    fileName.serializedWrite(obj);
}


/* plot (function version) ------------------------------------------------------
* gnuplot plot function (function version)
* args   : sdrplt_t *plt    I   sdr plot struct
* return : none
* note : function version waits drawing graphs
*------------------------------------------------------------------------------*/
void plot(string file = __FILE__, size_t line = __LINE__)(sdrplt_t *plt, string initial)
{
    traceln("called");
    plotthread(plt, initial);
}