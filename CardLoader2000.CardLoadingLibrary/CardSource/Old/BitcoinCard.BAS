Option Explicit
Option Base Explicit
#Pragma Allow9xxx
Rem Page 28 of manual. Id of card for selection purposes.
#Pragma UID(Double)
Rem Answer to reset, probably defined in Tag 4 specification. (I THINK THE x80 IS WHY ONLY x80 COMMANDS WORKED!!! May have disproved this already..  no matter..)
#Pragma ATS(TA1=&H11, HB=Chr$(&H80))
Rem CPU processor speed at default for NFC. RSA/EC up one from default and DES/AES coprocessor speeds down one.
Rem should not be changed at runtime as power fluctuations will interfere with RF communication. It is set as one byte, CPU is bits 0-3, AES co-processor is bit 4 and EC co proc is 5-7.
Rem Was 8
#Pragma RFClock (62,72,4)

Rem first so includes can see it.
Eeprom GlobalDebugValue$ = "NotUsed"

Function DebugMessage(newDebugMessage as String) as String
    GlobalDebugValue$ = GlobalDebugValue$ + newDebugMessage
    If Len(GlobalDebugValue$) > 255 Then
        GlobalDebugValue$ = Mid$(GlobalDebugValue$, Len(GlobalDebugValue$)-254, 255)
    End If
    DebugMessage = GlobalDebugValue$
End Function

Rem You cannot add files normally; you must create and save them, include them as below and then rebuild the project. They will then appear.
#Include BTCCommands.DEF
#Include SetupConstants.DEF
#Include TXDataClasses.DEF
#Include MathUtil.BAS
#Include PurchaseStatistics.BAS
#Include VignereCipher.BAS
#Include GeneralEC256.BAS
#Include TXDataHandler.BAS
#Include EC-P.DEF
#Include TXPaymentCreator.BAS
#Include RequestClasses.DEF
#Include RequestHandler.BAS
#Include FILEIO.DEF

Rem BOBC:
Declare ApplicationID="BlochstechOpenBitcoinCard"

Rem Speeds up execution by limiting expected stack size.
Rem Note: It may cause errors if used up; raise it in that case.
Rem #Stack 570
Rem Private/Public data is put on stack. If RAM runs out EEPHEAP is used which is slow.
Rem Our critical multiplication and div alogrithms use private data so we set stack size LOW.
Rem this is because Arrays take only 2 bytes on stack, rest is in RAMHEAP.
Rem RAMHEAP becomes smaller if stack is large.

Rem Should lock card root folder access as forbidden.
Read Lock "\"
Write Lock "\"

Dir "\"
    File "CurveFile" Len=0
        input "C:\Users\mcb\Dropbox\Hobby stuff\75Branch\secp256k1.16.bin"
        rem input "C:\Users\martin clemens bloch\Dropbox\Hobby stuff\75Branch\secp256k1.16.bin"
        Rem mcb for work computer
        Rem Martin Clemens Bloch for home computer.
End Dir

Rem set to false when resetting and true when starting data transfer process or payment process.
Rem Eeprom ProcedureInProgress as Byte

Rem Callable anytime.
Command &H80 &H00 Network (returnvalue as Integer)

Rem NetworkId is from SetupConstants file. (refers to the Bitcoin/alt-coin network)
    returnvalue = NetworkId

End Command

Rem Callable anytime.
Command &H80 &H01 Protocol (returnvalue%)

Rem ProtocolVersion is from SetupConstants file. (Refers to the card API)
    returnvalue% = ProtocolVersion

End Command

Rem Callable anytime. Let it stay as non-hash160 addresses.
Command &H80 &H02 GetAddresses (returnvalue$)

    returnvalue$ = Addr1
    Rem + ":" + Addr2 + ":" + Addr3 + ":" + Addr4 + ":" + Addr5

End Command

Rem Callable anytime, BUT once called only lower amounts may be charged. 0 btc clears the charge and restarts the delay lock as a normal transaction.

