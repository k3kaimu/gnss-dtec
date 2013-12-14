module util.range;

import std.algorithm : equal;
import std.array;
import std.math;
import std.range;



/**
レンジの内容をコピーします。

Params:
    input =     コピーしたいレンジです。
                このレンジは、前進レンジ(Forward Range)でなくてはならず、copyToによっては変更されません
    
    output =    コピー先の出力レンジです。
                このレンジは、inputの要素(ElementType!(typeof(input)))をとる出力レンジである必要があります。
                copyToによって書き換えられます。

Returns: コピーした要素の個数を返します。
*/
size_t copyTo(R, W)(in auto ref R input, auto ref W output)
if(isForwardRange!R && isOutputRange!(W, ElementType!R))
{
    size_t cnt;
    foreach(e; input.save){                 // saveを呼び出すことで、外部への影響を無くす
        put(output, e);                     // std.range.put
        ++cnt;
    }

    return cnt;
}

///
unittest{
    auto src = [0, 1, 2, 3],
         dst = new int[4];

    assert(src.copyTo(dst[]) == 4);
    assert(src == dst);
}


/**
レンジの内容をoutputにムーブします。

Params:
    input =     ムーブ元のレンジです。
                このレンジは、入力レンジ(Input Range)でなくてはならず、moveToによって変更されます。
    
    output =    コピー先の出力レンジです。
                このレンジは、inputの要素(ElementType!(typeof(input)))をとる出力レンジ(Output Range)である必要があります。
                copyToによって書き換えられます。

Returns: コピーした要素の個数を返します。
*/
size_t moveTo(R, W)(auto ref R input, auto ref W output)
if(isInputRange!R && isOutputRange!(W, ElementType!R))
{
    size_t cnt;
    for(; !input.empty; input.popFront()){
        put(output, input.front);               // std.range.put
        ++cnt;
    }

    return cnt;
}

///
unittest{
    auto src = [0, 1, 2, 3],
         dst = new int[4];

    assert(src.moveTo(dst[]) == 4);
    assert(src.empty);
    assert(dst == [0, 1, 2, 3]);
}


/**
slice[a .. b]がb >= aでしか使用できないのに対して、slice[b .. a] b >= aで使用できるようにしたもの
*/
auto slice(R)(R r, size_t startIndex, size_t endIndex)
if(isInputRange!R)
{
    static struct Result()
    {
        auto ref front() @property in{ assert(!empty); } body { return _r.front; }
        bool empty() @property { return _empty || _r.empty; }
        void popFront()
        in{ assert(!empty); }
        body{
            ++_i;
            _r.popFront();

            if(_s <= _e){
                if(_i >= _e){
                    _empty = true;
                    return;
                }
            }else{
                if(_e == _i) while(_e <= _i && _i < _s && !_r.empty){
                    _r.popFront();
                    ++_i;
                }
            }
        }


      static if(isForwardRange!R)
        auto save() @property
        {
            auto dst = this;
            dst._r = dst._r.save;
            return dst;
        }


      private:
        bool _empty;
        R _r;
        size_t _i, _s, _e;
    }


    Result!() dst = {_empty : false, _r : r, _i : 0, _s : startIndex, _e : endIndex};


    with(dst){
        if(_s <= _e){
            while(_i < _s && !_r.empty){
                _r.popFront();
                ++_i;
            }

            if(_i >= _e)
                _empty = true;
        }else
            if(_e == 0){
                while(_i < _s && !_r.empty){
                    _r.popFront();
                    ++_i;
                }
            }
    }

    return dst;
}

///
unittest{
    auto r = iota(100);

    assert(equal(r.slice(0, 0), r[0 .. 0]));
    assert(equal(r.slice(0, 1), r[0 .. 1]));
    assert(equal(r.slice(1, 10), r[1 .. 10]));
    assert(equal(r.slice(0, 100), r));
    assert(equal(r.slice(0, 1000), r));

    assert(equal(r.slice(10, 0), r[10 .. $]));
    assert(equal(r.slice(10, 1), r[0 .. 1].chain(r[10 .. $])));
    assert(equal(r.slice(20, 10), r[0 .. 10].chain(r[20 .. $])));
    assert(equal(r.slice(1000, 10), r[0 .. 10]));
}


/**
r.slice(a, b)の補集合を返す
*/
auto sliceEx(R)(R r, size_t exStartIndex, size_t exEndIndex)
{
    if(exStartIndex == exEndIndex && exStartIndex == 0)
        return r.slice(0, size_t.max);
    else
        return r.slice(exEndIndex, exStartIndex);
}

///
unittest{
    auto r = iota(100);

    assert(equal(r.sliceEx(0, 0), r[0 .. $]));
    assert(equal(r.sliceEx(0, 1), r[1 .. $]));
    assert(equal(r.sliceEx(1, 10), r[0 .. 1].chain(r[10 .. $])));
    assert(equal(r.sliceEx(0, 100), r[$ .. $]));
    assert(equal(r.sliceEx(0, 1000), r[$ .. $]));

    assert(equal(r.sliceEx(10, 0), r[0 .. 10]));
    assert(equal(r.sliceEx(10, 1), r[1 .. 10]));
    assert(equal(r.sliceEx(20, 10), r[10 .. 20]));
    assert(equal(r.sliceEx(1000, 10), r[10 .. $]));
    assert(equal(r.sliceEx(1000, 0), r[0 .. $]));
}
