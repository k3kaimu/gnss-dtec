module fftw;

public import std.complex;
import std.array, std.traits, std.typecons, std.c.stdio;

/+
auto fftwComplexArray(T)(size_t n) nothrow
if(isFloatingPoint!T && !is(T == real))
{
    static struct FftwComplexArrayImpl()
    {
        this(size_t n)
        {
            memory = (cast(Complex!T*)FftwSelect!(T, "malloc")(T.sizeof * 2 * n))[0 .. n];
        }


        ~this()
        {
            FftwSelect!(T, "free")(memory.ptr);
        }


      private:
        Complex!T[] _memory;
    }


    static struct FftwComplexSlice()
    {
        this(FftwComplexArray!T array) pure nothrow @safe
        {
            _array = array;
            _f = 0;
            _b = array._memory.length;
        }


        ref inout(Complex!T) front() pure nothrow @safe inout @property { return _array._memory[_f]; }
        ref inout(Complex!T) back()  pure nothrow @safe inout @property { return _array._memory[_b-1]; }
        ref inout(Complex!T) opIndex(size_t n) pure nothrow inout @safe in{ assert(_f <= n && n < _b); }body{ return _array._memory[n]; }
        
        void popFront() pure nothrow @safe { ++_f; }
        void popBack()  pure nothrow @safe { --_b; }

        bool empty() pure nothrow @safe inout @property { return _f == _b; }

        inout(typeof(this)) save() pure nothrow @safe inout @property { return this; }

        size_t length() pure nothrow @safe inout @property { return _b - _f; }
        alias length opDollar;

        inout(typeof(this)) opSlice() pure nothrow @safe inout { return this; }
        inout(typeof(this)) opSlice(size_t i, size_t j) pure nothrow @safe inout { return inout(typeof(this))(_f + i, _f + (j - i), _array); }

      private:
        size_t _f, _b;
        FftwComplexArray!T _array;
    }


    return FftwSlice(RefCounted!(FftwComplexArrayImpl!())(n));
}


class Fftw(T)
{
    void fft(FftwComplexArray!T input, FftwComplexArray!T output)
}+/
/*
void main(){
    enum N = 1024 * 1024;
    import std.datetime;

    StopWatch sw1, sw2;
    auto input = fftwComplexArray!float(N);
    auto output = fftwComplexArray!float(N);

    import std.stdio, std.math, std.complex;
    foreach(i; 0 .. N)
        input.memory[i] = sin(2 * PI / 16 * i);

    sw1.start();
    auto p = FftwSelect!(float, "plan_dft_1d")(N, input.ptr, output.ptr, FFTW_FORWARD, FFTW_ESTIMATE);
    FftwSelect!(float, "execute")(p);
    FftwSelect!(float, "destroy_plan")(p);
    sw1.stop();

    import std.numeric, std.algorithm;
    sw2.start();
    auto resu = fft(map!"a.re"(input.memory));
    sw2.stop();
    
    writeln(sw1.peek.usecs);
    writeln(sw2.peek.usecs);
}*/


template FftwComplexArray(T)
{
    alias typeof(fftwComplexArray!T(0)) FftwComplexArray;
}

template getFftwTypeName(T)
{
    static if(is(T == float))
        enum string getFftwTypeName = "fftwf_";
    else static if(is(T == double))
        enum string getFftwTypeName = "fftw_";
    else
        static assert(0);
}

template FftwSelect(T, string name)
if(isFloatingPoint!T && !is(T == real))
{
    mixin("alias " ~ getFftwTypeName!T ~ name ~ " FftwSelect;");
}


enum fftw_r2r_kind_do_not_use_me {
     FFTW_R2HC=0, FFTW_HC2R=1, FFTW_DHT=2,
     FFTW_REDFT00=3, FFTW_REDFT01=4, FFTW_REDFT10=5, FFTW_REDFT11=6,
     FFTW_RODFT00=7, FFTW_RODFT01=8, FFTW_RODFT10=9, FFTW_RODFT11=10
}

struct fftw_iodim_do_not_use_me {
     int n;                     /* dimension size */
     int is_;            /* input stride */
     int os;            /* output stride */
}

struct fftw_iodim64_do_not_use_me {
     ptrdiff_t n;                     /* dimension size */
     ptrdiff_t is_;          /* input stride */
     ptrdiff_t os;          /* output stride */
}

