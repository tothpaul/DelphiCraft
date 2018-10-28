unit Execute.Inflate;
{
   Delphi Inflate Unit by Paul TOTH <tothpaul@free.fr>

   This code is based on the following:

      "inflate.c -- Not copyrighted 1992 by Mark Adler"
      version c10p1, 10 January 1993

   Written 1995 by Oliver Fromme <fromme@rz.tu-clausthal.de>.
   Donated to the public domain.

   Freely distributable, freely usable.
   Nobody may claim copyright on this code.

   Disclaimer:  Use it at your own risk.  I am not liable for anything.
}
{$R-,Q-}
interface

uses
  Execute.SysUtils;

type
// NB: Sender is for Object Method compatibilities
  TReadProc = procedure(Sender: Pointer; var Data; Size: NativeInt);
  TWriteProc = procedure(Sender: Pointer; const Data; Size: NativeInt);

  TReadMethod = procedure(var Data; Size: NativeInt) of object;
  TWriteMethod = procedure(const Data; Size: NativeInt) of object;

function InflateProcs(Read: TReadProc; Write: TWriteProc; Reader, Writer: Pointer): NativeInt;
function InflateMethods(Read: TReadMethod; Write: TWriteMethod): NativeInt;
function InflateStream(ASource, ATarget: TStream): Integer; inline;

implementation

const
 WSIZE = $8000;
 BMAX  = 16;  // maximum bit length of any code (16 for explode)
 N_MAX = 288; // maximum number of codes in any set

