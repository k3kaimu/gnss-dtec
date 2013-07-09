/* Converted to D from fec.h by htod */
module fec;

import std.conv : octal;
/* User include file for libfec
 * Copyright 2004, Phil Karn, KA9Q
 * May be used under the terms of the GNU Lesser General Public License (LGPL)
 */

//C     #ifndef _FEC_H_
//C     #define _FEC_H_

//C     #ifdef __cplusplus
//C     extern "C"
//C     {
//C     #endif

/* r=1/2 k=7 convolutional encoder polynomials */
//C     #define	V27POLYA	0x4f
//C     #define	V27POLYB	0x6d
const V27POLYA = 0x4f;

const V27POLYB = 0x6d;
//C     void *create_viterbi27(int len);
extern (C):
void * create_viterbi27(int len);
//C     void set_viterbi27_polynomial(int polys[2]);
void  set_viterbi27_polynomial(int *polys);
//C     int init_viterbi27(void *vp,int starting_state);
int  init_viterbi27(void *vp, int starting_state);
//C     int update_viterbi27_blk(void *vp,unsigned char sym[],int npairs);
int  update_viterbi27_blk(void *vp, ubyte *sym, int npairs);
//C     int chainback_viterbi27(void *vp, unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi27(void *vp, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi27(void *vp);
void  delete_viterbi27(void *vp);

//C     #ifdef __VEC__
//C     void *create_viterbi27_av(int len);
//C     void set_viterbi27_polynomial_av(int polys[2]);
//C     int init_viterbi27_av(void *p,int starting_state);
//C     int chainback_viterbi27_av(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi27_av(void *p);
//C     int update_viterbi27_blk_av(void *p,unsigned char *syms,int nbits);
//C     #endif

//C     #ifdef __i386__
//C     void *create_viterbi27_mmx(int len);
//C     void set_viterbi27_polynomial_mmx(int polys[2]);
//C     int init_viterbi27_mmx(void *p,int starting_state);
//C     int chainback_viterbi27_mmx(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi27_mmx(void *p);
//C     int update_viterbi27_blk_mmx(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi27_sse(int len);
//C     void set_viterbi27_polynomial_sse(int polys[2]);
//C     int init_viterbi27_sse(void *p,int starting_state);
//C     int chainback_viterbi27_sse(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi27_sse(void *p);
//C     int update_viterbi27_blk_sse(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi27_sse2(int len);
//C     void set_viterbi27_polynomial_sse2(int polys[2]);
//C     int init_viterbi27_sse2(void *p,int starting_state);
//C     int chainback_viterbi27_sse2(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi27_sse2(void *p);
//C     int update_viterbi27_blk_sse2(void *p,unsigned char *syms,int nbits);
//C     #endif

//C     void *create_viterbi27_port(int len);
void * create_viterbi27_port(int len);
//C     void set_viterbi27_polynomial_port(int polys[2]);
void  set_viterbi27_polynomial_port(int *polys);
//C     int init_viterbi27_port(void *p,int starting_state);
int  init_viterbi27_port(void *p, int starting_state);
//C     int chainback_viterbi27_port(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi27_port(void *p, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi27_port(void *p);
void  delete_viterbi27_port(void *p);
//C     int update_viterbi27_blk_port(void *p,unsigned char *syms,int nbits);
int  update_viterbi27_blk_port(void *p, ubyte *syms, int nbits);

/* r=1/2 k=9 convolutional encoder polynomials */
//C     #define	V29POLYA	0x1af
//C     #define	V29POLYB	0x11d
const V29POLYA = 0x1af;

const V29POLYB = 0x11d;
//C     void *create_viterbi29(int len);
void * create_viterbi29(int len);
//C     void set_viterbi29_polynomial(int polys[2]);
void  set_viterbi29_polynomial(int *polys);
//C     int init_viterbi29(void *vp,int starting_state);
int  init_viterbi29(void *vp, int starting_state);
//C     int update_viterbi29_blk(void *vp,unsigned char syms[],int nbits);
int  update_viterbi29_blk(void *vp, ubyte *syms, int nbits);
//C     int chainback_viterbi29(void *vp, unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi29(void *vp, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi29(void *vp);
void  delete_viterbi29(void *vp);

