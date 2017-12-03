#Include HugeNumberUtil.BAS
#Include HugeDiviMultUtil.BAS
#Include HugeIntWrappers.BAS

Rem Modulus is static p - Koblitz SECP256K1
Eeprom Modulus@(0 To 32) = 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 255, 255, 252, 47

Function antiK(ByRef k() as Byte)
   Rem Using Extended Euclidian algorithm.
   Rem 0 AND 1 are invalid so check for K not being that. Return 0 otherwise or whatever.
   
   Rem Change to static length arrays to get it put in RAMheap OR use EEPROM arrays.
   Public Xmin2(0 To 31) as Byte
   Public Xmin2Sign as Byte
   Public Xmin1(0 To 31) as Byte
   Public Xmin1Sign as Byte
   
   Public Ymin2(0 To 31) as Byte
   Public Ymin2Sign as Byte
   Public Ymin1(0 To 31) as Byte
   Public Ymin1Sign as Byte
   
   Public Rmin1(0 To 31) as Byte
   Public Rmin0(0 To 31) as Byte
   Public Q(0 To 31) as Byte
   
   Rem Private T(0 To 63) as Byte
   REm Private T2(0 To 63) as Byte
   
   Public void@
   Public I as Byte
   
   Rem 1 Initialize:
   void@ = copyArray(Rmin1, Modulus@, 32)
   void@ = copyArray(Rmin0, k, 32)
   
   For I = 0 To 31 Step +1
      Xmin2(I) = 0
      Xmin1(I) = 0
      Ymin2(I) = 0
      Ymin1(I) = 0
   Next I
   Xmin2(31) = 1
   Ymin1(31) = 1
   
   Rem 2 Step:
   Rem Quotient/Remainder (if remainder==1 end algo):
   REM IntDivision(ByRef Numerator() as Byte, ByRef Divisor() as Byte, ByRef Quotient() as Byte, ByRef Remainder() as Byte, arrayLength as Byte) as Byte

   Rem void@ = IntDivision(Rmin1, Rmin0, Q, T, 32)
   REM (Leave A/B1 in A/B0 after copying at end step)
   Rem void@ = copyArray(T, Xmin1, 32)
   Rem void@ = copyArray(T2, Q, 32)
   Rem void@ = IntMultiply(T, T2, 64)
   REM void@ = M
   
   REM Xmin0 = Xmin2 - Xmin1*Q
   REM Ymin0 = Ymin2 - Ymin1*Q
   
   Rem 3 Final value:
   REM If X is negative, apply the modulus A to X to find the inverse of B in modA.
   
End Function