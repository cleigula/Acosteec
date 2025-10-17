#INCLUDE "PROTHEUS.CH"

User Function SF2460I()

    RecLock("SF2",.F.) 
    F2_USERF := Alltrim( UsrFullName(RetCodUsr()))
  
Return()
