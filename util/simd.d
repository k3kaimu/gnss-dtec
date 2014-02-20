module util.simd;

import core.simd;

auto array(T)(T aligned) pure nothrow @safe
if(is(typeof(aligned[i].array) : T[N], T, size_t N))
{
    return aligned.ptr[0 .. aligned.length * ForeachType!T.array.length];
}


E dotProduct(E)(E[] v1, E[] v2)
in{
    assert(v1.length == v2.length);
}
body{
    E sum = 0;

    foreach(i; 0 .. v1.length)
        sum += v1[i] * v2[i];

    return sum;
}