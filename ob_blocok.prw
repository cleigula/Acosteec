//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"
#Include 'Protheus.ch'
#Include "TOPCONN.CH"


user function ob_blocok()
	cPerg :=  padr("OB_BLK",len(SX1->X1_GRUPO)," ")
	ValidPerg()
	if Pergunte(cPerg,.T.)
		FWMsgRun(, {|oSay| bProc(oSay) }, "Processando...", "Executando processo..." )
	EndIf

Return

static function bProc(oSay)
	local cQuery

	if mv_par01 == 1
	    oSay:SetText("Gerando backup da segunda UN de medida...")
		cQuery := "BEGIN TRANSACTION " + chr(13) + chr(10)
		cQuery += "UPDATE SB1010 SET B1_BKPSUM = B1_SEGUM WHERE RTRIM(B1_SEGUM) <> ''
		cQuery += "COMMIT" + chr(13) + chr(10)
		TcSqlExec(cQuery)

		oSay:SetText("Ajustando segunda UN de medida...")
		cQuery := "BEGIN TRANSACTION " + chr(13) + chr(10)
		cQuery += "UPDATE SB1010 SET B1_SEGUM = '' WHERE RTRIM(B1_SEGUM) <> ''
		cQuery += "COMMIT" + chr(13) + chr(10)
		TcSqlExec(cQuery)
	else
		oSay:SetText("Restaurando segunda UN de medida...")
		cQuery := "BEGIN TRANSACTION " + chr(13) + chr(10)
		cQuery += "UPDATE SB1010 SET B1_SEGUM = B1_BKPSUM WHERE RTRIM(B1_BKPSUM) <> ''
		cQuery += "COMMIT" + chr(13) + chr(10)
		TcSqlExec(cQuery)
	endif


return

Static Function ValidPerg()
	cAlias := Alias()
	aRegs  :={}
	local j,i

	AADD(aRegs,{cPerg,"01","Tipo de processamento ?","Tipo de processamento?","Tipo de processamento","mv_ch1","C",01,0,0,"C","","mv_par01","Preparar","","","","","Restaurar","","","","","","","","","","","","","","","","","","","",""})

	DbSelectArea("SX1")
	DbSetOrder(1)
	For i:=1 to Len(aRegs)
		If !DbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j<=Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next
	DbSelectArea(cAlias)
Return