Rem IMPORTANT: 8 decimals assumed for BOBC-0 protocol.
Rem We COULD get this from the terminal, but the current format is uint64 and we have no idea what the future many-digit format will be.
Rem HOWEVER: We CAN still shape the API so that it is compatible with future formats: Amount is in lowest decimal units (satoshi for 8 decimals) and exp is always positive.
Rem This will be ignored by this card, but future cards can use same call type/BOBC-0 with 9 decimals for instance.
Command &H80 &H03 RequestPayment(ErrorCode%, RequiresPIN@, AmountMantissa%, AmountExp@, FeeMantissa%, FeeExp@, TerminalAmountMantissa%, TerminalAmountExp@, Decimals@, ReceiverAddressType@, ReceiverAddress as String*20, TerminalReceiverAddressType@, TerminalReceiverAddress as String*20, returnvalue as String*8)

    Rem Exp is signed byte 127->-128  if(byte>127) Then -byte+127
    Rem Main is basically an interface, put most validation in sub functions/supporters.
    returnValue = SaveRequest(ErrorCode%, RequiresPIN@, AmountMantissa%, AmountExp@, FeeMantissa%, FeeExp@, TerminalAmountMantissa%, TerminalAmountExp@, Decimals@, ReceiverAddressType@, ReceiverAddress, TerminalReceiverAddressType@, TerminalReceiverAddress)
    Rem What do we return on error? sw1/2 bytes? No; 8String = error:00
    Rem ..=Amount too large. .. = too small (20median/10000). 00=decimals wrong. 01=address invalid. 02=Incorrect command order. (.. auto-fix amount to the max/min)

End Command

Rem After RequestPayment only.
Rem At no PIN required any PIN is accepted. Card should have way to communicate, min, max and no-PIN amounts...
Command &H80 &H04 GivePINGetTx(ErrorCode%, Pin%, EndOfTXStream@, TXBytes as String*245)

    Call GivePINGetTXSub(ErrorCode%, Pin%, EndOfTxStream@, TXBytes as String*245)

End Command

Rem Callable anytime (after addresses makes sense) (return count instead of hasmore bool? Yes and send wanted index.)
Command &H80 &H05 GetSources(ErrorCode%, NextSourceIndex@, OutIndex as String*4, TXHash as String*32, Value as String*8, Verified@)

    Rem Card cycles through its known sources. Purpose: To prevent getting known data in next steps.
    Call GetOneSource(ErrorCode%, NextSourceIndex@, OutIndex, TXHash, Value, Verified@)

End Command

Rem Any time (best to call getSources first). Resets info commands progress.
Rem This first to check if valid at all. (EndOfTx gives end index if true so we easily know the packet end)
Rem If terminal sends accepted false then existing data is cleared!
Command &H80 &H06 GiveTX(ErrorCode%, Accepted@, EndOfTXStream@, TXBytes as String*246)

    Rem Ongoing: Parse TXBytes into source data type.
    Rem Step 1: If not end, add to chached TX data. (more EEPROM than max command length)
    Call ValidateTX(ErrorCode%, Accepted@, EndOfTXStream@, TXBytes)
    Rem Step 2: Validate hash/source in GiveHeader/GiveHash.

End Command

Rem After GiveTX only. This second to check if valid at all + second heaviest operation.
Rem (Accepted = 1 for "ok and done" and 0 for "cannot use TX", BOBC errors for exceptions).
Rem Data is block header (first 6 fields only). Contains reference to previous block aswell as merkle root.
Command &H80 &H07 GiveHeader(ErrorCode%, Accepted@, VerifyingTXHash as String*32, Data as String*80)
    Call CheckDifficulty(ErrorCode%, Accepted@, VerifyingTXHash, Data)
End Command

Rem After GiveHeader only. This last because its possibly the heaviest operation.
Rem Checks hashes starting with TX hash and ending at confirmed merkleroot. Card checks validity.
Rem Accept only at confirm.
Command &H80 &H08 GiveHash(Accepted@, RightNode@, Data as String*32)
    Call CheckMerkleBranch(Accepted@, RightNode@, Data)
End Command

Rem callable anytime. Returns necessary calls remaining to unlock card for PIN usage.
Command &H80 &H09 DelayUnlockCard(returnvalue%)
    returnvalue% = DelayUnlockRequest()
End Command

