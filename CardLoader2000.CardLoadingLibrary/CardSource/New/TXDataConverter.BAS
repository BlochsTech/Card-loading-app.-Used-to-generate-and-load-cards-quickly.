Rem Mid$(string, start[, len]) -> SubString
Rem Asc(char/string) -> Byte
Rem Chr$(byte) -> Char
Rem Hex$(long) -> HexString
Rem ValH(hex string, len) -> ongoing

Function ByteStringToHex(value as String) as String
   ByteStringToHex = ""
   Private tempString as String
   Private Iada as Integer
   For Iada = 1 To Len(value)
      tempString = Hex$(Asc(Mid$(value, Iada, 1)))
      If Len(tempString) < 2 Then
         tempString = "0" + tempString
      End If
      ByteStringToHex = ByteStringToHex + tempString
   Next Iada
End Function

Function ReverseByteString(value As String) As String
    ReverseByteString = ""

    Private I00a As Integer
    For I00a = 1 To Len(value)
        ReverseByteString = Mid$(value, I00a, 1) + ReverseByteString
    Next I00a
End Function

Function VarIntToString(value As VarInt) As String
    If value.ByteSize = 1 Then
        VarIntToString = value.Value
    ElseIf value.ByteSize = 3 Then
        VarIntToString = Chr$(253) + Mid$(value.Value, 1, 2)
    ElseIf value.ByteSize = 5 Then
        VarIntToString = Chr$(254) + Mid$(value.Value, 1, 4)
    Else
        VarIntToString = Chr$(255) + value.Value
    End If
End Function

Function StringToVarInt(value as String*9) as VarInt
   Rem Maximum is 9 bytes, not all of string may be used!
   Rem Get ByteSize:
   Private ReadByte as Byte
   Private tempValue$
   tempValue$ = value
   ReadByte = Asc(Mid$(tempValue$, 1, 1))
   
   Rem FD = 3 byte, FD = 253
   If ReadByte < 253 Then
      StringToVarInt.ByteSize = 1
      StringToVarInt.Value = Chr$( ReadByte )
      StringToVarInt.NumberValue = ReadByte
   Else If ReadByte < 254 Then
      StringToVarInt.ByteSize = 3
      StringToVarInt.Value = Mid$(value, 2, 2)
      tempValue$ = Hex$(Asc(Mid$(value, 2, 1))) + Hex$(Asc(Mid$(value, 3, 1)))
      StringToVarInt.NumberValue =  ValH(tempValue$)
   Else If ReadByte < 255 Then
      StringToVarInt.ByteSize = 5
      StringToVarInt.Value = Mid$(value, 2, 4)
      tempValue$ = Hex$(Asc(Mid$(value, 2, 1))) + Hex$(Asc(Mid$(value, 3, 1)))_
                 + Hex$(Asc(Mid$(value, 4, 1))) + Hex$(Asc(Mid$(value, 5, 1)))
      StringToVarInt.NumberValue =  ValH(tempValue$)
   Else
      StringToVarInt.ByteSize = 9
      StringToVarInt.Value = Mid$(value, 2, 8)
      tempValue$ = Hex$(Asc(Mid$(value, 2, 1))) + Hex$(Asc(Mid$(value, 3, 1)))_
                 + Hex$(Asc(Mid$(value, 4, 1))) + Hex$(Asc(Mid$(value, 5, 1)))_
                 + Hex$(Asc(Mid$(value, 6, 1))) + Hex$(Asc(Mid$(value, 7, 1)))_
                 + Hex$(Asc(Mid$(value, 8, 1))) + Hex$(Asc(Mid$(value, 9, 1)))
      StringToVarInt.NumberValue =  ValH(tempValue$)
   End If
End Function

Function StringToTXSource(data as String, sourceHash as String*32, index as Byte) as TXOut
   Private readIndex as Integer
   Private readVarInt as VarInt
   readIndex = 1
   StringToTXSource.Source.TXHash = sourceHash
   StringToTXSource.Source.Amount = Mid$(data, readIndex, 8)
   StringToTXSource.Source.TXIndex = Chr$(index) + Chr$(&H00, &H00, &H00)
   readIndex = readIndex + 8
   
   readVarInt = StringToVarInt(Mid$(data, readIndex, 9))
   readIndex = readIndex + readVarInt.ByteSize
   StringToTXSource.ByteSize = readIndex + readVarInt.NumberValue - 1
   
   If Mid$(data, readIndex, 2) <> Chr$( &H76,&HA9 ) Or_
      Mid$(data, readIndex+readVarInt.NumberValue-2, 2) <> Chr$( &H88,&HAC ) Or_
      readVarInt.NumberValue <> 25 Then
      
      StringToTXSource.IsValid = 0
      Exit Function
   End If
   Rem Private J as Integer
   Rem For J = 0 To 4
   If Hash160KeyArray(0) = Mid$(data, readIndex+3, 20) Then
      StringToTXSource.Source.AddressIndex = 0
      StringToTXSource.IsValid = 1
      Exit Function
   End If
   Rem Next J
   
   StringToTXSource.IsValid = 0
End Function

Function StringToOutpoint(value as String) as Outpoint
   StringToOutpoint.TXHash = Mid$(value, 0, 32)
   Private tempValue$
   tempValue$ = Hex$(Asc(Mid$(value, 32, 1))) + Hex$(Asc(Mid$(value, 33, 1)))_
              + Hex$(Asc(Mid$(value, 34, 1))) + Hex$(Asc(Mid$(value, 35, 1)))
   StringToOutpoint.Index =  ValH(tempValue$)
End Function