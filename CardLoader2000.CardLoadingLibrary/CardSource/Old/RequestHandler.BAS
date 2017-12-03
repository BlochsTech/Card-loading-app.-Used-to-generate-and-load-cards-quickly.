Rem RequestHandler function/sub?? + Eeproms here... not eeproms? 
Rem #Include KeyAddressPairs.DEF
Rem #Include Bitcoin.BAS Is included in PurchaseStatistics.

Rem Used to lock the card for a while preventing the merchant from double charging the card.
Rem See SetProcessorSpeed in manual.
Eeprom DelayCounter& = DelayLockSeconds
Rem Is incremented with WrongCodePunishIncrement sec for each wrong PIN and cleared on correct PIN. Leads to card becoming more or less locked after some time. (1 year for 25% chance of bruteforce)
Eeprom PINPunishTime& = 0
Rem Sets a limit on the no PIN behaviour
Eeprom ChargedSincePIN! = 0.0

Rem Top 10 are safe ie. least used will only get replaced by new trusted/re-used old trusted.
Rem Bottom 20 are cycled, any new address will replace least used.
Eeprom TrustedAddresses(0 To 9) as TrustInfo
Eeprom TrustCandidates(0 To 19) as TrustInfo
Rem UBound(array) used for capacity, need var for used length since its an array, not a list.

#Include LoggingUtil.BAS

Sub RemoveTrustInfo(RemoveAddress as TrustInfo, TrustInfoArray() as TrustInfo)
   Rem Basically reverse of InsertAtTop:
   Rem 1. Go through and do nothing.
   Rem 2. At found, remove and start replacing with next.
   Rem 3. If found in TrustedAddreses, a trusted address in candidates should be moved up.
   Private StartShifting as Byte = 0
   Private Iaaf as Integer = 0
   For Iaaf = 0 To UBound(TrustInfoArray)
      If TrustInfoArray(Iaaf).Address = RemoveAddress.Address Then
         StartShifting = 1
      End If
      If StartShifting = 1 And Iaaf < UBound(TrustInfoArray) Then
         TrustInfoArray(Iaaf) = TrustInfoArray(Iaaf+1)
      Else If StartShifting = 1 Then
         TrustInfoArray(Iaaf).Address = ""
         TrustInfoArray(Iaaf).Verified = 0
      End If
   Next Iaaf
End Sub

Sub InsertAtTop(TopAddress as TrustInfo, TrustInfoArray() as TrustInfo)
   Private OldTempTrustInfo as TrustInfo
   Private NewTempTrustInfo as TrustInfo
   Private Iaae as Integer
   Rem 1. Shift all infos up in the array (index 0 being the top ranked spot)
   Rem 2. If address not found, put in spot 0 at the end.
   Rem 3. If address FOUND, only above it should have shifted down.
   For Iaae = 0 To UBound(TrustInfoArray)
      Rem If is TopAddress, topaddress is replaced and cycle stopped:
      If TrustInfoArray(Iaae).Address = TopAddress.Address Then
         If Iaae > 0 Then
            TrustInfoArray(Iaae) = OldTempTrustInfo
         End If
         Exit For
      Rem Move other addreses down in rank:
      Else
         NewTempTrustInfo = TrustInfoArray(Iaae)
         TrustInfoArray(Iaae) = OldTempTrustInfo
         OldTempTrustInfo = NewTempTrustInfo
      End If
      Rem Set top address:
      If Iaae = 0 Then
         TrustInfoArray(Iaae) = TopAddress
      End If
   Next Iaae
End Sub

Function FindTrustInfo(Address as String*20) as Byte
   Rem Go through both and return Info object if found:
   Private Iaca as Integer = 0
   For Iaca = 0 To UBound(TrustCandidates)
      If TrustCandidates(Iaca).Address = Address Then
         If TrustCandidates(Iaca).Verified >= 2 Then
            FindTrustInfo = 1
         Else
            FindTrustInfo = 0
         End If
         Exit Function
      End If
   Next Iaca
   For Iaca = 0 To UBound(TrustedAddresses)
      If TrustedAddresses(Iaca).Address = Address Then
         If TrustedAddresses(Iaca).Verified >= 2 Then
            FindTrustInfo = 1
         Else
            FindTrustInfo = 0
         End If
         Exit Function
      End If
   Next Iaca
   FindTrustInfo = 0
End Function

