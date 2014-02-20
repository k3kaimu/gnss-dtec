import std.stdio;
import std.range;
import std.conv;
import std.string;


void main(string[] args)
{
    auto inFile = File(args[1]);
    auto n = args[2].to!size_t();
    auto outFile = File(args[3], "w");

    foreach(line; inFile.byLine(KeepTerminator.yes).stride(n))
        outFile.writeln(line.chomp());
}
