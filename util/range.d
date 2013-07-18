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