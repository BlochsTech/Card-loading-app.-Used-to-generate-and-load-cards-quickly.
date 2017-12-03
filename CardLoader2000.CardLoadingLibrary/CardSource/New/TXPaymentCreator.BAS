Rem Saved valid request:
Eeprom SavedWaitingAmount as Single
Eeprom SavedWaitingAddress as String*20
Eeprom SavedWaitingAddressType as Byte

Eeprom SavedWaitingFeeAmount as Single

Eeprom SavedWaitingTerminalAmount as Single
Eeprom SavedWaitingTerminalAddress as String*20
Eeprom SavedWaitingTerminalAddressType as Byte
Eeprom WaitingIsNoPinRequest as Byte = 0
Eeprom WaitingIsResetRequest as Byte = 0

Eeprom WaitingVignereCode as String*8

Sub RemoveSource(removeTXId as TXSourceIdInfo)
   Private shiftSourcesUp as Byte = 0
   Private I001 as Integer

   Rem Step 1 Find source
   For I001 = 0 To UBound(TXSources)
      If TXSources(I001).TXHash = removeTXId.TXHash _
         And TXSources(I001).TXIndex = removeTXId.TXIndex Then
         shiftSourcesUp = 1
         If TXSourcesLength@ > 0 Then
            TXSourcesLength@ = TXSourcesLength@ - 1
         End If
      End If
      
      Rem Step 2 Replace source w. next.
      If shiftSourcesUp = 1 Then
         If I001 < UBound(TXSources) Then
            TXSources(I001) = TXSources(I001+1)
         End If
         If I001 = UBound(TXSources) Then
            TXSources(I001).TXHash = ""
            TXSources(I001).Amount = ""
            TXSources(I001).TXIndex = ""
            TXSources(I001).Verified = 0
            TXSources(I001).AddressIndex = 0
         End If
      End If
   Next I001
End Sub

Rem 0->99999 is represented perfectly, higher amounts will have precision loss. 1.23456789 BTC would become 1.23457000
Rem Use UInt64 strings directly instead? Should be ok for 99% of cases and until very high BTC value.

Rem Use UInt64 with decimals denoting the value of the lowest digit? For this card it would always be the standard
Rem but it would also support future protocol...?
Rem Maybe for 1.0 we CANNOT delay more without good reason.

