import std.stdio;
import std.range;
import std.typecons;
import std.exception;
import std.string;
import std.algorithm;
import std.conv;
import std.traits;
import std.getopt;
import std.parallelism;
import std.math;


alias Elem = Tuple!(real, real, real);

/**
CSVの1行目にbuffloc,
    2   carrierPhase,
    3   remcode
*/
void main(string[] args)
{
    string qzssL1, qzssL2, gpsL1, gpsL2, outputTEC = "resultTEC.csv", outputDTEC = "resultDTEC.csv";

    getopt(args,
        "qzssl1", &qzssL1,
        "qzssl2", &qzssL2,
        "gpsl1", &gpsL1,
        "gpsl2", &gpsL2,
        "oDtec", &outputDTEC,
        "oTec", &outputTEC);

    auto data = (){
        // multi thread programming
        auto qzssL2Task = task!readData(qzssL2),
             gpsL1Task = task!readData(gpsL1),
             gpsL2Task = task!readData(gpsL2);

        taskPool.put(qzssL2Task);
        taskPool.put(gpsL1Task);
        taskPool.put(gpsL2Task);

        return [tuple(readData(qzssL1), qzssL2Task.yieldForce),
                tuple(gpsL1Task.yieldForce, gpsL2Task.yieldForce)];
    }();


    auto tecData = (){
        // multi thread programming
        auto gpsTECTask = task!calcTEC(data[1].tupleof);
        taskPool.put(gpsTECTask);

        return [calcTEC(data[0].tupleof), gpsTECTask.yieldForce];
    }();

    auto qzssTEC = tecData[0],
         gpsTEC = tecData[1];

    immutable qzssAvgTECVel = ((a, b) => (b[2] - a[2])/(b[0] - a[0]))(qzssTEC[$/4*1], qzssTEC[$/4*3]);

    auto fileTEC = File(outputTEC, "w"),
         fileDTEC = File(outputDTEC, "w");

    foreach(e; gpsTEC){
        if(!e[1].isNaN)
            fileTEC.writefln("%s, %.4f", cast(long)e[0], e[1]);

        fileDTEC.writefln("%s, %.4f", cast(long)e[0], e[2] - qzssAvgTECVel*e[0]);
    }
}



Elem[] readData(string filename)
{
    Elem[] data;

    auto file = File(filename);
    file.byLine.popFront();
    foreach(line; file.byLine)
    {
        auto ss = line.split(",").map!(strip)();

        immutable buffloc = ss[0].to!real,
                  remcode = ss[1].to!real,
                  carrPhase = ss[2].to!real;

        data ~= Elem(buffloc, remcode, carrPhase);
    }

    return data;
}


Elem[] calcTEC(in Elem[] l1data, in Elem[] l2data) pure nothrow @safe
{
    auto l2Buffloc =  l2data.map!"a[0]".array();
    auto l2Remcode = l2data.map!(a => toNear(a[1], 1023))().array();
    auto l2CarrPhase = l2data.map!"a[2]".array();

    auto l2RawRemcode = l2data.map!"a[1]"().array();

    Elem[] output;
    foreach(e; l1data)
    {
        immutable l1Idx = e[0],
                  l1P = e[1] * (3.0e8 / 1.023e6),
                  l1L = e[2];

        immutable l2L = interp1(l2Buffloc, l2CarrPhase, l1Idx),
                  l2P = interp1(l2Buffloc, l2Remcode, l1Idx) * (3.0e8 / 1.023e6);

        immutable dtec = calcTEC(l1L, l2L),
                  tec = calcTEC!"m"(l1P - l2P);

        if(interp1(l2Buffloc, l2RawRemcode, l1Idx) > (1023/2))
            output ~= Elem(l1Idx, real.nan, dtec);
        else
            output ~= Elem(l1Idx, tec, dtec);
    }

    return output;
}


real calcTEC(real phiL1, real phiL2) pure nothrow @safe
{
    immutable a = 4.03e17,
              c = 3.0e8,
              f_l1 = 10.23e6 * 77 * 2,
              f_l2 = 10.23e6 * 60 * 2;

    real lambda(real f) pure nothrow @safe { return 1.0L/f * c; }

    immutable dx = lambda(f_l1) * phiL1 - lambda(f_l2) * phiL2;

    return calcTEC!"m"(dx);
}