//C     #ifdef __VEC__
//C     void *create_viterbi29_av(int len);
//C     void set_viterbi29_polynomial_av(int polys[2]);
//C     int init_viterbi29_av(void *p,int starting_state);
//C     int chainback_viterbi29_av(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi29_av(void *p);
//C     int update_viterbi29_blk_av(void *p,unsigned char *syms,int nbits);
//C     #endif

//C     #ifdef __i386__
//C     void *create_viterbi29_mmx(int len);
//C     void set_viterbi29_polynomial_mmx(int polys[2]);
//C     int init_viterbi29_mmx(void *p,int starting_state);
//C     int chainback_viterbi29_mmx(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi29_mmx(void *p);
//C     int update_viterbi29_blk_mmx(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi29_sse(int len);
//C     void set_viterbi29_polynomial_sse(int polys[2]);
//C     int init_viterbi29_sse(void *p,int starting_state);
//C     int chainback_viterbi29_sse(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi29_sse(void *p);
//C     int update_viterbi29_blk_sse(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi29_sse2(int len);
//C     void set_viterbi29_polynomial_sse2(int polys[2]);
//C     int init_viterbi29_sse2(void *p,int starting_state);
//C     int chainback_viterbi29_sse2(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi29_sse2(void *p);
//C     int update_viterbi29_blk_sse2(void *p,unsigned char *syms,int nbits);
//C     #endif

//C     void *create_viterbi29_port(int len);
void * create_viterbi29_port(int len);
//C     void set_viterbi29_polynomial_port(int polys[2]);
void  set_viterbi29_polynomial_port(int *polys);
//C     int init_viterbi29_port(void *p,int starting_state);
int  init_viterbi29_port(void *p, int starting_state);
//C     int chainback_viterbi29_port(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi29_port(void *p, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi29_port(void *p);
void  delete_viterbi29_port(void *p);
//C     int update_viterbi29_blk_port(void *p,unsigned char *syms,int nbits);
int  update_viterbi29_blk_port(void *p, ubyte *syms, int nbits);

/* r=1/3 k=9 convolutional encoder polynomials */
//C     #define	V39POLYA	0x1ed
//C     #define	V39POLYB	0x19b
const V39POLYA = 0x1ed;
//C     #define	V39POLYC	0x127
const V39POLYB = 0x19b;

const V39POLYC = 0x127;
//C     void *create_viterbi39(int len);
void * create_viterbi39(int len);
//C     void set_viterbi39_polynomial(int polys[3]);
void  set_viterbi39_polynomial(int *polys);
//C     int init_viterbi39(void *vp,int starting_state);
int  init_viterbi39(void *vp, int starting_state);
//C     int update_viterbi39_blk(void *vp,unsigned char syms[],int nbits);
int  update_viterbi39_blk(void *vp, ubyte *syms, int nbits);
//C     int chainback_viterbi39(void *vp, unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi39(void *vp, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi39(void *vp);
void  delete_viterbi39(void *vp);

//C     #ifdef __VEC__
//C     void *create_viterbi39_av(int len);
//C     void set_viterbi39_polynomial_av(int polys[3]);
//C     int init_viterbi39_av(void *p,int starting_state);
//C     int chainback_viterbi39_av(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi39_av(void *p);
//C     int update_viterbi39_blk_av(void *p,unsigned char *syms,int nbits);
//C     #endif

