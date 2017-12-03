REM Needs HugeNumberUtil and HugeDiviMultiUtil in that order.

Rem TODO: Wrapper for divFunc/tests
Rem Takes and returns 32 byte integers:
Function IntDivision(ByRef Numerator() as Byte, ByRef Divisor() as Byte, ByRef Quotient() as Byte, ByRef Remainder() as Byte, arrayLength as Byte) as Byte
   Private void@
   Rem convert to 33 byte float:
   Private N(0 To arrayLength) as Byte
   Private Nexp as Integer
   Private Q(0 To arrayLength) as Byte
   Private Qexp as Integer
   Private D(0 To arrayLength) as Byte
   Private Dexp as Integer
   Private R(0 To arrayLength) as Byte
   Private Rexp as Integer
   Private T(0 To arrayLength) as Byte
   Private Texp as Integer
   Private T2(0 To arrayLength) as Byte
   Private T2exp as Integer
   Private T3(0 To arrayLength) as Byte
   Private T3exp as Integer
   
   void@ = copyArray(N, Numerator, arrayLength)
   void@ = IntToFloat(N, Nexp, arrayLength+1)
   void@ = copyArray(Q, Quotient, arrayLength)
   void@ = IntToFloat(Q, Qexp, arrayLength+1)
   void@ = copyArray(R, Remainder, arrayLength)
   void@ = IntToFloat(R, Rexp, arrayLength+1)
   void@ = copyArray(D, Divisor, arrayLength)
   void@ = IntToFloat(D, Dexp, arrayLength+1)
   
   Rem Divide:
   void@ = HugeDivide(N, Nexp, D, Dexp, Q, Qexp, R, Rexp, arrayLength+1)
   
   Rem Check results/round up/down:
   Rem Simple rounding: Round highest bit of byte 33 and cut to 32 byte.
   Rem If remainder larger than divisor? + simple rounding. Continue until remainder less than div.
   Rem Check Q too large, No. Newton-Raphson division should go up approaching a limit.
   
   Private I as Byte
   For I = 0 To (arrayLength) Step +1
      If I = arrayLength-1 Then
         T2(I) = 128
      Else
         T2(I) = 0
      End If
   Next I
   T2exp = 0
   
   void@ = copyHuge(T, Texp, Q, Qexp, arrayLength+1)
   void@ = round(T, Texp, arrayLength, arrayLength+1)
   void@ = copyHuge(T3, T3exp, T, Texp, arrayLength+1)
   void@ = HugeMultiply(T3, T3exp, D, Dexp, arrayLength+1)
   void@ = compare(N, Nexp, T3, T3exp, arrayLength+1)
   
   While void@ = 1
      void@ = copyHuge(Q, Qexp, T, Texp, arrayLength+1)
      void@ = Plus(T, Texp, T2, T2exp, arrayLength+1)
      void@ = copyHuge(T3, T3exp, T, Texp, arrayLength+1)
      void@ = HugeMultiply(T3, T3exp, D, Dexp, arrayLength+1)
      void@ = compare(N, Nexp, T3, T3exp, arrayLength+1)
   Wend
   
   Rem Convert back to 32 byte int:
   void@ = copyArray(Quotient, Q, arrayLength)
   void@ = FloatToInt(Quotient, Qexp, arrayLength)
   
   void@ = copyArray(Remainder, R, arrayLength)
   void@ = FloatToInt(Remainder, Rexp, arrayLength)
End Function

REM Result in first number:
Function IntMultiply(ByRef number1() as Byte, number2() as Byte, arrayLength as Byte) as Byte
   Private void@ as Byte
   
   Private T(0 To arrayLength) as Byte
   Private Texp as Integer
   Private T2(0 To arrayLength) as Byte
   Private T2exp as Integer
   
   void@ = copyArray(T, number1, arrayLength)
   void@ = copyArray(T2, number2, arrayLength)
   void@ = IntToFloat(T, Texp, arrayLength+1)
   void@ = IntToFloat(T2, T2exp, arrayLength+1)
   
   void@ = HugeMultiply(T, Texp, T2, T2exp, arrayLength)
   
   void@ = FloatToInt(T, Texp, arrayLength)
   void@ = copyArray(number1, T, arrayLength)
End Function

Function IntMinus(number() as Byte, subtractor() as Byte, arrayLength as Byte) as Byte

End Function