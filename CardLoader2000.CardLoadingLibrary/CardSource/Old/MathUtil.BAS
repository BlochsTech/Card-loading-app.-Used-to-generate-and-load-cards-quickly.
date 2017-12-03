Function AbsDiff(number1 as Single, number2 as Single) as Single
   If (number1 > number2) Then
      AbsDiff = (number1-number2)
   Else
      AbsDiff = (number2-number1)
   End If
End Function

Rem Function BTCValid(address as String*35) as Byte COMMENTED AS WE NO LONGER USE SIMPLE ADDRESS STRINGS.
Rem   If (Mid$(address, 1, 1) = "1" Or Mid$(address, 1, 1) = "3")_
Rem      And Len(address) > 32 Then
Rem      BTCValid = 1
Rem   Else
Rem      BTCValid = 0
Rem   End If
   Rem TODO:
   Rem Is this worth it? No, terminals problem, do it later.
   Rem How to: First number is address type 1/3, following is base58
   Rem Convert this to hex bytes. <-- Non trivial, simple sanity check for now.
   Rem Do hashing and checking.
Rem End Function

Rem This test passes:
Rem GlobalDebugValue$ = "8:"+Str$(LogN(999999000,10))+"  8:"+Str$(LogN(100000000,10))+"  1:"+Str$(LogN(99.9999,10))+"  1:"+Str$(LogN(10.0,10))+"  0:"+Str$(LogN(1.0,10))+"  -1:"+Str$(LogN(0.1,10))+"  -1:"+Str$(LogN(0.999999,10))+"  -8:"+Str$(LogN(0.00000001,10))+"  -8:"+Str$(LogN(0.0000000999999,10))
Function LogN (ByVal X as Single, N as Integer) as Integer
   LogN = 0
   If X >= 1 Then
      While (X >= N)
         X = X / N
         LogN = LogN + 1
      Wend
   Else If X <> 0 Then
      LogN = - 1
      X = X * N
      While (X < 1)
         X = X * N
         LogN = LogN - 1
      Wend
      If X + 0.000001 >= N Then
         LogN = LogN + 1
      End If
   End If
End Function

Rem So does this:
Rem GlobalDebugValue$ = "10:"+Str$(SPow(10.0,10))+"  1:"+Str$(SPow(10.0,1))+"  0:"+Str$(SPow(10.0,0))+"  -1:"+Str$(SPow(10.0,-1))+"  -10:"+Str$(SPow(10.0,-10))
Function SPow (X as Single, Exp as Integer) as Single
   Private I as Integer
   I = 0
   SPow = 1
   If Exp > 0 Then
      While (I < Exp)
         SPow = SPow * X
         I = I + 1
      Wend
   Else If Exp < 0 Then
      Private tmp as Single
      tmp = 1.0
      While (I < -Exp)
         tmp = tmp * X
         I = I + 1
      Wend
      SPow = 1.0/tmp 
   End If
End Function

Function LongPow (X as Long, Exp as Long) as Long
   Private I as Integer
   I = 0
   LongPow = X
   If Exp > 0 Then
      While (I < Exp)
         LongPow = LongPow * X
         I = I + 1
      Wend
   Else If X <> 0 Then
      While (I <= -Exp)
         LongPow = LongPow / X
         I = I + 1
      Wend
   Else
      LongPow = 1
   End If
End Function

Rem Removes all decimals from Single, NOTE: Converts to LONG.
Function SFloor(SFloorX as Single) as Long
   Private SFloorTempInt1 as Long
   Private SFloorTempInt2 as Long
   Private SFloorTestSingle as Single
   SFloorTempInt1 = SFloorX

   If SFloorX >= 0 Then
      SFloorTempInt2 = (SFloorX - 0.5)
   Else
      SFloorTempInt2 = (SFloorX + 0.5)
   End If
   
   If SFloorTempInt1 = SFloorTempInt2 Then
      SFloor = SFloorTempInt1
   Else
      SFloorTestSingle = SFloorTempInt1
      If SFloorX = SFloorTestSingle Then
         SFloor = SFloorTempInt1
      Else
         SFloor = SFloorTempInt2
      End If
   End If
End Function

Rem Amount has "smallest bytes" first. Returns Satoshi.
Function BTCStringToSingle(amount as String*8) as Single
   BTCStringToSingle = 0.0
   Private tmpSingle as Single
   Private Iaea as Integer
   For Iaea = 1 To 8
      tmpSingle = Asc(Mid$(amount, Iaea, 1))
      BTCStringToSingle = BTCStringToSingle + SPow(256.0, Iaea-1)*tmpSingle
   Next Iaea
End Function

