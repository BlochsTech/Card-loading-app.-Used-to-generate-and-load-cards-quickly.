Rem 8 - 11 == average
Eeprom MedianArray(0 To 19) as Single
Rem Dim Dynamic MedArray(20) as Long would be a dynamic array, above is fixed.
Rem Dim means "public". Dynamic keyword costs 1 byte.
Rem Eeprom ReDim DecimalArray(20) as Integer
Rem 0 is first index and the smallest number

Eeprom StatisticsInitialized@ = 0
Eeprom InitialAverageAmount! = InitialAverageAmountSetting!

Eeprom TotalPurchaseCount% = 0

Function AveragePurchase() as Single
   Private I as Integer
   If StatisticsInitialized@ = 0 Then
      For I = 0 To 19
         MedianArray(I) = InitialAverageAmount!
      Next I
      StatisticsInitialized@ = 1
      AveragePurchase = InitialAverageAmount!
   Else
      Private sum as Single
      sum = 0
      For I = 8 To 11
         sum = sum + MedianArray(I)
         Rem BTC addition and division needed... Are singles better? Yeeees... dammit!!!
         Rem GO!
      Next I
      AveragePurchase = sum/4
   End If
End Function

Function CommitAmount (amount!)
   Rem BTC func for this also? +/- ?
   Private I,J as Integer
   Private btc as Single
   btc = amount!
   For I = 0 To 19
      If (MedianArray(0) >= btc) Then
         Rem Changes to the ends shift the entire array to avoid permanent dissynchronization.
         For J = 19 To 1 Step -1
            MedianArray(J) = MedianArray(J-1)
         Next J
         MedianArray(0) = btc
         Exit For
      Else If (MedianArray(19) <= btc) Then
         For J = 0 To 18 Step +1
            MedianArray(J) = MedianArray(J+1)
         Next J
         MedianArray(19) = btc
         Exit For
      Else If (btc >= MedianArray(I)) And (btc <= MedianArray(I+1)) Then
         Rem Replace the one of largest difference:
         If AbsDiff(MedianArray(I),btc) > AbsDiff(MedianArray(I+1),btc) Then
            MedianArray(I) = btc
         Else
            MedianArray(I+1) = btc
         End If
         Exit For
      End If
      Rem If(
      Rem 21 btc = max long....
      Rem int number int exponent (1,0 = 1BTC 1,-8=1Satoshi.... also define decimals to avoid loss)
   Next I
   If TotalPurchaseCount% < 30000 Then
      TotalPurchaseCount% = TotalPurchaseCount% + 1
   End If
End Function