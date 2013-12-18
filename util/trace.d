/**
 * GNSS-SDRLIB by D.
 * 
 * Authors:     Kazuki Komatsu
 * Data:        2013/07/10
 * License:     NYSL
 */

module util.trace;

import sdrconfig;

import std.conv : to;
import std.stdio;
import std.traits;
import std.typecons;
import std.range;
import std.functional;


/**
このスレッドでtracelnやtraceflnを出力するかどうかの実行時スイッチになります。

デフォルトではtrueとなっており、出力されますが、falseにすることで出力されなくなります。
もちろん、バージョンが TRACE でない場合にはtracelnやtraceflnは出力されなくなります。

Example:
----
sdr.util.trace.tracing = true;
traceln("これは出力される");
sdr.util.trace.tracing = false;
traceln("これは出力されない");
sdr.util.trace.tracing = true;
----

たとえば、現在のtracingのtrue/falseにかかわらず、次のtraceメッセージだけは出力したい場合、次のようにします。

Example:
----
bool currTraceState = sdr.util.trace.tracing;
sdr.util.trace.tracing = true;
traceln("どのような状況でも出力される");
sdr.util.trace.tracing = currTraceState;        // さっきの状態に復帰させる
----

See_Also:
    tracefln, traceln
*/
bool tracing = true;


/**
実行時にlogを標準出力に出力します。
ログのフォーマットは、$(B "log: $(I File)($(I Line)): $(I Function): $(I FormattedString)")になります。
また、バージョン指定で $(U $(B $(I TRACE))) が有効でないと出力されません。

Example:
----
int a = 12, b = 13;

tracefln("called: a = %s, b = %s", a, b);
----
*/
void tracefln(string file = __FILE__, size_t line = __LINE__, string fn = __FUNCTION__, S, T...)(S format, T args)
if(isSomeString!S)
{
    static if(Config.trace)
    {
        if(tracing){
            stdout.writef("log: %s(%s): %s: ", file, line, fn);
            stdout.writefln(format, args);
            stdout.flush();
        }
    }
}


/**
実行時にlogを標準出力に出力します。
ログのフォーマットは、$(B "log: $(I File)($(I Line)): $(I Function): $(I FormattedArgs)")になります。
また、バージョン指定で$(U $(B $(I TRACE)))が有効でないと出力されません。

Example:
----
int a = 12, b = 13;

traceln("called: a = ", a, ", b = " b);
----
*/
void traceln(string file = __FILE__, size_t line = __LINE__, string fn = __FUNCTION__, T...)(T args)
{
    static if(Config.trace)
    {
        if(tracing){
            stdout.writef("log: %s(%s): %s: ", file, line, fn);
            stdout.writeln(args);
            stdout.flush();
        }
    }
}


/**
コンパイル時に、ログを出力します。
ログのフォーマットは$(B "$(I File)($(I Line))")です。
バージョン指定で$(U $(B $(I TRACE)))が有効でなくてもコンパイル時に出力されます。

Example:
----
ctTrace();          // コンパイル時にファイルと行数が出力される
----
*/
void ctTrace(string file = __FILE__, size_t line = __LINE__)()
{
    pragma(msg, file ~ "(" ~ line.to!string() ~ "): ");
}


void csvOutput(R)(R data, string filename)
if(isInputRange!R)
{
    static if(Config.traceCSV)
    {
        alias T = ElementType!R;

        auto file = File(filename, "w");
        static if(is(T : typeof(tuple(T.init.tupleof)))){
            foreach(e; data){
                foreach(ee; e.tupleof)
                    file.writef("%s,", ee);
                file.writeln();
            }
        }else{
            foreach(e; data)
                file.writefln("%s,", e);
        }
    }
}


T ifExpr(alias pred = "a", T)(T value, scope void delegate(T a) dg)
if(is(typeof(unaryFun!pred(value))))
{
    if(unaryFun!pred(value))
        dg(value);

    return value;
}


T ifExpr(alias pred = "a", T)(T value, void delegate() dg)
if(is(typeof(unaryFun!pred(value))))
{
    if(unaryFun!pred(value))
        dg();

    return value;
}


T tryExpr(T)(lazy T expr, scope void delegate() dg)
{
    scope(failure) dg();
    return expr;
}