alias void fftw_write_char_func_do_not_use_me(char c, void *);
alias int fftw_read_char_func_do_not_use_me(void *);


enum fftwCHeaderCode = q{
  extern(C):
  nothrow:

    struct {X}plan_s{}
    alias {X}plan_s* {X}plan;

    alias fftw_iodim_do_not_use_me {X}iodim;
    alias fftw_iodim64_do_not_use_me {X}iodim64;
    alias fftw_r2r_kind_do_not_use_me {X}r2r_kind;
    alias fftw_write_char_func_do_not_use_me {X}write_char_func;
    alias fftw_read_char_func_do_not_use_me {X}read_char_func;

    void {X}execute(const {X}plan p);

    {X}plan {X}plan_dft(int rank, const int* n,            
                {C}* in_, {C}* out_, int sign, uint flags);          
                                          
    {X}plan {X}plan_dft_1d(int n, {C}* in_, {C}* out_, int sign,     
                   uint flags);                   
    {X}plan {X}plan_dft_2d(int n0, int n1,             
                   {C}* in_, {C}* out_, int sign, uint flags);      
    {X}plan {X}plan_dft_3d(int n0, int n1, int n2,         
                   {C}* in_, {C}* out_, int sign, uint flags);       
                                          
    {X}plan {X}plan_many_dft(int rank, const int* n,           
                             int howmany,                      
                             {C}* in_, const int* inembed,            
                             int istride, int idist,               
                             {C}* out_, const int* onembed,               
                             int ostride, int odist,               
                             int sign, uint flags);            
                                          
    {X}plan {X}plan_guru_dft(int rank, const {X}iodim* dims,       
                 int howmany_rank,                 
                 const {X}iodim* howmany_dims,             
                 {C}* in_, {C}* out_,                    
                 int sign, uint flags);           
    {X}plan {X}plan_guru_split_dft(int rank, const {X}iodim* dims, 
                 int howmany_rank,                 
                 const {X}iodim* howmany_dims,             
                 {R}* ri, {R}* ii, {R}* ro, {R}* io,               
                 uint flags);                  
                                          
    {X}plan {X}plan_guru64_dft(int rank,               
                             const {X}iodim64* dims,               
                 int howmany_rank,                 
                 const {X}iodim64* howmany_dims,           
                 {C}* in_, {C}* out_,                    
                 int sign, uint flags);           
    {X}plan {X}plan_guru64_split_dft(int rank,             
                             const {X}iodim64* dims,               
                 int howmany_rank,                 
                 const {X}iodim64* howmany_dims,           
                 {R}* ri, {R}* ii, {R}* ro, {R}* io,               
                 uint flags);                  
                                          
    void {X}execute_dft(const {X}plan p, {C}* in_, {C}* out_);      
    void {X}execute_split_dft(const {X}plan p, {R}* ri, {R}* ii,       
                                          {R}* ro, {R}* io);               
                                          
    {X}plan {X}plan_many_dft_r2c(int rank, const int* n,       
                                 int howmany,                  
                                 {R}* in_, const int* inembed,            
                                 int istride, int idist,               
                                 {C}* out_, const int* onembed,           
                                 int ostride, int odist,               
                                 uint flags);                  
                                          
    {X}plan {X}plan_dft_r2c(int rank, const int* n,        
                            {R}* in_, {C}* out_, uint flags);            
                                          
    {X}plan {X}plan_dft_r2c_1d(int n,{R}* in_,{C}* out_,uint flags);
    {X}plan {X}plan_dft_r2c_2d(int n0, int n1,             
                   {R}* in_, {C}* out_, uint flags);        
    {X}plan {X}plan_dft_r2c_3d(int n0, int n1,             
                   int n2,                     
                   {R}* in_, {C}* out_, uint flags);         
                                           
                                          
    {X}plan {X}plan_many_dft_c2r(int rank, const int* n,       
                     int howmany,                  
                     {C}* in_, const int* inembed,            
                     int istride, int idist,               
                     {R}* out_, const int* onembed,           
                     int ostride, int odist,               
                     uint flags);                  
                                          
    {X}plan {X}plan_dft_c2r(int rank, const int* n,        
                            {C}* in_, {R}* out_, uint flags);            
                                          
