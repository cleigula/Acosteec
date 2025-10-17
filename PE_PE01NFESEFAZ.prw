//Bibliotecas
#Include "Protheus.ch"

/*/{Protheus.doc} PE01NFESEFAZ
Ponto de entrada no fim do NfeSefaz para manipular os arrays do XML
@author Atilio
@since 08/01/2018
@version 1.0
@type function
@see http://tdn.totvs.com/pages/releaseview.action?pageId=274327446
@obs Posições do ParamIXB:
    001 - aProd       -  Produto
    002 - cMensCli    -  Mensagem da nota
    003 - cMensFis    -  Mensagem padrao
    004 - aDest       -  Destinatario
    005 - aNota       -  Numero da nota
    006 - aInfoItem   -  Informações do Item
    007 - aDupl       -  Duplicata
    008 - aTransp     -  Transporte
    009 - aEntrega    -  Entrega
    010 - aRetirada   -  Retirada
    011 - aVeiculo    -  Veiculo
    012 - aReboque    -  Placa Reboque
    013 - aNfVincRur  -  Nota Produtor Rural Referenciada
    014 - aEspVol     -  Especie Volume
    015 - aNfVinc     -  NF Vinculada
    016 - aDetPag     -  
/*/
/*
User Function PE01NFESEFAZ()
	Local aArea      :=  FWGetArea()
	//Arrays originais
    Local aDados     := ParamIXB
	Local cMensagem  := aDados[2]
	Local aNota      := aDados[5]
 

	If aNota[04] == '1' 
		cMensagem += "Vendedor: " +  Alltrim(POSICIONE("SA3",1,FWxFilial('SA3') + SF2->F2_VEND1,'A3_NOME'))
		aDados[2] := cMensagem
	EndIf

    FWRestArea(aArea)
    
Return aDados

*/