Sub IncrementTrust(Address as String*20)
   Rem 1. Find TrustInfo. Add to Verified.
   Rem 2. If verified move to top rank spot else top candidate spot.
   Private TempInfo as TrustInfo
   Private FoundAsCandidate as Byte = 0
   Private FoundAsTrusted as Byte = 0
   Private Iaba as Integer = 0
   For Iaba = 0 To UBound(TrustCandidates)
      If TrustCandidates(Iaba).Address = Address Then
         TempInfo = TrustCandidates(Iaba)
         FoundAsCandidate = 1
      End If
   Next Iaba
   If TempInfo.Address = Address Then
      If TempInfo.Verified < 2 Then
         TempInfo.Verified = TempInfo.Verified + 1
      End If
      If TempInfo.Verified < 2 Then
         Call InsertAtTop(TempInfo,TrustCandidates)
         Exit Sub
      Else
         Rem Remove current in candidates.
         Call RemoveTrustInfo(TempInfo, TrustCandidates)
         Rem Bottom trusted should be inserted in Candidates.
         Call InsertAtTop(TrustedAddresses(UBound(TrustedAddresses)), TrustCandidates)
         Rem Insert current at top trusted.
         Call InsertAtTop(TempInfo,TrustedAddresses)
         Exit Sub
      End If
   End If
   If FoundAsCandidate = 0 Then
      For Iaba = 0 To UBound(TrustedAddresses)
         If TrustedAddresses(Iaba).Address = Address Then
            TempInfo = TrustedAddresses(Iaba)
            Rem Move up to top:
            Call RemoveTrustInfo(TempInfo, TrustedAddresses)
            Call InsertAtTop(TempInfo, TrustedAddresses)
            FoundAsTrusted = 1
            Exit For
         End If
      Next Iaba
   End If
   If FoundAsTrusted = 0 And FoundAsCandidate = 0 Then
      TempInfo.Address = Address
      TempInfo.Verified = 1
      Call InsertAtTop(TempInfo,TrustCandidates)
   End If
End Sub

Sub ResetChargeAmountsOnly()
   SavedWaitingAmount = 0.0
   SavedWaitingAddress = ""
   SavedWaitingAddressType = 0

   SavedWaitingFeeAmount = 0.0

   SavedWaitingTerminalAmount = 0.0
   SavedWaitingTerminalAddress = ""
   SavedWaitingTerminalAddressType = 0
   
   WaitingIsNoPinRequest = 0
End Sub

Sub ResetChargeAmounts()
   Call ResetChargeAmountsOnly()

   DelayCounter& = PINPunishTime& + DelayLockSeconds
   
   If BTCStringToSingle(AccumulatedCardFees) > DustLimitSatoshis! Then
      AccumulatedCardFees = Chr$(&H00,&H00,&H00,&H00, &H00,&H00,&H00,&H00)
   End If
End Sub

