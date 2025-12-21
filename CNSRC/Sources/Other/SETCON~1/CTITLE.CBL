      $ set Ans85 Mf NoOsvs NoVsc2 NoQual NoAlter DefaultByte"00"
       special-names.
           call-convention 74 is WINAPI.
       working-storage section.
       78 programName value 'TITLE'.
       1   SetConsoleTitleReturn pic xxxx comp-5.
       1   wsKeyStroke pic x.
       procedure division.
           display spaces upon crt
           call WINAPI "SetConsoleTitleA"
               using by reference z"My Application"
               returning SetConsoleTitleReturn
           display programName ': Starting.'
           display programName ': Press Enter Key. ' no advancing
           accept wsKeyStroke
           display programName ': Ending.'
           stop run.
