Rem 2kb RAM and 16kb EEPROM

Rem returns 1 if float large is larger than float small, else 0.
Function compare(large() as Byte, expLarge as Integer, small() as Byte, expSmall as Integer, arrayLength as Byte) as Byte
   compare = 0
   If expLarge > expSmall Then
      compare = 1
   Else If expSmall > expLarge Then
      compare = 0
   Else
      Rem harder, compare arrays:
      Private I as Byte
      For I = arrayLength-1 To 0 Step -1
         If large(I) > small(I) Then
            compare = 1
            Exit For
         Else If small(I) > large(I) Then
            compare = 0
            Exit For
         End If
      Next I
   End If
End Function

Rem Down shift.
Function RightShift(ByRef number() as Byte, shifts as Byte, arrayLength as Byte) as Byte
   Private X, Y, carry as Byte
   Private I as Integer
   X = shifts Mod 8
   Y = shifts / 8
   carry = 0
   
   Rem big byte shifts:
   For I = 0 To arrayLength
      If Y + I < arrayLength Then
         number(I) = number(Y+I)
      Else
         number(I) = 0
      End If
   Next I
   
   Rem bit shifts:
   Rem Carry all shifted bits down using Mod not just the first bit:
   If X > 0 Then
      For I = 0 To (arrayLength-2) Step +1
         number(I) = (number(I) ShrL X) + (number(I+1) Mod LongPow(2, X))*LongPow(2, 8-X)
         If I = (arrayLength-2) Then
            number(I+1) = number(I+1) ShrL X
         End If
      Next I
   End If
End Function

Function Plus(ByRef num1() as Byte, ByRef num1Exp as Integer, num2() as Byte, num2Exp as Integer, arrayLength as Byte) as Byte
   Private I, isNum1Larger as Byte
   Private carry as Byte
   carry = 0
   Private void@
   
   Rem down-shift array of smaller number:
   isNum1Larger = compare(num1, num1Exp, num2, num2Exp, arrayLength)
   
   If isNum1Larger = 1 Then
      void@ = RightShift(num2, num1Exp - num2Exp, arrayLength)
      num2Exp = num1Exp
   Else
      void@ = RightShift(num1, num2Exp - num1Exp, arrayLength)
      num1Exp = num2Exp
   End If
   
   Rem Do the addition:
   For I = 0 To (arrayLength-1) Step +1
      If num1(I) + num2(I) + carry > 255 Then
         num1(I) = num1(I)+num2(I)+carry-256
         carry = 1
      Else
         num1(I) = num1(I)+num2(I)+carry
         carry = 0
      End If
   Next I
End Function

Rem number is return.
Rem Minus = 1 for negative result.
Function Minus(number() as Byte, numExp as Integer, subtractor() as Byte, subExp as Integer, arrayLength as Byte) as Byte
   Private void@
   Rem find isNegResult, THEN do dependant logic, ignore same case:
   Minus = compare(subtractor, subExp, number, numExp, arrayLength)
   
   Rem Equalize exps/num arrays:
   Rem (By downshifting smaller number)
   If Minus = 1 Then
      void@ = RightShift(number, subExp - numExp, arrayLength)
      numExp = subExp
   Else
      void@ = RightShift(subtractor, numExp - subExp, arrayLength)
      subExp = numExp
   End If
   
   Private I as Byte
   Private negCarry as Byte
   negCarry = 0
   Rem Negative signs and exponents will be expressed separately.
   If Minus = 0 Then
      For I = 0 To (arrayLength-1) Step +1
         If number(I) - subtractor(I) - negCarry < 0 Then
            number(I) = number(I)-subtractor(I)-negCarry+256
            negCarry = 1
         Else
            number(I) = number(I)-subtractor(I)-negCarry
            negCarry = 0
         End If
      Next I
   Else
      For I = 0 To (arrayLength-1) Step +1
         If subtractor(I) - number(I) - negCarry < 0 Then
            number(I) = subtractor(I)-number(I)-negCarry+256
            negCarry = 1
         Else
            number(I) = subtractor(I)-number(I)-negCarry
            negCarry = 0
         End If
      Next I
   End If
End Function

Rem Up shift, return type is void. Subs will not allow more than one parameter. (Write ZC?)
Function LeftShift(number() as Byte, shifts as Byte, arrayLength as Byte) as Byte
   Private X, Y as Byte
   Private I as Byte
   X = shifts Mod 8
   Y = shifts / 8
   
   Rem big byte shifts:
   For I = arrayLength To 0 Step -1
      If I-Y >= 0 Then
         number(I) = number(I-Y)
      Else
         number(I) = 0
      End If
   Next I
   
   Rem bit shifts:
   Rem carry 1's to higher boxes and shift all 
   If X > 0 Then
      For I = arrayLength To 1 Step -1
         number(I) = (number(I) Shl X) + (number(I-1) ShrL (8-X))
         If I = 1 Then
            number(I-1) = number(I-1) Shl X
         End If
      Next I
   End If
