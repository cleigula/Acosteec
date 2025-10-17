User Function RetCodMun(cTp,cCpo)

Local aArea := GetArea()
Local cRet  := ""

If cTp == "E"   //Tabela de Fornecedores
    dbSelectArea("SA2")
    dbSetOrder(1)
    If dbSeek(xFilial("SA2")+SD1->D1_FORNECE+SD1->D1_LOJA)
        cRet := StrZero(Val(SA2->&(cCpo)),6)
    Endif
Else            //Tabela de Clientes
    dbSelectArea("SA1")
    dbSetOrder(1)
    If dbSeek(xFilial("SA1")+SD2->D2_CLIENTE+SD2->D2_LOJA)
        cRet := StrZero(Val(SA1->&(cCpo)),6)
    Endif
Endif
RestArea(aArea)

Return(cRet)
