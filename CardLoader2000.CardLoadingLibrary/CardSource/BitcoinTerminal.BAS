Rem Variabled MUST be explicitly declared:
Option Explicit
Rem base of arrays MUST be explicitly declared:
Option Base Explicit

Rem Files must be included here to be in project:
#Include BTCCommands.DEF
#Include CARDUTIL.DEF

Rem for the printing:
#Include COLOURS.DEF

Rem  Declare locally defined procedures
Declare Sub Test()
Declare Sub CardTerminalTest(X$)

Rem Execution starts here:
Call WaitForCard()
ResetCard : Call CheckSW1SW2()
Call Test()

Sub Test()

  FgCol = BrightGreen : Print : Print "Card/terminal test:"
  FgCol = BrightWhite
  Call CardTerminalTest ("Terminal says 'hello'.")

End Sub

Sub CardTerminalTest (X$)
    Public int as Integer
    Rem Print X$ ; " sent to card. "
    Call GetAddresses (X$) : Call CheckSW1SW2()
    Print X$
    Rem Print "Next command:"
    Rem Call TestCommand (X$) : Call CheckSW1SW2()
    
    Rem Print Asc(X$) ;
    Rem Print Asc(Mid$(X$,2)) ;
    Rem Print Asc(Mid$(X$,3))
End Sub