End Function

Rem Scale to 0.5-1:
Rem Highest bit is 2^0, second highest 2^-1 and so on leading to a number 1->2 multiplied by
Rem 2^exponent - standard floating point representation.
Function IntToFloat(ByRef number() as Byte, ByRef exponent as Integer, arrayLength as Byte) as Byte
   Rem remove leading 0s/set exponent:
   exponent = 255
   Rem (256 bit means highest bit is 2^255, we will have 1 byte of decimals for precision during division=33bytes)
   Rem Count 0s:
   Private I as Integer
   Private upshifts as Byte
   upshifts = 0
   For I = (arrayLength-1) To 0 Step -1
      Rem 1, 2, 4, 8, 16, 32, 64, 128
      If number(I) > 0 Then
         If number(I) >= 128 Then
            upshifts = ((arrayLength-1)-I)*8 + 0
            Exit For
         Else If number(I) >= 64 Then
            upshifts = ((arrayLength-1)-I)*8 + 1
            Exit For
         Else If number(I) >= 32 Then
            upshifts = ((arrayLength-1)-I)*8 + 2
            Exit For
         Else If number(I) >= 16 Then
            upshifts = ((arrayLength-1)-I)*8 + 3
            Exit For
         Else If number(I) >= 8 Then
            upshifts = ((arrayLength-1)-I)*8 + 4
            Exit For
         Else If number(I) >= 4 Then
            upshifts = ((arrayLength-1)-I)*8 + 5
            Exit For
         Else If number(I) >= 2 Then
            upshifts = ((arrayLength-1)-I)*8 + 6
            Exit For
         Else If number(I) >= 1 Then
            upshifts = ((arrayLength-1)-I)*8 + 7
            Exit For
         End If
      End If
   Next I
   Private void@
   void@ = LeftShift(number, upshifts, arrayLength)
   exponent = exponent - upshifts
End Function

Rem Converts float array back to integer:
Function FloatToInt(ByRef number() as Byte, ByRef exponent as Integer, arrayLength as Byte) as Byte
   Rem Shift according to exponent:
   Private I as Byte
   Private void@
   If exponent >= 0 Then
      Rem exponent above zero the 1-2 number should be shifted down by 255-exponent and have excess digits cut off.
      If 254-exponent >= 0 Then
         void@ = RightShift(number, 254-exponent, arrayLength)
      Else
         void@ = LeftShift(number, exponent-255, arrayLength)
      End If
   Else
      Rem exponent below zero the 1-1.9999 float number is 0 as integer.
      For I = 0 To (arrayLength-1) Step +1
         number(I) = 0
      Next I
   End If
   exponent = 0
End Function

Function Scale(ByRef divisor() as Byte, ByRef DExponent as Integer, ByRef numerator() as Byte, ByRef NExponent as Integer, arrayLength as Byte) as Byte
   Rem Remove leading zeros:
   DExponent = IntToFloat(divisor, DExponent, arrayLength)
   NExponent = IntToFloat(numerator, NExponent, arrayLength)
   Rem Scale divisor to 0.5-1 and let numerator follow:
   Private scaling as Integer
   scaling = 1 + DExponent
   DExponent = DExponent - scaling
   NExponent = NExponent - scaling
End Function

Function copyArray(ByRef target() as Byte, origin() as Byte, arrayLength as Byte) as Byte
   Private I as Byte
   For I = 0 To (arrayLength-1) Step +1
      target(I) = origin(I)
   Next I
End Function

Function copyHuge(ByRef target() as Byte, ByRef targetExp as Integer, origin() as Byte, originExp as Integer, arrayLength as Byte) as Byte
   Private I as Byte
   For I = 0 To (arrayLength-1) Step +1
      target(I) = origin(I)
   Next I
   targetExp = originExp
End Function

Function round(ByRef number() as Byte, ByRef numExp as Integer, roundByte as Byte, arrayLength as Byte) as Byte
   Private I as Byte
   Private void@
   Private T(0 To arrayLength) as Byte
   Private Texp as Integer
   
   Private change as Byte
   change = 256-number(roundByte)
   
   If number(roundByte) > 128 Then
      For I = 0 To (arrayLength-1) Step +1
         If I = roundByte Then
            T(I) = change
         Else
            T(I) = 0
         End If
      Next I
      Texp = numExp
      void@ = Plus(number, numExp, T, Texp, arrayLength)
      For I = roundByte To (arrayLength-1) Step +1
         number(roundByte) = 0
      Next I
   Else
      number(roundByte) = 0
   End If
End Function