Function ConvertSingleToString(PConvertAmount as Single) as String
   ConvertSingleToString = ""
   Private ModDifference as Single = 0
   Private ConvertTempSingle as Single
   Private ConvertTempInt as Integer
   Private ConvertByte as Integer
   
   Private I005 as Integer = 0
   For I005 = 7 To 0 Step -1
      If 1.0 > PConvertAmount / SPow(256.0, I005)+0.000001 Then
         ConvertSingleToString = Chr$(&H00) + ConvertSingleToString
      Else
         ConvertTempSingle = (PConvertAmount - ModDifference) / SPow(256.0, I005)
         ConvertTempInt = LogN(ConvertTempSingle*1.000001, 10)
         Rem ConvertTempSingle should always be from 0 and to 255:
         If ConvertTempInt < 6 Then
            ConvertTempSingle = ConvertTempSingle + SPow(10.0, -6+ConvertTempInt)
         End If
         ConvertByte = SFloor(ConvertTempSingle)
         ModDifference = ModDifference + SPow(256.0, I005) * ConvertByte
         ConvertSingleToString = Chr$(ConvertByte) + ConvertSingleToString
      End If
   Next I005
End Function

Function AddBTCStrings(FirstValue as String*8, SecondValue as String*8) as String*8
   Private I007 as Integer = 0
   Private FirstByte as Integer
   Private SecondByte as Integer
   Private Carry as Integer = 0
   Private TempResultValue as Integer
   Private TempStringValue as String = ""
   For I007 = 0 To 7
      FirstByte = Asc(Mid$(FirstValue, I007+1, 1))
      SecondByte = Asc(Mid$(SecondValue, I007+1, 1))
      
      TempResultValue = FirstByte + SecondByte + Carry
      TempResultValue = TempResultValue Mod 256
      TempStringValue = TempStringValue + Chr$(TempResultValue)
      If FirstByte + SecondByte + Carry > 256 Then
         Carry = 1
      Else
         Carry = 0
      End If
   Next I007
   AddBTCStrings = TempStringValue
End Function

Function SubtractBTCStrings(BiggerValue as String*8, SmallerValue as String*8) as String*8
   Private I009 as Integer = 0
   Private BiggerByte as Byte
   Private SmallerByte as Byte
   Private NegCarry as Byte = 0
   Private TempSubStringValue as String = ""
   For I009 = 0 To 7
      BiggerByte = Asc(Mid$(BiggerValue, I009+1, 1))
      SmallerByte = Asc(Mid$(SmallerValue, I009+1, 1))
      
      If BiggerByte - SmallerByte - NegCarry < 0 Then
         TempSubStringValue = TempSubStringValue + Chr$(256 + BiggerByte - SmallerByte - NegCarry)
         NegCarry = 1
      Else
         TempSubStringValue = TempSubStringValue + Chr$(BiggerByte - SmallerByte - NegCarry)
         NegCarry = 0
      End If
   Next I009
   SubtractBTCStrings = TempSubStringValue
End Function

Sub CompareBTCStrings(PFirstValue as String*8, PSecondValue as String*8, CompareDifference as String*8, IsFirstLargerOrSame as Byte)
   Private I008 as Integer = 0
   Private PFirstByte as Byte
   Private PSecondByte as Byte
   For I008 = 7 To 0 Step -1
      PFirstByte = Asc(Mid$(PFirstValue, I008+1, 1))
      PSecondByte = Asc(Mid$(PSecondValue, I008+1, 1))
      If PFirstByte > PSecondByte Then
         CompareDifference = SubtractBTCStrings(PFirstValue, PSecondValue)
         IsFirstLargerOrSame = 1
         Exit Sub
      Else If PFirstByte < PSecondByte Then
         CompareDifference = SubtractBTCStrings(PSecondValue, PFirstValue)
         IsFirstLargerOrSame = 0
         Exit Sub
      End If
   Next I008
   CompareDifference = Chr$(&H00,&H00,&H00,&H00, &H00,&H00,&H00,&H00)
   IsFirstLargerOrSame = 1
End Sub

Sub SingleToSimpleFloat(SingleValue!, SimpleMantissa%, SimpleExponent@)
   Private tmpSingle!
   Private tmpLastSingle!
   Private tmpModLong&
   
   tmpSingle! = SingleValue!
   SimpleExponent@ = 0
   While tmpSingle! > 32767.0
      SimpleExponent@ = SimpleExponent@ + 1
      tmpLastSingle! = tmpSingle!
      tmpSingle! = tmpSingle! / 10
   Wend
   SimpleMantissa% = tmpSingle!
   If SimpleMantissa% < 32767 Then
      tmpModLong& = tmpLastSingle!
      tmpModLong& = tmpModLong& Mod 10
      If tmpModLong& >= 5 Then
         SimpleMantissa% = SimpleMantissa% + 1
      End If
   End If
End Sub