import std.process;
import std.stdio;
import std.string;
import std.getopt;
import std.algorithm;

void main(string[] args)
{
    enum files = `sdr actors fec rtklib sdracq sdrcmn sdrcode sdrinit sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize util/numeric util/server util/locker`;

    auto dmd = executeShell("dmd " ~ args[1 .. $].join(" ") ~ " " ~ files);
    writeln(dmd.output);
    writeln("end status: ", dmd.status);
}
