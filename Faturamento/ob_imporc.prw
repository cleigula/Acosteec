#INCLUDE "Rwmake.CH"
#include "sigawin.ch"
#include "colors.ch"
#INCLUDE "topconn.ch"
#include "topdef.ch"
#INCLUDE "TBICONN.CH"
#include "ap5mail.ch"
#INCLUDE "FILEIO.CH"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "PROTHEUS.CH"
#Include "FWPrintSetup.ch"
#Include "RPTDef.ch"

user function ob_imporc()

	impA4(Alltrim(_cCodPro),Alltrim(_cDesPro),Alltrim(_cLote))
	

return

static function bimpA4(_cCodPro,_cDesPro,_cLote)


	Local lAdjustToLegacy := .F.
	Local lDisableSetup  := .T.
	Local oPrinter
	Local cLocal          := "c:\temp\"
	Local cFilePrint := ""
	Local nLin := 35
	Local nCol :=  20
	local lMen30 := .f.
	local nPosc:= 21 //val(FWInputBox("insira o valor:",'20'))
	local cDes1,cDes2 := ''
	local nTaFdesc := 70


	if len(Alltrim(_cDesPro)) >= 40
		nTaFdesc := 60 //val(FWInputBox("valor fonte:",'70'))
		nPosc    := 22 // val(FWInputBox("insira o valor:",'22'))
	endif

	_cBarra1 := "(01)"+Alltrim(_cCodPro)+;
		"(17)"+SubStr(dtos(_dValid),3,4)+"01"+;
		"(10)"+Alltrim(_cLote)+">8"

	if len(Alltrim(_cDesPro)) > nPosc
		while Alltrim(SUBSTRING(Alltrim(_cDesPro), nPosc, 1)) <> '' .or. nPosc <= 0
			if Alltrim(SUBSTRING(Alltrim(_cDesPro), nPosc, 1)) <> ''
				nPosc:= nPosc-1
			endif
		enddo
		cDes1:= Alltrim(left(_cDesPro,nPosc))
		// se o ultimo caracter da primeira linha for um hifen ou um ponto eu retiro ele da impressao
		if Right(cDes1,1) == "-" .or. Right(cDes1,1) == "."
			cDes1:=Alltrim(SUBSTRING(Alltrim(cDes1), 1, len(cDes1)-1))
		endif

		cDes2:= Alltrim(Right(Alltrim(_cDesPro),len(Alltrim(_cDesPro)) - nPosc))
		// se o primeiro caracter da segunda linha for um hifen ou umponto eu retiro ele da impressao
		if left(cDes2,1) == "-" .or. left(cDes2,1) == "."
			cDes2:=Alltrim(SUBSTRING(Alltrim(cDes2), 2, len(cDes2)))
		endif

	else
		lMen30 := .t.
	endif

	

	oFont5 := TFont():New("Courier new",,48,,.F.,,,,,.F. )
	oFont8 := TFont():New('Courier new',,nTaFdesc /*val(FWInputBox("fonte 08:"))*/,,.t.,,,,,.F. ) //120
	oFont9 := TFont():New('Calibri',,130/*val(FWInputBox("fonte 09"))*/,,.t.,,,,,.F. )  //120




	oPrinter := FWMSPrinter():New('etiqueta.pdf', IMP_PDF, lAdjustToLegacy,cLocal, lDisableSetup, , , , , , .F., )
	oPrinter:setlandscape()
	oPrinter:StartPage()

	nLin := 100
	nCol := 30
	oPrinter:Say(nLin,nCol,"CODIGO:",oFont5)
	nLin := 100
	nCol := 250
	oPrinter:Say(nLin,nCol,_cCodPro,oFont8)


	nLin := 170
	nCol := 30
	oPrinter:Say(nLin,nCol,"DESC:",oFont5)
	nLin := 170
	nCol := 150
	oPrinter:Say(nLin,nCol,cDes1,oFont8)

	nLin := 230
	nCol := 30
	oPrinter:Say(nLin,nCol,cDes2,oFont8)


	nLin := 380
	nCol := 30
	oPrinter:Say(nLin,nCol,"LOTE:",oFont5)
	nLin := 380
	nCol := 200
	oPrinter:Say(nLin,nCol,_cLote,oFont9)

	oPrinter:QRCode(590/*val(FWInputBox("lin"))*/,320/* val(FWInputBox("col"))*/, _cBarra1, 180/*val(FWInputBox("tamanho"))*/)

	cFilePrint := cLocal+"etiqueta.pdf"
	oPrinter:cPathPDF:= cLocal
	oPrinter:Preview()