Rem See protocol document.
Function SaveRequest (ErrorCode%, RequiresPIN@, amountMantissa%, amountExp@, feeMantissa%, feeExp@, terminalAmountMantissa%, terminalAmountExp@, decimals@, addressType@, address as String*20, terminalAddressType@, terminalAddress as String * 20) As String*8
   Rem CHECK FOR ALL HACKS!
   Rem amount check too large/small, decimal check, address checks?
   
   If (addressType@ <> 0 And addressType@ <> 5)_
      Or (terminalAddressType@ <> 0 And terminalAddressType@ <> 5) Then
      ErrorCode% = 6
      Exit Function
   End If
   
   Private btc as Single
   Rem Satoshis are used!
   btc = 1.0 * amountMantissa% * SPow(10, amountExp@) + 1.0 * feeMantissa% * SPow(10, feeExp@) + 1.0 * terminalAmountMantissa% * SPow(10, terminalAmountExp@)
   
   If (btc > SavedWaitingAmount+SavedWaitingTerminalAmount+SavedWaitingFeeAmount_
      And SavedWaitingAmount+SavedWaitingTerminalAmount+SavedWaitingFeeAmount > 0)_
      Or WaitingIsResetRequest = 1 Then
      ErrorCode% = 15
      DebugMessage(" Amount is above waiting amount, card reset required. IsWaiting:" + Str$(WaitingIsResetRequest)_
      + " Amount:" + Str$(btc) + " Waiting:" + Str$(SavedWaitingAmount+SavedWaitingTerminalAmount+SavedWaitingFeeAmount))
      Exit Function
   End If
   
   Private noPINAmounts as Single = 0.001 + NoPINAmountsSetting!
   If ChargedSincePIN! + btc >= noPINAmounts * AveragePurchase()_
      Or btc > 1.5*AveragePurchase()_
      Or FindTrustInfo(address) = 0_
      Or (100.0*terminalAmountMantissa%*SPow(10, terminalAmountExp@)) > (1.0 * amountMantissa%*SPow(10, amountExp@)) Then
      Rem Use PIN/Delay required instead of error.
      RequiresPIN@ = 1
      WaitingIsNoPinRequest = 0
   Else
      RequiresPIN@ = 0
      WaitingIsNoPinRequest = 1
   End If
   
   If btc = 0 Then
      Call ResetChargeAmountsOnly()
      WaitingIsResetRequest = 1
      Rem Reset always requires pin code to avoid vignerecode cheating:
      WaitingIsNoPinRequest = 0
      RequiresPIN@ = 1
      Rem Only 000e000 vignere in this case for reset (since reset requires PIN):
      WaitingVignereCode = VignereResponse(btc)
      SaveRequest = WaitingVignereCode
      Exit Function
   Else If btc < SavedWaitingAmount+SavedWaitingTerminalAmount+SavedWaitingFeeAmount_
      Or (SavedWaitingAmount+SavedWaitingTerminalAmount+SavedWaitingFeeAmount = 0_
      And WaitingIsResetRequest = 0) Then
      Rem check decimals
      If decimals@ <> ExpectedDecimals Then
         Rem Wrong decimal count.
         ErrorCode% = 14
         Exit Function
      End If
      
      Rem Allow a transfer:
      Rem Check max amount.
      If 1.001 * AveragePurchase()*AverageAmountsMax < btc Then
         ErrorCode% = 5
         Exit Function
      End If
      
      SavedWaitingAddress = address
      SavedWaitingAmount = 1.0 * amountMantissa% * SPow(10, amountExp@)
      SavedWaitingAddressType = addressType@
      
      SavedWaitingFeeAmount = 1.0 * feeMantissa% * SPow(10, feeExp@)
      
      SavedWaitingTerminalAmount = 1.0 * terminalAmountMantissa% * SPow(10, terminalAmountExp@)
      SavedWaitingTerminalAddress = terminalAddress
      SavedWaitingTerminalAddressType = terminalAddressType@
      
      WaitingVignereCode = VignereResponse(btc)
      SaveRequest = WaitingVignereCode
   Else
      Rem Wrong command order. (Changing the amount upwards is not allowed as that would make the vignerecode pointless.)
      ErrorCode% = 2
   End If
End Function

Function DelayUnlockRequest() as Integer
   Private purposeLessCounter as Integer
   If DelayCounter& > 0 Then
      Private K as Integer
      For K = 0 To 16000
         purposeLessCounter = purposeLessCounter + 1
      Next K
      DelayCounter& = DelayCounter& - 1
      DelayUnlockRequest = DelayCounter&
   Else
      DelayUnlockRequest = 0
   End If
End Function

Sub WaitingChargeRequest(AmountMantissa%, AmountExp@, FeeMantissa%, FeeExp@, TerminalAmountMantissa%, TerminalAmountExp@, ReceiverAddressType@_
      , ReceiverAddress as String*20, TerminalReceiverAddressType@, TerminalReceiverAddress as String*20, CardFeeMantissa%, CardFeeExp@, RequiresPIN@, VignereCode as String*8_
      , IsResetRequest@)
      
   Call SingleToSimpleFloat(SavedWaitingAmount, AmountMantissa%, AmountExp@)
   
   Call SingleToSimpleFloat(SavedWaitingFeeAmount, FeeMantissa%, FeeExp@)
   
   Call SingleToSimpleFloat(SavedWaitingTerminalAmount, TerminalAmountMantissa%, TerminalAmountExp@)
   
   If CardFeeMultiplier! > 0.0 And (ExpireUsageTimes = 0 Or TotalPurchaseCount% < ExpireUsageTimes) Then
      Private NewWaitCardFees as String*8
      Private TempAccumulatedWaitCardFees as String*8
      NewWaitCardFees = ConvertSingleToString(SavedWaitingAmount*CardFeeMultiplier!)
      TempAccumulatedWaitCardFees = AddBTCStrings(AccumulatedCardFees, NewWaitCardFees)
      If BTCStringToSingle(TempAccumulatedWaitCardFees) >= DustLimitSatoshis! Then
         Call SingleToSimpleFloat(BTCStringToSingle(TempAccumulatedWaitCardFees), CardFeeMantissa%, CardFeeExp@)
      Else
         CardFeeExp@ = 0
         CardFeeMantissa% = 0
      End If
   Else
      CardFeeExp@ = 0
      CardFeeMantissa% = 0
   End If
   
   TerminalReceiverAddress = SavedWaitingTerminalAddress
   TerminalReceiverAddressType@ = SavedWaitingTerminalAddressType
   ReceiverAddress = SavedWaitingAddress
   ReceiverAddressType@ = SavedWaitingAddressType
   If WaitingIsNoPinRequest = 0 Then
      RequiresPIN@ = 1
   Else
      RequiresPIN@ = 0
   End If
   VignereCode = WaitingVignereCode
   IsResetRequest@ = WaitingIsResetRequest
