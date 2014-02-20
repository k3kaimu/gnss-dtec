//##& set waitTime 1000000
//##$ rdmd -m64 -O -release -inline -unittest -version=Actors --build-only actors

////##$ dmd -run runSDR -m64 -O -release -inline -unittest -version=Actors sdrconfig sdrmain

/**
マルチスレッドバージョンのSDR

アクターモデルを採用したマルチスレッドなプログラミングスタイル。

license：NYSL
author: Kazuki Komatsu
*/
module actors;

import sdr;
import sdrconfig;
import sdrrcv;
import sdrmain;
import sdracq;
import sdrtrk;
import sdrcmn;

import core.memory;

import std.algorithm,
       std.array,
       std.concurrency,
       std.container,
       std.conv,
       std.datetime,
       std.exception,
       std.functional,
       std.math,
       std.random,
       std.stdio,
       std.string,
       std.typecons;

struct GrabberIsEmpty       {}
struct NotFoundSiganl       { size_t chId; }
struct LostSignal           { size_t chId; }
struct Testament            { size_t chId; }        // 死刑になった場合に親に送る遺言
struct TimeSignal           { size_t buffloc; }
struct Register             { FType ftype; }
struct Unregister           { FType ftype; }
struct ReceivedData         { size_t buffloc; SysTime time; immutable(byte)[] data; }
struct DeathPenalty         {}                      // たとえば、GUIからあるスレッドを殺すのに使う
struct TrackingState        { size_t chId; CType ctype; size_t buffloc; double L; double remcode;}


enum tecThreadName = "tecThread";

/**
メインスレッドのアクター

このスレッドの仕事は、Grabberスレッドの作成と、イベントに応じてSDRスレッドの作成を行うことである。
*/
void mainThread()
{
    try{
        struct CHInfo(bool isRunnnig)
        {
          static if(isRunnnig)
          {
            Tid tid;
            CHInfo!false info;
            alias info this;
          }
          else
          {
            size_t id;
            double l1DopplerFreq;
          }
        }

        DList!(CHInfo!false) suspendingCHs;         // 今停止しているチャンネル
        CHInfo!true[size_t] runningCHs;             // 今現在走っているチャンネル

        Tid serverTid;                         // grabberのTid
        Tid keyTid;


        /**
        L1スレッドを起動する
        */
        CHInfo!true spawnL1Thread(CHInfo!false info)
        {
            auto tid = spawn(&(sdrThread!(CType.L1CA)), info.id, serverTid, info.l1DopplerFreq);
            return CHInfo!true(tid, info);
        }


        /**
        スレッドのコンストラクタ
        */
        {
            enforce(register("main-thread", thisTid));

            // serverの起動
            serverTid = spawn(&dataServer, thisTid);

            // keyの起動
            keyTid = spawn(&keyThread, thisTid);

            // tecThreadの起動
            spawn(&tecThread);

            // 全スレッド起動
            foreach(i, e; Config.channels)
                runningCHs[i] = spawnL1Thread(CHInfo!false(i, real.nan));
        }


        /**
        スレッドのデストラクタ
        */
        scope(exit)
        {

        }


        /**
        全てのスレッドから送られてきたメッセージを読み取る
        */
        auto pullMessage(alias receive, T...)(auto ref T optArg)
        {
            return
            receive(forward!optArg,

                // GrabberからのEmptyメッセージ
                (GrabberIsEmpty event, Tid sender){
                    enforce(0);
                },


                // L1 Threadからの信号捕捉失敗メッセージ
                (NotFoundSiganl event, Tid sender){
                    auto info = runningCHs[event.chId];
                    runningCHs.remove(event.chId);
                    info.l1DopplerFreq = real.nan;                  // 初期化
                    suspendingCHs.insertBack(info);                 // 最後に回す
                },


                // L1 Threadからの信号追尾失敗メッセージ
                (LostSignal event, Tid sender){
                    auto info = runningCHs[event.chId];
                    runningCHs.remove(event.chId);
                    info.l1DopplerFreq = real.nan;                  // 初期化
                    suspendingCHs.insertBack(info);                 // 最後に回す
                },


                // L1の遺言
                (Testament event, Tid sender){
                    auto info = runningCHs[event.chId];
                    runningCHs.remove(event.chId);
                    info.l1DopplerFreq = real.nan;                  // 初期化
                    suspendingCHs.insertBack(info);                 // 最後に回す
                },


                // Grabberスレッドから送られてくるN秒毎のメッセージ
                (TimeSignal event, Tid sender){
                    if(!suspendingCHs.empty){
                        immutable info = suspendingCHs.front;
                        suspendingCHs.removeFront(1);

                        runningCHs[info.id] = spawnL1Thread(info);
                    }

                    // mainThreadは受け取った日付を返さない
                },


                // 他のスレッドから「頼むから死んでくれ」と言われた場合の対処方法
                (DeathPenalty event, Tid sender){
                    writeln("mainThread received an event of 'DeathPenalty'");
                    serverTid.send(DeathPenalty.init, thisTid);
                    enforce(0);
                },


                // スパムメールへの対処方法
                (Variant event){
                    writeln("warning : mainThread received an unsupported event %s. ", event);
                }
            );
        }


        /**
        スレッドのメイン
        */
        {
            while(1)
                pullMessage!receive();
        }
    }
    catch(Throwable ex)
        writeln(ex);
}