return




Static Function _VldLote()
	Local _lRet := .T.
	_dFabric 	:= sTod("")
	_dValid 	:= sTod("")
	cQuery := " SELECT * FROM "+RetSqlName("SB8")+" SB8 "
	cQuery += " WHERE B8_FILIAL = '"+xFilial("SB8")+"' "
	cQuery += " AND B8_PRODUTO 	= '"+_cCodPro+"'"
	cQuery += " AND B8_LOTECTL  = '"+_cLote+"'"
	cQuery += " AND D_E_L_E_T_	<> '*' "
	cQuery += " AND B8_DFABRIC  <> ' ' "
	cQuery += " ORDER BY R_E_C_N_O_ "

	TCQuery cQuery NEW ALIAS "_SB8"
	DbSelectArea("_SB8")
	_SB8->(DbGoTop())
	If !_SB8->(EOF())
		_dFabric	:= stod(_SB8->B8_DFABRIC)
		_dValid		:= stod(_SB8->B8_DTVALID)
	EndIf
	_SB8-> (DbCloseArea())
	cQuery := " "
	cQuery += " SELECT * FROM "+RetSqlName("SC2")+" SC2 "
	cQuery += " WHERE C2_FILIAL =  '"+xFilial("SC2")+"' "
	cQuery += " AND D_E_L_E_T_ 	<> '*' "
	cQuery += " AND C2_LOTE 	= '"+_cLote+"' "
	cQuery += " AND C2_PRODUTO 	= '"+_cCodPro+"' "
	cQuery += " ORDER BY C2_NUM "

	TCQuery cQuery NEW ALIAS "_SC2"

	DbSelectArea("_SC2")
	_SC2->(DbGoTop())
	If !_SC2->(EOF())
		_cOP 		:= _SC2->C2_NUM+_SC2->C2_ITEM+_SC2->C2_SEQUEN+_SC2->C2_ITEMGRD
		_dFabric 	:= IIF(!Empty(_dFabric),_dFabric,stod(_SC2->C2_EMISSAO))
		_dValid		:= IIF(!EMpty(_dValid),_dValid,_dFabric + Posicione("SB1",1,xFilial("SB1")+_SC2->C2_PRODUTO,"SB1->B1_PRVALID"))
	Else
		_cOP 		:= SPACE(15)
	EndIf
	_SC2->(DbCloseArea())
	DbSelectArea("SC2")
	_oOP:Refresh()
	_oFabric:Refresh()
	_oValid:Refresh()
Return(_lRet)

Static Function _VldProd()
	Local _lRet := .T.
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+_cCodPro)
	If Found()
		_cDesPro  	:= SB1->B1_DESC
		_cCodBar	:= SB1->B1_CODETQ//SB1->B1_CODBAR
		_nQtEtiq  	:= 1
	Else
		_nQtEtiq  := 0
		_cCodPro  := ""
		_cDesPro  := ""
		_cCodBar  	:= ""
	Endif
	_oQtEtiq:Refresh()
	_oCodPro:Refresh()
	_oDesPro:Refresh()
	_oCodBar:Refresh()
Return(_lRet)

