
Function AbsDiff(number1 as Single, number2 as Single) as Single
   If (number1 > number2) Then
      BTCDiff = (number1-number2)
   Else
      BTCDiff = (number2-number1)
   End If
End Function

Function BTCValid(address as String*33) as Integer
   Rem TODO implement:
   BTCValid = -1
End Function

Function Pow (X as Single, Exp as Integer) as Single
   Private I as Integer
   I = 0
   Pow = X
   If Exp > 0 Then
      While (I < Exp)
         Pow = Pow * Pow
         I = I + 1
      Wend
   Else If X <> 0 Then
      While (I <= -Exp)
         Pow = Pow / Pow
         I = I + 1
      Wend
   Else
      Pow = 0
   End If
End Function

Function LogN (ByVal X as Single, N as Integer) as Integer
   LogN = 0
   If X >= 1 Then
      X = X / N
      While (X >= 1)
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
   Else
      LogN = 0
   End If
End Function