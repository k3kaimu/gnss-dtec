module util.numeric;

import std.exception;
import std.math;
import std.traits;

bool isValidNum(F)(F f) pure nothrow @safe @property
{
    return !(isNaN(f) || isInfinity(f));
}


auto ref F enforceValidNum(F)(auto ref F f,  string file = __FILE__, size_t line = __LINE__) pure @safe
{
    enforce(f.isValidNum, "argument is NaN or infinite", file, line);
    return f;
}