    {X}plan {X}plan_dft_c2r_1d(int n,{C}* in_,{R}* out_,uint flags);
    {X}plan {X}plan_dft_c2r_2d(int n0, int n1,             
                   {C}* in_, {R}* out_, uint flags);        
    {X}plan {X}plan_dft_c2r_3d(int n0, int n1,             
                   int n2,                     
                   {C}* in_, {R}* out_, uint flags);         
                                          
    {X}plan {X}plan_guru_dft_r2c(int rank, const {X}iodim* dims,   
                     int howmany_rank,                 
                     const {X}iodim* howmany_dims,         
                     {R}* in_, {C}* out_,                
                     uint flags);                 
    {X}plan {X}plan_guru_dft_c2r(int rank, const {X}iodim* dims,   
                     int howmany_rank,                 
                     const {X}iodim* howmany_dims,         
                     {C}* in_, {R}* out_,                
                     uint flags);                  
                                          
    {X}plan {X}plan_guru_split_dft_r2c(                
                                 int rank, const {X}iodim* dims,           
                     int howmany_rank,                 
                     const {X}iodim* howmany_dims,         
                     {R}* in_, {R}* ro, {R}* io,              
                     uint flags);                 
    {X}plan {X}plan_guru_split_dft_c2r(                
                                 int rank, const {X}iodim* dims,           
                     int howmany_rank,                 
                     const {X}iodim* howmany_dims,         
                     {R}* ri, {R}* ii, {R}* out_,             
                     uint flags);                  
                                          
    {X}plan {X}plan_guru64_dft_r2c(int rank,               
                                 const {X}iodim64* dims,               
                     int howmany_rank,                 
                     const {X}iodim64* howmany_dims,           
                     {R}* in_, {C}* out_,                
                     uint flags);                 
    {X}plan {X}plan_guru64_dft_c2r(int rank,               
                                 const {X}iodim64* dims,               
                     int howmany_rank,                 
                     const {X}iodim64* howmany_dims,           
                     {C}* in_, {R}* out_,                
                     uint flags);                  
                                          
    {X}plan {X}plan_guru64_split_dft_r2c(              
                                 int rank, const {X}iodim64* dims,         
                     int howmany_rank,                 
                     const {X}iodim64* howmany_dims,           
                     {R}* in_, {R}* ro, {R}* io,              
                     uint flags);                 
    {X}plan {X}plan_guru64_split_dft_c2r(              
                                 int rank, const {X}iodim64* dims,         
                     int howmany_rank,                 
                     const {X}iodim64* howmany_dims,           
                     {R}* ri, {R}* ii, {R}* out_,             
                     uint flags);                  
                                          
    void {X}execute_dft_r2c(const {X}plan p, {R}* in_, {C}* out_);      
    void {X}execute_dft_c2r(const {X}plan p, {C}* in_, {R}* out_);       
                                           
    void {X}execute_split_dft_r2c(const {X}plan p,         
                                              {R}* in_, {R}* ro, {R}* io);       
    void {X}execute_split_dft_c2r(const {X}plan p,         
                                              {R}* ri, {R}* ii, {R}* out_);       
                                          
    {X}plan {X}plan_many_r2r(int rank, const int* n,           
                             int howmany,                      
                             {R}* in_, const int* inembed,            
                             int istride, int idist,               
                             {R}* out_, const int* onembed,               
                             int ostride, int odist,               
                             const {X}r2r_kind* kind, uint flags);     
                                          
    {X}plan {X}plan_r2r(int rank, const int* n, {R}* in_, {R}* out_,     
                        const {X}r2r_kind* kind, uint flags);          
                                          
    {X}plan {X}plan_r2r_1d(int n, {R}* in_, {R}* out_,           
                           {X}r2r_kind kind, uint flags);         
    {X}plan {X}plan_r2r_2d(int n0, int n1, {R}* in_, {R}* out_,      
                           {X}r2r_kind kind0, {X}r2r_kind kind1,           
                           uint flags);                   
    {X}plan {X}plan_r2r_3d(int n0, int n1, int n2,         
                           {R}* in_, {R}* out_, {X}r2r_kind kind0,           
                           {X}r2r_kind kind1, {X}r2r_kind kind2,           
                           uint flags);                    
                                          
    {X}plan {X}plan_guru_r2r(int rank, const {X}iodim* dims,       
                             int howmany_rank,                 
                             const {X}iodim* howmany_dims,             
                             {R}* in_, {R}* out_,                    
                             const {X}r2r_kind* kind, uint flags);     
                                          