Rem Order: Payment (, CardFee) (, TerminalFee) (, MinersFee) , LeftOver1 (, LeftOver2)
Eeprom AccumulatedCardFees as String*8 = Chr$(&H00,&H00,&H00,&H00, &H00,&H00,&H00,&H00)
Sub CreateChargeArray(ErrorCode%, ParamSplitLeftOver as Byte, PStartFromIndex as Byte_
   , PEndSourceIndex as Byte, PDirectionCounter as Integer_
   , ParamStringBTCCharges() as TXChargeData)
   
   Rem Find available input amounts.
   Private AccurateAvailableAmounts as String*8 = Chr$(&H00,&H00,&H00,&H00, &H00,&H00,&H00,&H00)
   Private I00b as Integer
   For I00b = PStartFromIndex To PEndSourceIndex Step +PDirectionCounter
      AccurateAvailableAmounts = AddBTCStrings(TXSources(I00b).Amount, AccurateAvailableAmounts)
   Next I00b
   
   Rem Create 8 byte int outputs.
   Private AmountsCounter as Byte
   
   If SavedWaitingAmount > 0.0 Then
      AmountsCounter = AmountsCounter + 1
   End If
   
   If CardFeeMultiplier! > 0.0 And (ExpireUsageTimes = 0 Or TotalPurchaseCount% < ExpireUsageTimes) Then
      Private NewCardFees as String*8
      NewCardFees = ConvertSingleToString(SavedWaitingAmount*CardFeeMultiplier!)
      AccumulatedCardFees = AddBTCStrings(AccumulatedCardFees, NewCardFees)
      If BTCStringToSingle(AccumulatedCardFees) > DustLimitSatoshis! Then
         AmountsCounter = AmountsCounter + 1
      End If
   End If
   
   If SavedWaitingTerminalAmount > 0 And SavedWaitingTerminalAmount >= DustLimitSatoshis! Then
      AmountsCounter = AmountsCounter + 1
   End If
   
   If SavedWaitingFeeAmount > 0.0 Then
      AmountsCounter = AmountsCounter + 1
   End If
   
   Rem Leftover (if there is none or below limit array is remade):
   AmountsCounter = AmountsCounter + 1
   
   If ParamSplitLeftOver = 1 Then
      AmountsCounter = AmountsCounter + 1
   End If
   
   ReDim ParamStringBTCCharges(0 To AmountsCounter-1) as TXChargeData
   
   Rem Compare one at a time. Error if too small.
   Rem Calculate leftover. Unkown error if below 0 - no fancy adjustments.
   Private CompareDifference as String*8
   Private IsFirstLargerOrSame as Byte
   Private AccurateAccumulatedCharge as String*8 = Chr$(&H00,&H00,&H00,&H00, &H00,&H00,&H00,&H00)
   Private LeftOverBTC as String*8 = Chr$(&H00,&H00,&H00,&H00, &H00,&H00,&H00,&H00)
   Private I006 as Byte = 0
   If SavedWaitingAmount > 0.0 Then
      ParamStringBTCCharges(I006).ChargeType = 0
      ParamStringBTCCharges(I006).Amount = ConvertSingleToString(SavedWaitingAmount)
      AccurateAccumulatedCharge = AddBTCStrings(AccurateAccumulatedCharge, ParamStringBTCCharges(I006).Amount)
        Call CompareStrings(AccurateAvailableAmounts, AccurateAccumulatedCharge, CompareDifference, IsFirstLargerOrSame)
        If IsFirstLargerOrSame = 0 Then
            ErrorCode% = 1
            DebugMessage(" Line 113+/-, TXPaymentCreator.BAS. Related to 'AccurateAvailableAmounts'.")
            DebugMessage(" Avail:" + ByteStringToHex(AccurateAvailableAmounts) + " Accu:" + ByteStringToHex(AccurateAccumulatedCharge))
            Exit Sub
        End If
        I006 = I006 + 1
    End If
   If CardFeeMultiplier! > 0.0 And (ExpireUsageTimes = 0 Or ExpireUsageTimes > TotalPurchaseCount%)_
      And BTCStringToSingle(AccumulatedCardFees) > DustLimitSatoshis! Then
        ParamStringBTCCharges(I006).ChargeType = 1
        ParamStringBTCCharges(I006).Amount = AccumulatedCardFees
        AccumulatedCardFees = Chr$(&H0, &H0, &H0, &H0, &H0, &H0, &H0, &H0)
        AccurateAccumulatedCharge = AddBTCStrings(AccurateAccumulatedCharge, ParamStringBTCCharges(I006).Amount)
        Call CompareStrings(AccurateAvailableAmounts, AccurateAccumulatedCharge, CompareDifference, IsFirstLargerOrSame)
        If IsFirstLargerOrSame = 0 Then
            ErrorCode% = 1
            DebugMessage(" Line 126+/-, TXPaymentCreator.BAS. Related to 'AccurateAvailableAmounts'.")
            Exit Sub
        End If
        I006 = I006 + 1
    End If
    If SavedWaitingTerminalAmount > 0.0 And SavedWaitingTerminalAmount >= DustLimitSatoshis! Then
        ParamStringBTCCharges(I006).ChargeType = 2
        ParamStringBTCCharges(I006).Amount = ConvertSingleToString(SavedWaitingTerminalAmount)
        AccurateAccumulatedCharge = AddBTCStrings(AccurateAccumulatedCharge, ParamStringBTCCharges(I006).Amount)
        Call CompareStrings(AccurateAvailableAmounts, AccurateAccumulatedCharge, CompareDifference, IsFirstLargerOrSame)
        If IsFirstLargerOrSame = 0 Then
            ErrorCode% = 1
            DebugMessage(" Line 138+/-, TXPaymentCreator.BAS. Related to 'AccurateAvailableAmounts'.")
            Exit Sub
        End If
        I006 = I006 + 1
    End If
    If SavedWaitingFeeAmount > 0.0 Then
        ParamStringBTCCharges(I006).ChargeType = 3
        ParamStringBTCCharges(I006).Amount = ConvertSingleToString(SavedWaitingFeeAmount)
        AccurateAccumulatedCharge = AddBTCStrings(AccurateAccumulatedCharge, ParamStringBTCCharges(I006).Amount)
        Call CompareStrings(AccurateAvailableAmounts, AccurateAccumulatedCharge, CompareDifference, IsFirstLargerOrSame)
        If IsFirstLargerOrSame = 0 Then
            ErrorCode% = 1
            DebugMessage(" Line 150+/-, TXPaymentCreator.BAS. Related to 'AccurateAvailableAmounts'.")
            Exit Sub
        End If
        I006 = I006 + 1
    End If
    If ParamSplitLeftOver = 1 Then
        Private TempSingle As Single
        TempSingle = BTCStringToSingle(AccurateAvailableAmounts) - SavedWaitingFeeAmount - SavedWaitingAmount_
      - SavedWaitingTerminalAmount - SavedWaitingAmount*CardFeeMultiplier!
        If TempSingle / 2 < DustLimitSatoshis! Then
            ErrorCode% = 1
            DebugMessage(" Line 161+/-, TXPaymentCreator.BAS. Related to 'DustLimitSatoshis'.")
            Exit Sub
        End If
        ParamStringBTCCharges(I006).ChargeType = 4
        ParamStringBTCCharges(I006).Amount = ConvertSingleToString(TempSingle / 2)
        AccurateAccumulatedCharge = AddBTCStrings(AccurateAccumulatedCharge, ParamStringBTCCharges(I006).Amount)
        I006 = I006 + 1
    End If
    Call CompareStrings(AccurateAvailableAmounts, AccurateAccumulatedCharge, CompareDifference, IsFirstLargerOrSame)
    If IsFirstLargerOrSame = 0 Then
        ErrorCode% = 1
        DebugMessage(" Line 172+/-, TXPaymentCreator.BAS. Related to 'AccurateAvailableAmounts'.")
        Exit Sub
    End If

    REM Handle leftovers:
    LeftOverBTC = SubtractStrings(AccurateAvailableAmounts, AccurateAccumulatedCharge)
    REM DustLimit comparison:
    Private DustLimitString As String = Chr$(&H54, &H15, &H0, &H0, &H0, &H0, &H0, &H0)
    Call CompareStrings(LeftOverBTC, DustLimitString, CompareDifference, IsFirstLargerOrSame)
    If IsFirstLargerOrSame = 0 Then
        REM Leftover added to paid amount:
        Private TempBTCCharges() As TXChargeData
      ReDim TempBTCCharges(0 To UBound(ParamStringBTCCharges)-1) as TXChargeData

        TempBTCCharges(0).ChargeType = ParamStringBTCCharges(0).ChargeType
        TempBTCCharges(0).Amount = AddBTCStrings(LeftOverBTC, ParamStringBTCCharges(0).Amount)

        For I00b = 1 To UBound(TempBTCCharges)
            TempBTCCharges(I00b).ChargeType = ParamStringBTCCharges(I00b).ChargeType
            TempBTCCharges(I00b).Amount = ParamStringBTCCharges(I00b).Amount
        Next I00b

        REM Overwrite result array:
      ReDim ParamStringBTCCharges(0 To UBound(TempBTCCharges)) as TXChargeData
        For I00b = 0 To UBound(TempBTCCharges)
            ParamStringBTCCharges(I00b).ChargeType = TempBTCCharges(I00b).ChargeType
            ParamStringBTCCharges(I00b).Amount = TempBTCCharges(I00b).Amount
        Next I00b
    Else
        REM Leftover:
        ParamStringBTCCharges(I006).ChargeType = 5
        ParamStringBTCCharges(I006).Amount = LeftOverBTC
    End If
    REM All amounts accurately known, return array.