void keyThread(Tid mainTid)
{
    scope(exit)
        while(receiveTimeout(dur!"usecs"(0), (Variant event){})){}

    foreach(line; stdin.byLine) try {
        auto commands = line.chomp().split(" ");

        if(commands.length)
            switch(commands[0]){
              case "quit", "q", "Q":
                mainTid.send(DeathPenalty.init, thisTid);
                return;                                     // 自分も死ぬ
                break;

              case "kill":
                if(commands.length > 1){
                    auto objTid = locate(commands[1].to!string());
                    objTid.send(DeathPenalty.init, thisTid);
                }
                break;

              default:
                writeln("command table:");
                writeln("[quit|q|Q] : quit this program");
                writeln("kill <ThreadName> : kill a thread");
            }
    }
    catch(Throwable ex)     // Pokemon Exception Handling
        writeln(ex);
}


struct FPSKeeper
{
    this(Duration interval)
    {
        _last = Clock.currTime;
        _interval = interval;
    }


    void wait()
    {
        while(_interval > Clock.currTime - _last){}
        _last = Clock.currTime;
    }


  private:
    SysTime _last;
    Duration _interval;
}


/**
Serverのアクター

データを読み込んで、各スレッドへ投げるスレッド。
*/
void dataServer(Tid mainTid)
{
    scope(exit)
        while(receiveTimeout(dur!"usecs"(0), (Variant event){})){}

    try{
        enum sendTimeSignalIntervalNsec = 10;               // 10秒ごとに時報を送る

        sdrstat_t state;

        struct FendObj
        {
            StateReader reader;
            bool[Tid] customers;
        }

        FendObj[2] fends;


        /**
        スレッドのデストラクタ
        */
        scope(exit)
        {
            void sendEmpty(Tid tid)
            {
                tid.send(GrabberIsEmpty.init, thisTid);
            }


            sendEmpty(ownerTid);
            foreach(ref fd; fends[]) foreach(tid; fd.customers.byKey)
                sendEmpty(tid);
        }


        /**
        スレッドのコンストラクタ
        */
        {
            enforce(register("data-server", thisTid));

            state = sdrstat_t(null);
            foreach(i, ref fend; fends[])
                fend.reader = StateReader(&state, (i+1).to!FType);
        }


        /**
        全てのスレッドから送られてきたメッセージを読み取る
        */
        auto pullMessage(alias receive, T...)(auto ref T optArg)
        {
            return
            receive(forward!optArg,

                // データ送ってくれっていうメッセージ
                (Register event, Tid sender){
                    enforce((sender in fends[event.ftype-1].customers) is null);
                    fends[event.ftype-1].customers[sender] = true;   // 前の時報が届いていることを錯覚させる
                },


                // tidにはもうデータを送らないでくれ、というメッセージ
                (Unregister event, Tid sender){
                    enforce(fends[event.ftype-1].customers.remove(sender));
                },


                // L1, L2のスレッドからくる時報のオウム返しが来たときの処理
                (TimeSignal event, Tid sender){
                    foreach(ref fd; fends[])
                        if(auto p = sender in fd.customers){
                            *p = true;          // 届いたよーっていう報告
                            return;
                        }

                    enforce(0, "は？？");
                },


                // 他のスレッドから「頼むから死んでくれ」と言われた場合の対処方法
                (DeathPenalty event, Tid sender){
                    writeln("dataServer received an event of 'DeathPenalty' from %s", sender);
                    enforce(0);
                },


                // スパムメールへの対処方法
                (Variant event){
                    writefln("warning : dataServer received an unsupported event %s. ", event);
                }
            );
        }


        /**
        時報を送りつける
        */
        void sendTimeSignal()
        {
            while(pullMessage!receiveTimeout(dur!"msecs"(0))){}

            // 全フラグをリセット
            foreach(ref fd; fends[])
                foreach(ref b; fd.customers.byValue)
                    b = false;

            writefln("send TimeSignal(buffloc : %s, state.buffloc : %s) to [ftype1: %s, ftype2: %s]", fends[0].reader.pos, fends[0].reader._state.buffloccnt * fends[0].reader._state.fendbuffsize, fends[0].customers.length, fends[1].customers.length);

            // 時報を作成
            foreach(ref fd; fends[]){
                TimeSignal event = {fd.reader.pos};
                foreach(cTid; fd.customers.byKey)
                    cTid.send(event, thisTid);
            }

            mainTid.send(TimeSignal(fends[0].reader.pos), thisTid);

            // 全スレッドで10秒のデータを消化できたか確認する
            // できて無ければ、消化できるまで待つ
          WHILE:
            while(1){
                foreach(ref fd; fends[])
                    foreach(bool b; fd.customers.byValue)
                        if(!b){
                            pullMessage!receive();
                            continue WHILE;
                        }

                break;
            }
        }


        /**
        スレッドのメイン
        */
        {
            enum ushort readNms = 100;
            //enum ushort tsIntvl = 10 * 1000;
            //auto keepFPS = FPSKeeper(dur!"usecs"(readNms * 1000));
            size_t prNms, prNsec;
            auto lastTime = Clock.currTime;

            while(1){
                while(pullMessage!receiveTimeout(dur!"msecs"(0))){};
                //keepFPS.wait();

                while(prNms > 10 * 1000){
                    prNms -= 10 * 1000;
                    prNsec += 10;
                    sendTimeSignal();

                    auto now = Clock.currTime;
                    writefln("process %s [sec], speed %03f [%%]...", prNsec, (now - lastTime).total!"msecs"() / (1000.0 * 10) * 100);
                    GC.collect();
                    GC.minimize();
                    lastTime = now;
                }

                // ファイルから読み込んで、送りつける
                {
                    size_t toSize_t(real f)
                    {
                        auto n = f.to!size_t();
                        enforce(n == f);
                        return n;
                    }

                    immutable time = Clock.currTime;
                    //writefln("buffer send to [ftype1 : %s, ftype2 : %s] thread on %s", fends[0].customers.length, fends[1].customers.length, time);
                    foreach(i, ref fend; fends[]){
                        immutable ftype = i == 0 ? FType.Type1 : FType.Type2,
                                  readN = toSize_t(ftype.f_sf * readNms / 1000) * ftype.dtype,
                                  data = fend.reader.copy(uninitializedArray!(byte[])(readN)).assumeUnique();

                        foreach(cTid; fend.customers.byKey)
                            cTid.send(ReceivedData(fend.reader.pos, time, data), thisTid);

                        fend.reader.consume(readN / ftype.dtype);
                    }

                    prNms += readNms;
                }
            }
        }
    }
    catch(Throwable ex)
        writeln(ex);
}


