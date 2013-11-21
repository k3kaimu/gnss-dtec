module util.server;

import std.algorithm,
       std.concurrency,
       std.range,
       std.traits;

private struct DefaultTag{};

/**
複数スレッドへデータを転送するのに有効
*/
struct BufferServer(T, Tag)
if(isArray!T && (is(ForeachType!T == immutable) || is(ForeachType!T == shared)) && Tag.tupleof.length == 0)
{
    struct End{}

    void put(T buf)
    {
        foreach(e; _clients)
            e.send(Tag.init, buf);
    }


    void put(Tag)
    {
        foreach(e; _clients)
            e.send(Tag.init);
    }


    void sendEnd()
    {
        this.put(Tag.init);
    }


    Tid[] _clients;
}


/// ditto
BufferServer!(T, Tag) server(T, Tag = DefaultTag)(Tid[] to...)
if(isArray!T && (is(ForeachType!T == immutable) || is(ForeachType!T == shared)) && Tag.tupleof.length == 0)
{
    typeof(return) dst;

    dst._clients = to.dup;

    return dst;
}


/**
送られてくるデータを拾うのに有効
*/
struct BufferClient(T, Tag)
if(isArray!T && (is(ForeachType!T == immutable) || is(ForeachType!T == shared)) && Tag.tupleof.length == 0)
{
    @property
    T front() pure nothrow @safe
    {
        assert(!this.empty);
        return _buf;
    }


    @property
    bool empty() pure nothrow @safe
    {
        return _empty;
    }


    @property
    void popFront()
    {
        receive(
            (Tag _, T buf){ _buf = buf; },
            (Tag _){ _empty = true; }
        );
    }


    T _buf;
    bool _empty = false;
}


/// ditto
BufferClient!(T, Tag) client(T, Tag = DefaultTag)()
if(isArray!T && (is(ForeachType!T == immutable) || is(ForeachType!T == shared)) && Tag.tupleof.length == 0)
{
    typeof(return) dst;

    dst.popFront();

    return dst;
}


unittest
{
    import std.stdio;

    // クライアントスレッドのmain関数
    static void clientFunc()
    {
        // クライアントの起動
        auto clt = client!string();

        // このスレッドのオーナーに対して、テストが成功したかどうか伝える
        ownerTid.send(equal(clt, ["aaa", "bbb", "ccc", "aaa", "bbb", "ccc"]));
    }


    // クライアントスレッドの起動
    auto cltTid = spawn(&clientFunc);


    // サーバースレッドのmain関数
    static void serverFunc(Tid clt)
    {
        // サーバーの起動
        auto srv = server!string(clt);
        scope(exit) srv.sendEnd();          // クライアントへ、データがもう無いことを知らせる

        // クライアントへ向けて文字列を送る
        srv.put("aaa");
        srv.put("bbb");
        srv.put("ccc");

        // 文字列のリストも送れる
        put(srv, ["aaa", "bbb", "ccc"]);
    }

    // サーバースレッドの起動
    auto srv = spawn(&serverFunc, cltTid);

    // クライアントスレッドから成功したかどうか送られる。
    assert(receiveOnly!bool());
}