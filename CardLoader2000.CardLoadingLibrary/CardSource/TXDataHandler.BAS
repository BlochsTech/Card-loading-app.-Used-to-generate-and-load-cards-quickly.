Rem TXDataHandler

Rem Eeprom txdata? Next address to use? Should this be in classes?

Rem (Pure byte arrays are used in the form of defined length strings for stuff.)

#Include SHA.DEF

Rem 6-8, 6 called anytime and resets order.
Eeprom NextInfoCommand@ = 6

Rem Ready-for-use TXSources:
Const TXSourcesCapacity = 30
Rem UBound can be used instead, but we don't want to redo this.
Eeprom TXSourcesLength@ = 0
Eeprom TXSources(0 To 29) as TXSource
Rem Sorted, index 0 is largest.

Sub LogTXSources()
  DebugMessage(" SourcesArray:")
  Private I00B as Integer
  For I00B = 0 To UBound(TXSources)
     DebugMessage("("+Mid$(ByteStringToHex(TXSources(I00B).TXHash), 1, 8)+"|"_
        +Mid$(ByteStringToHex(TXSources(I00B).TXIndex), 1, 2)+")")
  Next I00B
End Sub

Function TotalCardAmount() as Single
   Private TempTotal as String*8
   Private I00c as Integer
   For I00c = 0 To TXSourcesLength@
      TempTotal = AddBTCStrings(TempTotal, TXSources(I00c).Amount)
   Next I00c
   TotalCardAmount = BTCStringToSingle(TempTotal)
End Function

Function TXSourcesAdd(newSource as TXSource) as Byte
   If TXSourcesLength@ >= TXSourcesCapacity Then
      TXSourcesAdd = 0
      DebugMessage(" No capacity.")
   Else
      TXSourcesAdd = 1
      
      Private OldTempSource as TXSource
      Private NewTempSource as TXSource
      
      Private tempNodeS as Single
      Private newNodeS as Single
      newNodeS = BTCStringToSingle(newSource.Amount)
      Private specialIndex as Byte = 255
      Private I000 as Integer
      For I000 = 0 To UBound(TXSources)
         If TXSources(I000).TXHash = newSource.TXHash And TXSources(I000).TXIndex = newSource.TXIndex Then
            TXSourcesAdd = 0
            DebugMessage(" Already added:")
            Call LogTXSources()
            Exit Function
         End If
      
         tempNodeS = BTCStringToSingle(TXSources(I000).Amount)
         If tempNodeS < newNodeS Or TXSourcesLength@ <= I000 Then
            Rem Place at this index and move sources after down.
            If specialIndex = 255 Then
               specialIndex = I000
               TXSourcesLength@ = TXSourcesLength@ + 1
            End If
            
            Rem This shifts things downwards (0 being top). Everything after insertion point.
            NewTempSource = TXSources(I000)
            TXSources(I000) = OldTempSource
            OldTempSource = NewTempSource
            
            Rem Set source:
            If I000 = specialIndex Then
               TXSources(I000) = newSource
            End If
         End If
      Next I000
   End If
End Function

Rem Use below when verifying merkle branch.
Eeprom TXHashBeingVerified$ = ""
Eeprom ConfirmedMerkleRoot$ = ""
Eeprom AverageDifficulty! = 10000000000000.0
Eeprom LastMerkleHash$ = ""
Rem Use float/single, part 10.000 last diff min.

Rem Used TXSources:
Rem Eeprom SpentTXesLength@ = 0
Eeprom SpentTXes(0 To 9) as TXSourceIdInfo

Function CheckSourceIsNew(newSource as TXSource) as Byte
   Rem Prefix: aab
   Private Iaab as Integer
   Rem Check it is new:
   If TXSourcesLength@ > 0 Then
      For Iaab=0 To TXSourcesLength@-1
         If TXSources(Iaab).TXHash = newSource.TXHash_
            And TXSources(Iaab).TXIndex = newSource.TXIndex Then
               CheckSourceIsNew = 0
               Exit Function
         End If
      Next Iaab
   End If
   
   Rem Check it is unspent:
   For Iaab=0 To UBound(SpentTXes)
      If SpentTXes(Iaab).TXHash = newSource.TXHash_
         And SpentTXes(Iaab).TXIndex = newSource.TXIndex Then
            CheckSourceIsNew = 0
            Exit Function
      End If
   Next Iaab
   CheckSourceIsNew = 1
End Function

