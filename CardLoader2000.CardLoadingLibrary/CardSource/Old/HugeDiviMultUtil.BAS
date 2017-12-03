Rem needs HugeNumerUtil

Rem TODO: Simple multiplication, first number is result, byte return for "Void":
Function HugeMultiply(ByRef number1() as Byte, ByRef exp1 as Integer, number2() as Byte, exp2 as Integer, arrayLength as Byte) as Byte
   Rem TODO: Wiki float multiplication.. NO INFO. Self invent.
   Private void@
   Rem 0. Expect float format and make result float format.
   Rem 1. Exps add.
   Private newExp as Integer
   newExp = exp1+exp2
   Rem 2. Calculate max index of result.. float format would mean result is always 1-4?
   Rem YES cut all result below a certain index (0) If result is 2 or above shift it 1 bit down.

   Rem 3. Multiply:
   Rem J is number2
   Private raw, temp as Long
   Private result(0 To arrayLength) as Byte
   Private carry as Byte
   carry = 0
   Rem Downshit multiplication result 7 places.
   Rem This corrects for using bytes instead of real bits.
   Private I, J as Byte
   For I = 0 To (arrayLength-1)
      For J = 0 To (arrayLength-1)
         If I+J >= arrayLength Then
            Rem Raw multiplication result:
            raw = number1(I) * number2(J)
            Rem Underflow + carry to present index, (1*1 right-shifted 7 is less than 1):
            If  J+I-arrayLength >= 0 Then
               Rem add res shl 1 to index-1 (same as downshift by 7):
               temp = result(I+J-arrayLength) + ((raw Mod 128) Shl 1)
               
               result(I+J-arrayLength) = temp Mod 256
               Rem "overflow" to present index:
               If temp > 255 Then
                  carry = 1
               Else
                  carry = 0
               End If
            End If
            
            Rem Present index + carry to higher index:
            temp = result(I+J+1-arrayLength) + (raw ShrL 7) + carry
            result(I+J+1-arrayLength) = temp Mod 256
            
            Rem handle overflow:
            If temp > 255 Then
               Rem Detect result overflow:
               If I+J+2-arrayLength < arrayLength Then
                  Rem Carry to higher index:
                  result(I+J+2-arrayLength) = result(I+J+2-arrayLength) + 1
               Else
                  Rem Handle overflow, otherwise result is done.
                  Rem Down-shift result 1 bit, add 128 to highest byte:
                  void@ = RightShift(result, 1, arrayLength)
                  result(arrayLength-1) = result(arrayLength-1) + 128
                  newExp = newExp + 1
               End If
            End If
         End If
      Next J
   Next I
   
   Rem 4: Put result in number1:
   void@ = copyArray(number1, result, arrayLength)
   exp1 = newExp
   
End Function


Rem TODO: Newton-Raphson division + result check/correction:
Function HugeDivide(ByRef numerator() as Byte, numExp as Integer, ByRef divisor() as Byte, divExp as Integer, ByRef Quotient() as Byte, ByRef quoExp as Integer, ByRef Remainder() as Byte, ByRef remExp as Integer, arrayLength as Byte) as Byte
   Rem NOTE: This division algo expects 32 (+1 for precision) byte float numbers and will return 33 byte float numbers. Caller will have to do any conversions.
   
   Private void@
   
   Rem 1 Find X0:
   Rem 1a 48 and 32 constant:
   Private constant48(0 To arrayLength-1) as Byte
   Private constant32(0 To arrayLength-1) as Byte
   Private I, J as Integer
   For I = 0 To (arrayLength-1) Step +1
      constant48(I) = 180
      Rem exp48 = 1
      constant32(I) = 240
      Rem exp32 = 0
   Next I
   Rem 1b scale D and N:
   Private expChange as Integer
   expChange = divExp+1
   divExp = -1
   
   Rem 1c calc X0:
   Private T(0 To arrayLength-1) as Byte
   Private Texp as Integer
   Rem Temp var:
   Private T2(0 To arrayLength-1) as Byte
   Private T2exp as Integer
   Private Xi(0 To arrayLength-1) as Byte
   Private Xiexp as Integer
   
   Texp = 0
   void@ = copyArray(T, constant32, arrayLength)
   Rem This will copy integer divisor array of 32 byte into integer T2 array of 33 bytes:
   void@ = HugeMultiply(T, Texp, divisor, divExp, arrayLength)
   Rem Minus, result should never be negative:
   void@ = copyHuge(T2, T2exp, constant48, 1, arrayLength)
   void@ = Minus(T2, T2exp, T, Texp, arrayLength)
   Rem Here is X0:
   void@ = copyHuge(Xi, Xiexp, T2, T2exp, arrayLength)
   void@ = copyHuge(T, Texp, T2, T2exp, arrayLength)
   
   Rem 2: Repeat alogrithm 6 times:
   Rem Algo: Xi+1= Xi+Xi*(1-D*Xi)
   For I = 0 To (6) Step +1
      void@ = HugeMultiply(T, Texp, divisor, divExp, arrayLength)
      
      Rem The "1":
      For J = 0 To (arrayLength-1) Step +1
         T2(J) = 0
      Next J
      T2(arrayLength) = 128
      T2exp = 0
      void@ = Minus(T, Texp, T2, T2exp, arrayLength)
      
      void@ = HugeMultiply(T, Texp, Xi, Xiexp, arrayLength)
      void@ = Plus(T, Texp, Xi, Xiexp, arrayLength)
      
      void@ = copyHuge(Xi, Xiexp, T, Texp, arrayLength)
   Next I
   
   Rem 3: Find result and test etc.:
   Rem Quotient and Remainder will always be 32 byte, be integers and have exps of 0/nothing.
   
   Rem numerator is now integer and exp is 0. It has not been used yet. expChange contains the scaling information.
   Rem numerator must be put in Quotient, converted to float, multiplied with Xs and finally converted back to int.
   Rem Quotient has different length from numerator...
   Rem Move 32 bytes to 33 byte array:
   void@ = copyHuge(T, Texp, numerator, numExp, arrayLength)
   Rem Down-scale:
   Texp = Texp - expChange
   Rem Multiply inverse with numerator and scale back up:
   void@ = HugeMultiply(T, Texp, Xi, Xiexp, arrayLength)
   Rem Re-scale:
   Texp = Texp + expChange
   Rem Return Quotient in float form here:
   void@ = copyHuge(Quotient, quoExp, T, Texp, arrayLength)
   Rem Return Remainder in float form here:
   void@ = HugeMultiply(T, Texp, divisor, divExp, arrayLength)
   void@ = copyHuge(Remainder, remExp, numerator, numExp, arrayLength)
   Rem Subtract the product of the quotient and the divisor from the numerator to get the remainder:
   void@ = Minus(Remainder, remExp, T, Texp, arrayLength)
End Function