Declare Function VignereCipher (ByVal plaintext as String*8) as String*8

Rem public data is initialized at powerup, may slow the card..
Eeprom ReadOnly LetterArray@(0 To 9) = Asc("A"), Asc("B"), Asc("C"), Asc("D"), Asc("E"), Asc("F"), Asc("G"), Asc("H"), Asc("I"), Asc("J")
Rem Eeprom ReadOnly NumberArray@(0 To 9) = Asc("0"), Asc("1"), Asc("2"), Asc("3"), Asc("4"), Asc("5"), Asc("6"), Asc("7"), Asc("8"), Asc("9")
Eeprom ReadOnly keyArray@(0 To 6) = Asc(Mid$(DisplayKey,1,1)),Asc(Mid$(DisplayKey,2,1)),Asc(Mid$(DisplayKey,3,1)),Asc(Mid$(DisplayKey,4,1)),Asc(Mid$(DisplayKey,5,1)),Asc(Mid$(DisplayKey,6,1)),Asc(Mid$(DisplayKey,7,1))

Function VignereResponse (ByVal amount as Single) as String*8
   Rem X,YZe-99<->999 or 8 chars.
   Rem Use page 40 of basiccard manual. Step 1: Base string.
   Private exp as Integer
   exp = LogN(amount,10)-8
   Private sexp as String
   sexp = Str$(exp)
   
   Private modAmount as Single
   Rem The purpose of this line is to reduce the amount, no matter its numerical size, to "x,yz E0":
   modAmount = amount * SPow(10.0,-exp-8)
   
   Private roundingDigit$
   roundingDigit$ = Str$(modAmount)
   Private rDigit2&
   rDigit2& = Val&(Mid$(roundingDigit$, 5, 1))
   
   If (rDigit2& >= 5) Then
      modAmount = 0.01+modAmount
      If modAmount >= 10.0 Then
         exp = exp + 1
         sexp = Str$(exp)
      End If
   End If
   
   If exp < -9 Then
      VignereResponse = Mid$(Str$(modAmount),1, 4)+"e-"+Mid$(sexp,2)
   Else If exp < 0 Then
      VignereResponse = Mid$(Str$(modAmount),1, 4)+"e-0"+Mid$(sexp,2)
   Else If exp <= 9 Then
      VignereResponse = Mid$(Str$(modAmount),1, 4)+"e00"+sexp
   Else If exp <= 99 Then
      VignereResponse = Mid$(Str$(modAmount),1, 4)+"e0"+sexp
   Else If exp <= 999 Then
      VignereResponse = Mid$(Str$(modAmount),1, 4)+"e"+sexp
   End If
   
   Rem Step 2: Cipher string.
   VignereResponse = VignereCipher(VignereResponse)
   
End Function

Function AlphabetShift(valueIndex%, shift%)
   AlphabetShift = (valueIndex% + shift%) Mod 10
   If AlphabetShift >= keyArray@(6)-48 Then
      AlphabetShift = 9 - AlphabetShift + keyArray@(6)-48
   End If
End Function

Function VignereCipher (ByVal plaintext as String*8) as String*8
   Rem 0123456789
   Rem ABCDJIHGFE Result with above values and key = 000... and alphabet table = 4
   Rem CAlphabet ABCDEFGHIJ
   Rem PAlphabet 0123456789
   Rem key length: 6 From setup constants... ONE page so that it can be copy pasted in from BlochsTech generator.
   Rem "," and "e" are skipped as they are always the same (not ALWAYS same index for ","), hence the key length of 6.
   Rem 7th digit of the key shifts the entire alphabet used.
   
   Private I, charExceptions, charCode, keyIndex as Integer
   charExceptions = 0
   keyIndex = 0
   Private VignereCipherString$ = ""
   For I = 0 To 7
      charCode = Asc(Mid$(plaintext, I+1, 1))
      If charCode >= 48 And charCode <= 57 Then
         VignereCipherString$ = VignereCipherString$ + Chr$(LetterArray@(AlphabetShift(charCode-48, keyArray@(keyIndex)-48)))
         keyIndex = keyIndex + 1
      Else If charExceptions < 3 Then
         If charExceptions = 0 Then
            VignereCipherString$ = VignereCipherString$ + "."
         Else If charExceptions = 1 Then
            VignereCipherString$ = VignereCipherString$ + "e"
         Else If charExceptions = 2 Then
            VignereCipherString$ = VignereCipherString$ + "-"
            keyIndex = keyIndex + 1
         Else
            VignereCipherString$ = "Error:01"
         End If
         charExceptions = charExceptions + 1
      Else
         VignereCipherString$ = "Error:01"
      End If
   Next I
   VignereCipher = VignereCipherString$
End Function