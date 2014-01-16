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
import std.traits;
import std.regex;


/**
ラグランジュ補間しながら、各諸量を計算するすごいの
*/
void main(string[] args)
{
    string iFileA,
           iFileB,
           oFile;
    string regexA = `^(.+),(.+)$`,
           regexB = `^(.+),(.+)$`;
    size_t[]  regIdxA/* = [0, 1]*/,
              regIdxB/* = [0, 1]*/;

    getopt(args,
        "inputA", &iFileA,
        "inputB", &iFileB,
        "regexA", &regexA,
        "regexB", &regexB,
        "regIdxA", &regIdxA,
        "regIdxB", &regIdxB,
        "output", &oFile);

    //writeln()

    auto dataA = readData(iFileA, regexA, regIdxA);
    auto dataB = readData(iFileB, regexB, regIdxB);

    writeln(dataA);
    writeln(dataB);

    auto dataBt = dataB.map!"a[0]"().array(),
         dataBb = dataB.map!"a[1]"().array();

    File of = File(oFile, "w");
    foreach(e; dataA)
    {
        immutable t = e[0],
                  a = e[1],
                  b = interp1(dataBt, dataBb, t);

        if(t > dataBt[$-1])
            break;

        of.writefln("%s, %s, %s, %s", t, a, b, cast(double)(a - b));
    }
}


real[][] readData(string filename, string reg, in size_t[] idx)
{
    auto file = File(filename);
    auto re = regex(reg);
    real[][] data;

    foreach(line; file.byLine.map!chomp)
    {
        auto c = line.matchFirst(re);
        if(c.empty)
            continue;

        //writeln(c);

        real[] elem;
        try{
            foreach(i; idx){
                elem ~= c[i+1].to!real();
            }
        }catch(ConvException ex)
            continue;

        data ~= elem;
    }

    return data;
}


/**
t付近の最大3点について、ラグランジュ補間を行った結果を返します。

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