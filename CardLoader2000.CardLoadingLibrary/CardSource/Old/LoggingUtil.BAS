Sub LogAverageArray()
   DebugMessage(" AvgArray:")
   Private I00B as Integer
   For I00B = 0 To UBound(MedianArray)
      DebugMessage("|"+Str$(MedianArray(I00B)))
   Next I00B
End Sub

Sub LogSpentTXes()
   DebugMessage(" SpentArray:")
   Private I00B as Integer
   For I00B = 0 To UBound(SpentTXes)
      DebugMessage("("+Mid$(ByteStringToHex(SpentTXes(I00B).TXHash), 1, 8)+"|"_
         +Mid$(ByteStringToHex(SpentTXes(I00B).TXIndex), 1, 2)+")")
   Next I00B
End Sub

Rem Sub LogTXSources() Moved to bottom of TXDataHandler
Rem   DebugMessage(" SourcesArray:")
Rem   Private I00B as Integer
Rem   For I00B = 0 To UBound(TXSources)
Rem      DebugMessage("("+Mid$(ByteStringToHex(TXSources(I00B).TXHash), 1, 8)+"|"_
Rem         +Mid$(ByteStringToHex(TXSources(I00B).TXIndex), 1, 2)+")")
Rem   Next I00B
Rem End Sub

Sub LogTrustInfo()
   DebugMessage(" TrustArrays:")
   Private I00B as Integer
   For I00B = 0 To UBound(TrustedAddresses)
      DebugMessage("("+Mid$(ByteStringToHex(TrustedAddresses(I00B).Address), 1, 4)+"|"_
         +Str$(TrustedAddresses(I00B).Verified)+")")
   Next I00B
   DebugMessage("|C|")
   For I00B = 0 To UBound(TrustCandidates)
      DebugMessage("("+Mid$(ByteStringToHex(TrustCandidates(I00B).Address), 1, 4)+"|"_
         +Str$(TrustCandidates(I00B).Verified)+")")
   Next I00B
End Sub