Function SpentTXAdd(newSourceId as TXSourceIdInfo) as Byte
   SpentTXAdd = 1
   
   Private OldTempSourceId as TXSourceIdInfo
   Private NewTempSourceId as TXSourceIdInfo
   
   Private SpentAddI as Integer
   For SpentAddI = 0 To UBound(SpentTXes)
      Rem Already added:
      If SpentTXes(SpentAddI).TXHash = newSourceId.TXHash And SpentTXes(SpentAddI).TXIndex = newSourceId.TXIndex Then
         SpentTXAdd = 0
         Exit Function
      End If
      
      Rem This shifts things downwards (0 being top). Everything after insertion point (always 0).
      NewTempSourceId = SpentTXes(SpentAddI)
      SpentTXes(SpentAddI) = OldTempSourceId
      OldTempSourceId = NewTempSourceId
      
      Rem Set source:
      If SpentAddI = 0 Then
         SpentTXes(SpentAddI) = newSourceId
      End If
   Next SpentAddI
End Function

Rem Save verified hash then just compare post merkle branch method? -> yes.
Rem Is there any reason to accumulate difficulty when it adds 0 extra security? (fake block can just point at real block) -> NO.
Sub CheckDifficulty(ErrorCode%, Accepted@, VerifyingTXHash$, BlockHeader$)
   Accepted@ = 0
   ErrorCode% = 0
   Private hash as String
   hash = Sha256Hash(blockHeader$)
   hash = Sha256Hash(hash)
   Private Iaac as Integer
   Private zeroBytes as Integer
   zeroBytes = 0
   For Iaac = 0 To (Len(hash)-1)
      If Mid$(hash, Len(hash)-Iaac, 1) = Chr$(&H00) Then
         zeroBytes = zeroBytes + 1
      Else
         Exit For
      End If
   Next Iaac
   Private currentDifficulty as Single
   currentDifficulty = SPow(256.0, zeroBytes)
   
   ConfirmedMerkleRoot$ = ""
   TXHashBeingVerified$ = ""
   LastMerkleHash$ = ""
   
   Private hashKnown@ = 0
   For Iaac = 0 To TXSourcesLength@
      If TXSources(Iaac).TXHash = VerifyingTXHash$ Then
         hashKnown@ = 1
      End If
   Next Iaac
   If hashKnown@ = 0 Then
      ErrorCode% = 7
   End If
   
   If currentDifficulty*10000 < AverageDifficulty! Or hashKnown@ = 0 Then
      Accepted@ = 0
   Else
      ConfirmedMerkleRoot$ = Mid$(blockHeader$, 1+4+32, 32)
      AverageDifficulty! = (AverageDifficulty! + currentDifficulty) / 2
      TXHashBeingVerified$ = VerifyingTXHash$
      Accepted@ = 1
   End If
End Sub

Sub CheckMerkleBranch(Accepted@, IsRightNode@, MerkleHash$)
   If LastMerkleHash$ = "" Then
      LastMerkleHash$ = TXHashBeingVerified$
   End If
   
   If IsRightNode@ = 1 Then
      LastMerkleHash$ = LastMerkleHash$ + MerkleHash$
   Else
      LastMerkleHash$ = MerkleHash$ + LastMerkleHash$
   End If
   LastMerkleHash$ = Sha256Hash(Sha256Hash(LastMerkleHash$))
   If LastMerkleHash$ = ConfirmedMerkleRoot$ Then
      Private Iaad as Integer
      For Iaad=0 To TXSourcesLength@-1
         If TXSources(Iaad).TXHash = TXHashBeingVerified$ Then
            Rem Header function can be called during merkle validation, but it still has to have difficulty and a valid txhash
            Rem otherwise it and/or merklevalidation will fail anyway.
            Rem Similarily card can be charged, but unverified sources will not be used.
            TXSources(Iaad).Verified = 1
         End If
      Next Iaad
      Accepted@ = 1
   End If
End Sub

Rem New TX being processed (remember we can also create our own when having change):
Eeprom RawTXBytes as String = ""
Rem Eeprom txincount as VarInt Just save outputs to be claimed!

Rem methods:
Sub GetOneSource(ErrorCode%, NextSourceIndex@, OutIndex as String*4, TXHash as String*32, Value as String*8, Verified@)
   If NextSourceIndex@ < TXSourcesLength@ Then
      OutIndex = TXSources(NextSourceIndex@).TXIndex
      TXHash = TXSources(NextSourceIndex@).TXHash
      Value = TXSources(NextSourceIndex@).Amount
      Verified@ = TXSources(NextSourceIndex@).Verified
      If NextSourceIndex@+1 < TXSourcesLength@_
         And OutIndex <> ""_
         And TXHash <> "" Then
         NextSourceIndex@ = NextSourceIndex@ + 1
      Else
         NextSourceIndex@ = 0
      End If
   Else If NextSourceIndex@ = 0 Then
      NextSourceIndex@ = 0
      TXHash = ""
      OutIndex = ""
      Value = ""
   Else
      DebugMessage(" NextSourceIndex out of bounds and not 0.")
      ErrorCode% = 3
      NextSourceIndex@ = 0
      TXHash = ""
      OutIndex = ""
      Value = ""
   End If
