#Include "protheus.ch"
#Include "rwmake.ch"

User Function M460FIM()

	Local _aArea := GetArea()
	Local _lRet  := .T.

	
	_DadosAdic()

	RestArea(_aArea)

Return(_lRet)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Chamada da funcao _DadosAdic()               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Static Function _DadosAdic()
	Local _cNota  := SF2->F2_DOC
	Local _cSerie := SF2->F2_SERIE
   	Local cTpFrete   := SF2->F2_TPFRETE
	_cDoc     := Alltrim(SF2->F2_DOC) + "-" + Alltrim(SF2->F2_SERIE)
	_cTransp  := SF2->F2_TRANSP
	_cNomTra  := Space(40)
	_cNomRed  := Space(40)
	_nVolume1 := SF2->F2_VOLUME1
	_nVolume2 := SF2->F2_VOLUME2
	_nVolume3 := SF2->F2_VOLUME3
	_nVolume4 := SF2->F2_VOLUME4
	_cPlaca   := SF2->F2_VEICUL1
	_cEspeci1 := SF2->F2_ESPECI1
	_cEspeci2 := SF2->F2_ESPECI2
	_cEspeci3 := SF2->F2_ESPECI3
	_cEspeci4 := SF2->F2_ESPECI4
	_nPesoBru := 0
	_nPesoLiq := 0

	DbSelectArea("SB1")
	SB1->(DbsetOrder(1))

	DbSelectArea("SD2")
	SD2->(DbSetOrder(3))
	SD2->(MsSeek(xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE))
	While !SD2->(Eof()) .and. SD2->D2_FILIAL + SD2->D2_DOC + SD2->D2_SERIE == xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE

		SB1->(MsSeek(xFilial("SB1") + SD2->D2_COD))
		
		_nPesoBru += SD2->D2_QUANT * SB1->B1_PESBRU
		_nPesoLiq += SD2->D2_QUANT * SB1->B1_PESO

		SD2->(DbSkip())
	Enddo
	
	DEFINE MSDIALOG oDlg TITLE "Dados Adicionais da NFe " + _cDoc FROM 09,00 TO 45,105
	@ 005 , 005 Say "Transportadora  "
	@ 020 ,005 Say "Tipo Frete:"            
  
  
   @ 065 , 005 Say "Placa       "
	@ 080 , 005 Say "Qtde Volumes 1  "
	@ 080 , 150 Say "Especie 1       "
	@ 095 , 005 Say "Qtde Volumes 2  "
	@ 095 , 150 Say "Especie 2       "
	@ 110 , 005 Say "Qtde Volumes 3  "
	@ 110 , 150 Say "Especie 3       "
	@ 125 , 005 Say "Qtde Volumes 4  "
	@ 125 , 150 Say "Especie 4       "
	@ 140 , 005 Say "Peso Bruto      "
	@ 140 , 150 Say "Peso Liquido    "
	

	@ 005, 060 GET _cTransp  Picture "@!" When .T. Valid VldTra() F3 "SA4" SIZE 053, 20
	@ 005, 150 GET _cNomTra  Picture "@!" When .F.       SIZE 190, 20

   @ 020, 060 GET cTpFrete  Picture "@!" When .T.       SIZE 053, 20

	@ 065 , 060 GET _cPlaca   Picture "@!"                F3 "DA3" SIZE 053, 20
	@ 080 , 060 GET _nVolume1 Picture "@E 999999"         SIZE 053, 20
	@ 080 , 210 GET _cEspeci1 Picture "@!"                SIZE 053, 20
	@ 095 , 060 GET _nVolume2 Picture "@E 999999"         SIZE 053, 20
	@ 095 , 210 GET _cEspeci2 Picture "@!"                SIZE 053, 20
	@ 110 , 060 GET _nVolume3 Picture "@E 999999"         SIZE 053, 20
	@ 110 , 210 GET _cEspeci3 Picture "@!"                SIZE 053, 20
	@ 125 , 060 GET _nVolume4 Picture "@E 999999"         SIZE 053, 20
	@ 125 , 210 GET _cEspeci4 Picture "@!"                SIZE 053, 20
	@ 140 , 060 GET _nPesoBru Picture "@E 999,999.9999"   SIZE 053, 20
	@ 140 , 210 GET _nPesoLiq Picture "@E 999,999.9999"   SIZE 053, 20

	@ 245 , 320 BUTTON "Confirmar"	SIZE 050,11 ACTION oDlg:End() OF oDlg PIXEL
	ACTIVATE MSDIALOG oDlg CENTERED


	DbSelectArea("SF2")
	RecLock("SF2",.F.)
	SF2->F2_TRANSP  := _cTransp
	SF2->F2_VOLUME1 := _nVolume1
	SF2->F2_VOLUME2 := _nVolume2
	SF2->F2_VOLUME3 := _nVolume3
	SF2->F2_VOLUME4 := _nVolume4
	SF2->F2_VEICUL1 := _cPlaca
	SF2->F2_ESPECI1 := _cEspeci1
	SF2->F2_ESPECI2 := _cEspeci2
	SF2->F2_ESPECI3 := _cEspeci3
	SF2->F2_ESPECI4 := _cEspeci4
	SF2->F2_PBRUTO  := _nPesoBru
	SF2->F2_PLIQUI  := _nPesoLiq
    SF2->F2_TPFRETE := cTpFrete 
	MsUnlock()

Return


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Efetua Consistencia na Transportadora                          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function VldTra()
	DbSelectArea("SA4")
	DbSeek(xFilial("SA4") + _cTransp)
	_cNomTra := SA4->A4_NOME

Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Efetua Consistencia no Redespacho                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function VldRed()
	DbSelectArea("SA4")
	DbSeek(xFilial("SA4") + _cRedesp)
	_cNomRed := SA4->A4_NOME

Return