End Sub

Eeprom ReturningTXBytes as String = ""
Eeprom ReturningTXBlock as Byte = 0
Sub GivePINGetTXSub(ErrorCode%, Pin%, EndOfTXStream@, TXBytes as String*245)
   
   If ReturningTXBytes = "" And ReturningTXBlock = 0 Then
      
      Rem 1. Verify PIN. Ignore Pin if IsNoPinRequest.
      If WaitingIsNoPinRequest = 0 Or WaitingIsResetRequest = 1 Then
         If DelayCounter& > 0 Then
         Rem Pin should not require unlocking, only VignereCode/Charging card. HELLOOO? What about brute forcing PIN!!!?
         Rem WRONG WRONG WRONG! Pin attempts AND Vignere (and  hence - charge) ALL must require unlocking.
         Rem Ok, Pin should, requesting should not, but requesting higher amounts/reset SHOULD require pin and hence unlock.
           ErrorCode% = 8
           Exit Sub
         End If
         If Pin% <> PIN Then
             Pin% = -1
             If PINPunishTime& < 100000000 Then
               Rem If to prevent overflow clearing.
               PINPunishTime& = PINPunishTime& + WrongCodePunishIncrement
             End If
             DelayCounter& = PINPunishTime& + DelayLockSeconds
             Exit Sub
         Else
            PINPunishTime& = 0
            ChargedSincePIN! = 0.0
            If WaitingIsResetRequest = 1 Then
               WaitingIsResetRequest = 0
               Exit Sub
            End If
         End If
      End If
      
      Rem 2. Verify waiting address and amount. (Double check)
      If SavedWaitingAddress = "" Then
         ErrorCode% = 6
         Exit Sub
      End If
      If SavedWaitingAmount + SavedWaitingFeeAmount + SavedWaitingTerminalAmount > _
         1.001*AveragePurchase()*AverageAmountsMax Or_
         SavedWaitingAmount = 0 Then
         ErrorCode% = 5
         DebugMessage(" Amount charged is above maximum or 0.")
         Exit Sub
      End If
      
      Rem 3. Generate TX using waiting amount and charge.
      ReturningTXBlock = 0
      Call CreatePaymentTX(ErrorCode%, ReturningTXBytes)
      
      If ErrorCode% <> 0 Then
         Exit Sub
      End If
      
      Rem 4. Commit waiting amount to statistics.
      ChargedSincePIN! = ChargedSincePIN! + SavedWaitingAmount + SavedWaitingFeeAmount + SavedWaitingTerminalAmount
      
      CommitAmount(SavedWaitingAmount)
      Call IncrementTrust(SavedWaitingAddress)
      
      Rem DebugMessage(" AvgPost:" + Str$(AveragePurchase()))
      Rem Call LogAverageArray()
      Rem Call LogSpentTXes()
      Rem Call LogTrustInfo()
      Rem DebugMessage(" WaitTrust:" + Str$(FindTrustInfo(SavedWaitingAddress)))
      
      Call ResetChargeAmounts()
      Rem Resetting also sets delay.
      
   Else If ReturningTXBytes <> "" And ReturningTXBlock = 0 Or_
      ReturningTXBytes = "" And ReturningTXBlock <> 0 Then
      
      ReturningTXBlock = 0
      ReturningTXBytes = ""
      ErrorCode% = 1
      DebugMessage(" Line 349+/-, RequestHandler.BAS. Related to 'ReturningTXBytes'.")
      Exit Sub
   End If
   
   Rem 5. Send packages then reset so card is ready for next cycle.
   If Len(ReturningTXBytes) - ReturningTXBlock * 245 <= 245 Then
      TXBytes = Mid$(ReturningTXBytes, ReturningTXBlock*245+1, Len(ReturningTXBytes) - ReturningTXBlock * 245)
      EndOfTXStream@ = Len(ReturningTXBytes) - ReturningTXBlock * 245
      ReturningTXBytes = ""
      ReturningTXBlock = 0
   Else
      TXBytes = Mid$(ReturningTXBytes, ReturningTXBlock*245+1, 245)
      EndOfTXStream@ = 0
      ReturningTXBlock = ReturningTXBlock + 1
   End If
End Sub

Rem Slogan list:
Rem "Not without incident" "I am a financial terrorist" "I back Bitcoin" "Be your own bank" "Obey me world" "Your mom now takes Bitcoin"
Rem "Internet funny money" "Eroding the nation state" "Disproving economics" "Works anywhere in the solar system"