//C     #ifdef __i386__
//C     void *create_viterbi39_mmx(int len);
//C     void set_viterbi39_polynomial_mmx(int polys[3]);
//C     int init_viterbi39_mmx(void *p,int starting_state);
//C     int chainback_viterbi39_mmx(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi39_mmx(void *p);
//C     int update_viterbi39_blk_mmx(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi39_sse(int len);
//C     void set_viterbi39_polynomial_sse(int polys[3]);
//C     int init_viterbi39_sse(void *p,int starting_state);
//C     int chainback_viterbi39_sse(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi39_sse(void *p);
//C     int update_viterbi39_blk_sse(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi39_sse2(int len);
//C     void set_viterbi39_polynomial_sse2(int polys[3]);
//C     int init_viterbi39_sse2(void *p,int starting_state);
//C     int chainback_viterbi39_sse2(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi39_sse2(void *p);
//C     int update_viterbi39_blk_sse2(void *p,unsigned char *syms,int nbits);
//C     #endif

//C     void *create_viterbi39_port(int len);
void * create_viterbi39_port(int len);
//C     void set_viterbi39_polynomial_port(int polys[3]);
void  set_viterbi39_polynomial_port(int *polys);
//C     int init_viterbi39_port(void *p,int starting_state);
int  init_viterbi39_port(void *p, int starting_state);
//C     int chainback_viterbi39_port(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi39_port(void *p, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi39_port(void *p);
void  delete_viterbi39_port(void *p);
//C     int update_viterbi39_blk_port(void *p,unsigned char *syms,int nbits);
int  update_viterbi39_blk_port(void *p, ubyte *syms, int nbits);


/* r=1/6 k=15 Cassini convolutional encoder polynomials without symbol inversion
 * dfree = 56
 * These bits may be left-right flipped from some textbook representations;
 * here I have the bits entering the shift register from the right (low) end
 *
 * Some other spacecraft use the same code, but with the polynomials in a different order.
 * E.g., Mars Pathfinder and STEREO swap POLYC and POLYD. All use alternate symbol inversion,
 * so use set_viterbi615_polynomial() as appropriate.
 */
//C     #define	V615POLYA	042631
//C     #define	V615POLYB	047245
const V615POLYA = octal!42631;
//C     #define V615POLYC       056507
const V615POLYB = octal!47245;
//C     #define V615POLYD       073363
const V615POLYC = octal!56507;
//C     #define V615POLYE       077267
const V615POLYD = octal!73363;
//C     #define V615POLYF       064537
const V615POLYE = octal!77267;

const V615POLYF = octal!64537;
//C     void *create_viterbi615(int len);
void * create_viterbi615(int len);
//C     void set_viterbi615_polynomial(int polys[6]);
void  set_viterbi615_polynomial(int *polys);
//C     int init_viterbi615(void *vp,int starting_state);
int  init_viterbi615(void *vp, int starting_state);
//C     int update_viterbi615_blk(void *vp,unsigned char *syms,int nbits);
int  update_viterbi615_blk(void *vp, ubyte *syms, int nbits);
//C     int chainback_viterbi615(void *vp, unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi615(void *vp, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi615(void *vp);
void  delete_viterbi615(void *vp);

//C     #ifdef __VEC__
//C     void *create_viterbi615_av(int len);
//C     void set_viterbi615_polynomial_av(int polys[6]);
//C     int init_viterbi615_av(void *p,int starting_state);
//C     int chainback_viterbi615_av(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi615_av(void *p);
//C     int update_viterbi615_blk_av(void *p,unsigned char *syms,int nbits);
//C     #endif

//C     #ifdef __i386__
//C     void *create_viterbi615_mmx(int len);
//C     void set_viterbi615_polynomial_mmx(int polys[6]);
//C     int init_viterbi615_mmx(void *p,int starting_state);
//C     int chainback_viterbi615_mmx(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi615_mmx(void *p);
//C     int update_viterbi615_blk_mmx(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi615_sse(int len);
//C     void set_viterbi615_polynomial_sse(int polys[6]);
//C     int init_viterbi615_sse(void *p,int starting_state);
//C     int chainback_viterbi615_sse(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi615_sse(void *p);
//C     int update_viterbi615_blk_sse(void *p,unsigned char *syms,int nbits);