Static Function _VldOP(_cOP, _lRefresh)
	Local _lRet := .T.
	DbSelectArea("SC2")
	DbSetOrder(1)
	DbSeek(xFilial("SC2")+Alltrim(_cOP))
	If Found() .And. !Empty(_cOP)
		_nQtEtiq := SC2->C2_QUANT
		_cLote   := SC2->C2_LOTE
		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+SC2->C2_PRODUTO)
		If Found()
			_cCodPro  	:= SC2->C2_PRODUTO
			_cDesPro  	:= SB1->B1_DESC
			_cCodBar	:= SB1->B1_CODETQ//SB1->B1_CODBAR
		Else
			_cCodPro  	:= Space(15)
			_cDesPro  	:= ""
			_cCodBar  	:= ""
		Endif
		_dFabric 	:= sTod("")
		_dValid 	:= sTod("")
		cQuery := " SELECT * FROM "+RetSqlName("SB8")+" SB8 "
		cQuery += " WHERE B8_FILIAL = '"+xFilial("SB8")+"' "
		cQuery += " AND B8_PRODUTO 	= '"+_cCodPro+"'"
		cQuery += " AND B8_LOTECTL  = '"+_cLote+"'"
		cQuery += " AND D_E_L_E_T_	<> '*' "
		cQuery += " AND B8_DFABRIC  <> ' ' "
		cQuery += " ORDER BY R_E_C_N_O_ "

		TCQuery cQuery NEW ALIAS "_SB8"
		DbSelectArea("_SB8")
		_SB8->(DbGoTop())
		If !_SB8->(EOF())
			_dFabric	:= stod(_SB8->B8_DFABRIC)
			_dValid		:= stod(_SB8->B8_DTVALID)
		EndIf
		_SB8-> (DbCloseArea())
		DbSelectArea("SC2")
		_dFabric 	:= IIF(!Empty(_dFabric),_dFabric,SC2->C2_EMISSAO)
		_dValid		:= IIF(!EMpty(_dValid),_dValid,_dFabric + Posicione("SB1",1,xFilial("SB1")+_cCodPro,"SB1->B1_PRVALID"))
	else
		MsgBox("Ordem de Producao Invalida","ATENCAO","STOP")
		_lRet := .F.
	Endif
	If _lRefresh
		_oCodPro:Refresh()
		_oDesPro:Refresh()
		_oCodBar:Refresh()
		_oQtEtiq:Refresh()
		_oCodPro:Refresh()
		_oDesPro:Refresh()
		_oFabric:Refresh()
		_oValid:Refresh()
	EndIf
Return(_lRet)

Static Function _VldQtEtiq(_lRefresh, _lImpressao)
	Local _lRet := .T.
	If _nQtEtiq <= 0
		MsgBox("Quantidade Invalida","ATENCAO","STOP")
		_lRet := .F.
	EndIf
	If _lRefresh
		_oQtEtiq:Refresh()
	Endif
Return(_lRet)