{Tables for deflate from PKZIP's appnote.txt.}

 border:array [0..18] of word = ( // Order of the bit length code lengths
  16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15
 );

 cplens:array [0..30] of word = ( // Copy lengths for literal codes 257..285
   3, 4, 5, 6, 7, 8, 9,10, 11, 13, 15, 17, 19, 23,27,
  31,35,43,51,59,67,83,99,115,131,163,195,227,258, 0, 0
 );

 cplext:array [0..30] of word = ( // Extra bits for literal codes 257..285
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
  3,3,3,3,4,4,4,4,5,5,5,5,0,99,99
 ); {99=invalid}

 cpdist:array [0..29] of word = ( //  Copy offsets for distance codes 0..29
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
  257,385,513,769,1025,1537,2049,3073,4097,6145,
  8193,12289,16385,24577
 );

 cpdext:array [0..29] of word = ( // Extra bits for distance codes
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,
  7,7,8,8,9,9,10,10,11,11,12,12,13,13
 );

 mask_bits:array [0..16] of word = (
  0,1,3,7,15,31,63,127,255,511,1023,
  2047,4095,8191,16383,32767,65535
 );

 lbits = 9; // bits in base literal/length lookup table
 dbits = 6; // bits in base distance lookup table

type
 phuft = ^huft ;
 huft = record
   e : byte ; {number of extra bits or operation}
   b : byte ; {number of bits in this code or subcode}
   v : record {this odd Record is just for easier Pas2C}
   case integer of
     0:(n:word);  {literal, length base, or distance base}
     1:(t:phuft); {pointer to next level of table}
   end
 end;
 pphuft=^phuft ;

var
 Slide:array[0..WSIZE-1] of byte;
 ReadSource : TReadMethod;
 WriteTarget: TWriteMethod;
 wp:word;     // current position in Slide
 bk:byte;     // bits in bit buffer
 bb:cardinal; // bit buffer, unsigned
 hufts:word;  // track memory usage

procedure NEEDBITS(n:byte);
var
  Src: Byte;
begin
 while bk < n do
 begin
   ReadSource(Src, 1);
   bb := bb or (Src shl bk);
   inc(bk,8);
 end;
end;

procedure DUMPBITS(n:byte);
begin
 bb:=bb shr n;
 dec(bk,n);
end;

function inflate_stored:integer;
var
 n:word;     // number of bytes in block
begin
 // go to byte boundary
 n:=bk and 7;
 DUMPBITS(n);
 // get the length and its complement
 NEEDBITS(16);
 n:=bb and $ffff;
 DUMPBITS(16);
 NEEDBITS(16);
 if n<>((not bb) and $ffff) then begin
  Result:=1; {error in compressed data}
  exit;
 end;
 DUMPBITS(16) ;
 // read and output the compressed data
 while n<>0 do begin
  dec(n);
  ReadSource(slide[wp], 1);
  inc(wp);
  if wp=WSIZE then begin
   WriteTarget(slide[0], wp);
   wp:=0
  end;
 end;
 Result:=0;
end;

function huft_build(
   b : pWord ;     {code lengths in bits (all assumed <= BMAX)}
   n : Word ;      {number of codes (assumed <= N_MAX)}
   s : Word ;      {number of simple-valued codes (0..s-1)}
   d : pWord ;     {list of base values for non-simple codes}
   e : pWord ;     {list of extra bits for non-simple codes}
   t : pphuft;     {result: starting table}
   m : pInteger    {maximum lookup bits, returns actual}
   ) : integer ;

var
 c:array [0..BMAX] of word;    // bit length count table
 p:pword;                      // pointer into c[], b[], or v[] (register variable)
 i:word;                       // counter, current code (register variable)
 a:word;                       {counter for codes of length k}
 f : word ;                    {i repeats in table every f entries}
 g : Integer ;                 {maximum code length}
 h : Integer ;                 {table level}
 j : Word ;                    {counter (register variable)}
 k : Integer ;                 {number of bits in current code (register variable)}
 l : Integer ;                 {bits per table (returned in m)}
 q : phuft ;                   {points to current table (register variable)}
 r : huft ;                    {table entry for structure assignment}
 u : Array [0..BMAX-1] Of phuft ;{table stack}
 v : Array [0..N_MAX-1] Of Word ;{values in order of bit length}
 w : Integer ;                 {bits before this table = (l*h) (register variable)}
 x : Array [0..BMAX] Of Word ; {bit offsets, then code stack}
 xp : pWord ;                  {pointer into x}
 y : Integer ;                 {number of dummy codes added}
 z : Word ;                    {number of entries in current table}
 alloc_tmp : Word ;
 phuft_tmp : phuft ;
 pword_tmp : pWord ;
begin
 // Generate counts for each bit length
 Fillchar(c,SizeOf(c),0);
 p:=b;
 for i:=0 to n-1 do begin
  inc(c[p^]); // assume all entries <= BMAX
  inc(p);
 end;
 if c[0]=n then begin // null input--all zero length codes
  t^:=nil;
  m^:=0;
  Result:=0;
  exit;
 end;

 // Find minimum and maximum length, bound m^ by those
 l:=m^;
 j:=1; while (j<=BMAX) and (c[j]=0) do inc(j);
 k:=j; // minimum code length
 if l<j then l:=j;
 i:=BMAX; while (i>0)and(c[i]=0) do dec(i);
 g:=i; // maximum code length
 if l>i then l:=i;
 m^:=l;

 // Adjust last length count to fill out codes, if needed
 y:=1 shl j;
 while j<i do begin
  dec(y,c[j]);
  if y<0 then begin
   Result:=2; // bad input: more codes than bits
   exit;
  end;
  inc(j);
  inc(y,y);
 end;
 dec(y,c[i]);
 if y<0 then begin
  Result:=2; // bad input: more codes than bits
  exit;
 end;
 inc(c[i],y);

 // Generate starting offsets into the value table for each length
 x[1]:=0;
 j:=0;
 p :=Addr(c[1]);
 xp:=Addr(x[2]);
 dec(i); // note that i=g from above
 while i<>0 do begin
  inc(j,p^);
  inc(p);
  xp^:=j;
  inc(xp);
  dec(i);
 end;

 // Make a table of values in order of bit lengths
 p:=b;
 i:=0;
 repeat
  j:=p^;
  inc(p);
  if j<>0 then begin
   v[x[j]]:=i;
   inc(x[j]);
  end;
  inc(i);
 until i>=n;

 // Generate the Huffman codes and for each, make the table entries
 x[0]:=0;    // first Huffman code is zero
 i:=0;
 p:=Addr(v); // grab values in bit order
 h:=-1;      // no tables yet--level -1
 w:=-l;      // bits decoded = (l*h)
 u[0]:=nil;  // just to keep compilers happy
 q:=nil;     // ditto
 z:=0;       // ditto

 // go through the bit lengths (k already is bits in shortest code)
 while k<=g do begin
  a:=c[k];
  while (a>0) do begin
   dec(a);
   // here i is the Huffman code of length k bits for value *p
   // make tables up to required level
   while k>w+l do begin
    inc(h);
    inc(w,l);            // previous table always l bits
                         // compute minimum size table less than or equal to l bits
    if g-w>l then        // upper limit on table size
     z:=l
    else
     z:=g-w;
    j:=k-w;            // try a k-w bit table
    f:=1 shl j;
    if f>a+1 then begin // too few codes for k-w bit table
     dec(f,a+1);        // deduct codes from patterns left
     xp:=Addr(c[k]);
     inc(j);
     while j<z do begin // try smaller tables up to z bits
      f:=f shl 1;
      inc(xp);
      if f<=xp^ then break; // enough codes to use up j bits
      dec(f,xp^);    // else deduct codes from patterns
      inc(j);
     end;
    end;
    z:=1 shl j;        // table entries for j-bit table
                       // allocate and link in new table
    alloc_tmp:=2+(z+1)*SizeOf(huft);
    GetMem(q,alloc_tmp);
    pWord(q)^:=alloc_tmp;
    inc(cardinal(q),2);
    inc(hufts,z+1);      // track memory usage
    t^:=q; inc(t^);      // link to list for huft_free()
    t :=Addr(q^.v.t);
    t^:=nil;
    inc(q);
    u[h]:=q;            // table starts after link
    // connect to last table, if there is one
    if h<>0 then begin
     x[h]:=i;        // save pattern for backing up
     r.b:=l;         // bits to dump before this table
     r.e:=16+j;      // bits in this table
     r.v.t:=q;       // pointer to this table
     j:=i shr (w-l); // (get around Turbo C bug)
     {u[h-1][j] := r}
     phuft_tmp:=u[h-1];
     inc(phuft_tmp,j);
     phuft_tmp^:=r;  // connect to last table
    end;
   end;
   // set up table entry in r
   r.b:=byte(k-w);
   if cardinal(p)>=cardinal(@(v[n])) then
    r.e:=99            // out of values--invalid code
   else if p^<s then begin
    if p^<256 then     // 256 is end-of-block code
     r.e:=16
    else
     r.e:=15;
    r.v.n:=p^;         // simple code is just the value
    inc(p);
   end else begin
    pword_tmp:=e;
    inc(pword_tmp,p^-s);
    r.e:=pword_tmp^;  // non-simple--look up in lists
    pword_tmp:=d;
    inc(pword_tmp,p^-s);
    r.v.n:=pword_tmp^;
    inc(p)
   end;
   // fill code-like entries with r
   f:=1 shl (k-w);
   j:=i shr w;
   while j<z do begin
    phuft_tmp:=q;
    inc(phuft_tmp,j);
    phuft_tmp^:=r;
    inc(j,f);
   end;
   // backwards increment the k-bit code i
   j:=1 shl (k-1);
   while (i and j)<>0 do begin
    i:=i xor j;
    j:=j shr 1;
   end;
   i:=i xor j;
   // backup over finished tables
   while (i and (1 shl w -1))<>x[h] do begin
    dec(h); // don't need to update q
    dec(w,l);
   end;

  end;
  // dec(a);
  inc(k);
 end;
 // Return 1 if we were given an incomplete table
 if (y<>0) and (g<>1) then
  huft_build:=1
 else
  huft_build:=0;
end;

procedure huft_free(t:phuft {table to free});
var
 p,q : phuft; {(register variables)}
 alloc_tmp : Word;
begin
 // Go through linked list, freeing from the malloced (t[-1]) address.
 p := t;
 while p <> nil do begin
  dec(p);
  q := p^.v.t;
  Dec(cardinal(p),2);
  alloc_tmp := (pWord(p))^;
  FreeMem(p,alloc_tmp);
  p := q;
 end;
end ;


function inflate_codes(
 tl,td : phuft ; {literal/length and distance decoder tables}
 bl,bd : Integer {number of bits decoded by tl[] and td[]}
):integer ;
var
 e:word ;     {table entry flag/number of extra bits (register variable)}
 n,d:Word ;   {length and index for copy}
 t : phuft ;    {pointer to table entry}
 ml,md : Word ; {masks for bl and bd bits}
begin
 // inflate the coded data
 ml := mask_bits[bl]; {precompute masks for speed}
 md := mask_bits[bd];
 while true do begin // do until end of block
  NEEDBITS(bl);
  t := tl;
  inc(t,bb and ml);
  e := t^.e;
  if e > 16 then
   repeat
    if e = 99 then begin
     Result:=1;
     exit;
    end;
    DUMPBITS(t^.b);
    dec(e,16);
    NEEDBITS(e);
    t := t^.v.t;
    inc(t,bb and mask_bits[e]);
    e := t^.e;
   until e <= 16;
   DUMPBITS(t^.b);
   if e = 16 then begin // it's a literal
    slide[wp] := t^.v.n;
    Inc(wp);
    If wp=WSIZE Then Begin
//     move(Slide[0],Dst^,wp);
//     inc(Dst,wp);
     WriteTarget(Slide[0], wp);
     wp:=0;
    end;
   end else begin // it's an EOB or a length
                  // exit if end of block
   if e=15 then break;
   // get length of block to copy
   NEEDBITS(e);
   n := t^.v.n+(bb And mask_bits[e]);
   DUMPBITS(e);
   // decode distance of block to copy
   NEEDBITS(bd);
   t := td;
   inc(t,bb and md);
   e := t^.e;
   if e > 16 then
    repeat
     if e = 99 then begin
      Result:=1;
      exit;
     end;
     DUMPBITS(t^.b);
     dec(e,16);
     NEEDBITS(e);
     t := t^.v.t;
     inc(t,bb and mask_bits[e]);
     e := t^.e;
    until e <= 16;
   DUMPBITS(t^.b);
   NEEDBITS(e);
   d := wp - t^.v.n - Word(bb And mask_bits[e]);
   DUMPBITS(e);
   // do the copy
   repeat
    d := d And(WSIZE-1);
    if d > wp Then
     e := WSIZE-d
    else
     e := WSIZE-wp;
    if e > n Then e := n;
    Dec(n,e);
    while e > 0 do begin
     slide[wp] := slide[d];
     inc(wp);
     inc(d);
     dec(e);
    end;
    if wp=WSIZE then begin
//     Move(Slide[0],Dst^,wp);
//     inc(Dst,wp);
     WriteTarget(Slide[0], wp);
     wp:=0;
    end
   until n=0;
  end;
 end;
//done
 Result:= 0;
end;

function inflate_fixed:integer;
var
 i :integer;  // temporary variable
 tl:phuft;    // literal/length code table
 td:phuft;    // distance code table
 bl:integer;  // lookup bits for tl
 bd:integer;  // lookup bits for td
 l :array [0..287] of word ; // length list for huft_build
begin
 // set up literal table
 for i:=0   to 143 do l[i]:=8;
 for i:=144 to 255 do l[i]:=9;
 for i:=256 to 279 do l[i]:=7;
 for i:=280 to 287 do l[i]:=8;

 bl:=7;
 Result:=huft_build(@l,288,257,@cplens,@cplext,Addr(tl),Addr(bl));
 if Result<>0 then exit;
 try
  // set up distance table
  for i:=0 to 29 do l[i]:=5;// make an incomplete code set
  bd:=5;
  Result:=huft_build(@l,30,0,@cpdist,@cpdext,Addr(td),Addr(bd));
  if Result>1 then exit;
  // decompress until an end-of-block code
  Result:=inflate_codes(tl,td,bl,bd);
  huft_free(td);
 finally
  huft_free(tl);
 end;
end;

function inflate_dynamic:integer;
var
 i : Integer;  {temporary variables}
 j : Word;
 l : Word;     {last length}
 m : Word;     {mask for bit lengths table}
 n : Word;     {number of lengths to get}
 tl : phuft;   {literal/length code table}
 td : phuft;   {distance code table}
 bl : Integer; {lookup bits for tl}
 bd : Integer; {lookup bits for td}
 nb : Word;    {number of bit length codes}
 nl : Word;    {number of literal/length codes}
 nd : Word;    {number of distance codes}
 ll : Array[0..286+30-1] Of Word;  {literal/length and distance code lengths}
begin
 // read in table lengths
 NEEDBITS(5);
 nl := 257+(bb And $1f); {number of literal/length codes}
 DUMPBITS(5);
 NEEDBITS(5);
 nd := 1+(bb And $1f); {number of distance codes}
 DUMPBITS(5);
 NEEDBITS(4);
 nb := 4+(bb And $f); {number of bit length codes}
 DUMPBITS(4);
 If (nl>286) Or (nd > 30) Then Begin
  Result:=1; {bad lengths}
  exit;
 end;
 // read in bit-length-code lengths
 for j:=0 To nb-1 Do Begin
  NEEDBITS(3);
  ll[border[j]] := bb And 7;
  DUMPBITS(3);
 end ;
 for j:=nb to 18 do ll[border[j]] := 0;
 // build decoding table for trees--single level, 7 bit lookup
 bl := 7;
 Result:=huft_build(@ll,19,19,NIL,NIL,Addr(tl),Addr(bl));
 if Result<>0 then begin {incomplete code set}
  if Result=1 then huft_free(tl);
  exit;
 end;
 // read in literal and distance code lengths}
 n := nl+nd;
 m := mask_bits[bl];
 l := 0;
 i := 0;
 while i<n do begin
  NEEDBITS(bl);
  td := tl;
  Inc (td,bb And m);
  j := td^.b;
  DUMPBITS (j);
  j := td^.v.n;
  If j < 16 Then Begin {length of code in bits (0..15)}
   l := j; {save last length in l}
   ll[i] := j;
   Inc(i);
  end else if j = 16 Then Begin {repeat last length 3 to 6 times}
   NEEDBITS(2);
   j := 3+(bb And 3);
   DUMPBITS(2);
   If i+j>n Then Begin
    Result:= 1;
    exit;
   end;
   while j <> 0 Do Begin
    Dec(j);
    ll[i] := l;
    Inc(i);
   end;
  // Dec(j);
  end else If j = 17 Then Begin {3 to 10 zero length codes}
   NEEDBITS(3);
   j := 3+(bb And 7);
   DUMPBITS(3);
   If i+j > n Then Begin
    Result:= 1;
    exit;
   end;
   While j <> 0 Do Begin
    Dec(j);
    ll[i] := 0;
    Inc(i);
   end;
  // dec(j);
   l := 0;
  end else Begin {j=18: 11 to 138 zero length codes}
   NEEDBITS(7);
   j := 11+(bb And $7f);
   DUMPBITS(7);
   If i+j > n Then Begin
    Result:= 1;
    exit
   end ;
   While j <> 0 Do Begin
    Dec(j);
    ll[i] := 0;
    Inc(i)
   end;
  // Dec(j);
   l := 0;
  end
 end;
 // free decoding table for trees
 huft_free(tl);
 // build the decoding tables for literal/length and distance codes
 bl := lbits;
 Result:=huft_build(@ll,nl,257,@cplens,@cplext,Addr(tl),Addr(bl));
 if Result <> 0 Then Begin
  if Result = 1 Then huft_free(tl);
  exit;
 end;
 bd := dbits;
 Result:= huft_build(@(ll[nl]),nd,0,@cpdist,@cpdext,Addr(td),Addr(bd));
 If Result<>0 then begin
  if Result= 1 then huft_free (td);
  huft_free (tl);
  exit;
 end;
 // decompress until an end-of-block code
 Result:=inflate_codes(tl,td,bl,bd);
 huft_free (tl);
 huft_free (td);
end;

function inflate_block(e:pInteger {last block flag}):integer;
var
 t:word;     // block type
begin
 // read in last block bit
 NEEDBITS(1);
 e^:= bb and 1;
 DUMPBITS(1);
 // read in block type
 NEEDBITS(2);
 t := bb and 3;
 DUMPBITS(2);
 // inflate that block type
 case t of
   0 : Result:=inflate_stored;
   1 : Result:=inflate_fixed;
   2 : Result:=inflate_dynamic;
  else Result:=2 {bad block type};
 end;
end;

//function Inflate(const SrcData,DstBuffer):integer;
//var
// e:integer; // last block flag
// h:word;    // maximum struct huft's malloc'ed
//begin
// Src:=@SrcData;
// Dst:=@DstBuffer;
// // initialize window, bit buffer
// wp:=0;
// bk:=0;
// bb:=0;
// // decompress until the last block
// h:=0;
// repeat
//  hufts:=0;
//  Result:=inflate_block(Addr(e));
//  if Result<>0 then exit;
//  if hufts>h then h:=hufts;
// until e<>0;
// // flush out slide, return error code
// Move(Slide[0],Dst^,wp);
// Result:=0;
//end;

function Inflate: NativeInt;
var
  e: Integer; // last block flag
  h: Word;    // maximum struct huft's malloc'ed
begin
  // initialize window, bit buffer
  wp := 0;
  bk := 0;
  bb := 0;
 // decompress until the last block
  h := 0;
  repeat
    hufts := 0;
    Result := inflate_block(Addr(e));
    if Result <> 0 then
      Exit;
    if hufts > h then
      h := hufts;
  until e <> 0;
 // flush out slide, return error code
  WriteTarget(Slide[0], wp); // Move(Slide[0],Dst^,wp);
  Result := 0;
end;

function InflateMethods(Read: TReadMethod; Write: TWriteMethod): NativeInt;
begin
  ReadSource := Read;
  WriteTarget := Write;
  Result := Inflate();
end;

function InflateProcs(Read: TReadProc; Write: TWriteProc; Reader, Writer: Pointer): NativeInt;
begin
  TMethod(ReadSource).Code := @Read;
  TMethod(ReadSource).Data := Reader;
  TMethod(WriteTarget).Code := @Write;
  TMethod(WriteTarget).Data := Writer;
  Result := Inflate();
end;

function InflateStream(ASource, ATarget: TStream): Integer;
begin
  Result := InflateMethods(ASource.ReadBuffer, ATarget.WriteBuffer);
end;

end.