//C     void *create_viterbi615_sse2(int len);
//C     void set_viterbi615_polynomial_sse2(int polys[6]);
//C     int init_viterbi615_sse2(void *p,int starting_state);
//C     int chainback_viterbi615_sse2(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
//C     void delete_viterbi615_sse2(void *p);
//C     int update_viterbi615_blk_sse2(void *p,unsigned char *syms,int nbits);

//C     #endif

//C     void *create_viterbi615_port(int len);
void * create_viterbi615_port(int len);
//C     void set_viterbi615_polynomial_port(int polys[6]);
void  set_viterbi615_polynomial_port(int *polys);
//C     int init_viterbi615_port(void *p,int starting_state);
int  init_viterbi615_port(void *p, int starting_state);
//C     int chainback_viterbi615_port(void *p,unsigned char *data,unsigned int nbits,unsigned int endstate);
int  chainback_viterbi615_port(void *p, ubyte *data, uint nbits, uint endstate);
//C     void delete_viterbi615_port(void *p);
void  delete_viterbi615_port(void *p);
//C     int update_viterbi615_blk_port(void *p,unsigned char *syms,int nbits);
int  update_viterbi615_blk_port(void *p, ubyte *syms, int nbits);


/* General purpose RS codec, 8-bit symbols */
//C     void encode_rs_char(void *rs,unsigned char *data,unsigned char *parity);
void  encode_rs_char(void *rs, ubyte *data, ubyte *parity);
//C     int decode_rs_char(void *rs,unsigned char *data,int *eras_pos,
//C     		   int no_eras);
int  decode_rs_char(void *rs, ubyte *data, int *eras_pos, int no_eras);
//C     void *init_rs_char(int symsize,int gfpoly,
//C     		   int fcr,int prim,int nroots,
//C     		   int pad);
void * init_rs_char(int symsize, int gfpoly, int fcr, int prim, int nroots, int pad);
//C     void free_rs_char(void *rs);
void  free_rs_char(void *rs);

/* General purpose RS codec, integer symbols */
//C     void encode_rs_int(void *rs,int *data,int *parity);
void  encode_rs_int(void *rs, int *data, int *parity);
//C     int decode_rs_int(void *rs,int *data,int *eras_pos,int no_eras);
int  decode_rs_int(void *rs, int *data, int *eras_pos, int no_eras);
//C     void *init_rs_int(int symsize,int gfpoly,int fcr,
//C     		  int prim,int nroots,int pad);
void * init_rs_int(int symsize, int gfpoly, int fcr, int prim, int nroots, int pad);
//C     void free_rs_int(void *rs);
void  free_rs_int(void *rs);

/* CCSDS standard (255,223) RS codec with conventional (*not* dual-basis)
 * symbol representation
 */
//C     void encode_rs_8(unsigned char *data,unsigned char *parity,int pad);
void  encode_rs_8(ubyte *data, ubyte *parity, int pad);
//C     int decode_rs_8(unsigned char *data,int *eras_pos,int no_eras,int pad);
int  decode_rs_8(ubyte *data, int *eras_pos, int no_eras, int pad);

/* CCSDS standard (255,223) RS codec with dual-basis symbol representation */
//C     void encode_rs_ccsds(unsigned char *data,unsigned char *parity,int pad);
void  encode_rs_ccsds(ubyte *data, ubyte *parity, int pad);
//C     int decode_rs_ccsds(unsigned char *data,int *eras_pos,int no_eras,int pad);
int  decode_rs_ccsds(ubyte *data, int *eras_pos, int no_eras, int pad);

/* Tables to map from conventional->dual (Taltab) and
 * dual->conventional (Tal1tab) bases
 */
//C     extern unsigned char Taltab[],Tal1tab[];
extern __gshared ubyte* Taltab;
extern __gshared ubyte* Tal1tab;