real calcTEC(string unit : "m")(real meter) pure nothrow @safe
{
    immutable a = 4.03e17,
              f_l1 = 10.23e6 * 77 * 2,
              f_l2 = 10.23e6 * 60 * 2;

    return meter / a * f_l1^^2 * f_l2^^2 / (f_l1^^2 - f_l2^^2);
}

real calcTEC(string unit : "s")(real sec) pure nothrow @safe
{
    return calcTEC!"m"(sec * 3.0e8);
}


/**
t付近の最大3点について、ラグランジュ補完を行った結果を返します。

Params:
    x =     xのデータ列
    y =     f(x)のデータ列
    t =     補間したいxの値

Return: 補間されたf(t)
*/
F interp1(F, G)(in F[] x, in F[] y, G t) pure nothrow @safe
if(isFloatingPoint!F && is(G : F))
in{
    assert(x.length > 0);
    assert(y.length > 0);
}
body{
    immutable inputN = x.length < y.length ? x.length : y.length;

    if(inputN == 1)
        return y[0];
    else if(inputN == 2)    // loop unrolling
        return (y[0] * (t - x[1]) - y[1] * (t - x[0])) / (x[0] - x[1]);
    else if(inputN == 3){
        // loop unrolling
        immutable real x0m1 = x[0] - x[1],
                       x0m2 = x[0] - x[2],
                       x1m2 = x[1] - x[2],
                       tmx0 = t - x[0],
                       tmx1 = t - x[1],
                       tmx2 = t - x[2],
                       k0 = tmx1 * tmx2 / (x0m1 * x0m2) * y[0],
                       k1 = tmx2 * tmx0 / (x1m2 * x0m1) * y[1],
                       k2 = tmx0 * tmx1 / (x0m2 * x1m2) * y[2];

        return k0 - k1 + k2;
    }else{
        // データ数 <= 3にして再帰
        // tの近傍のxを探す

        // 特殊な場合
        if(t < x[1])
            return interp1(x[0 .. 3], y[0 .. 3], t);
        else if(t >= x[inputN - 2])
            return interp1(x[inputN-3 .. inputN], y[inputN-3 .. inputN], t);


        // tが、s[s] <= t <= s[s+1]に存在するようなsを探す
        immutable s = (in F[] x, in F t) pure nothrow @safe {
            size_t s = 0,       // tの探索範囲はx[s .. e]
                   e = inputN;

            // このループではtを探す <- 2分探索でsとeを縮めていく
            while(e - s != 1){
                immutable mid = (s + e) / 2;

                if(t < x[mid])
                    e = mid;
                else
                    s = mid;
            }

            return s;
        }(x, t);

        // 確認
        assert(x[s] <= t && t <= x[s+1]);

        // 3点目の選択。近い方の3点を取る
        if(std.math.abs(t - x[s]) < std.math.abs(t - x[s+1]))
            return interp1(x[s-1 .. s+2], y[s-1 .. s+2], t);
        else
            return interp1(x[s .. s+3], y[s .. s+3], t);
    }
}


///
pure nothrow @safe
unittest
{
    assert(approxEqual(interp1([0.0], [1.3], 5), 1.3));                             // 1点の場合は、y[0]を返すしかない
    assert(approxEqual(interp1([1.0, 2.0], [0.0, 4.0], 3), 8));                     // 2点の場合は線形補間
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 0.1), 0.01));      // 3点以上では、近傍3点のラグランジュ補完
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 0.5), 0.25));
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 1.1), 1.21));
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 1.9), 3.61));
    assert(approxEqual(interp1([0.0, 1.0, 2.0], [0.0, 1.0, 4.0], 2.1), 4.41));

    double[] x = cast(double[])[1900, 1910, 1920, 1930, 1940, 1950, 1960, 1970, 1980, 1990];
    double[] y = [ 75.995,  91.972, 105.711, 123.203, 131.669,
                  150.697, 179.323, 203.212, 226.505, 249.633];

    foreach(i, xe; x)
        assert(interp1(x, y, xe) == y[i]);
}


real toNear(real value, real pole) pure nothrow @safe
{
    value %= pole;
    if(value > pole/2)
        return value - pole;
    else if(value < -pole/2)
        return value + pole;
    return value;
}

pure nothrow @safe
unittest
{
    assert(toNear(0.01, 1).approxEqual(0.01));
    assert(toNear(1.99, 1).approxEqual(-0.01));
    assert(toNear(-1.99, 1).approxEqual(0.01));
    assert(toNear(-0.01, 1).approxEqual(-0.01));
}