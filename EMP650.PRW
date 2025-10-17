/*
PE na geracao dos empenhos
TRS - Caxias do Sul
31/05/2022 - troca o armazem dos empenhos para FB_LOCEMP
*/
User Function Emp650()
Local nX:= 0
Local cLocal:= SuperGetMv("FB_LOCEMP", .F., "04")
If xFilial("SC2")=="0101"
    For nX:= 1 To Len(aCols)
        If !aCols[nX,Len(aCols[nX])]
            aCols[nX, 3]:= cLocal
        EndIf
    Next nX
Endif
Return
