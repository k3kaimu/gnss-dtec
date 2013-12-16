import std.process;
import std.stdio;
import std.string;
import std.getopt;


void main(string[] args)
{
    enum files = `sdr fec rtklib sdracq sdrcmn sdrcode sdrinit sdrnav sdrout sdrplot sdrrcv sdrspectrum sdrtrk stereo fftw util/range util/trace util/serialize util/numeric util/server util/locker`;

    auto dmdPid = spawnProcess("dmd" ~ files.split(" ") ~ args[1 .. $]);
    if (wait(dmdPid) != 0)
        writeln("failed!");
}