/**
SDRのアクター
*/
void sdrThread(CType ctype)(size_t chId, Tid serverTid, double freq)
{
    scope(exit)
        while(receiveTimeout(dur!"usecs"(0), (Variant event){})){}


    try{
      static if(ctype == CType.L2RCCM)
      {
        sdrinit.l1ca_doppler = (freq - Config.channels[chId].fends[CType.L2RCCM].f_if) * 77.0 / 60.0 + Config.channels[chId].fends[CType.L1CA].f_if;
      }

        immutable thisThreadName = "sdr-thread-" ~ chId.to!string() ~ "-" ~ ctype.to!string();

        /**
        DataReader
        */
        static struct ReceivedReader
        {
            this(byte[] delegate(byte[]) copy, void delegate(size_t) consume, size_t delegate() pos)
            {
                _copy = copy;
                _consume = consume;
                _pos = pos;
            }


            byte[] copy(byte[] buf)
            {
                return _copy(buf);
            }


            void consume(size_t n)
            {
                _consume(n);
            }


            size_t pos() @property
            {
                return _pos();
            }


          private:
            byte[] delegate(byte[]) _copy;
            void delegate(size_t) _consume;
            size_t delegate() _pos;
        }


        /**
        SDRChannel
        */
        static struct Ch
        {
            sdrch_t sdr;
            ReceivedReader reader;


            this(sdrch_t sdr, byte[] delegate(byte[]) copy, void delegate(size_t) consume, size_t delegate() pos)
            {
                this.sdr = sdr;
                this.reader = ReceivedReader(copy, consume, pos);
            }
        }


        Ch ch;
        immutable(byte)[][] availables;
        size_t buffloc;

      static if(ctype == CType.L1CA)
      {
        Nullable!Tid l2Tid;
        size_t l2WaitCnt = 1;
      }


        /**
        メッセージを読み取ったり、とにかくなにかする。
        */
        void pullMessage(alias receive, T...)(auto ref T optArg)
        {
            return
            receive(forward!optArg,

                (GrabberIsEmpty event, Tid sender){
                    enforce(0, "終った…");
                },


                // L2が信号捕捉に失敗したみたいです
                (NotFoundSiganl event, Tid sender){
                  static if(ctype == CType.L1CA)
                  {
                    enforce(sender == l2Tid, "誰だお前");
                    l2Tid.nullify();        // お疲れ様
                                            // また頑張ってね
                    l2WaitCnt = uniform!"[]"(6, 12);
                  }
                  else
                    enforce(0, "誰だお前");
                },


                (LostSignal event, Tid sender){
                  static if(ctype == CType.L1CA)
                  {
                    enforce(sender == l2Tid, "誰だお前");
                    l2Tid.nullify();        // お疲れ様
                                            // また頑張ってね
                    l2WaitCnt = uniform!"[]"(6, 12) * 2;
                  }
                  else
                    enforce(0, "誰だお前");
                },


                // L2からの遺言
                (Testament event, Tid sender){
                  static if(ctype == CType.L1CA)
                  {
                    enforce(sender == l2Tid, "誰だお前");
                    l2Tid.nullify();        // お疲れ様
                                            // また頑張ってね
                    l2WaitCnt = 0;
                  }
                  else  // ctype == CType.L2RCCM
                  {
                    enforce(sender == ownerTid, "誰だお前");
                    enforce(0); // 死
                  }
                },


                // 時報
                (TimeSignal event, Tid sender){
                    sender.send(event, thisTid);
                    writefln("ChId(%s: %s) get time-signal %s <---> now %s", chId, ctype, event.buffloc, buffloc);

                  static if(ctype == CType.L1CA)
                  {
                    if(ch.sdr.flagacq && l2Tid.isNull){
                        if(l2WaitCnt != 0)
                            --l2WaitCnt;

                        if(l2WaitCnt == 0){
                            immutable carrierRatio = 60.0 / 77.0,
                                      inferenced = (ch.sdr.trk.carrfreq - Config.channels[chId].fends[CType.L1CA].f_if) * carrierRatio
                                                 + Config.channels[chId].fends[CType.L2RCCM].f_if;

                            l2Tid = spawn(&sdrThread!(CType.L2RCCM), chId, serverTid, inferenced);
                        }
                    }
                    else
                    {
                        auto tecTid = locate(tecThreadName);
                        tecTid.send(TrackingState(chId, ctype, buffloc, ch.sdr.trk.L[0], ch.sdr.trk.remcodeout[0]), sender);
                    }
                  }
                  else
                  {
                    auto tecTid = locate(tecThreadName);
                    tecTid.send(TrackingState(chId, ctype, buffloc, ch.sdr.trk.L[0], ch.sdr.trk.remcodeout[0]), sender);
                  }
                },


                // 送られてきたデータ
                (ReceivedData event, Tid sender){
                    availables ~= event.data;

                    if(!buffloc)        // 一番最初だけbufflocを初期化
                        buffloc = event.buffloc;
                },


                // 他のスレッドから「頼むから死んでくれ」と言われた場合の対処方法
                (DeathPenalty event, Tid sender){
                    writeln("SDRThread received an event of 'DeathPenalty'");
                    enforce(0);
                },


                // スパムメールへの対処方法
                (Variant event){
                    writefln("warning : %s received an unsupported event %s. ", thisThreadName, event);
                }
            );
        }


        /**
        DataReader.copyの実装
        */
        byte[] copyBuffer(byte[] buf)
        {
            for(auto i = size_t.init, _buf = buf;
                _buf.length;
                ++i)
            {
                while(availables.length < i + 1)
                    pullMessage!receive();

                immutable copyN = min(_buf.length, availables[i].length);
                _buf[0 .. copyN] = availables[i][0 .. copyN];
                _buf = _buf[copyN .. $];
            }

            return buf;
        }


        /**
        DataReader.consumeの実装
        */
        void consumeBuffer(size_t n)
        {
            buffloc += n;
            n *= Config.channels[chId].fends[ctype].dtype;

            while(n){
                while(!availables.length)
                    pullMessage!receive();

                if(n >= availables[0].length){
                    n -= availables[0].length;
                    availables = availables[1 .. $];
                }else{
                    availables[0] = availables[0][n .. $];
                    return;
                }
            }
        }


        /**
        DataReader.posの実装
        */
        size_t getPos()
        {
            return buffloc;
        }


        /**
        DataServerに登録する
        */
        void registerToServer()
        {
            serverTid.send(Register(ctype == CType.L1CA ? FType.Type1 : FType.Type2), thisTid);
        }


        /**
        DataServerから抹消してもらう
        */
        void unregisterFromServer()
        {
            serverTid.send(Unregister(ctype == CType.L1CA ? FType.Type1 : FType.Type2), thisTid);
        }


        /**
        スレッドのデストラクタ
        */
        scope(exit)
        {
            writefln("end %s", thisThreadName);
            unregisterFromServer();

          static if(ctype == CType.L1CA)
          {
            if(!l2Tid.isNull)
                l2Tid.send(Testament(), thisTid);
          }
        }


        /**
        スレッドのコンストラクタとメイン関数
        */
        try{
            writefln("start %s", thisThreadName);
            enforce(register(thisThreadName, thisTid));

            registerToServer();
            ch = Ch(sdrch_t(chId, ctype), &copyBuffer, &consumeBuffer, &getPos);

            sdrthread(ch);
        }
        catch(sdracq.CannotFindSignal){
            ownerTid.send(NotFoundSiganl(chId), thisTid);
            writefln("from %s : failed acquisition", thisThreadName);
        }
        catch(sdrtrk.LostSignal){
            ownerTid.send(LostSignal(chId), thisTid);
            writefln("from %s : failed tracking", thisThreadName);
        }
    }
    catch(Throwable ex){
        writeln(ex);
        ownerTid.send(Testament(), thisTid);
    }
}


