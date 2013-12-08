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
入力のレンジをn倍に引き伸ばしたレンジを返します。

Returns: 返り値の型は Voldemort Type という技法によって関数内に隠蔽されています。
*/
auto stretch(R)(R range, size_t n)
if(isInputRange!R)
{
    static struct Result
    {
        @property auto front()
        {
            return cast(const)_range.front;
        }


      static if(isInfinite!R)
        enum bool empty = false;
      else
        @property bool empty()
        {
            return _range.empty || _n == 0;
        }


        void popFront()
        {
            ++_currCnt;

            if(_currCnt == _n){
                _range.popFront();
                _currCnt = 0;
            }
        }


      static if(isForwardRange!R)
        @property typeof(this) save()
        {
            return typeof(this)(_range.save, _n, _currCnt);
        }


      static if(hasLength!R)
        @property size_t length()
        {
            return _range.length * _n - _currCnt;
        }


      private:
        R _range;
        size_t _n;
        size_t _currCnt;
    }



    return Result(range, n, 0);
}

///
unittest{
    auto input = [0, 1, 2, 3];

    auto result = stretch(input, 2);
    assert(equal(result, [0, 0, 1, 1, 2, 2, 3, 3]));

    result = stretch(input, 1);
    assert(equal(result, input));

    result = stretch(input, 0);
    assert(result.empty);
}



/**
入力のレンジをx倍に引き伸ばしたレンジを返します。

Returns: 返り値の型は Voldemort Type という技法によって関数内に隠蔽されています。
*/
auto stretch(R)(R range, real x)
if(isInputRange!R)
in{
    assert(!x.isNaN);
    assert(!x.isInfinity);
    assert(x >= 0);
}
body{
    static struct Result
    {
        @property auto front()
        {
            return cast(const)(_range.front);
        }


      static if(isInfinite!R)
        enum bool empty = false;
      else
        @property bool empty()
        {
            return _range.empty || _xInv == (1 / 0.0L);
        }


        void popFront()
        {
            _acc += _xInv;

            while(_acc >= 1 && !_range.empty){
                _acc -= 1;
                _range.popFront();
            }
        }


      static if(isForwardRange!R)
        @property typeof(this) save()
        {
            return typeof(this)(_range.save, _acc, _xInv);
        }


      private:
        R _range;
        real _acc;
        real _xInv;
    }


    return Result(range, 0, 1 / x);
}

///
unittest{
    auto input = [0, 1, 2, 3];

    auto result = stretch(input, 2.0);
    assert(equal(result, [0, 0, 1, 1, 2, 2, 3, 3]));

    result = stretch(input, 1.0);
    assert(equal(result, input));

    result = stretch(input, 0.0);
    assert(result.empty);
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



///**
//Cycleを逆転させた
//*/
//auto retroCycle(R)(R r)
//if(isRandomAccessRange!R && hasLength!R)
//{
//    alias E = ElementType!R;

//    static struct Result
//    {
//        enum empty = false;

//        auto ref front() @property { return _r[_idx]; }

//      static if(hasAssignableElements!R)
//        void front(E e) @property { _r[_idx] = e; }

//        void popFront()
//        {
//            if(_idx == 0) _idx = _r.length;
//            --_idx;
//        }

//        auto save() @property
//        {
//            auto dst = this;
//            dst._r = dst._r.save;
//            return dst;
//        }


//        auto ref opIndex(size_t idx)
//        {
//            return _r[getPopFrontNIndex(idx)];
//        }


//      static if(hasAssignableElements!R)
//        void opIndexAssign(E e, size_t idx)
//        {
//            _r[getPopFrontNIndex(idx)] = e;
//        }


//      private:
//        R _r;
//        size_t _idx;


//        size_t getPopFrontNIndex(size_t idx)
//        {
//            ptrdiff_t idx = (cast(ptrdiff_t)_idx) - (cast(ptrdiff_t)idx);
//            idx %= _r.length;

//            if(idx < 0)
//                idx += _r.length;

//            return idx;
//        }
//    }


//    return Result(cycle(r));
//}

/////
//unittest{
//    auto rc = retroCycle(new int[8]);
//    rc.
//}