    {X}plan {X}plan_guru64_r2r(int rank, const {X}iodim64* dims,   
                             int howmany_rank,                 
                             const {X}iodim64* howmany_dims,           
                             {R}* in_, {R}* out_,                    
                             const {X}r2r_kind* kind, uint flags);     
                                          
    void {X}execute_r2r(const {X}plan p, {R}* in_, {R}* out_);       
                                          
    void {X}destroy_plan({X}plan p);                  
    void {X}forget_wisdom();                  
    void {X}cleanup();                     
                                          
    void {X}set_timelimit(double t);                   
                                          
    void {X}plan_with_nthreads(int nthreads);             
    int {X}init_threads();                    
    void {X}cleanup_threads();                 
                                          
    int {X}export_wisdom_to_filename(const char* filename);   
    void {X}export_wisdom_to_file(FILE* output_file);         
    char* {X}export_wisdom_to_string();           
    void {X}export_wisdom({X}write_char_func write_char,       
                                      void* data);                
    int {X}import_system_wisdom();                
    int {X}import_wisdom_from_filename(const char* filename);     
    int {X}import_wisdom_from_file(FILE* input_file);         
    int {X}import_wisdom_from_string(const char* input_string);   
    int {X}import_wisdom({X}read_char_func read_char, void* data); 
                                          
    void {X}fprint_plan(const {X}plan p, FILE* output_file);      
    void {X}print_plan(const {X}plan p);               
                                          
    void* {X}malloc(size_t n);                    
    {R}* {X}alloc_real(size_t n);                   
    {C}* {X}alloc_complex(size_t n);                
    void {X}free(void* p);                     
                                          
    void {X}flops(const {X}plan p,                 
                              double* add, double* mul, double* fmas);    
    double {X}estimate_cost(const {X}plan p);             
    double {X}cost(const {X}plan p);                   
/+                                          
    const char {X}version[];                      
    const char {X}cc[];                        
    const char {X}codelet_optim[];+/
};


string genFftwDHeader(string code, Tuple!(string, string)[] replaceStrings...)
{
    foreach(e; replaceStrings)
        code = code.replace(e[0], e[1]);

    return code;
}

mixin(genFftwDHeader(fftwCHeaderCode, tuple("{X}", "fftwf_"), tuple("{R}", "float"), tuple("{C}", "Complex!float")));
mixin(genFftwDHeader(fftwCHeaderCode, tuple("{X}", "fftw_"), tuple("{R}", "double"), tuple("{C}", "Complex!double")));

enum FFTW_FORWARD = -1;
enum FFTW_BACKWARD = +1;

enum FFTW_NO_TIMELIMIT = -1.0;

/* documented flags */
enum FFTW_MEASURE = 0U;
enum FFTW_DESTROY_INPUT = 1U << 0;
enum FFTW_UNALIGNED = 1U << 1;
enum FFTW_CONSERVE_MEMORY = 1U << 2;
enum FFTW_EXHAUSTIVE = 1U << 3; /* NO_EXHAUSTIVE is default */
enum FFTW_PRESERVE_INPUT = 1U << 4; /* cancels FFTW_DESTROY_INPUT */
enum FFTW_PATIENT = 1U << 5; /* IMPATIENT is default */
enum FFTW_ESTIMATE = 1U << 6;
enum FFTW_WISDOM_ONLY = 1U << 21;

/* undocumented beyond-guru flags */
enum FFTW_ESTIMATE_PATIENT = 1U << 7;
enum FFTW_BELIEVE_PCOST = 1U << 8;
enum FFTW_NO_DFT_R2HC = 1U << 9;
enum FFTW_NO_NONTHREADED = 1U << 10;
enum FFTW_NO_BUFFERING = 1U << 11;
enum FFTW_NO_INDIRECT_OP = 1U << 12;
enum FFTW_ALLOW_LARGE_GENERIC = 1U << 13; /* NO_LARGE_GENERIC is default */
enum FFTW_NO_RANK_SPLITS = 1U << 14;
enum FFTW_NO_VRANK_SPLITS = 1U << 15;
enum FFTW_NO_VRECURSE = 1U << 16;
enum FFTW_NO_SIMD = 1U << 17;
enum FFTW_NO_SLOW = 1U << 18;
enum FFTW_NO_FIXED_RADIX_LARGE_N = 1U << 19;
enum FFTW_ALLOW_PRUNING = 1U << 20;