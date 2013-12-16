module util.locker;

import core.sync.mutex;

import std.algorithm;


template mutexLock(alias env)
{
    private __gshared Mutex _mutex;

    shared static this()
    {
        _mutex = new Mutex();
    }

    auto mutexLock(alias fn, T...)(auto ref T args)
    {
        synchronized(_mutex)
            return fn(forward!args);
    }
}