End Sub

Rem saved as waiting source if ok
Sub ValidateTX(ErrorCode%, Accepted@, EndOfTXStream@, TXBytes as String*246)

Rem Sub methods can change variables. Prefix: aaa
   If Accepted@ = 0 Then
      RawTXBytes = ""
   End If
   
   Accepted@ = 1
   ErrorCode% = 0
   If TXSourcesLength@ >= TXSourcesCapacity Then
      ErrorCode% = 9
      Accepted@ = 0
      RawTXBytes = ""
      Exit Sub
   End If
   
   If Len(RawTXBytes)+246<2001 And EndOfTXStream@ <= 246 Then
      If EndOfTXStream@ > 0 Then
         RawTXBytes = RawTXBytes + Mid$(TXBytes, 1, EndOfTXStream@)
      Else
         RawTXBytes = RawTXBytes + TXBytes
      End If
      If EndOfTXStream@ > 0 Then
         Private TXHash as String
         Private readString as String
         Private readInt as VarInt
         Private txSourceResponse as TXOut
         Private readPointer as Integer
         Private txValid as Byte
         txValid = 0
         TXHash = Sha256Hash(RawTXBytes)
         TXHash = Sha256Hash(TXHash)
         Rem 01 00 00 00 = Expected TX version. Bitcoin message header not included here.
         readString = Mid$(RawTXBytes, 1, 4)
         readPointer = 5
         If readString = Chr$(&H01,&H00,&H00,&H00) Then
            readString = Mid$(RawTXBytes, readPointer, 9)
            readInt = StringToVarInt(readString)
            readPointer = readPointer + readInt.ByteSize
            Rem We dont care about ins. Only outs as it is these we will claim/put in the source info data.
            Rem We just need to find the index after the ins:
            Private longTemp&
            longTemp& = readInt.NumberValue
            Private Iaaa as Integer
            For Iaaa=1 To longTemp&
               Rem Skip txsource id:
               readPointer = readPointer + 36
               Rem Script length/skip script:
               readString = Mid$(RawTXBytes, readPointer, 9)
               readInt = StringToVarInt(readString)
               readPointer = readPointer + readInt.ByteSize
               Rem Skip sequence:
               readPointer = readPointer + readInt.NumberValue
               Rem Skip sequence bytes:
               readPointer = readPointer + 4
            Next Iaaa
            Rem Go through the outs and validate script and destination:
            Rem Read outs_varint
            readString = Mid$(RawTXBytes, readPointer, 9)
            readInt = StringToVarInt(readString)
            longTemp& = readInt.NumberValue
            readPointer = readPointer + readInt.ByteSize
            
            Rem Test readpointer here? -> Can always convert converter function to sub if it doesnt work, no test necessary yet.
            Rem Foreach out:
            For Iaaa=0 To (longTemp&-1)
               txSourceResponse = StringToTXSource(Mid$(RawTXBytes, readPointer), TXHash, Iaaa)
               
               readPointer = readPointer + txSourceResponse.ByteSize
               
               If txSourceResponse.IsValid = 1 Then
                  If CheckSourceIsNew(txSourceResponse.Source) = 1 Then
                     
                     Private errTest as Byte
                     errTest = TXSourcesAdd(txSourceResponse.Source)
                     If errTest = 0 Then
                        ErrorCode% = 1
                        DebugMessage(" Line 320+/-, TXDataHandler. Related to adding source.")
                        Accepted@ = 0
                        RawTXBytes = ""
                        Exit Sub
                     End If
                     txValid = 1
                  Else
                     Rem TX can still be valid if ANOTHER source in same TX has been cleared and is unspent!!!
                     ErrorCode% = 11
                  End If
               End If
            Next Iaaa
            If txValid = 1 Then
               Accepted@ = 1
               Rem Clear error if valid source provided (unlikely but still):
               If ErrorCode% = 11 Then
                  ErrorCode% = 0
               End If
            Else
               Accepted@ = 0
               If ErrorCode% <> 11 Then
                  ErrorCode% = 10
               Else
                  DebugMessage(" BOBC Err 11: TX source spent.")
               End If
            End If
         Else
            Rem Wrong TX format version.
            Accepted@ = 0
            ErrorCode% = 4
         End If
         RawTXBytes = ""
      End If
   Else
      Rem Data/Command/String too long. Important to reset so card does not end in faulted state!
      DebugMessage(" TX too long to process.")
      RawTXBytes = ""
      Accepted@ = 0
      ErrorCode% = 3
   End If
End Sub