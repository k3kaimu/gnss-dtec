import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.array;
import std.range;
import std.exception;


void main(string[] args)
{
    auto filename = args[1];
    auto file = File(filename);
    file.byLine.popFront();

    auto data = readCSV(file.byLine);
    data.smooth();

    auto oFile = File("smoothing.csv", "w");
    foreach(c; data)
        oFile.writefln("%(%.9f, %)", c);
}


real[][] readCSV(R)(R r)
{
    real[][] dst;

    foreach(e; r)
        dst ~= e.chomp().strip().split(",").map!(a => a.strip().to!real().ifThrown(0.0L))().array();

    return dst;
}


void smooth(real[][] data)
{
    auto size = data[0].length;
    auto filos = iota(size).map!(a => meanFILO!real(1024 * 10))().array();

    foreach(ref c; data){
        foreach(i, ref e; c){
            while(i == 1 && e > (1023/2))
                e -= 1023;

            if(i != 0){
                filos[i].put(e);
                e = filos[i].mean;
            }
        }
    }
}


auto meanFILO(E)(size_t n)
{
    static struct FIRFilter()
    {
        auto mean() @property { return _sum / _size; }
        void put(E e) {
            _sum -= _data[0];
            _sum += e;
            _data[0] = e;
            _data.popFront();
        }

      private:
        Cycle!(E[]) _data;
        E _sum;
        size_t _size;
    }

    auto arr = new E[n];

    foreach(ref e; arr)
        e = 0;

    return FIRFilter!()(cycle(arr), 0.0, n);
}