User Function PE01NFESEFAZ()

	Local aAreaAtu  := FWGetArea()
	Local aAreaSA1  := SA1->( FWGetArea() )
	Local aAreaSA4  := SA4->( FWGetArea() )
	Local aAreaSB1  := SB1->( FWGetArea() )
	Local aAreaSC5  := SC5->( FWGetArea() )
	Local aAreaSD1  := SD1->( FWGetArea() )
	Local aAreaSD2  := SD2->( FWGetArea() )
	Local aAreaSF1  := SF1->( FWGetArea() )
	Local aAreaSF2  := SF2->( FWGetArea() )
	Local aAreaSF4  := SF4->( FWGetArea() )
	Local aAreaSM2  := SM2->( FWGetArea() )
	Local aAreaSM4  := SM4->( FWGetArea() )
	Local aAreaSB5  := SB5->( FWGetArea() )

	//Arrays originais
	Local aProduto    := PARAMIXB[1]
	Local cMensCli    := PARAMIXB[2]
	Local cMensFis    := PARAMIXB[3]
	Local aDest       := PARAMIXB[4]
	Local aNota 	  := PARAMIXB[5]
	Local aInfoItem   := PARAMIXB[6]
	Local aDupl	      := PARAMIXB[7]
	Local aTransp	  := PARAMIXB[8]
	Local aEntrega    := PARAMIXB[9]
	Local aRetirada   := PARAMIXB[10]
	Local aVeiculo    := PARAMIXB[11]
	Local aReboque    := PARAMIXB[12]
	Local aNfVincRur  := PARAMIXB[13]
	Local aEspVol     := PARAMIXB[14]
	Local aNfVinc     := PARAMIXB[15]
	Local aDetPag     := PARAMIXB[16]
	Local aObsCont    := PARAMIXB[17]
	Local aProcRef    := PARAMIXB[18]

	Local nX        := 0

	If aNota[04] == '1' // Notas de Saidas

		//DbSElectArea("SC5")
		//SC5->(DbSetOrder(1))
		//SC5->(DbSeek(xFilial("SC5") + AINFOITEM[1][1]  ))
		cMensCli += "Vend:" +  Alltrim(POSICIONE("SA3",1,FWxFilial('SA3') + SF2->F2_VEND1,'A3_NOME')) + " Usuario:" + alltrim(SF2->F2_USERF)

		If !SF2->F2_TIPO $ "B/D"

			dbSelectArea("SA1")
			SA1->(dbSetOrder(1))
			For nX:= 1 To Len(aProduto)
				DbSElectArea("SC6")
				SC6->(DbSetOrder(1))
				SC6->(DbSeek(xFilial("SC6") + aInfoItem[nX][1] + aInfoItem[nX][2] ))
				If !Empty(SC6->C6_PRODCLI)

					If SA1->A1_COMPPRO == '2' ////1=Cod e prod interno;2=Desc + cod pro cli;3=Cod cliente;4=Cod e Desc Cliente
						aProduto[nX,04] := Alltrim(	aProduto[nX, 4])+" ("+Alltrim(SC6->C6_PRODCLI)+")"
					endif

					if  SA1->A1_COMPPRO == '3' ////1=Cod e prod interno;2=Desc + cod pro cli;3=Cod cliente;4=Cod e Desc Cliente
						aProduto[nX,02] := SC6->C6_PRODCLI
					EndIf

					if  SA1->A1_COMPPRO == '4' ////1=Cod e prod interno;2=Desc + cod pro cli;3=Cod cliente;4=Cod e Desc Cliente
						aProduto[nX,02] := SC6->C6_PRODCLI
						aProduto[nX,04] := Alltrim(	SC6->C6_DESCCLI)
					EndIf

					/*
					If SA1->A1_COMPPRO == '2' ////1=Cod e prod interno;2=Desc + cod pro cli;3=Cod cliente
						aProduto[nX,04] := Alltrim(	aProduto[nX, 4])+" ("+Alltrim(SC6->C6_PRODCLI)+")"
					ElseIf SA1->A1_COMPPRO == '3' ////1=Cod e prod interno;2=Desc + cod pro cli;3=Cod cliente
						aProduto[nX,02] := SC6->C6_PRODCLI
					EndIf
					*/


				EndIf
				If SA1->A1_UNVEND == "2" .And.;//1=Primeira Unidade de medida;2=Segunda Unidade de medida
					!Empty(SC6->C6_SEGUM) .And.;//Segunda Unidade de Medida
					SC6->C6_UNSVEN > 0 // Qtde vendida na 2a UM
					aProduto[nX][8] := SC6->C6_SEGUM
					aProduto[nX][9] := SC6->C6_UNSVEN
					aProduto[nX][11] := SC6->C6_SEGUM
					aProduto[nX][12] := SC6->C6_UNSVEN
				EndIf



			Next nX
		Endif
	EndIf



	PARAMIXB[1]   := aProduto
	PARAMIXB[2]   := cMensCli
	PARAMIXB[3]   := cMensFis
	PARAMIXB[4]   := aDest
	PARAMIXB[5]   := aNota
	PARAMIXB[6]   := aInfoItem
	PARAMIXB[7]   := aDupl
	PARAMIXB[8]   := aTransp
	PARAMIXB[9]   := aEntrega
	PARAMIXB[10]  := aRetirada
	PARAMIXB[11]  := aVeiculo
	PARAMIXB[12]  := aReboque
	PARAMIXB[13]  := aNfVincRur
	PARAMIXB[14]  := aEspVol
	PARAMIXB[15]  := aNfVinc
	PARAMIXB[16]  := aDetPag
	PARAMIXB[17]  := aObsCont
	PARAMIXB[18]  := aProcRef

	FWRestArea( aAreaAtu )
	FWRestArea( aAreaSA1 )
	FWRestArea( aAreaSA4 )
	FWRestArea( aAreaSB1 )
	FWRestArea( aAreaSC5 )
	FWRestArea( aAreaSD1 )
	FWRestArea( aAreaSD2 )
	FWRestArea( aAreaSF1 )
	FWRestArea( aAreaSF2 )
	FWRestArea( aAreaSF4 )
	FWRestArea( aAreaSM2 )
	FWRestArea( aAreaSM4 )
	FWRestArea( aAreaSB5 )

Return( PARAMIXB )