Static Function _VImpEtq()
	Local _lRet 	:= .F.
	Local _nSeqEtq	:= 1
	local _nCarc    := 0
	Private _oDestino
	Private _cDestino  := ""
	Private _oImpress
	Private _cImpress  := ""
	Private _cLocImp   := sPace(6)
	Private _lLocImp   := .T.
	_cLocImp := "ETQPCP"

	If !Empty(_cLocImp)
		_cDestino := U_VldCb5(_cLocImp,.F.)
	EndIf
	@ 050, 100 TO 250,600 DIALOG oDlgImp TITLE "Local Impressao"
	@ 005, 005 say "Local Impressao:"    Pixel Of oDlgImp
	@ 020, 060 Get _cImpress  Size 150, 11 Object _oImpress When .F.
	@ 005, 060 get _cLocImp   Size 040, 11 Picture "@!" When _lLocImp F3 "CB5" Valid !Empty(U_VldCb5(_cLocImp,.T.)) Object _oLocImp
	@ 035, 060 Get _cDestino  Size 150, 11 Object _oDestino When .F.

	@ 060, 060 BUTTON "&Imprimir" 	Size 45, 15 ACTION Close(oDlgImp) .and. (_lRet := .T.) Pixel Of oDlg1
	@ 060, 105 BUTTON "&Sair" 		Size 45, 15 ACTION Close(oDlgImp) .And. (_lRet := .F.) Pixel Of oDlg1
	ACTIVATE DIALOG oDlgImp CENTERED

	_cDestino := U_VldCb5(_cLocImp)
	If _lRet
		U_CB5SetImp(_cLocImp)
		//CB5SetImp(_cLocImp)

		/*
			For _nSeqEtq := 1 To _nQtEtiq
				MSCBBegin(1,2)

				MSCBSAY(05, 10, _cCodPro, "B", "D", "01,01")
				MSCBSAY(10, 1, AllTrim(substr(_cDesPro,1,30)), "B", "4", "10,10")
				MSCBSAY(15, 1, AllTrim(substr(_cDesPro,31,30)), "B", "4", "20,20")

				MSCBSAYBAR(54, 3, Alltrim(_cCodBar), "B", "A", 12.00, .F., .T., .F., , 6, 2, .F., .F., "1", .T.)

				MSCBSAY(36, 20, "PART:"+Alltrim(_cLote), "B", "2", "01,01")
				MSCBSAY(48, 20, "FABR:"+SubStr(dtos(_dFabric),5,2)+"/"+SubStr(dtos(_dFabric),1,4), "B", "2", "01,01")
				MSCBSAY(54, 20, "VENC:"+SubStr(dtos(_dValid),5,2)+"/"+SubStr(dtos(_dValid),1,4), "B", "2", "01,01")

				_cBarra1 := "(01)"+Alltrim(_cCodPro)+;
					"(17)"+SubStr(dtos(_dValid),3,4)+"01"+;
					"(10)"+Alltrim(_cLote)+">8"
				//MSCBWrite("^FT700,390^BQN,2,3^FDM,"+_cBarra1+"^FS")//qrcode28,72
				MSCBWrite("^FO350,100^BXN,10,200^FD"+_cBarra1+"^FS")//Data Matrix

				MSCBEND()

			Next _nSeqEtq
		*/

		//_cCodBar:= '823456789123455'

		_nCarc := 0

		//_cDesPro := FWInputBox("PRODUTO",_cDesPro)

		lEAN13 := .T.
		IF len(Alltrim(_cCodBar)) > 13
			lEAN13 := .F.
		endif

		For _nSeqEtq := 1 To _nQtEtiq

			MSCBBegin(1,6)
			MSCBWrite("^XA")
			cText := "^XA"  + CRLF


			MSCBWrite("^FWR,0") //inverte o texto
			cText += "^FWR,0"  + CRLF
			//MSCBWrite("^CF0,120") //tamanho da fonte
			//MSCBWrite("^FO450,250^FD"+_cCodPro+"^FS")


			MSCBWrite("^CF0,120")
			cText += "^CF0,120"  + CRLF

			MSCBWrite("^FO450,20")
			cText += "^FO450,20"  + CRLF

			MSCBWrite("^FB800,1,0,C,0")
			cText += "^FB800,1,0,C,0"  + CRLF

			MSCBWrite("^FD"+Alltrim(_cCodPro)+"^FS")
			cText += "^FD"+Alltrim(_cCodPro)+"^FS"  + CRLF



			MSCBWrite("^CF0,50")  //tamanho da fonte
			cText += "^CF0,50"  + CRLF

			lMen30 := .f.
			nPosc:= 30
			if len(Alltrim(_cDesPro)) > 30
				while Alltrim(SUBSTRING(Alltrim(_cDesPro), nPosc, 1)) <> '' .or. nPosc <= 0
					if Alltrim(SUBSTRING(Alltrim(_cDesPro), nPosc, 1)) <> ''
						nPosc:= nPosc-1
					endif
				enddo
				cDes1:= Alltrim(left(_cDesPro,nPosc))
				// se o ultimo caracter da primeira linha for um hifen ou um ponto eu retiro ele da impressao
				if Right(cDes1,1) == "-" .or. Right(cDes1,1) == "."
					cDes1:=Alltrim(SUBSTRING(Alltrim(cDes1), 1, len(cDes1)-1))
				endif

				cDes2:= Alltrim(Right(Alltrim(_cDesPro),len(Alltrim(_cDesPro)) - nPosc))
				// se o primeiro caracter da segunda linha for um hifen ou umponto eu retiro ele da impressao
				if left(cDes2,1) == "-" .or. left(cDes2,1) == "."
					cDes2:=Alltrim(SUBSTRING(Alltrim(cDes2), 2, len(cDes2)))
				endif

			else
				lMen30 := .t.
			endif

			if lMen30

				if len(Alltrim(_cDesPro)) < 22

					MSCBWrite("^CF0,150,70")
					cText += "^CF0,150,70"  + CRLF

					MSCBWrite("^FO280,20")
					cText += "^FO280,20"  + CRLF
				else
					MSCBWrite("^CF0,90,50")
					cText += "^CF0,90,50"  + CRLF

					MSCBWrite("^FO330,20")
					cText += "^FO330,20"  + CRLF

				endif

				MSCBWrite("^FB800,1,0,C,0")
				cText += "^FB800,1,0,C,0"  + CRLF


				MSCBWrite("^CI28")
				cText += "^CI28"  + CRLF

				MSCBWrite("^FD"+AllTrim(substr(_cDesPro,1,30))+"^FS")
				cText += "^FD"+AllTrim(substr(_cDesPro,1,30))+"^FS"  + CRLF

			else

				MSCBWrite("^CF0,90,50")
				cText += "^CF0,90,50"  + CRLF

				MSCBWrite("^FO360,20")
				cText += "^FO360,20"  + CRLF

				MSCBWrite("^FB800,1,0,C,0")
				cText += "^FB800,1,0,C,0"  + CRLF

				MSCBWrite("^CI28")
				cText += "^CI28"  + CRLF

				MSCBWrite("^FD"+cDes1+"^FS")
				cText += "^FD"+cDes1+"^FS"  + CRLF


				MSCBWrite("^CF0,90,"+iif(len(cDes2) > 33,"40","50"))
				cText += "^CF0,90,"+iif(len(cDes2) > 33,"40","50")  + CRLF

				MSCBWrite("^FO240,20")
				cText += "^FO240,20"  + CRLF

				MSCBWrite("^FB800,1,0,C,0")
				cText += "^FB800,1,0,C,0"


				MSCBWrite("^CI28")
				cText += "^CI28 " + CRLF


				MSCBWrite("^FD"+cDes2+"^FS")
				cText += "^FD"+cDes2+"^FS"  + CRLF


			endif


			_cBarra1 := "(01)"+Alltrim(_cCodPro)+;
				"(17)"+SubStr(dtos(_dValid),3,4)+"01"+;
				"(10)"+Alltrim(_cLote)+">8"


			if lEAN13
				MSCBWrite("^CF0,30")
				cText += "^CF0,30"  + CRLF

				MSCBWrite("^FO042,360^GB150,220,3^FS")
				cText += "^FO042,360^GB150,220,3^FS"  + CRLF

				MSCBWrite("^FO147,370^FDLOTE:"+Alltrim(_cLote)+"^FS")
				cText += "^FO147,370^FDLOTE:"+Alltrim(_cLote)+"^FS"  + CRLF

				MSCBWrite("^FO100,370^FDFAB.:"+retcMes(SubStr(dtos(_dFabric),5,2))+"/"+SubStr(dtos(_dFabric),1,4)+"^FS")
				cText += "^FO100,370^FDFAB.:"+retcMes(SubStr(dtos(_dFabric),5,2))+"/"+SubStr(dtos(_dFabric),1,4)+"^FS"  + CRLF

				MSCBWrite("^FO050,370^FDVAL.:"+retcMes(SubStr(dtos(_dValid),5,2))+"/"+SubStr(dtos(_dValid),1,4)+"^FS")
				cText += "^FO050,370^FDVAL.:"+retcMes(SubStr(dtos(_dValid),5,2))+"/"+SubStr(dtos(_dValid),1,4)+"^FS"  + CRLF

				MSCBWrite("^BY3,3,120^FT68,60^BER,,Y,N") //BER inverte o condigo de barras
				cText += "^BY3,3,120^FT68,60^BER,,Y,N"  + CRLF

				MSCBWrite("^FD"+aLLTRIM(_cCodBar)+"^FS")
				cText += "^FD"+aLLTRIM(_cCodBar)+"^FS"  + CRLF

				MSCBWrite("^FO35,600^BXR,09,200^FD"+_cBarra1+"^FS")
				cText += "^FO35,600^BXR,09,200^FD"+_cBarra1+"^FS"  + CRLF
			else
				MSCBWrite("^CF0,27")
				cText += "^CF0,27"  + CRLF

				MSCBWrite("^FO042,420^GB150,220,3^FS")
				cText += "^FO042,420^GB150,220,3^FS"  + CRLF

				MSCBWrite("^FO147,430^FDLOTE:"+Alltrim(_cLote)+"^FS")
				cText += "^FO147,430^FDLOTE:"+Alltrim(_cLote)+"^FS"  + CRLF

				MSCBWrite("^FO100,430^FDFAB.:"+retcMes(SubStr(dtos(_dFabric),5,2))+"/"+SubStr(dtos(_dFabric),1,4)+"^FS")
				cText += "^FO100,430^FDFAB.:"+retcMes(SubStr(dtos(_dFabric),5,2))+"/"+SubStr(dtos(_dFabric),1,4)+"^FS"  + CRLF

				MSCBWrite("^FO050,430^FDVAL.:"+retcMes(SubStr(dtos(_dValid),5,2))+"/"+SubStr(dtos(_dValid),1,4)+"^FS")
				cText += "^FO050,430^FDVAL.:"+retcMes(SubStr(dtos(_dValid),5,2))+"/"+SubStr(dtos(_dValid),1,4)+"^FS"  + CRLF



				MSCBWrite("^FO60,20^BY2^BCR,130,Y,N") //BER inverte o condigo de barras
				cText += "^FO60,20^BY2^BCR,130,Y,N"  + CRLF

				MSCBWrite("^FD"+aLLTRIM(_cCodBar)+"^FS")
				cText += "^FD"+aLLTRIM(_cCodBar)+"^FS"  + CRLF

				MSCBWrite("^FO35,650^BXR,08,200^FD"+_cBarra1+"^FS")
				cText += "^FO35,650^BXR,09,200^FD"+_cBarra1+"^FS"  + CRLF

			endif
			MSCBWrite("^PQ1,0,1,Y^XZ ")
			cText += "^PQ1,0,1,Y^XZ "  + CRLF

			//u_zMsgLog(cText, "arquivo zpl", 1, .T.)

			MSCBEND()
		Next _nSeqEtq
		MSCBCLOSEPRINTER()
	Endif


Return

static function retcMes(cMes)
	local cMMM:= ""

	Do Case
	Case cMes == "01" .or. cMes =="1"
		cMMM:="JAN"
	Case cMes == "02" .or. cMes =="2"
		cMMM:="FEV"
	Case cMes == "03" .or. cMes =="3"
		cMMM:="MAR"
	Case cMes == "04" .or. cMes =="4"
		cMMM:="ABR"
	Case cMes == "05" .or. cMes =="5"
		cMMM:="MAI"
	Case cMes == "06" .or. cMes =="6"
		cMMM:="JUN"
	Case cMes == "07" .or. cMes =="7"
		cMMM:="JUL"
	Case cMes == "08" .or. cMes =="8"
		cMMM:="AGO"
	Case cMes == "09" .or. cMes =="9"
		cMMM:="SET"
	Case cMes == "10"
		cMMM:="OUT"
	Case cMes == "11"
		cMMM:="NOV"
	Case cMes == "12"
		cMMM:="DEZ"

	EndCase



return (cMMM)