End Sub

REM Data sources:
REM TXDataHandler/TXDataClasses = KnownSources/Source type
REM RequestHandler = Waiting amounts to be charged.
REM BitcoinCard.BAS = Has file reference to SECP256k1
REM MathUtil.BAS BTCStringToSingle function.


Eeprom ReadOnly MaxSValue as String*32 = Chr$(&HA0,&H20,&H1B,&H68,&H46,&H2F,&HE9,&HDF,&H1D,&H50,&HA4,&H57,&H73,_
                                              &H6E,&H57,&H5D,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,_
                                              &HFF,&HFF,&HFF,&HFF,&HFF,&H7F)

Eeprom ReadOnly SPivotValue as String*32  = Chr$(&H41,&H41,&H36,&HD0,&H8C,&H5E,&HD2,&HBF,&H3B,&HA0,&H48,&HAF,&HE6,_
                                                 &HDC,&HAE,&HBA,&HFE,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,&HFF,_
                                                 &HFF,&HFF,&HFF,&HFF,&HFF,&HFF)

Eeprom TXSignature as String
Eeprom FeeCycleCounter as Byte = 0
Sub CreatePaymentTX(ErrorCode%, PaymentTXBytes As String)

    Call ECpSetCurveFromFile("\CurveFile")
    If LibError <> 0 Then
        ErrorCode% = 1
        DebugMessage(" ECpCurveSetErr:" + Hex$(LibError))
        Exit Sub
    End If

    Private chargeBTC As Single

    chargeBTC = SavedWaitingAmount + SavedWaitingAmount * CardFeeMultiplier! + SavedWaitingFeeAmount + SavedWaitingTerminalAmount

    Private StringBTCCharges() As TXChargeData

    REM Part 1: Source management.
    REM Array is (now) sorted.

    REM Part 2: Source creation.

    REM Amount -> Choose amounts that split into usable chunks Or do merges.
    REM Amounts in bit 64 uint. We need handling methods?
    REM FIRST thing needed: Simple choice algo:
    REM Algorithm: 
    REM 1 Sources are sorted by amount.
    REM 2 Try to make new sources equal to averagepurchase.
    REM 3A If Charge above 1.5x average use largest sources first else smallest first.
    REM 3B If the last source incorporated brings the leftover above 2 times average charge, split leftover in two (never more splits).

    Private startFromIndex As Byte = 0
    Private directionCounter As Integer = 1
    Private endSourceIndex As Integer = -1
    Private txInCount As Byte = 0

    Private splitLeftOver As Byte = 0
    Private accumulatedBTC As Single = 0.0
    Private I002 As Integer

    REM Make sure no unverified sources are used, remove them.
    Private removeId As TXSourceIdInfo
    For I002 = 0 To TXSourcesLength@ - 1
        If TXSources(I002).Verified = 0 Then
            removeId.TXHash = TXSources(I002).TXHash
            removeId.TXIndex = TXSources(I002).TXIndex
            RemoveSource(removeId)
        End If
    Next I002

    If AveragePurchase() * 1.5 <= chargeBTC Then
        For I002 = 0 To (TXSourcesLength@ - 1)
            accumulatedBTC = accumulatedBTC + BTCStringToSingle(TXSources(I002).Amount)
            endSourceIndex = endSourceIndex + 1
            txInCount = txInCount + 1
            If accumulatedBTC > chargeBTC Then
                Exit For
            End If
        Next I002
    Else
        directionCounter = -1
        endSourceIndex = TXSourcesLength@
        startFromIndex = TXSourcesLength@ - 1
        For I002 = TXSourcesLength@ - 1 To 0 Step -1
            accumulatedBTC = accumulatedBTC + BTCStringToSingle(TXSources(I002).Amount)
            endSourceIndex = endSourceIndex - 1
            txInCount = txInCount + 1
            If accumulatedBTC > chargeBTC * 1.001 Then
                Exit For
            End If
        Next I002
    End If
    If accumulatedBTC >= chargeBTC Then
        If accumulatedBTC - chargeBTC > 2.0 * AveragePurchase() And accumulatedBTC - chargeBTC > DustLimitSatoshis! * 2 Then
            REM Split leftover into two sources.
            SplitLeftOver = 1
        End If
    Else
        DebugMessage(" Insufficient funds. Charge:" + Str$(chargeBTC) + " Accumulated:" + Str$(accumulatedBTC))
        ErrorCode% = 7
        PaymentTXBytes = ""
        Exit Sub
    End If
    If SavedWaitingAmount < DustLimitSatoshis! Then
        DebugMessage(" Charge is below the dust limit. Limit:" + Str$(DustLimitSatoshis!))
        ErrorCode% = 17
        PaymentTXBytes = ""
        Exit Sub
    End If
    Call CreateChargeArray(ErrorCode%, SplitLeftOver, startFromIndex, endSourceIndex, directionCounter, StringBTCCharges)
    If ErrorCode% <> 0 Then
        Exit Sub
    End If
    REM Part 3: Build TX.
    REM A Build as it should be for signature.
    REM B Save script insertion indexes as you build.
    REM C Use info about start/end index and whether to split source or not.
    Private InsertionPoints(0 To txInCount) As Integer
    Private currentIndex As Integer = 0
    Private I003 As Integer
    Private I00C As Integer = 0

    PaymentTXBytes = ""
    REM Version:
    PaymentTXBytes = PaymentTXBytes + Chr$(&H1, &H0, &H0, &H0)
    currentIndex = 4
    REM Nr. of inputs (simple hex valid up to 254 or so and we have tops 30 sources):
    PaymentTXBytes = PaymentTXBytes + Chr$(txInCount)
    currentIndex = currentIndex + 1

    For I003 = startFromIndex To endSourceIndex Step +directionCounter
        PaymentTXBytes = PaymentTXBytes + TXSources(I003).TXHash
        currentIndex = currentIndex + 32
        PaymentTXBytes = PaymentTXBytes + TXSources(I003).TXIndex
        currentIndex = currentIndex + 4
        InsertionPoints(I00C) = currentIndex
        REM For signing we put temporarily an empty script:
        PaymentTXBytes = PaymentTXBytes + Chr$(&H0)
        currentIndex = currentIndex + 1
        REM Unused sequence number, always FFFF FFFF
        PaymentTXBytes = PaymentTXBytes + Chr$(&HFF, &HFF, &HFF, &HFF)
        currentIndex = currentIndex + 4
        I00C = I00C + 1
    Next I003

    REM Outs count append.
    Private ArrayHasMiningFee As Integer = 0
    For I003 = 0 To UBound(StringBTCCharges)
        If StringBTCCharges(I003).ChargeType = 3 Then
            ArrayHasMiningFee = 1
            Exit For
        End If
    Next I003
    If ArrayHasMiningFee = 1 Then
        PaymentTXBytes = PaymentTXBytes + Chr$(UBound(StringBTCCharges))
    Else
        PaymentTXBytes = PaymentTXBytes + Chr$(UBound(StringBTCCharges) + 1)
    End If

    REM Order: Payment (, CardFee) (, TerminalFee) (, MinersFee) , LeftOver1 (, LeftOver2) -> Miners fee simply left out.
    For I003 = 0 To UBound(StringBTCCharges)
        If StringBTCCharges(I003).ChargeType <> 3 Then
            PaymentTXBytes = PaymentTXBytes + StringBTCCharges(I003).Amount
        End If
        If StringBTCCharges(I003).ChargeType = 0 Then
            If SavedWaitingAddressType = 0 Then
                PaymentTXBytes = PaymentTXBytes + Chr$(&H19)
                REM OP_Dup Op_Hash160 Op_Push20 data OP_EqualVeriry OP_Checksig:
                PaymentTXBytes = PaymentTXBytes + Chr$(&H76, &HA9, &H14) + SavedWaitingAddress + Chr$(&H88, &HAC)
            Else
                PaymentTXBytes = PaymentTXBytes + Chr$(&H17)
                REM OP_HASH160 OP_Push20Bytes P2SH-bytes OP_Equal:
                PaymentTXBytes = PaymentTXBytes + Chr$(&HA9, &H14) + SavedWaitingAddress + Chr$(&H87)
            End If
        ElseIf StringBTCCharges(I003).ChargeType = 1 Then
            PaymentTXBytes = PaymentTXBytes + Chr$(&H19)
            REM OP_Dup Op_Hash160 Op_Push20 data OP_EqualVeriry OP_Checksig:
            If AltCardFeeHash160Addr$ = "" Then
                PaymentTXBytes = PaymentTXBytes + Chr$(&H76, &HA9, &H14) + CardFeeHash160Addr$ + Chr$(&H88, &HAC)
            Else
                If FeeCycleCounter >= AltCardFeeAddressCount Then
                    FeeCycleCounter = FeeCycleCounter - AltCardFeeAddressCount
                    PaymentTXBytes = PaymentTXBytes + Chr$(&H76, &HA9, &H14) + AltCardFeeHash160Addr$ + Chr$(&H88, &HAC)
                Else
                    FeeCycleCounter = FeeCycleCounter + 10
                    PaymentTXBytes = PaymentTXBytes + Chr$(&H76, &HA9, &H14) + CardFeeHash160Addr$ + Chr$(&H88, &HAC)
                End If
            End If
        ElseIf StringBTCCharges(I003).ChargeType = 2 Then
            If SavedWaitingTerminalAddressType = 0 Then
                PaymentTXBytes = PaymentTXBytes + Chr$(&H19)
                REM OP_Dup Op_Hash160 Op_Push20 data OP_EqualVeriry OP_Checksig:
                PaymentTXBytes = PaymentTXBytes + Chr$(&H76, &HA9, &H14) + SavedWaitingTerminalAddress + Chr$(&H88, &HAC)
            Else
                PaymentTXBytes = PaymentTXBytes + Chr$(&H17)
                REM OP_HASH160 OP_Push20Bytes P2SH-bytes OP_Equal:
                PaymentTXBytes = PaymentTXBytes + Chr$(&HA9, &H14) + SavedWaitingTerminalAddress + Chr$(&H87)
            End If
        ElseIf StringBTCCharges(I003).ChargeType = 4 Or StringBTCCharges(I003).ChargeType = 5 Then
            PaymentTXBytes = PaymentTXBytes + Chr$(&H19)
            REM OP_Dup Op_Hash160 Op_Push20 data OP_EqualVeriry OP_Checksig:
            PaymentTXBytes = PaymentTXBytes + Chr$(&H76, &HA9, &H14) + Hash160KeyArray(0) + Chr$(&H88, &HAC)
        End If
    Next I003
    REM LockTime:
    PaymentTXBytes = PaymentTXBytes + Chr$(&H0, &H0, &H0, &H0)

    REM Remove used TXSources and add them to SpentTXes:
    Private SourcesCount As Integer = 0
    If startFromIndex <= endSourceIndex Then
        SourcesCount = endSourceIndex - startFromIndex
    Else
        SourcesCount = startFromIndex - endSourceIndex
    End If
    Private RemoveTXIds(0 To SourcesCount) As TXSourceIdInfo
    Private K000 As Integer = 0
    For I002 = startFromIndex To endSourceIndex Step +directionCounter
        RemoveTXIds(K000).TXHash = TXSources(I002).TXHash
        RemoveTXIds(K000).TXIndex = TXSources(I002).TXIndex
        SpentTXAdd(RemoveTXIds(K000))
        K000 = K000 + 1
    Next I002
    For I002 = 0 To SourcesCount
        Call RemoveSource(RemoveTXIds(I002))
    Next I002

    REM Part 4: Make hashes for signing and sign each:
    Private TempString As String
    Private DERBytesLength As Integer = 0
    Private DERXLength As Integer = 0
    Private DERYLength As Integer = 0
    Private TXLen As Integer
    REM We assume the returned signature is 64 bytes of R and S concatenated.
    Private Signatures(0 To txInCount) As String
    REM Private Signature as String REPLACED WITH EEPROM "TXSignature" (as fix attempt for access/name overlap issues)

    TXLen = Len(PaymentTXBytes)

    For I003 = 0 To (txInCount - 1) Step 1
        TempString = Chr$(&H19)
        TempString = TempString + Chr$(&H76, &HA9, &H14) + Hash160KeyArray(0) + Chr$(&H88, &HAC)

        REM (+2 because 0 index for Mid$ is 1 and we skip the empty placeholder script of 1 byte)
        REM (Last 4 bytes are SIGHASH_ALL)
        TempString = Mid$(PaymentTXBytes, 1, InsertionPoints(I003)) + TempString_
         + Mid$(PaymentTXBytes, InsertionPoints(I003)+2, TXLen - InsertionPoints(I003)-1) + Chr$(&H01,&H00,&H00,&H00)

        TempString = Sha256Hash(Sha256Hash(TempString))

        Call ECpSignDSA(TempString, Key1, TXSignature)
        If LibError <> 0 Then
            ErrorCode% = 16
            DebugMessage(" ECpDSA Library error:" + Str$(LibError))
            Exit Sub
        End If

        REM Enforce low signature S values:
      Private SigS as String*32
        SigS = ReverseByteString(Mid$(TXSignature, 33, 32))
        Private SCompareDifference As String
        Private SFirstLargerOrSame As Byte
        Call CompareStrings(MaxSValue, SigS, SCompareDifference, SFirstLargerOrSame)
        If SFirstLargerOrSame = 0 Then
            SigS = SubtractStrings(SPivotValue, SigS)
            TXSignature = Mid$(TXSignature, 1, 32) + ReverseByteString(SigS)
        End If

        Signatures(I003) = TXSignature
    Next I003
    REM Part 5: Signature insert, insert an DER encode (https://bitcointalk.org/index.php?topic=653313.0):
    For I003 = 0 To (txInCount - 1) Step 1
        DERBytesLength = 6
        DERXLength = 0
        DERYLength = 0
        If Asc(Mid$(Signatures(I003), 1, 1)) >= &H80 Then
            DERXLength = DERXLength + 1
        End If
        If Asc(Mid$(Signatures(I003), 33, 1)) >= &H80 Then
            DERYLength = DERYLength + 1
        End If
        DERBytesLength = DERBytesLength + DERXLength + DERYLength

        REM Total Sig length + sig type byte + pubkey version byte + 64 bytes pubkey + 2 opcodes + DER bytes (as VarInt):
        TempString = Chr$(Len(Signatures(I003)) + 1 + 1 + 64 + 2 + DERBytesLength)

        If Len(Signatures(I003)) + 1 + DERBytesLength > 75 Then
            REM + 1 extra for the OP_PUSH byte added to TOTAL length:
            TempString = Chr$(Len(Signatures(I003)) + 1 + 1 + 64 + 2 + DERBytesLength + 1)
            REM Code signifying push byte of length 1 byte - actual push length comes after this if.
            TempString = TempString + Chr$(&H4B)
        End If
        REM Push this amount of bytes:
        TempString = TempString + Chr$(Len(Signatures(I003)) + 1 + DERBytesLength)

        REM First DER encoding bytes, sequence type and sequence length:
        TempString = TempString + Chr$(&H30) + Chr$(&H44 + DERXLength + DERYLength)
        REM Integer type and length:
        TempString = TempString + Chr$(&H2) + Chr$(&H20 + DERXLength)
        REM R of R,S signature:
        If DERXLength = 1 Then
            TempString = TempString + Chr$(0)
        End If
        TempString = TempString + Mid$(Signatures(I003), 1, 32)
        REM Integer type and length:
        TempString = TempString + Chr$(&H2) + Chr$(&H20 + DERYLength)
        If DERYLength = 1 Then
            TempString = TempString + Chr$(0)
        End If
        REM S part of signature + 01 hash_type byte 
        TempString = TempString + Mid$(Signatures(I003), 33, 32) + Chr$(&H1)
        REM Second push byte:
        TempString = TempString + Chr$(&H41)
        REM Pubkey version byte:
        TempString = TempString + Chr$(&H4)
        REM Pub key bytes, both x and y:
        TempString = TempString + PubKey1

        REM Temp string is the real claim script, insert it: (+2 because 0 index for Mid$ is 1)
        PaymentTXBytes = Mid$(PaymentTXBytes, 1, InsertionPoints(I003)) + TempString_
         + Mid$(PaymentTXBytes, InsertionPoints(I003) + 2, TXLen - InsertionPoints(I003)-1)
        TXLen = Len(PaymentTXBytes)

        For I00C = I003 To txInCount
            REM (-1 because script was len 1 before overwriting)
            InsertionPoints(I00C) = InsertionPoints(I00C) + Len(TempString) - 1
        Next I00C
    Next I003
End Sub