/**
TECスレッド
*/
void tecThread()
{
    enum real AverageTime = 15 * 60.0;

    static assert(AverageTime > 10);

    enum real mInv = 1.0 / (AverageTime/10);

    scope(exit)
        while(receiveTimeout(dur!"usecs"(0), (Variant event){})){}

    try{
        register(tecThreadName, thisTid);

        static struct Data
        {
            File file;
            TrackingState[][2] result;
            double baseDTEC;
            double aveTEC;
            double oldDTEC;
        }

        Data[Config.channels.length] table;

        void pullMessage()
        {
            receive(
                (TrackingState event, Tid sender){
                    immutable sf = Config.Receiver.fends[0].f_sf;
                    immutable idx = event.ctype == CType.L1CA ? 0 : 1;

                    // 直前のメッセージを確認する
                    with(table[event.chId]){
                        if(result[idx].unaryFun!(a => a.length >= 1 && (event.buffloc - a[$-1].buffloc) / sf > 15)){
                            result[idx] = [];
                            baseDTEC = double.nan;
                        }
                    }

                    table[event.chId].result[idx] ~= event;
                },

                (Variant e){
                    writeln("warning : TECThread received an unsupported event %s. ", e);
                }
            );
        }


        while(1)
        {
            foreach(chId, ref value; table) with(value){
                if(result[0].length > 2 && result[1].length > 2)
                {
                    if(abs(result[0][2].buffloc.to!real - result[1][2].buffloc.to!real) < Config.Receiver.fends[0].f_sf * 2)
                    {
                        immutable f_sf = Config.Receiver.fends[0].f_sf;

                        immutable l1L = result[0][2].L,
                                  l1b = result[0][2].buffloc;

                        auto l2Ls = result[1].map!"cast(real)(a.L)"().array(),
                             l2bs = result[1].map!"cast(real)(a.buffloc)"().array();

                        // L1に合わて補間
                        immutable double l2L = interp1(l2bs, l2Ls, l1b),
                                         l2b = result[1][2].buffloc;

                        immutable double l1remcode = result[0][2].remcode,
                                         l2remcode = result[1][2].remcode.toNearby(0.001 * f_sf / 2);

                        if(baseDTEC.isNaN){
                            baseDTEC = -calcTEC!"cycle"(l1L, l2L);
                            aveTEC = calcTEC!"m"(((l1b + l1remcode) - (l2b + l2remcode)) / f_sf * 3e8, 0);
                            oldDTEC = 0;

                            if(!file.isOpen){
                                file = File(format("TEC_Result_chId%s_%s.csv", chId, Clock.currTime.toISOString()), "w");
                                file.writeln("buffloc, DeltaTEC[TEC], TEC[TEC], aveTEC[TEC], bufflocL1, remcodeL1, bufflocL2, remcodeL2");
                            }else{
                                //file.writefln("%s, %s,", "Base-DTEC-Change", baseDTEC);
                            }
                        }else{
                            immutable double dtec = -calcTEC!"cycle"(l1L, l2L) - baseDTEC;
                            immutable double tec = calcTEC!"m"(((l1b + l1remcode) - (l2b + l2remcode)) / f_sf * 3e8, 0);

                            aveTEC = mInv * tec + (1 - mInv) * (aveTEC + (dtec - oldDTEC));
                            oldDTEC = dtec;
                            file.writefln("%s, %s, %s, %s, %s, %s, %s, %s", l1b, dtec, tec, aveTEC, l1b, l1remcode, l2b, l2remcode);
                            file.flush();
                            writefln("[TECThread]{chId: %s}{%s [DeltaTEC], %s [TEC], ave: %s [TEC]}@{buffloc: %s}", chId, dtec, tec, aveTEC, l1b);
                        }

                        result[0].popFront();
                        result[1].popFront();
                    }
                    else if(result[0][2].buffloc > result[1][2].buffloc)
                        result[1].popFront();
                    else
                        result[0].popFront();
                }
            }
            pullMessage();
        }
    }catch(Exception ex){
        writeln(ex);
        writeln("[TECThread] restart");
        tecThread();
    }catch(Throwable ex)
        writeln(ex);
}


double calcTEC(string unit : "cycle")(double l1, double l2)
{
    immutable vl1 = l1 * Constant.get!"lambda"(CType.L1CA),
              vl2 = l2 * Constant.get!"lambda"(CType.L2RCCM);

    return calcTEC!"m"(vl1, vl2);
}


double calcTEC(string unit : "m")(double l1, double l2)
{
    immutable ft = Constant.TecCoeff.freqTerm(Constant.get!"freq"(CType.L1CA), Constant.get!"freq"(CType.L2RCCM));

    return (l1 - l2) / Constant.TecCoeff.a * ft;
}