/* CPU SIMD instruction set available */
//C     enum Cpu_mode {UNKNOWN=0,PORT,MMX,SSE,SSE2_=4,ALTIVEC};
enum Cpu_mode
{
    UNKNOWN,
    PORT,
    MMX,
    SSE,
    SSE2_,
    ALTIVEC,
}
//C     void find_cpu_mode(void); /* Call this once at startup to set Cpu_mode */
void  find_cpu_mode();

/* Determine parity of argument: 1 = odd, 0 = even */
//C     #ifdef __i386__
//C     static inline int parityb(unsigned char x){
//C       __asm__ __volatile__ ("test %1,%1;setpo %0" : "=q"(x) : "q" (x));
//C       return x;
//C     }
//C     #else
//C     void partab_init();
void  partab_init();

//C     static int parityb(unsigned char x){
//C       extern unsigned char Partab[256];
//C       extern int P_init;
//C       if(!P_init){
//C         partab_init();
//C       }
//C       return Partab[x];
//C     }
//C     #endif


//C     static int parity(int x){
int  parityb(ubyte );
  /* Fold down to one byte */
//C       x ^= (x >> 16);
//C       x ^= (x >> 8);
//C       return parityb(x);
//C     }

/* Useful utilities for simulation */
//C     double normal_rand(double mean, double std_dev);
int  parity(int );
double  normal_rand(double mean, double std_dev);
//C     unsigned char addnoise(int sym,double amp,double gain,double offset,int clip);
ubyte  addnoise(int sym, double amp, double gain, double offset, int clip);

//C     extern int Bitcnt[];
extern __gshared int* Bitcnt;

/* Dot product functions */
//C     void *initdp(signed short coeffs[],int len);
void * initdp(short *coeffs, int len);
//C     void freedp(void *dp);
void  freedp(void *dp);
//C     long dotprod(void *dp,signed short a[]);
int  dotprod(void *dp, short *a);

//C     void *initdp_port(signed short coeffs[],int len);
void * initdp_port(short *coeffs, int len);
//C     void freedp_port(void *dp);
void  freedp_port(void *dp);
//C     long dotprod_port(void *dp,signed short a[]);
int  dotprod_port(void *dp, short *a);

//C     #ifdef __i386__
//C     void *initdp_mmx(signed short coeffs[],int len);
//C     void freedp_mmx(void *dp);
//C     long dotprod_mmx(void *dp,signed short a[]);

//C     void *initdp_sse(signed short coeffs[],int len);
//C     void freedp_sse(void *dp);
//C     long dotprod_sse(void *dp,signed short a[]);

//C     void *initdp_sse2(signed short coeffs[],int len);
//C     void freedp_sse2(void *dp);
//C     long dotprod_sse2(void *dp,signed short a[]);
//C     #endif

//C     #ifdef __VEC__
//C     void *initdp_av(signed short coeffs[],int len);
//C     void freedp_av(void *dp);
//C     long dotprod_av(void *dp,signed short a[]);
//C     #endif

/* Sum of squares - accepts signed shorts, produces unsigned long long */
//C     unsigned long long sumsq(signed short *in,int cnt);
ulong  sumsq(short *in_, int cnt);
//C     unsigned long long sumsq_port(signed short *in,int cnt);
ulong  sumsq_port(short *in_, int cnt);

//C     #ifdef __i386__
//C     unsigned long long sumsq_mmx(signed short *in,int cnt);
//C     unsigned long long sumsq_sse(signed short *in,int cnt);
//C     unsigned long long sumsq_sse2(signed short *in,int cnt);
//C     #endif
//C     #ifdef __VEC__
//C     unsigned long long sumsq_av(signed short *in,int cnt);
//C     #endif


/* Low-level data structures and routines */

//C     int cpu_features(void);
int  cpu_features();

//C     #ifdef __cplusplus
//C     }  /* extern "C" */
//C     #endif /* __cplusplus */

//C     #endif /* _FEC_H_ */