Rem Max amount that will not be cut by card.
Command &H80 &H0A MaxAmount(AmountMantissa%, AmountExp@)
    Call SingleToSimpleFloat((AverageAmountsMax * AveragePurchase()), AmountMantissa%, AmountExp@)
End Command

Rem Full desciption of what the card is waiting for PIN for, used by terminal to check card state/deal with some scenarios.
Command &H80 &H0B WaitingCharge(AmountMantissa%, AmountExp@, FeeMantissa%, FeeExp@, TerminalAmountMantissa%, TerminalAmountExp@, ReceiverAddressType@_
    , ReceiverAddress as String*20, TerminalReceiverAddressType@, TerminalReceiverAddress as String*20, CardFeeMantissa%, CardFeeExp@, RequiresPIN@, VignereCode as String*8_
    , IsResetRequest@)
    
    Call WaitingChargeRequest(AmountMantissa%, AmountExp@, FeeMantissa%, FeeExp@, TerminalAmountMantissa%, TerminalAmountExp@, ReceiverAddressType@_
        , ReceiverAddress as String*20, TerminalReceiverAddressType@, TerminalReceiverAddress as String*20, CardFeeMantissa%, CardFeeExp@, RequiresPIN@, VignereCode as String*8_
        , IsResetRequest@)

End Command

Rem This function is used to prevent card from constructing TXs with invalid/old data. (in case another wallet has spent from the cards addresses)
Command &H80 &H0C DumpTXSources()
    Rem Delete all known sources. Do not move them to used array, just remove them.
    Rem No security considerations necessary, another terminal can always give unused sources back.
    Rem Card cannot make its own sources due to transaction malability.
    Rem Only consideration: Do NOT dump SPENT TX sources, those will only be dumped when their array is full - to prevent double spends from card.
    Private I00F as Integer = 0
    For I00F = 0 To 29
        TXSources(I00F).TXHash = ""
        TXSources(I00F).Amount = ""
        TXSources(I00F).TXIndex = ""
        TXSources(I00F).Verified = 0
        TXSources(I00F).AddressIndex = 0
    Next
End Command

Command &H80 &H0D Decimals(ExpextedDecimals%)
    ExpextedDecimals% = ExpectedDecimals
End Command

Rem If false device has own connection.
Command &H80 &H0E WantData(WantResponse%)
    WantResponse% = 1
End Command

Command &H80 &H0F MaxSources(MaxResponse%)
    MaxResponse% = 30
End Command

Command &H80 &H10 ResetPinCode(ErrorCode%, PukCodeValue&, NewPinCode%)
    If DelayCounter& = 0 Then
        If PukCodeValue& = PUK Then
            PIN = NewPinCode%
            PINPunishTime& = 0
        Else
            PukCodeValue& = -1
            If PINPunishTime& < 100000000 Then
                Rem If to prevent overflow clearing.
                PINPunishTime& = PINPunishTime& + WrongCodePunishIncrement
            End If
        End If
        DelayCounter& = PINPunishTime& + DelayLockSeconds
    Else
        ErrorCode% = 8
    End If
End Command

Rem Use not accepted header instead.
Rem Command &H80 &H10 ExpectedDifficulty(ZeroBytes@)
Rem     ZeroBytes@ = LogN((AverageDifficulty!/10000.0), 256)
Rem End Command


Rem NEVER change old commands, simply add on new ones in newer BOBC protocols (if possible.)

Rem Eeprom TestState@ = &H00
Rem USE 80!!!!!!!!!!!!!
Rem Remember to change commands definitions if you change commands here, else you will likely get a type mismatch error.
Rem Debug command, INS = FF, called anytime AND may be different for different vendors. To be used for diagnostics.
Command &H80 &HFF Debug(returnvalue as String)
    REM First index is 1 and length MUST be maximum 255.
    If Len(GlobalDebugValue$) > 255 Then
        GlobalDebugValue$ = Mid$(GlobalDebugValue$, 1, 255)
    End If
    returnvalue = GlobalDebugValue$
End Command

Rem Terminal: NFC comm. with card!
Rem Terminal: Load card with sources.
Rem Terminal: Make request.
Rem Terminal: Send transaction with electrum.
Rem Plan: Work full time.