#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#Include "Ap5Mail.ch"
#Include "FILEIO.CH"

#DEFINE MSG_FILE 1

#DEFINE X3_USADO_EMUSO "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ†"
#DEFINE X3_USADO_NAOUSADO "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ"
#DEFINE X3_OBRIGAT "¡Ä"
#DEFINE X3_RESER "˛¿"
#DEFINE X3_RESER_NUMERICO "¯«"

#DEFINE F_NAME 1
#DEFINE F_ATT  5

#DEFINE cCRLF  CHR(13)+CHR(10)

/*
Emissao de boletos - mantive o nome da funÁ„o - FBBOLTRS
*/
User Function FBBOLTRS()
	//Local oFont08		:= TFont():New("Times New Roman",08,08,,.F.,,,,.T.,.F.)
	//Local oFont08N		:= TFont():New("Times New Roman",08,08,,.T.,,,,.T.,.F.)
	//Local oFont10N		:= TFont():New("Times New Roman",10,10,,.T.,,,,.T.,.F.)

	Local aCpos  := {}
	Local aCores := {}

	Local lInverte := .F.

	//Local oBtnAlt   := NIL
	//Local oBtnExclu := NIL
	Local oBtnConf  := NIL
	Local oBtnSair  := NIL


	Private nOpc := 0
	Private oOK := LoadBitmap(GetResources(),'LBOK')
	Private oNO := LoadBitmap(GetResources(),'LBNO')

	Private oGreen := LoadBitmap(GetResources(),'BR_VERDE')
	Private oRed   := LoadBitmap(GetResources(),'BR_VERMELHO')

	Private _oDlg     := NIL

	Private oMark  := NIL
	Private cMark  := GetMark()

	Private oDuplic
	Private cPerg := PADR(("PSBOLETO"+ cFilAnt),LEN(SX1->X1_GRUPO)," ")

	Private cNomeArq := ""

	ValidPerg()

	if Pergunte(cPerg, .T.)

		_aBancos:= {}
		aadd(_aBancos, '001') // Banco do Brasil
		//aAdd(_aBancos, '104') // Caixa
		//aadd(_aBancos, '033') // Banco Santander
		//aadd(_aBancos, '341') // Banco Itau
		//aadd(_aBancos, '237') // Banco Bradesco
		//aadd(_aBancos, '041') // Banco Banrisul
		//aadd(_aBancos, '399') // Banco HSBC
		//aadd(_aBancos, '748') // Banco Sicredi
		//aadd(_aBancos, '756') // Banco Siscoob

		if aScan(_aBancos, mv_par09) == 0
			MsgBox('Banco n„o liberado.', 'Atencao!', 'STOP')
			return
		endif

		DEFINE MSDIALOG _oDlg FROM 0,0 TO oMainWnd:nClientHeight - 70, oMainWnd:nClientWidth - 10 OF oMainWnd PIXEL TITLE "Impress„o de Boletos"


		// Crio TRB utilizado no MsSelect
        criaArqT()

		// Define as cores dos itens de legenda.
		aCores := {}
		
        // Define quais colunas (campos da MTRB) serao exibidas na MsSelect
		criaSelect(@aCpos)

		CarregaTrb()

		// Coordenadas MsSelect
		// [1] = Coordenada vertical inicial
		// [2] = Coordenada horizontal inicial
		// [3] = Altura do objeto MsSelect
		// [4] = Largura do objeto MsSelect

		// Cria a MsSelect - Ordens de ProduÁ„o

		oMark := MsSelect():New("MTRB","OK","",aCpos,@lInverte,@cMark,{10,5,_oDlg:nClientHeight / 2 - 45, _oDlg:nClientWidth / 2 - 20},,,,,aCores)
		oMark:bMark := {|| MarkTRB() }


		@ (_oDlg:nClientHeight / 2 - 35), 090  BUTTON "Imprimir"   SIZE 60, 14 ACTION Processa({|| IniciaBol() }) OBJECT oBtnConf
		@ (_oDlg:nClientHeight / 2 - 35), 170  BUTTON "(Des)Marcar"   SIZE 60, 14 ACTION Processa({|| Markall() }) OBJECT oBtnConf
		@ (_oDlg:nClientHeight / 2 - 35), 250  BUTTON "Sair"       SIZE 60, 14 ACTION _oDlg:End() OBJECT oBtnSair


		ACTIVATE DIALOG _oDlg CENTERED

		//Elimina arquivo de trabalho
		dbSelectArea("MTRB")
		MTRB->(dbCloseArea())
		SET FILTER TO
	endif
Return

Static Function IniciaBol()
	local cStartPath:= ""
	oDuplic:=FWMSPrinter():New("BOLETO_PROTHEUS",IMP_PDF,.F.,cStartPath,,,@oDuplic,,,,,.T.)
	oDuplic:SetResolution(72)
	oDuplic:SetPortrait()

	oDuplic:SetPaperSize(DMPAPER_A4)
	oDuplic:SetMargin(10,10,10,10)
	PixelX  := oDuplic:nLogPixelX()
	PixelY  := oDuplic:nLogPixelY()
	nMM     := 0

	processa({|| FBBOL001()}, "Buscando Dados...")

	//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
	//≥ TERMINO ROTINA DE IMPRESSAO                                            ≥
	//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
	oDuplic:Preview()


return

static function FBBOL001()
	Local oFont07    	:= TFont():New("Arial",06,06,,.F.,,,,.T.,.F.)	//Fonte Times New Roman 07
	Local oFont07N    	:= TFont():New("Arial",06,06,,.T.,,,,.T.,.F.)	//Fonte Times New Roman 07
	Local oFont08    	:= TFont():New("Arial",08,08,,.F.,,,,.T.,.F.)	//Fonte Times New Roman 08
	Local oFont10    	:= TFont():New("Arial",10,10,,.T.,,,,.T.,.F.)	//Fonte Times New Roman 08
	Local oFont24 	    := TFont():New("Arial",,20,,.T.,,,,,.F.)
	Local oFont12  		:= TFont():New("Arial",,12,,.T.,,,,,.F.)
	Local _x 			:= 0
	Local _j 			:= 0
	Local aDadosEmp		:= {}
	Private STR_NUM := ARRAY(99)
	//DECLARE STR_NUM[99] 
	Private _XXA := ARRAY(5)
	//DECLARE _XXA[5]
	Private _XXB := ARRAY(5) 
	//DECLARE _XXB[5] 
	AFILL(STR_NUM,0)
	AFILL(_XXA,"A")
	AFILL(_XXB,"A")

	DbSelectArea("SA6")
	DbSetOrder(1)
	If !DbSeek(xFilial("SA6")+mv_par09 + mv_par10 + mv_par11,.t.)
		MsgBox("Banco / Agencia / Conta nao cadastrados" + chr(13) + mv_par09 + ' / ' + mv_par10 + ' / ' + mv_par11 ,"ATENCAO!!!","STOP")
		Return
	Endif

	aAdd(aDadosEmp, ALLTRIM(SM0->M0_NOMECOM))															// Nome da Empresa
	aAdd(aDadosEmp, SM0->M0_ENDCOB)																// EndereÁo
	aAdd(aDadosEmp, AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB)	// Complemento
	aAdd(aDadosEmp, "CEP: "  + Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3))			// CEP
	aAdd(aDadosEmp, "FONE: " + SM0->M0_TEL)														// Telefones
	aAdd(aDadosEmp, "CNPJ: " + tran(SM0->M0_CGC, '@R 99.999.999/9999-99'))						// CNPJ
	aAdd(aDadosEmp, "I.E.: " + ALLTRIM(SM0->M0_INSC))											// Inscricao Estadual

	aBitMap := {}
	aAdd(aBitMap, alltrim (GetSrvProfString("StartPath",""))+"banco"+mv_par09+".bmp")					   // logo do banco
	aAdd(aBitMap, FisxLogo("1") )   				   // Logo da Empresa



	MTRB->(dbGoTop())

	While MTRB->(!EoF())

		If MTRB->OK == cMark


			dbselectarea("SE1")
			Dbsetorder(1)
			SE1->(DBseek(xFilial("SE1")+MTRB->PREFIXO+MTRB->TITULO+MTRB->PARCELA+MTRB->TIPO ))

			DbSelectArea("SEE")
			DbSetOrder(1)
			If DbSeek(xFilial("SEE") + mv_par09 + mv_par10 + mv_par11 + mv_par12,.f.)
				_nNumBco := val(SEE->EE_FAXATU)
				_nBolIni := val(SEE->EE_FAXINI)
				_nBolFim := val(SEE->EE_FAXFIM)
				_nRecno  :=	SEE->(RECNO())
				_cBcoBol := SEE->EE_CODIGO
				_cAgeBol := SEE->EE_AGENCIA
				_cDigAge	:= SEE->EE_DVAGE
				_cDigCon	:= SEE->EE_DVCTA
				_cCtaBol := SEE->EE_CONTA
			Else
				MsgBox("Nao Econtrado Dados Param. Bancos.", "ATENCAO!!!","STOP")
				DbSelectArea("SE1")
				exit
			Endif

			If SE1->E1_BOLIMP == "S" .and. !(EMPTY(SE1->E1_NUMBCO))
				If SE1->E1_PORTADO == mv_par09
					If MsgBox("Boleto " + AllTrim(SE1->E1_NUMBCO) + " Titulo " + SE1->E1_NUM + " ja impresso","Confirma re-impressao??","YESNO")
						_nNumBco := SE1->E1_NUMBCO
						nOpc := 1
					Else
						nOpc := 3
						MTRB->(dbSkip())
						Loop
					Endif
				Else
					_cTexto := "Boleto " + AllTrim(SE1->E1_NUMBCO) + " Titulo " + SE1->E1_NUM + " ja impresso no Banco " + SE1->E1_PORTADO + chr(13)
					_cTexto += "Este boleto nao sera re-impresso"
					MsgBox(_cTexto, " ATENCAO!!!","STOP")
					nOpc := 3
					MTRB->(dbSkip())
					Loop
				Endif
			EndIf

			if nOpc == 0
				DbSelectArea("SE1")
				Reclock("SE1", .F.)
				Se1->E1_PORTADO:= mv_par09
				MSunlock()

				nossonumero()
				_nNumBco := SE1->E1_NUMBCO
			endif

			aDadosTit   := {}
			aAdd(aDadosTit, SE1->E1_PREFIXO+RIGHT(SE1->E1_NUM,6)+LEFT(SE1->E1_PARCELA,1))
			aAdd(aDadosTit, SE1->E1_EMISSAO)						   // Data da emiss„o do tÌtulo
			aAdd(aDadosTit, Date())									   // Data da emiss„o do boleto
			aAdd(aDadosTit, SE1->E1_VENCTO)   						   // Data do vencimento
			aAdd(aDadosTit, SE1->E1_SALDO - SE1->E1_DECRESC)		   // Valor do tÌtulo


			aadd(aDadosTit,ALLTRIM(SE1->E1_NUMBCO))


			aAdd(aDadosTit, DDATABASE)								   // Data do Processamento
			aAdd(aDadosTit, SE1->E1_DECRESC)								   // Data do Processamento

			aDadosBanco := {}
			aAdd(aDadosBanco, SA6->A6_COD)						       // Numero do Banco

			// Nome do Banco
			aAdd(aDadosBanco, SA6->A6_NREDUZ)

			//AGENCIA
			aADD( aDadosBanco, Iif(mv_par09 == "756",SEE->EE_DVAGE,AllTrim(SEE->EE_AGENCIA)+IIf(!Empty(SEE->EE_DVAGE),"-"+AllTrim(SEE->EE_DVAGE),"")))

			//CONTA
			aadd(aDadosBanco,ALLTRIM(SEE->EE_CONTA)+IIF(!EMPTY(SEE->EE_DVCTA),"-"+ALLTRIM(SEE->EE_DVCTA),""))

			//cedente
			aadd(aDadosBanco,iif(mv_par09 == '748' ,  ALLTRIM(SEE->EE_AGENCIA) + ALLTRIM(SEE->EE_CODEMP),ALLTRIM(SEE->EE_CODEMP) ))

			//cedente Caixa
			aadd(aDadosBanco,ALLTRIM(SEE->EE_CODEMP)+ IIF(!EMPTY(SEE->EE_DVCTA),"-"+ALLTRIM(SEE->EE_DVCTA),""))


			dbselectarea("SA1")
			SA1->(dbsetorder(1))
			SA1->(dbseek(xfilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))

			_xCGCCPF    := IIf(Len(AllTrim(SA1->A1_CGC))<>14,Transform(SA1->A1_CGC,"@R 999.999.999-99"),Transform(SA1->A1_CGC,"@R 99.999.999/9999-99"))
			aDatSacado  := {}
			aAdd(aDatSacado, AllTrim(SA1->A1_NOME))									// Raz„o Social
			aAdd(aDatSacado, AllTrim(SA1->A1_COD))  								// CÛdigo
			If !Empty(SA1->A1_ENDCOB)
				aAdd(aDatSacado, AllTrim(SA1->A1_ENDCOB )+" "+SA1->A1_BAIRROC)		// EndereÁo
			Else
				aAdd(aDatSacado, AllTrim(SA1->A1_END )+" "+SA1->A1_BAIRRO)			// EndereÁo
			EndIf
			If !Empty(SA1->A1_MUNC)
				aAdd(aDatSacado, AllTrim(SA1->A1_MUNC))								// Cidade
				// Cidade
			Else
				aAdd(aDatSacado, AllTrim(SA1->A1_MUN))								// Cidade
			EndIf
			If !Empty(SA1->A1_ESTC)
				aAdd(aDatSacado, SA1->A1_ESTC)										// Estado
			Else
				aAdd(aDatSacado, SA1->A1_EST)										// Estado
			EndIf
			_xCEPBANRI:=SA1->A1_CEP

			If !Empty(SA1->A1_CEPC)
				aAdd(aDatSacado, LEFT(SA1->A1_CEPC,5)+"-"+RIGHT(SA1->A1_CEPC,3))	// CEP
				_xCEPBANRI:=SA1->A1_CEPC
			Else
				aAdd(aDatSacado, LEFT(SA1->A1_CEP,5)+"-"+RIGHT(SA1->A1_CEP,3))		// CEP
				_xCEPBANRI:=SA1->A1_CEP
			EndIf
			aAdd(aDatSacado, _xCGCCPF)

			CB_RN := CODIGOBARRAS()

			oDuplic:StartPage()
			//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
			//≥ BOX: Inciais Padrıes				                                   ≥
			//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
			oDuplic:Box(0030 + _x, 0015, 0130 + _x, 0550)
			oDuplic:Box(0160 + _x, 0015, 0430 + _x, 0550)
			oDuplic:Box(0490 + _x, 0015, 0765 + _x, 0550)

			//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
			//≥ Tracejados Entre Comprovantes                         				  ≥
			//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
			//Entrega
			for _j := 15 to 550 step 2
				oDuplic:Say( 0135 + _x ,_j + _x, "-",oFont07)
			next _j

			//Recibo Sacado
			for _j := 15 to 550 step 2
				oDuplic:Say( 0470 + _x ,_j + _x, "-",oFont07)
			next _j

			//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
			//≥ BOX: Comprovante de Entrega                         				  ≥
			//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ

			oDuplic:Line(0013+ _x, 0120, 0030+ _x, 0120)
			oDuplic:Line(0013+ _x, 0170, 0030+ _x, 0170)
			oDuplic:Line(0105+ _x, 0350, 0105+ _x, 0550)
			oDuplic:Line(0030+ _x, 0350, 0130+ _x, 0350)

			oDuplic:Line(105+ _x, 0430, 0130+ _x, 0430)
			oDuplic:Line(105+ _x, 0480, 0130+ _x, 0480)

			oDuplic:SayBitMap(0008+ _x,0018,aBitMap[2], 50, 20)

			oDuplic:Say(0025+ _x, 0470, "Comprovante de Entrega",oFont07N)
			oDuplic:Say(0040+ _x, 0018, "Benefici·rio",oFont07)
			oDuplic:Say(0050+ _x, 0018 ,aDadosEmp[1] +" - "+ aDadosEmp[6]   ,oFont10)
			oDuplic:Say(0060+ _x, 0018, "Pagador",oFont07)
			oDuplic:Say(0070+ _x, 0018 ,left(aDatSacado[1],55) + " (" + aDatSacado[2] + ")" 		,oFont10)
			oDuplic:Say(0080+ _x, 0018, "Data de Vencimento",oFont07)
			oDuplic:Say(0090+ _x, 0018 ,substr(Dtos(aDadosTit[4]),7,2)+"/"+substr(Dtos(aDadosTit[4]),5,2)+"/"+substr(Dtos(aDadosTit[4]),1,4),oFont10)
			oDuplic:Say(0080+ _x, 0100, "Nro. Documento",oFont07)
			oDuplic:Say(0090+ _x, 0100 ,aDadosTit[1]                              		,oFont10)
			oDuplic:Say(0080+ _x, 0200, "Moeda",oFont07)
			oDuplic:Say(0090+ _x, 0200 ,"R$"                              		,oFont10)
			oDuplic:Say(0080+ _x, 0280, "Valor",oFont07)
			oDuplic:Say(0090+ _x, 0280 ,alltrim(Tran(aDadosTit[5],"@E 9,999,999.99")) 	,oFont10)

			If mv_par09 == "041" .or. mv_par09 == "237"
				oDuplic:Say(0100+ _x, 0018, "Agencia/ Cod. Benefici·rio",oFont07)
			Else
				oDuplic:Say(0100+ _x, 0018, "Agencia/ Cod. Cedente",oFont07)
			EndIf

			if mv_par09 = '748'
				oDuplic:Say(0110+ _x, 0018 ,Substr(aDadosBanco[5], 1,4)+ "." + Substr(aDadosBanco[5], 5,2) + "." + Substr(aDadosBanco[5], 7,5) ,oFont10)
			elseif mv_par09 = '001' .or. mv_par09 = '237' 
				oDuplic:Say(0110+ _x, 0018 ,aDadosBanco[3]+"/"+ aDadosBanco[4],oFont10)
			elseif mv_par09 = '104'
				oDuplic:Say(0110+ _x, 0018 ,SubStr(aDadosBanco[3],1,4)+"/"+ SubStr(aDadosBanco[5],1,6) + "-" + SubStr(aDadosBanco[5],7,1),oFont10)
			else
				oDuplic:Say(0110+ _x, 0018 ,aDadosBanco[3]+"/"+ aDadosBanco[5],oFont10)
			endif


			oDuplic:Say(0100+ _x, 0150, "Nosso Numero",oFont07)
			oDuplic:Say(0110+ _x, 0150 ,IIF(aDadosBanco[1]=='341',left(aDadosTit[6],3)+'/'+substr(aDadosTit[6],4),aDadosTit[6]),oFont10)


			oDuplic:Say(0040+ _x, 0355, "MOTIVOS DE N√O ENTREGA(para uso do entregador)",oFont07)
			oDuplic:Say(0060+ _x, 0355, "[  ] Mudou-se",oFont07)
			oDuplic:Say(0080+ _x, 0355, "[  ] Recusado",oFont07)
			oDuplic:Say(0100+ _x, 0355, "[  ] Desconhecido",oFont07)

			oDuplic:Say(0060+ _x, 0400, "[  ] Ausente",oFont07)
			oDuplic:Say(0080+ _x, 0400, "[  ] N„o Procurado",oFont07)
			oDuplic:Say(0100+ _x, 0400, "[  ] EndereÁo Insuficiente",oFont07)

			oDuplic:Say(0060+ _x, 0465, "[  ] N„o Existe o N˙mero",oFont07)
			oDuplic:Say(0080+ _x, 0465, "[  ] Falecido",oFont07)
			oDuplic:Say(0100+ _x, 0465, "[  ] Outros (anotar no verso)",oFont07)

			oDuplic:Say(0110+ _x, 0355, "RecebÌ(emos) o bloqueto",oFont07)
			oDuplic:Say(0120+ _x, 0355, "com os dados ao lado.",oFont07)

			oDuplic:Say(0110+ _x, 0435, "Data",oFont07)
			oDuplic:Say(0110+ _x, 0485, "Assinatura",oFont07)


			if mv_par09=='001'
				oDuplic:Say(0028 + _x , 0125, '001-9' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '001-9' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '001-9' ,oFont24 )
			elseif mv_par09=='341'
				oDuplic:Say(0028 + _x , 0125, '341-7' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '341-7' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '341-7' ,oFont24 )
			elseif mv_par09=='041'
				oDuplic:Say(0028 + _x, 0125, '041-8' ,oFont24 )
				oDuplic:Say(0158 + _x, 0125, '041-8' ,oFont24 )
				oDuplic:Say(0488 + _x, 0125, '041-8' ,oFont24 )
			elseif mv_par09=='399'
				oDuplic:Say(0028 + _x, 0125, '399-9' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '399-9' ,oFont24 )
				oDuplic:Say(0488 + _x, 0125, '399-9' ,oFont24 )
			elseif mv_par09=='237'
				oDuplic:Say(0028 + _x, 0125, '237-2' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '237-2' ,oFont24 )
				oDuplic:Say(0488 + _x, 0125, '237-2' ,oFont24 )
			elseif mv_par09=='033'
				oDuplic:Say(0028 + _x , 0125, '033-7' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '033-7' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '033-7' ,oFont24 )
			elseif mv_par09=='748'
				oDuplic:Say(0028 + _x , 0125, '748-X' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '748-X' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '748-X' ,oFont24 )
			elseif mv_par09=='104'
				oDuplic:Say(0028 + _x , 0125, '104-0' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '104-0' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '104-0' ,oFont24 )
			elseif mv_par08 == "756"
				oDuplic:Say(0028 + _x , 0125, '756-0' ,oFont24 )
				oDuplic:Say(0158 + _x , 0125, '756-0' ,oFont24 )
				oDuplic:Say(0488 + _x , 0125, '756-0' ,oFont24 )
			endif


			oDuplic:Say(0158 + _x, 0250 ,CB_RN[2]    ,oFont12)

			//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
			//≥  BOX: Recibo do Sacado                           				  ≥
			//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
			oDuplic:Line(0143+ _x, 0120, 0160+ _x, 0120)
			oDuplic:Line(0143+ _x, 0170, 0160+ _x, 0170)


			oDuplic:Line(0180+ _x, 0015, 0180+ _x, 0550)
			oDuplic:Line(0200+ _x, 0015, 0200+ _x, 0550)

			oDuplic:Line(0240+ _x, 0100, 0200+ _x, 0100)

			oDuplic:Line(0240+ _x, 0150, 0220+ _x, 0150)
			oDuplic:Line(0220+ _x, 0270, 0200+ _x, 0270)

			oDuplic:Line(0240+ _x, 0320, 0200+ _x, 0320)
			oDuplic:Line(0240+ _x, 0210, 0200+ _x, 0210)

			oDuplic:Line(0220+ _x, 0015, 0220+ _x, 0550)
			oDuplic:Line(0240+ _x, 0015, 0240+ _x, 0550)

			oDuplic:Line(0260+ _x, 0420, 0260+ _x, 0550)
			oDuplic:Line(0280+ _x, 0420, 0280+ _x, 0550)
			oDuplic:Line(0300+ _x, 0420, 0300+ _x, 0550)
			oDuplic:Line(0320+ _x, 0420, 0320+ _x, 0550)

			oDuplic:Line(0160+ _x, 0420, 0340+ _x, 0420)
			oDuplic:Line(0340+ _x, 0015, 0340+ _x, 0550)

			oDuplic:Line(0200+ _x, 0045, 0180+ _x, 0045)

			oDuplic:SayBitMap(0140+ _x,0017,aBitmap[1], 60, 18)

			If mv_par09=='041'
				oDuplic:Say(0140+ _x, 0470, "Recibo do Pagador",oFont07N)
			Else
				oDuplic:Say(0140+ _x, 0470, "Recibo do Sacado",oFont07N)
			EndIf
			oDuplic:Say(0165+ _x, 0017, "Local de Pagamento",oFont07)

			if mv_par09 == '041'
				//- " + _CepBR(_xCEPBANRI)
				oDuplic:Say(0175+ _x, 0017 ,"PAGAR PREFERENCIALMENTE NAS AG NCIAS DO BANCO BANRISUL. ",oFont10)
			Elseif mv_par09 == '399'
				oDuplic:Say(0175+ _x, 0017 ,"Pagar preferencialmente em agencias HSBC" 	,oFont10)
			Elseif  mv_par09 == '237'
				oDuplic:Say(0175+ _x, 0017 ,"Pag·vel preferencialmente nas agencias BRADESCO"   ,oFont10)
			Elseif  mv_par09 == '341'
				oDuplic:Say(0175+ _x, 0017 ,"AtÈ o vencimento, preferencialmente no ITA⁄. ApÛs o vencimento, somente no ITA⁄."   ,oFont10)
			Elseif  mv_par09 == '033'
				oDuplic:Say(0175+ _x, 0017 ,"Pag·vel preferencialmente no Grupo Santander."   ,oFont10)
			Elseif  mv_par09 == '748'
				oDuplic:Say(0175+ _x, 0017 ,"Pag·vel preferencialmente nas Coop. de CrÈdito do Sicredi"   ,oFont10)
			Elseif  mv_par09 == '104'
				oDuplic:Say(0175+ _x, 0017 ,"Preferencialmente nas Casas LotÈricas atÈ o valor limite"   ,oFont10)
			else
				oDuplic:Say(0175+ _x, 0017 ,"Pag·vel em Qualquer Banco atÈ o Vencimento" 	,oFont10)
			endif


			oDuplic:Say(0165+ _x, 0423, "Vencimento",oFont07)
			oDuplic:Say(0175+ _x, 0423 ,substr(Dtos(aDadosTit[4]),7,2)+"/"+substr(Dtos(aDadosTit[4]),5,2)+"/"+substr(Dtos(aDadosTit[4]),1,4),oFont10)
			oDuplic:Say(0193+ _x, 0017, "Benefici·rio",oFont07)
			oDuplic:Say(0188+ _x, 0050 ,aDadosEmp[1] +" "+ aDadosEmp[6]              ,oFont10)
			oDuplic:Say(0198+ _x, 0050 , alltrim(SM0->M0_ENDCOB) +",  "+ AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB + " CEP: "  + Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)	,oFont08)

			If mv_par09 == '041' .or. mv_par09 == "237"
				oDuplic:Say(0185+ _x, 0423, "Agencia/Cod. Benefici·rio",oFont07)
			Else
				oDuplic:Say(0185+ _x, 0423, "Agencia/Cod. Cedente",oFont07)
			EndIf

			if mv_par09 = '748'
				oDuplic:Say(0195+ _x, 0423 ,Substr(aDadosBanco[5], 1,4)+ "." + Substr(aDadosBanco[5], 5,2) + "." + Substr(aDadosBanco[5], 7,5) ,oFont10)
			elseif mv_par09 = '001' .or. mv_par09 = '237' .or. mv_par09 = '341'
				oDuplic:Say(0195+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[4],oFont10)
			elseif mv_par09 = '104'
				oDuplic:Say(0195+ _x, 0423 ,SubStr(aDadosBanco[3],1,4)+"/"+ SubStr(aDadosBanco[5],1,6) + "-" + SubStr(aDadosBanco[5],7,1),oFont10)
			else
				oDuplic:Say(0195+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[5],oFont10)
			endif

			oDuplic:Say(0205+ _x, 0017, "Data Documento",oFont07)
			oDuplic:Say(0215+ _x, 0017 ,substr(Dtos(aDadosTit[2]),7,2)+"/"+substr(Dtos(aDadosTit[2]),5,2)+"/"+substr(Dtos(aDadosTit[2]),1,4)                        		,oFont10)

			oDuplic:Say(0205+ _x, 0103, "Nro. Documento",oFont07)
			oDuplic:Say(0215+ _x, 0103 ,aDadosTit[1]                                	,oFont10)

			oDuplic:Say(0205+ _x, 0215, "EspÈcie Doc.",oFont07)
			oDuplic:Say(0215+ _x, 0215 ,'DM'		                                	,oFont10)

			oDuplic:Say(0205+ _x, 0277, "Aceite",oFont07)
			oDuplic:Say(0215+ _x, 0277 ,"N"                                       ,oFont10)

			oDuplic:Say(0205+ _x, 0323, "Data do Processamento",oFont07)
			oDuplic:Say(0215+ _x, 0323 ,substr(Dtos(aDadosTit[7]),7,2)+"/"+substr(Dtos(aDadosTit[7]),5,2)+"/"+substr(Dtos(aDadosTit[7]),1,4)                        		,oFont10)

			oDuplic:Say(0205+ _x, 0423, "Nosso Numero",oFont07)

			If(aDadosBanco[1]=='341')
				oDuplic:Say(0215+ _x, 0423 ,left(aDadosTit[6],3)+'/'+substr(aDadosTit[6],4),oFont10)
			Elseif(aDadosBanco[1]=='237')
				oDuplic:Say(0215+ _x, 0423 ,substr(aDadosTit[6],1,2)+'/'+substr(aDadosTit[6],3),oFont10)
			else
				oDuplic:Say(0215+ _x, 0423 ,aDadosTit[6],oFont10)
			Endif


			oDuplic:Say(0225+ _x, 0017, "Uso do Banco",oFont07)
			oDuplic:Say(0225+ _x, 0103, "Carteira",oFont07)
			If aDadosBanco[1] == '104'
				oDuplic:Say(0235+ _x , 0103 ,SEE->EE_CODCART 	            ,oFont10)
			ElseIf(aDadosBanco[1]!='237')
				oDuplic:Say(0235+ _x , 0103 ,SEE->EE_CODCART                ,oFont10)
			else
				oDuplic:Say(0235+ _x , 0103 ,SEE->EE_CODCART 	            ,oFont10)
			endif

			oDuplic:Say(0225+ _x, 0153, "Moeda",oFont07)
			oDuplic:Say(0235+ _x, 0153 ,"R$"                                        	,oFont10)

			oDuplic:Say(0225+ _x, 0213, "Quantidade",oFont07)
			oDuplic:Say(0225+ _x, 0323, "Valor",oFont07)
			oDuplic:Say(0225+ _x, 0423, "(=) Valor do Documento",oFont07)
			oDuplic:Say(0235+ _x, 0423 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)

			If(aDadosBanco[1]=='041')
				oDuplic:Say(0245+ _x, 0017, "InstruÁıes/Texto de Responsabilidade do Benefici·rio",oFont07n)
			Else
				oDuplic:Say(0245+ _x, 0017, "InstruÁıes/Texto de Responsabilidade do Cedente",oFont07n)
			EndIf

			If(aDadosBanco[1]=='001')
				//oDuplic:Say( 0265 + _x, 0017, "Cobrar juros de: R$" + Transform((((SE1->E1_SALDO - SE1->E1_DECRESC)* 0.01) / 30),"@E 9,999,999.99") + " ao dia. ",oFont10)
				oDuplic:Say( 0275 + _x, 0017, "PROTESTO 5 DIAS AP”S VENCIMENTO",oFont10)
			ElseIf(aDadosBanco[1]=='041')
				oDuplic:Say( 0265 + _x, 0017, "Protestar 5 Dias ApÛs Vencimento.",oFont07n)
			ElseIf(aDadosBanco[1]=='237')
				oDuplic:Say( 0265 + _x, 0017, "AP”S VENCIMENTO, COBRAR JURO DE R$ " + Transform((SE1->E1_SALDO * 0.0012),"@E 9,999,999.99") + " AO DIA ",oFont07n)
				oDuplic:Say( 0275 + _x, 0017, "AP”S VENCIMENTO COBRAR MULTA DE R$ " + Transform((SE1->E1_SALDO * 0.02),"@E 9,999,999.99") + "",oFont07n)
			ElseIf(aDadosBanco[1]=='341')
			//	oDuplic:Say( 0265 + _x, 0017, "AP”S VENCIMENTO, COBRAR JURO DE R$ " + Transform((SE1->E1_SALDO * 0.0012),"@E 9,999,999.99") + " AO DIA ",oFont07n)
			//	oDuplic:Say( 0275 + _x, 0017, "AP”S VENCIMENTO COBRAR MULTA DE R$ " + Transform((SE1->E1_SALDO * 0.02),"@E 9,999,999.99") + "",oFont07n)
			endif

			oDuplic:Say(0285+ _x, 0017, alltrim(mv_par13)		,oFont07n)
			if !empty(SEE->EE_FORMEN1)
				oDuplic:Say(0295+ _x, 0017, SEE->EE_FORMEN1,oFont07n)
			endif
			if !empty(SEE->EE_FORMEN2)
				oDuplic:Say(0305+ _x, 0017, SEE->EE_FORMEN2,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT1)
				oDuplic:Say(0315+ _x, 0017, SEE->EE_FOREXT1,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT2)
				oDuplic:Say(0325+ _x, 0017, SEE->EE_FOREXT2,oFont07n)
			endif


			if mv_par09 == "041"
				oDuplic:Say(0340+ _x, 0017, "SAC BANRISUL - 0800 646 1515    OUVIDORIA BANRISUL - 0800 644 2200 ",oFont07n)
			endif


			oDuplic:Say(0245+ _x, 0423, "(-) Desconto/Abatimanto",oFont07)
			oDuplic:Say(0265+ _x, 0423, "(-) Outras DeduÁıes",oFont07)
			oDuplic:Say(0285+ _x, 0423, "(+) Mora/Multa",oFont07)
			oDuplic:Say(0305+ _x, 0423, "(+) Outros AcrÈscimos",oFont07)
			oDuplic:Say(0325+ _x, 0423, "(=) Valor Cobrado",oFont07)

			oDuplic:Say(0345+ _x, 0017, "Pagador",oFont07)
			oDuplic:Say(0355+ _x, 0017 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont10)
			oDuplic:Say(0365+ _x, 0017 ,aDatSacado[3]                                                ,oFont10)
			oDuplic:Say(0375+ _x, 0017 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
			oDuplic:Say(0385+ _x, 0017 ,aDatSacado[6]                                                ,oFont10)

			oDuplic:Say(0425+ _x, 0017, "Sacador/Avalista",oFont07)


			//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
			//≥  BOX: Ficha de CompensaÁ„o                             				  ≥
			//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
			oDuplic:Line(0473+ _x, 0120, 0490+ _x, 0120)
			oDuplic:Line(0473+ _x, 0170, 0490+ _x, 0170)


			oDuplic:Line(0510+ _x, 0015, 0510+ _x, 0550)
			oDuplic:Line(0530+ _x, 0015, 0530+ _x, 0550)
			oDuplic:Line(0550+ _x, 0015, 0550+ _x, 0550)
			oDuplic:Line(0570+ _x, 0015, 0570+ _x, 0550)

			oDuplic:Line(0570+ _x, 0100, 0530+ _x, 0100)

			oDuplic:Line(0570+ _x, 0320, 0530+ _x, 0320)
			oDuplic:Line(0570+ _x, 0210, 0530+ _x, 0210)

			oDuplic:Line(0570+ _x, 0150, 0550+ _x, 0150)
			oDuplic:Line(0550+ _x, 0270, 0530+ _x, 0270)

			oDuplic:Line(0590+ _x, 0420, 0590+ _x, 0550)
			oDuplic:Line(0610+ _x, 0420, 0610+ _x, 0550)
			oDuplic:Line(0630+ _x, 0420, 0630+ _x, 0550)
			oDuplic:Line(0650+ _x, 0420, 0650+ _x, 0550)

			oDuplic:Line(0490+ _x, 0420, 0670+ _x, 0420)
			oDuplic:Line(0670+ _x, 0015, 0670+ _x, 0550)

			oDuplic:Line(0530+ _x, 0045, 0510+ _x, 0045)



			oDuplic:Say(0495+ _x, 0017, "Local de Pagamento",oFont07)

			oDuplic:SayBitMap(0470+ _x,0017,aBitmap[1], 60, 18)

			oDuplic:Say(0488 + _x, 0250 ,CB_RN[2]    ,oFont12)

			if mv_par09 == '041'
				//- " + _CepBR(_xCEPBANRI)
				oDuplic:Say(0505+ _x, 0017 ,"PAGAR PREFERENCIALMENTE NAS AG NCIAS DO BANCO BANRISUL.",oFont10)
			Elseif mv_par09 == '399'
				oDuplic:Say(0505+ _x, 0017 ,"Pagar preferencialmente em agencias HSBC" 	,oFont10)
			Elseif  mv_par09 == '237'
				oDuplic:Say(0505+ _x, 0017 ,"Pag·vel preferencialmente nas agencias BRADESCO"   ,oFont10)
			Elseif  mv_par09 == '341'
				oDuplic:Say(0505+ _x, 0017 ,"AtÈ o vencimento, preferencialmente no ITA⁄. ApÛs o vencimento, somente no ITA⁄."   ,oFont10)
			Elseif  mv_par09 == '033'
				oDuplic:Say(0505+ _x, 0017 ,"Pag·vel preferencialmente no Grupo Santander."   ,oFont10)
			Elseif  mv_par09 == '748'
				oDuplic:Say(0505+ _x, 0017 ,"Pag·vel preferencialmente nas Coop. de CrÈdito do Sicredi"   ,oFont10)
			Elseif  mv_par09 == '104'
				oDuplic:Say(0505+ _x, 0017 ,"Preferencialmente nas Casas LotÈricas atÈ o valor limite"   ,oFont10)
			else
				oDuplic:Say(0505+ _x, 0017 ,"Pag·vel em Qualquer Banco atÈ o Vencimento" 	,oFont10)
			endif

			oDuplic:Say(0495+ _x, 0423, "Vencimento",oFont07)
			oDuplic:Say(0505+ _x, 0423 ,substr(Dtos(aDadosTit[4]),7,2)+"/"+substr(Dtos(aDadosTit[4]),5,2)+"/"+substr(Dtos(aDadosTit[4]),1,4),oFont10)
			oDuplic:Say(0523+ _x, 0017, "Benefici·rio",oFont07)
			oDuplic:Say(0518+ _x, 0050 ,aDadosEmp[1] +" "+ aDadosEmp[6]              ,oFont10)
			oDuplic:Say(0528+ _x, 0050 , alltrim(SM0->M0_ENDCOB) +",  "+ AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB + " CEP: "  + Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)	,oFont08)
			If mv_par09 == '041' .or. mv_par09 == "237"
				oDuplic:Say(0515+ _x, 0423, "Agencia/Cod. Benefici·rio",oFont07)
			Else
				oDuplic:Say(0515+ _x, 0423, "Agencia/Cod. Cedente",oFont07)
			EndIf

			if mv_par09 = '748'
				oDuplic:Say(0525+ _x, 0423 ,Substr(aDadosBanco[5], 1,4)+ "." + Substr(aDadosBanco[5], 5,2) + "." + Substr(aDadosBanco[5], 7,5) ,oFont10)
			elseif mv_par09 = '001' .or. mv_par09 = '237' .or. mv_par09 = '341'
				oDuplic:Say(0525+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[4],oFont10)
			elseif mv_par09 = '104'
				oDuplic:Say(0525+ _x, 0423 ,SubStr(aDadosBanco[3],1,4)+"/"+ SubStr(aDadosBanco[5],1,6) + "-" + SubStr(aDadosBanco[5],7,1),oFont10)
			else
				oDuplic:Say(0525+ _x, 0423 ,aDadosBanco[3]+"/"+ aDadosBanco[5],oFont10)
			endif
			oDuplic:Say(0535+ _x, 0017, "Data Documento",oFont07)
			oDuplic:Say(0545+ _x, 0017 ,substr(Dtos(aDadosTit[2]),7,2)+"/"+substr(Dtos(aDadosTit[2]),5,2)+"/"+substr(Dtos(aDadosTit[2]),1,4)                        		,oFont10)
			oDuplic:Say(0535+ _x, 0103, "Nro. Documento",oFont07)
			oDuplic:Say(0545+ _x, 0103 ,aDadosTit[1]                                	,oFont10)
			oDuplic:Say(0535+ _x, 0213, "EspÈcie Doc.",oFont07)
			oDuplic:Say(0545+ _x, 0213 ,'DM'		                                	,oFont10)
			oDuplic:Say(0535+ _x, 0277, "Aceite",oFont07)
			oDuplic:Say(0545+ _x, 0277 ,"N"                                       ,oFont10) 
			oDuplic:Say(0535+ _x, 0323, "Data do Processamento",oFont07)
			oDuplic:Say(0545+ _x, 0323 ,substr(Dtos(aDadosTit[7]),7,2)+"/"+substr(Dtos(aDadosTit[7]),5,2)+"/"+substr(Dtos(aDadosTit[7]),1,4)                        		,oFont10)
			oDuplic:Say(0535+ _x, 0423, "Nosso Numero",oFont07)

			If(aDadosBanco[1]=='341')
				oDuplic:Say(0545+ _x, 0423 ,left(aDadosTit[6],3)+'/'+substr(aDadosTit[6],4),oFont10)
			Elseif(aDadosBanco[1]=='237')
				oDuplic:Say(0545+ _x, 0423 ,substr(aDadosTit[6],1,2)+'/'+substr(aDadosTit[6],3),oFont10)
			else
				oDuplic:Say(0545+ _x, 0423 ,aDadosTit[6],oFont10)
			Endif

			oDuplic:Say(0555+ _x, 0017, "Uso do Banco",oFont07)
			oDuplic:Say(0555+ _x, 0103, "Carteira",oFont07)
			If aDadosBanco[1] == '104'
				oDuplic:Say(0565+ _x , 0103 ,SEE->EE_CODCART 	            ,oFont10)
			ElseIf(aDadosBanco[1]!='237')
				oDuplic:Say(0565+ _x, 0103 ,SEE->EE_CODCART                 ,oFont10)
			else
				oDuplic:Say(0565+ _x, 0103 ,SEE->EE_CODCART              ,oFont10)
			endif

			oDuplic:Say(0555+ _x, 0153, "Moeda",oFont07)
			oDuplic:Say(0565+ _x, 0153 ,"R$"                                        	,oFont10)
			oDuplic:Say(0555+ _x, 0213, "Quantidade",oFont07)
			oDuplic:Say(0555+ _x, 0323, "Valor",oFont07)
			oDuplic:Say(0555+ _x, 0423, "(=) Valor do Documento",oFont07)
			oDuplic:Say(0565+ _x, 0423 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)

			If(aDadosBanco[1]=='041')
				oDuplic:Say(0575+ _x, 0017, "InstruÁıes/Texto de Responsabilidade do Benefici·rio",oFont07n)
			Else
				oDuplic:Say(0575+ _x, 0017, "InstruÁıes/Texto de Responsabilidade do Cedente",oFont07n)
			EndIf

			If(aDadosBanco[1]=='001')
				//oDuplic:Say(0595+ _x, 0017, "Cobrar juros de: R$"+ Transform((((SE1->E1_SALDO - SE1->E1_DECRESC)* 0.01) / 30),"@E 9,999,999.99") + " ao dia.",oFont10)
				oDuplic:Say(0605+ _x, 0017, "PROTESTO 5 DIAS AP”S VENCIMENTO",oFont10)
			ElseIf(aDadosBanco[1]=='041')
				oDuplic:Say(0595+ _x, 0017, "Protestar 5 Dias ApÛs Vencimento.",oFont07n)
			ElseIf(aDadosBanco[1]=='237')
				oDuplic:Say( 0595 + _x, 0017, "AP”S VENCIMENTO, COBRAR JURO DE R$ " + Transform((SE1->E1_SALDO * 0.0012),"@E 9,999,999.99") + " AO DIA ",oFont07n)
				oDuplic:Say( 0605 + _x, 0017, "AP”S VENCIMENTO COBRAR MULTA DE R$ " + Transform((SE1->E1_SALDO * 0.02),"@E 9,999,999.99") + "",oFont07n)
			ElseIf(aDadosBanco[1]=='341')
			//	oDuplic:Say( 0595 + _x, 0017, "AP”S VENCIMENTO, COBRAR JURO DE R$ " + Transform((SE1->E1_SALDO * 0.0012),"@E 9,999,999.99") + " AO DIA ",oFont07n)
			//	oDuplic:Say( 0605 + _x, 0017, "AP”S VENCIMENTO COBRAR MULTA DE R$ " + Transform((SE1->E1_SALDO * 0.02),"@E 9,999,999.99") + "",oFont07n)
			endif
			oDuplic:Say(0615+ _x, 0017, alltrim(mv_par13),oFont07n)
			if !empty(SEE->EE_FORMEN1)
				oDuplic:Say(0625+ _x, 0017, SEE->EE_FORMEN1,oFont07n)
			endif
			if !empty(SEE->EE_FORMEN2)
				oDuplic:Say(0635+ _x, 0017, SEE->EE_FORMEN2,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT1)
				oDuplic:Say(0645+ _x, 0017, SEE->EE_FOREXT1,oFont07n)
			endif
			if !empty(SEE->EE_FOREXT2)
				oDuplic:Say(0655+ _x, 0017, SEE->EE_FOREXT1,oFont07n)
			endif

			if mv_par09 == "041"
				oDuplic:Say(0670+ _x, 0017, "SAC BANRISUL - 0800 646 1515    OUVIDORIA BANRISUL - 0800 644 2200",oFont07n)
			endif

			oDuplic:Say(0575+ _x, 0423, "(-) Desconto/Abatimanto",oFont07)
			oDuplic:Say(0595+ _x, 0423, "(-) Outras DeduÁıes",oFont07)
			oDuplic:Say(0615+ _x, 0423, "(+) Mora/Multa",oFont07)
			oDuplic:Say(0635+ _x, 0423, "(+) Outros AcrÈscimos",oFont07)
			oDuplic:Say(0655+ _x, 0423, "(=) Valor Cobrado",oFont07)

			oDuplic:Say(0675+ _x, 0017, "Pagador",oFont07)

			oDuplic:Say(0685+ _x, 0017 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont10)
			oDuplic:Say(0695+ _x, 0017 ,aDatSacado[3]                                                ,oFont10)
			oDuplic:Say(0705+ _x, 0017 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
			oDuplic:Say(0715+ _x, 0017 ,aDatSacado[6]                                                ,oFont10)


			oDuplic:Say(0755+ _x, 0017, "Sacador/Avalista",oFont07)
			oDuplic:Say(0770+ _x, 0470, "Ficha de CompensaÁ„o",oFont07N)
			oDuplic:Say(0770+ _x, 0380, "AutenticaÁ„o Mec‚nica",oFont07)

			oDuplic:Code128C(0830+ _x,025,CB_RN[1], 40 )

			oDuplic:EndPage()
		endif

		MTRB->(dbSkip())


	Enddo
	MTRB->(dbgotop())

return


/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒø±±
±±≥Funcao    ≥ VALIDPERG ≥ Autor ≥ Claudio H. Ferreira  ≥ Data ≥10.06.13  ≥±±
±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒ¥±±
±±≥Descricao ≥ Cria perguntas no SX1. Se a pergunta ja existir, atualiza. ≥±±
±±≥          ≥ Se houver mais perguntas no SX1 do que as definidas aqui,  ≥±±
±±≥          ≥ deleta as excedentes do SX1.                               ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/
Static Function ValidPerg()
	local _aArea  := GetArea ()
	local _aRegs  := {}
	local _aHelps := {}
	local _i      := 0
	local _j      := 0

	_aRegs = {}
	//           GRUPO  ORDEM PERGUNT                           PERSPA PERENG VARIAVL   TIPO TAM DEC PRESEL GSC  VALID         VAR01       DEF01              DEFSPA1             DEFENG1             CNT01 VAR02 DEF02             DEFSPA2             DEFENG2            CNT02 VAR03 DEF03   DEFSPA3  DEFENG3  CNT03 VAR04 DEF04  DEFSPA4  DEFENG4  CNT04 VAR05 DEF05   DEFSPA5   DEFENG5  CNT05  F3   PYME   GRPSXG   HELP   PICTURE
	AADD(_aRegs,{cPerg, "01", "Data Emiss„o de:                ", "",    "",    "mv_ch1", "D", 08, 0,  0,     "G", "",           "mv_par01", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "02", "Data Emiss„o AtÈ:               ", "",    "",    "mv_ch2", "D", 08, 0,  0,     "G", "",           "mv_par02", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "03", "Prefixo de:                     ", "",    "",    "mv_ch3", "C", 03, 0,  0,     "G", "",           "mv_par03", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "04", "Prefixo atÈ:                    ", "",    "",    "mv_ch4", "C", 03, 0,  0,     "G", "",           "mv_par04", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "05", "TÌtulo de:                      ", "",    "",    "mv_ch5", "C", 09, 0,  0,     "G", "",           "mv_par05", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "06", "TÌtulo atÈ:                     ", "",    "",    "mv_ch6", "C", 09, 0,  0,     "G", "",           "mv_par06", "",                "",                 "",                 "",   "",   "",                "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "07", "Portador:                       ", "",    "",    "mv_ch7", "C", 03, 0,  0,     "G", "",           "mv_par07", "",				  "",                 "",                 "",   "",   "",          		 "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "","S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "08", "Tipos de TÌtulo:(separado por ;)", "",    "",    "mv_ch8", "C", 60, 0,  0,     "G", "",           "mv_par08", "",                "",                 "",                 "",   "",   "",   	         "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "09", "Banco p/ Emiss„o:               ", "",    "",    "mv_ch9", "C", 03, 0,  0,     "G", "",           "mv_par09", "",				  "",                 "",                 "",   "",   "",          		 "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "A63","S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "10", "AgÍncia:                        ", "",    "",    "mv_ch10","C", 05, 0,  0,     "G", "",           "mv_par10", "",                "",                 "",                 "",   "",   "",             	 "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "11", "Conta:                          ", "",    "",    "mv_ch11","C", 10, 0,  0,     "G", "",           "mv_par11", "",           	  "",                 "",                 "",   "",   "",    			 "",                "",                "",   "",   "",	   "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "12", "Sub-Conta:                      ", "",    "",    "mv_ch12","C", 03, 0,  0,     "G", "",           "mv_par12", "",                "",                 "",                 "",   "",   "",         	     "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })
	AADD(_aRegs,{cPerg, "13", "Mensagem Extra:                 ", "",    "",    "mv_ch13","C", 60, 0,  0,     "G", "",           "mv_par13", "",                "",                 "",                 "",   "",   "",   	         "",                "",                "",   "",   "",     "",      "",      "",   "",   "",    "",      "",      "",   "",   "",      "",      "",      "",   "",   "S",   "",	   "",    ""            })



	// Definicao de textos de help (versao 7.10 em diante): uma array para cada linha.
	_aHelps = {}
	//              Ordem   1234567890123456789012345678901234567890    1234567890123456789012345678901234567890    1234567890123456789012345678901234567890
	//AADD (_aHelps, {"01", {"                                        ", "                                        ", "                                        "}})

	DbSelectArea ("SX1")
	DbSetOrder (1)
	For _i := 1 to Len (_aRegs)
		If ! DbSeek (cPerg + _aRegs [_i, 2])
			RecLock("SX1", .T.)
		Else
			RecLock("SX1", .F.)
		Endif
		For _j := 1 to FCount ()
			// Campos CNT nao sao gravados para preservar conteudo anterior.
			If _j <= Len (_aRegs [_i]) .and. left (fieldname (_j), 6) != "X1_CNT" .and. fieldname (_j) != "X1_PRESEL"
				FieldPut(_j, _aRegs [_i, _j])
			Endif
		Next
		MsUnlock()
	Next

	// Deleta do SX1 as perguntas que nao constam em _aRegs
	DbSeek (cPerg, .T.)
	do while ! eof () .and. x1_grupo == cPerg
		if ascan (_aRegs, {|_aVal| _aVal [2] == sx1 -> x1_ordem}) == 0
			reclock("SX1", .F.)
			dbdelete()
			msunlock()
		endif
		dbskip()
	enddo

	// Gera helps das perguntas
	For _i := 1 to Len (_aHelps)
		PutSX1Help ("P." + AllTrim(cPerg) + _aHelps [_i, 1] + ".", _aHelps [_i, 2], {}, {})
	Next

	Restarea(_aArea)

Return

/*
Cria ·rea de trabalho
*/
Static Function CriaArqT()

	Local aCampos		:= {}

	AADD(aCampos,{"OK", "C", 02, 0}) // CAMPO DE SELE«√O

	AADD(aCampos,{"STATUS", "C", 01, 0})

	aTam:=TamSX3 ("E1_NOMCLI")
	AADD(aCampos,{"Cliente",         aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_PREFIXO")
	AADD(aCampos,{"Prefixo",    aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_NUM")
	AADD(aCampos,{"Titulo",      aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_PARCELA")
	AADD(aCampos,{"Parcela",         aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_VALOR")
	AADD(aCampos,{"Valor",      aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_VENCTO")
	AADD(aCampos,{"Vencimento",   aTam[3],aTam[1],aTam[2]})

	aTam:=TamSX3 ("E1_TIPO")
	AADD(aCampos,{"Tipo",   aTam[3],aTam[1],aTam[2]})

	cNomeArq   := CriaTrab(aCampos)
	cIndOrdPag := CriaTrab(Nil,.F.)

	If Select("MTRB") <> 0
		DbSelectArea("MTRB")
		MTRB->(DbCloseArea())
	EndIf

	dbUseArea( .T., __cRDDNTTS, cNomeArq,"MTRB", .T., .F. )
	IndRegua("MTRB",cNomeArq,"Cliente",,,OemToAnsi("Selecionando Registros...")) // Õndice

Return

/*
Cria vetor utilizado no MsSelect
*/
Static Function CriaSelect(aCpos)

	dbSelectArea("SX3")
	_nOrdem := IndexOrd()

	SX3->(dbSetOrder(2))

	AADD(aCpos,{"OK",""," "})

	AADD(aCpos,{"STATUS", "", "Status", "@!"})

	SX3->(DbSeek("E1_NOMCLI"))
	AADD(aCpos,{"Cliente","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_PREFIXO"))
	AADD(aCpos,{"Prefixo","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_NUM"))
	AADD(aCpos,{"Titulo","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_PARCELA"))
	AADD(aCpos,{"Parcela","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_VALOR"))
	AADD(aCpos,{"Valor","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_VENCTO"))
	AADD(aCpos,{"Vencimento","",X3Titulo(),SX3->X3_PICTURE})

	SX3->(DbSeek("E1_TIPO"))
	AADD(aCpos,{"Tipo","",X3Titulo(),SX3->X3_PICTURE})

	dbSetOrder(_nOrdem)

Return

/*
Cria area de trabalho com a  duplicata
*/

Static Function CarregaTrb()
Local i:= 0
	cAliasTmp := GetNextAlias()
	aTeste    := {}

	if !empty(mv_par08)
		aTeste    := STRTOKARR(mv_par08, ';')
	endif

	cQuery := " SELECT E1_NOMCLI,E1_PREFIXO,E1_NUM,E1_PARCELA, E1_VALOR, E1_VENCTO, E1_TIPO  "
	cQuery += " FROM "+RetSqlName("SE1")+" SE1 "
	cQuery += " WHERE " + RetSqlCond("SE1") + " AND "
	cQuery += "E1_EMISSAO >= '" + DToS(mv_par01) + "' AND "
	cQuery += "E1_EMISSAO <= '" + DToS(mv_par02) + "' AND "
	cQuery += "E1_PREFIXO >= '" + mv_par03 + "' AND "
	cQuery += "E1_PREFIXO <= '" + mv_par04 + "' AND "
	cQuery += "E1_NUM >= '" + mv_par05 + "' AND "
	cQuery += "E1_NUM <= '" + mv_par06 + "' AND "
	cQuery += "E1_PORTADO = '" + mv_par07 + "'  "



	If len(Ateste) > 0
		cQuery += " AND ("
	endif
	//cQuery += "E1_TIPO <> 'DP' AND "
	For i := 1 to Len(aTeste)
		cQuery += " E1_TIPO IN ('"+AllTrim(aTeste[i])+"')  OR"
	Next
	If len(Ateste) > 0
		cQuery := SUBSTR(cQuery,1,LEN(cQuery) -2) + ")"
	endif
	//cQuery += " E1_TIPO = 'NF' OR E1_TIPO = 'DP' ) AND "	
	//	cQuery += " NOT (E1_VENCTO  = E1_EMISSAO) AND "
	cQuery += " AND NOT (E1_VENCREA = E1_EMISSAO) AND "


	cQuery += "E1_SALDO > 0"

	cQuery := ChangeQuery(cQuery)

	dbUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), cAliasTmp, .F., .T. )

	dbSelectArea("MTRB")

	MEMOWRITE("C:\TEMP\queryFBBOLT.TXT", cQuery)


	Do While !(cAliasTmp)->(EoF())

		RecLock("MTRB",.T.)

		Replace MTRB->OK        With cMark
		Replace MTRB->STATUS    With " "
		Replace MTRB->CLIENTE    With (cAliasTmp)->E1_NOMCLI
		Replace MTRB->PREFIXO   With (cAliasTmp)->E1_PREFIXO
		Replace MTRB->TITULO       With (cAliasTmp)->E1_NUM
		Replace MTRB->PARCELA   With (cAliasTmp)->E1_PARCELA
		Replace MTRB->VALOR	   With (cAliasTmp)->E1_VALOR
		Replace MTRB->VENCIMENTO    With Stod((cAliasTmp)->E1_VENCTO)
		Replace MTRB->TIPO    With (cAliasTmp)->E1_Tipo
		MsUnLock()

		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->(dbCloseArea())

	dbSelectArea("MTRB")
	MTRB->(dbGotop())

Return

/*
FunÁ„o executada ao marcar algum item no grid
*/

Static Function MarkTRB()

	RecLock("MTRB",.F.)
	If Marked("OK")
		MTRB->OK := cMark
	Else
		MTRB->OK := ""
	Endif
	MsUnLock()

	oMark:oBrowse:Refresh()

Return()

/*
FunÁ„o executada para marcar todos os registros validos
*/
Static Function MarkAll()


	MTRB->(dbGoTop())

	While MTRB->(!EoF())

		RecLock("MTRB",.F.)

		If !Marked("OK")
			MTRB->OK := cMark
		Else
			MTRB->OK := ""
		Endif

		MsUnLock()

		MTRB->(dbSkip())
	Enddo

	MTRB->(dbGoTop())

	oMark:oBrowse:Refresh()

Return()


//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥ Chamada da Funcao Modulo10()                                        ≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
/*
Static Function Modulo10(cData)

	Local L,D,P := 0
	Local B     := .F.
	L := Len(cData)
	B := .T.
	D := 0
	While L > 0
		P := Val(SubStr(cData, L, 1))
		If (B)
			P := P * 2
			If P > 9
				P := P - 9
			Endif
		Endif
		D := D + P
		L := L - 1
		B := !B
	Enddo
	D := 10 - (Mod(D,10))
	If D = 10
		D := 0
	Endif

Return(D)
*/

//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥ Chamada da Funcao CODIGOBARRAS()                                    ≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
Static Function CODIGOBARRAS()
	local _j := 0
	local _ix := 0
	Local i := 0
	Local nJ:= 0
	_xCodbar := ""
	_ccodbar := ""
	DO CASE
		CASE SE1->E1_PORTADO == "001"   // Banco Do Brasil
		if SEE->EE_POSCONV = '6' //Convenio 6 PosiÁoes
			i:=1
			Do While i<= 44
				STR_NUM[i] := 1
				i:=i+1
			Enddo

			STR_NUM[1]:=0
			STR_NUM[2]:=0
			STR_NUM[3]:=1
			STR_NUM[4]:=9    // MOEDA
			_nFator := SE1->E1_VENCTO - CTOD("07/10/1997")
			_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
			_XX := str(_nFator,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)
			STR_NUM[6]:=VAL(SUBSTR(_XX,1,1))
			STR_NUM[7]:=VAL(SUBSTR(_XX,2,1))
			STR_NUM[8]:=VAL(SUBSTR(_XX,3,1))
			STR_NUM[9]:=VAL(SUBSTR(_XX,4,1))
			STR_NUM[10]:=VAL(SUBSTR(_XX,5,1))
			STR_NUM[11]:=VAL(SUBSTR(_XX,6,1))
			STR_NUM[12]:=VAL(SUBSTR(_XX,7,1))
			STR_NUM[13]:=VAL(SUBSTR(_XX,8,1))
			STR_NUM[14]:=VAL(SUBSTR(_XX,9,1))
			STR_NUM[15]:=VAL(SUBSTR(_XX,10,1))
			STR_NUM[16]:=VAL(SUBSTR(_XX,11,1))
			STR_NUM[17]:=VAL(SUBSTR(_XX,12,1))
			STR_NUM[18]:=VAL(SUBSTR(_XX,13,1))
			STR_NUM[19]:=VAL(SUBSTR(_XX,14,1))
			_XX:=SUBSTR(SE1->E1_NUMBCO,1,11)
			STR_NUM[20]:=VAL(SUBSTR(_XX,1,1))
			STR_NUM[21]:=VAL(SUBSTR(_XX,2,1))
			STR_NUM[22]:=VAL(SUBSTR(_XX,3,1))
			STR_NUM[23]:=VAL(SUBSTR(_XX,4,1))
			STR_NUM[24]:=VAL(SUBSTR(_XX,5,1))
			STR_NUM[25]:=VAL(SUBSTR(_XX,6,1))
			STR_NUM[26]:=VAL(SUBSTR(_XX,7,1))
			STR_NUM[27]:=VAL(SUBSTR(_XX,8,1))
			STR_NUM[28]:=VAL(SUBSTR(_XX,9,1))
			STR_NUM[29]:=VAL(SUBSTR(_XX,10,1))
			STR_NUM[30]:=VAL(SUBSTR(_XX,11,1))
			_XX:=strzero(val(SEE->EE_AGENCIA),4)

			STR_NUM[31]:=VAL(SUBSTR(_XX,1,1))
			STR_NUM[32]:=VAL(SUBSTR(_XX,2,1))
			STR_NUM[33]:=VAL(SUBSTR(_XX,3,1))
			STR_NUM[34]:=VAL(SUBSTR(_XX,4,1))
			_XX:=strzero(val(SEE->EE_CONTA), 8)

			STR_NUM[35]:=VAL(SUBSTR(_XX,1,1))
			STR_NUM[36]:=VAL(SUBSTR(_XX,2,1))
			STR_NUM[37]:=VAL(SUBSTR(_XX,3,1))
			STR_NUM[38]:=VAL(SUBSTR(_XX,4,1))
			STR_NUM[39]:=VAL(SUBSTR(_XX,5,1))
			STR_NUM[40]:=VAL(SUBSTR(_XX,6,1))
			STR_NUM[41]:=VAL(SUBSTR(_XX,7,1))
			STR_NUM[42]:=VAL(SUBSTR(_XX,8,1))
			STR_NUM[43]:=1
			STR_NUM[44]:=8
			*---------------------------------- CALCULO DIGITO POS. 5
			_xx:=44
			_yy:=2
			_ZZ:=0
			do while _XX<>0
				if _yy>9
					_YY:=2
				Endif
				IF _XX==5
					_XX:=_XX-1
				ENDIF
				_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
				_YY:=_YY+1
				_XX:=_XX-1
			enddo
			IF _ZZ<11
				_DIG5:=_ZZ
			ELSE
				_DIG5:=MOD(_ZZ,11)
			ENDIF
			IF _DIG5<>0
				_DIG5:=11-_DIG5
			ENDIF
			IF _DIG5==10
				_DIG5:=1
			ENDIF
			IF _DIG5==11
				_DIG5:=1
			ENDIF
			IF _DIG5==0
				_DIG5:=1
			ENDIF
			STR_NUM[5]:=_DIG5

			//----------------------------------- DIGITO VERIFICADOR 1
			_XX:=(0*2)+(0*1)+(1*2)+(9*1)
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),1,1))*2
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),2,1))*1
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),3,1))*2
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),4,1))*1
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),5,1))*2
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			IF _XX<10
				_YY:=_XX
			ELSE
				_YY:=mod(_XX,10)
			ENDIF
			IF _YY==0
				_XX:=0
			ELSE
				_XX:=10-_YY
			ENDIF
			*----------------------------------- DIGITO VERIFICADOR 2
			_AA1:=25
			_XX1:=0
			_BB1:=1
			DO WHILE _AA1<=34
				IF STR_NUM[_AA1]*_BB1>9
					_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
				ELSE
					_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
				ENDIF
				IF _BB1==1
					_BB1:=2
				ELSE
					_BB1:=1
				ENDIF
				_AA1:=_AA1+1
			ENDDO
			IF _XX1<10
				_YY:=_XX1
			ELSE
				_YY:=mod(_XX1,10)
			ENDIF
			IF _YY==0
				_XX1:=0
			ELSE
				_XX1:=10-_YY
			ENDIF
			*----------------------------------- DIGITO VERIFICADOR 3
			_AA1:=35
			_XX2:=0
			_BB1:=1
			DO WHILE _AA1<=44
				IF STR_NUM[_AA1]*_BB1>9
					_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
				ELSE
					_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
				ENDIF
				IF _BB1==1
					_BB1:=2
				ELSE
					_BB1:=1
				ENDIF
				_AA1:=_AA1+1
			ENDDO
			IF _XX2<10
				_YY:=_XX2
			ELSE
				_YY:=mod(_XX2,10)
			ENDIF
			IF _YY==0
				_XX2:=0
			ELSE
				_XX2:=10-_YY
			ENDIF


			_ccodbar:=""
			FOR I:=1 to 44
				_ccodbar:=_ccodbar+STR(STR_NUM[i],1,0)
			NEXT

			_cCampo1 := '0019' + substr(_cCodBar,20,5)  	+ DvDigit('0019' + substr(_cCodBar,20,5))
			_cCampo2 := substr(_cCodBar,25,10)			 	+ DvDigit(substr(_cCodBar,25,10))
			_cCampo3 := substr(_cCodBar,35,10) 				+ DvDigit(substr(_cCodBar,35,10))
			_cCampo4 := substr(_cCodBar,5,1)					// digito verificador do cÛdigo de barras
			_cCampo5 := substr(_cCodBar,6,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)	// valor

			_xCodBar := tran(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999  99999.999999  99999.999999  9  99999999999999')
		else // convenio com 7 posicoes

			_XX:=STR((SE1->E1_SALDO - SE1->E1_DECRESC)*100,14,0)
			STR_NUM[1]:=0
			STR_NUM[2]:=0
			STR_NUM[3]:=1
			STR_NUM[4]:=9    // MOEDA
			_nFator := SE1->E1_VENCTO - CTOD("07/10/1997")
			_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
			_XX := str(_nFator,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10,0)
			STR_NUM[6]:=VAL(SUBSTR(_XX,1,1))
			STR_NUM[7]:=VAL(SUBSTR(_XX,2,1))
			STR_NUM[8]:=VAL(SUBSTR(_XX,3,1))
			STR_NUM[9]:=VAL(SUBSTR(_XX,4,1))
			STR_NUM[10]:=VAL(SUBSTR(_XX,5,1))
			STR_NUM[11]:=VAL(SUBSTR(_XX,6,1))
			STR_NUM[12]:=VAL(SUBSTR(_XX,7,1))
			STR_NUM[13]:=VAL(SUBSTR(_XX,8,1))
			STR_NUM[14]:=VAL(SUBSTR(_XX,9,1))
			STR_NUM[15]:=VAL(SUBSTR(_XX,10,1))
			STR_NUM[16]:=VAL(SUBSTR(_XX,11,1))
			STR_NUM[17]:=VAL(SUBSTR(_XX,12,1))
			STR_NUM[18]:=VAL(SUBSTR(_XX,13,1))
			STR_NUM[19]:=VAL(SUBSTR(_XX,14,1))
			STR_NUM[20]:=0
			STR_NUM[21]:=0
			STR_NUM[22]:=0
			STR_NUM[23]:=0
			STR_NUM[24]:=0
			STR_NUM[25]:=0

			_XX:=SUBSTR(SE1->E1_NUMBCO,1,17)
			STR_NUM[26]:=VAL(SUBSTR(_XX,1,1))
			STR_NUM[27]:=VAL(SUBSTR(_XX,2,1))
			STR_NUM[28]:=VAL(SUBSTR(_XX,3,1))
			STR_NUM[29]:=VAL(SUBSTR(_XX,4,1))
			STR_NUM[30]:=VAL(SUBSTR(_XX,5,1))
			STR_NUM[31]:=VAL(SUBSTR(_XX,6,1))
			STR_NUM[32]:=VAL(SUBSTR(_XX,7,1))
			STR_NUM[33]:=VAL(SUBSTR(_XX,8,1))
			STR_NUM[34]:=VAL(SUBSTR(_XX,9,1))
			STR_NUM[35]:=VAL(SUBSTR(_XX,10,1))
			STR_NUM[36]:=VAL(SUBSTR(_XX,11,1))
			STR_NUM[37]:=VAL(SUBSTR(_XX,12,1))
			STR_NUM[38]:=VAL(SUBSTR(_XX,13,1))
			STR_NUM[39]:=VAL(SUBSTR(_XX,14,1))
			STR_NUM[40]:=VAL(SUBSTR(_XX,15,1))
			STR_NUM[41]:=VAL(SUBSTR(_XX,16,1))
			STR_NUM[42]:=VAL(SUBSTR(_XX,17,1))
			STR_NUM[43]:=1
			STR_NUM[44]:=7
			*---------------------------------- CALCULO DIGITO POS. 5
			_xx:=44
			_yy:=2
			_ZZ:=0
			do while _XX<>0
				if _yy>9
					_YY:=2
				Endif
				IF _XX==5
					_XX:=_XX-1
				ENDIF
				_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
				_YY:=_YY+1
				_XX:=_XX-1
			enddo
			IF _ZZ<11
				_DIG5:=_ZZ
			ELSE
				_DIG5:=MOD(_ZZ,11)
			ENDIF
			IF _DIG5<>0
				_DIG5:=11-_DIG5
			ENDIF
			IF _DIG5==10
				_DIG5:=1
			ENDIF
			IF _DIG5==11
				_DIG5:=1
			ENDIF
			IF _DIG5==0
				_DIG5:=1
			ENDIF
			STR_NUM[5]:=_DIG5

			//----------------------------------- DIGITO VERIFICADOR 1
			_XX:=(0*2)+(0*1)+(1*2)+(9*1)
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,17),1,1))*2
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,17),2,1))*1
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,17),3,1))*2
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,17),4,1))*1
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,17),5,1))*2
			IF _wX1>9
				_wY1:=LEFT(STR(_wX1,2,0),1)
				_wY2:=RIGHT(STR(_wX1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+_wX1
			ENDIF
			IF _XX<10
				_YY:=_XX
			ELSE
				_YY:=mod(_XX,10)
			ENDIF
			IF _YY==0
				_XX:=0
			ELSE
				_XX:=10-_YY
			ENDIF
			*----------------------------------- DIGITO VERIFICADOR 2
			_AA1:=25
			_XX1:=0
			_BB1:=1
			DO WHILE _AA1<=34
				IF STR_NUM[_AA1]*_BB1>9
					_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
				ELSE
					_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
				ENDIF
				IF _BB1==1
					_BB1:=2
				ELSE
					_BB1:=1
				ENDIF
				_AA1:=_AA1+1
			ENDDO
			IF _XX1<10
				_YY:=_XX1
			ELSE
				_YY:=mod(_XX1,10)
			ENDIF
			IF _YY==0
				_XX1:=0
			ELSE
				_XX1:=10-_YY
			ENDIF
			*----------------------------------- DIGITO VERIFICADOR 3
			_AA1:=35
			_XX2:=0
			_BB1:=1
			DO WHILE _AA1<=44
				IF STR_NUM[_AA1]*_BB1>9
					_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
					_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
				ELSE
					_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
				ENDIF
				IF _BB1==1
					_BB1:=2
				ELSE
					_BB1:=1
				ENDIF
				_AA1:=_AA1+1
			ENDDO
			IF _XX2<10
				_YY:=_XX2
			ELSE
				_YY:=mod(_XX2,10)
			ENDIF
			IF _YY==0
				_XX2:=0
			ELSE
				_XX2:=10-_YY
			ENDIF


			_ccodbar:=""
			FOR I:=1 to 44
				_ccodbar:=_ccodbar+STR(STR_NUM[i],1,0)
			NEXT

			_cCampo1 := '0019' + substr(_cCodBar,20,5)  	+ DvDigit('0019' + substr(_cCodBar,20,5))
			_cCampo2 := substr(_cCodBar,25,10)			 	+ DvDigit(substr(_cCodBar,25,10))
			_cCampo3 := substr(_cCodBar,35,10) 				+ DvDigit(substr(_cCodBar,35,10))
			_cCampo4 := substr(_cCodBar,5,1)					// digito verificador do cÛdigo de barras
			_cCampo5 := substr(_cCodBar,6,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)	// valor

			_xCodBar := tran(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999  99999.999999  99999.999999  9  99999999999999')

		endif


		CASE SE1->E1_PORTADO $ "237"

		i:=1
		Do While i<= 44
			STR_NUM[i] := 0
			i:=i+1
		Enddo

		STR_NUM[1]:=2
		STR_NUM[2]:=3
		STR_NUM[3]:=7
		STR_NUM[4]:=9    // MOEDA
		_nFator := SE1->E1_VENCTO - CTOD("07/10/1997")
		_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
		_XX := str(_nFator,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10,0)
		STR_NUM[6]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[7]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[8]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[9]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[10]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[11]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[12]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[13]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[14]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[15]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[16]:=VAL(SUBSTR(_XX,11,1))
		STR_NUM[17]:=VAL(SUBSTR(_XX,12,1))
		STR_NUM[18]:=VAL(SUBSTR(_XX,13,1))
		STR_NUM[19]:=VAL(SUBSTR(_XX,14,1))

		_XX:=ALLTRIM(SEE->EE_AGENCIA)

		STR_NUM[20]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[21]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[22]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[23]:=VAL(SUBSTR(_XX,4,1))

		_XX:=ALLTRIM(SEE->EE_CODCART)

		STR_NUM[24]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[25]:=VAL(SUBSTR(_XX,2,1))

		_XX:=substr(SE1->E1_NUMBCO,3,14)

		STR_NUM[26]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[27]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[28]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[29]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[30]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[31]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[32]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[33]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[34]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[35]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[36]:=VAL(SUBSTR(_XX,11,1))

		_XX:=(SEE->EE_CONTA)

		STR_NUM[37]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[38]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[39]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[40]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[41]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[42]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[43]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[44]:=0
		//u_showarray(STR_NUM)

		//--------------------------------- CALCULO DIGITO POS. 5
		_xx:=44
		_yy:=2
		_ZZ:=0
		do while _XX<>0
			if _yy>9
				_YY:=2
			Endif
			IF _XX==5
				_XX:=_XX-1
			ENDIF
			_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
			_YY:=_YY+1
			_XX:=_XX-1
		enddo
		IF _ZZ<11
			_DIG5:=_ZZ
		ELSE
			_DIG5:=MOD(_ZZ,11)
		ENDIF
		IF _DIG5<>0
			_DIG5:=11-_DIG5
		ENDIF
		IF _DIG5==10
			_DIG5:=1
		ENDIF
		IF _DIG5==11
			_DIG5:=1
		ENDIF
		IF _DIG5==0
			_DIG5:=1
		ENDIF
		STR_NUM[5]:=_DIG5

		//----------------------------------- DIGITO VERIFICADOR 1
		_XX:=(2*2)+(3*1)+(5)+(9*1)
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),1,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),2,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),3,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),4,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),5,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		IF _XX<10
			_YY:=_XX
		ELSE
			_YY:=mod(_XX,10)
		ENDIF
		IF _YY==0
			_XX:=0
		ELSE
			_XX:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 2
		_AA1:=25
		_XX1:=0
		_BB1:=1
		DO WHILE _AA1<=34
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX1<10
			_YY:=_XX1
		ELSE
			_YY:=mod(_XX1,10)
		ENDIF
		IF _YY==0
			_XX1:=0
		ELSE
			_XX1:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 3
		_AA1:=35
		_XX2:=0
		_BB1:=1
		DO WHILE _AA1<=44
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX2<10
			_YY:=_XX2
		ELSE
			_YY:=mod(_XX2,10)
		ENDIF
		IF _YY==0
			_XX2:=0
		ELSE
			_XX2:=10-_YY
		ENDIF

		_Flag1:=1
		_ccodbar:=""
		FOR _j:=1 to 44
			_ccodbar:=_ccodbar+STR(STR_NUM[_j],1,0)
		NEXT

		_cCampo1 := '2379' + substr(_cCodBar,20,5)  	+ DvDigit('2379' + substr(_cCodBar,20,5))
		_cCampo2 := substr(_cCodBar,25,10)			 	+ DvDigit(substr(_cCodBar,25,10))
		_cCampo3 := substr(_cCodBar,35,10) 				+ DvDigit(substr(_cCodBar,35,10))

		_cCampo4 := substr(_cCodBar,5,1)					// digito verificador do cÛdigo de barras
		_cCampo5 := substr(_cCodBar,6,4) + substr(_cCodBar,10,10)	// valor

		_xCodBar := tran(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')

		MEMOWRITE("C:\TEMP\TESTEBRADE.TXT", _xCodbar + chr(13) + _ccodbar)

		//SICREDI

		CASE SE1->E1_PORTADO $ "748"

		i:=1

		Do While i<= 44
			STR_NUM[i] := 1
			i:=i+1
		Enddo
		STR_NUM[1]:=7
		STR_NUM[2]:=4
		STR_NUM[3]:=8
		STR_NUM[4]:=9    // MOEDA
		//FATOR DE VENCIMENTO
		_nFator := SE1->E1_VENCREA - CTOD("07/10/1997")
		_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
		_XX:=STR(_nFator,4,0)
		STR_NUM[6]:=VAL(SUBSTR(_XX,01,1))
		STR_NUM[7]:=VAL(SUBSTR(_XX,02,1))
		STR_NUM[8]:=VAL(SUBSTR(_XX,03,1))
		STR_NUM[9]:=VAL(SUBSTR(_XX,04,1))
		//valor
		_XX:=STRZERO((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)
		STR_NUM[10]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[11]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[12]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[13]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[14]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[15]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[16]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[17]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[18]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[19]:=VAL(SUBSTR(_XX,10,1))
		//fixos
		STR_NUM[20]:=1 // COM REGISTRO
		STR_NUM[21]:=1 // CARTEIRA SIMPLES
		//nosso numero
		_XX:=STRZERO(VAL(SUBSTR(SE1->E1_NUMBCO,1,2) + SUBSTR(SE1->E1_NUMBCO,4,6)/*+SUBSTR(SE1->E1_NUMBCO,8,1)*/),8)
		STR_NUM[22]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[23]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[24]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[25]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[26]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[27]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[28]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[29]:=VAL(SUBSTR(_XX,8,1))
		//_XX:=STRZERO(VAL(SUBSTR(SE1->E1_NUMBCO,10,1)),1)
		_XX:=STRZERO(VAL(SUBSTR(SE1->E1_NUMBCO,11,1)),1)
		STR_NUM[30]:=VAL(SUBSTR(_XX,1,1))
		//agencia + posto + cedente
		_XX:=substr(alltrim(SEE->EE_AGENCIA)+SEE->EE_CODEMP,1,11)
		STR_NUM[31]:=VAL(SUBSTR(_XX,01,1))
		STR_NUM[32]:=VAL(SUBSTR(_XX,02,1))
		STR_NUM[33]:=VAL(SUBSTR(_XX,03,1))
		STR_NUM[34]:=VAL(SUBSTR(_XX,04,1))
		STR_NUM[35]:=VAL(SUBSTR(_XX,05,1))
		STR_NUM[36]:=VAL(SUBSTR(_XX,06,1))
		STR_NUM[37]:=VAL(SUBSTR(_XX,07,1))
		STR_NUM[38]:=VAL(SUBSTR(_XX,08,1))
		STR_NUM[39]:=VAL(SUBSTR(_XX,09,1))
		STR_NUM[40]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[41]:=VAL(SUBSTR(_XX,11,1))
		//fixos
		STR_NUM[42]:=1
		STR_NUM[43]:=0
		*---------------------------------- CALCULO DIGITO POS 44 - MOD 11
		_X44    :=    ""
		For _ix := 20 to 43
			_X44    +=    StrZero(STR_NUM[_ix],1)
		Next _ix
		//_X44    +=    STRZERO(VAL(SUBSTR(SE1->E1_NUMBCO,1,8)),8)
		//_xx:=19
		_xx:=24
		_yy:=2
		_ZZ:=0
		do while _XX>=1
			if _yy>9
				_YY:=2
			Endif
			_ZZ:=_ZZ+(VAL(substr(_X44,_XX,1))*_YY)
			_YY:=_YY+1
			_XX:=_XX-1
		enddo
		IF _ZZ<11
			_XX2:=_ZZ
		ELSE
			_XX2:=MOD(_ZZ,11)
		ENDIF
		IF _XX2<>0
			_XX2:=11-_XX2
		Else
			_XX2:=0
		ENDIF
		If _XX2 >= 10
			_XX2:=0
		Endif
		STR_NUM[44]:=_XX2
		*---------------------------------- CALCULO DIGITO POS. 5
		_xx:=44
		_yy:=2
		_ZZ:=0
		do while _XX<>0
			if _yy>9
				_YY:=2
			Endif
			IF _XX==5
				_XX:=_XX-1
			ENDIF
			_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
			_YY:=_YY+1
			_XX:=_XX-1
		enddo
		IF _ZZ<11
			_DIG5:=_ZZ
		ELSE
			_DIG5:=MOD(_ZZ,11)
		ENDIF
		IF _DIG5<>0
			_DIG5:=11-_DIG5
		ENDIF
		IF _DIG5==10
			_DIG5:=1
		ENDIF
		IF _DIG5==11
			_DIG5:=1
		ENDIF
		IF _DIG5==0
			_DIG5:=1
		ENDIF
		STR_NUM[5]:=_DIG5
		//----------------------------------- DIGITO VERIFICADOR 1
		_AA1:=20
		_XX:=25
		_BB1:=2
		DO WHILE _AA1<=24
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX<10
			_YY:=_XX
		ELSE
			_YY:=mod(_XX,10)
		ENDIF
		IF _YY==0
			_XX:=0
		ELSE
			_XX:=10-_YY
		ENDIF
		*----------------------------------- DIGITO VERIFICADOR 2
		_AA1:=25
		_XX1:=0
		_BB1:=1
		DO WHILE _AA1<=34
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX1<10
			_YY:=_XX1
		ELSE
			_YY:=mod(_XX1,10)
		ENDIF
		IF _YY==0
			_XX1:=0
		ELSE
			_XX1:=10-_YY
		ENDIF
		//*----------------------------------- DIGITO VERIFICADOR 3
		_AA1:=35
		_XX2:=0
		_BB1:=1
		DO WHILE _AA1<=44
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX2<10
			_YY:=_XX2
		ELSE
			_YY:=mod(_XX2,10)
		ENDIF
		IF _YY==0
			_XX2:=0
		ELSE
			_XX2:=10-_YY
		ENDIF
		_xCodbar:="7489"+STRZERO(STR_NUM[20],1)+"."
		_AA1:=21
		DO WHILE _AA1<=24
			_xCodbar:=_xCodbar+STRZERO(STR_NUM[_AA1],1)
			_AA1:=_AA1+1
		ENDDO
		_xCodbar:=_xCodbar+STRZERO(_XX,1)+"  "
		_AA1:=25
		DO WHILE _AA1<=34
			IF _AA1==30
				_xCodbar:=_xCodbar+"."
			ENDIF
			_xCodbar:=_xCodbar+STRZERO(STR_NUM[_AA1],1)
			_AA1:=_AA1+1
		ENDDO
		_xCodbar:=_xCodbar+str(_XX1,1,0)+"  "
		_AA1:=35
		DO WHILE _AA1<=44
			IF _AA1==40
				_xCodbar:=_xCodbar+"."
			ENDIF
			_xCodbar:=_xCodbar+STRZERO(STR_NUM[_AA1],1)
			_AA1:=_AA1+1
		ENDDO
		_xCodbar:=_xCodbar+str(_XX2,1,0)+"  "
		_XFATVEN    :=    ""
		For _ix:= 6 to 9
			_XFATVEN    +=    STRZERO(STR_NUM[_ix],1)
		Next _ix
		_xCodbar:=_xCodbar+STRZERO(STR_NUM[5],1)+"  "+_XFATVEN+STRZERO((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)
		_Flag1:=1
		_ccodbar:=""
		FOR _j:=1 to 44
			_ccodbar:=_ccodbar+STR(STR_NUM[_j],1,0)
		NEXT



		_cCampo1 := '7489' + substr(_cCodBar,20,5)  	+ DvDigit('7489' + substr(_cCodBar,20,5))
		_cCampo2 := substr(_cCodBar,25,10)			 	+ DvDigit(substr(_cCodBar,25,10))
		_cCampo3 := substr(_cCodBar,35,10) 				+ DvDigit(substr(_cCodBar,35,10))
		_cCampo4 := substr(_cCodBar,5,1)					// digito verificador do cÛdigo de barras
		_cCampo5 := substr(_cCodBar,6,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)	// valor

		_xCodBar := tran(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999  99999.999999  99999.999999  9  99999999999999')


		MEMOWRITE("C:\TEMP\TESTESICRE.TXT", _xCodbar + chr(13) + _ccodbar)
		CASE SE1->E1_PORTADO $ "756"
		i := 1

		While i  <=  47

			STR_NUM[i] := 0

			i := i + 1

		End

		STR_NUM[1] := 7    // BANCO
		STR_NUM[2] := 5    // BANCO
		STR_NUM[3] := 6    // BANCO
		STR_NUM[4] := 9    // MOEDA
		_XX := StrZero( Val(AllTrim(SEE->EE_CODCART)),1 )
		STR_NUM[5] := Val( SubStr( _XX, 01, 1  ) )    // C”DIGO CARTEIRA

		STR_NUM[11] := 0    // C”DIGO MODALIDADE
		STR_NUM[12] := Val( SubStr( _XX, 01, 1  ) )     // C”DIGO MODALIDADE

		_XX := StrZero( Val(AllTrim(SEE->EE_AGENCIA)),4 )
		STR_NUM[6] := Val( SubStr( _XX, 01, 1  ) )    // C”DIGO AG NCIA
		STR_NUM[7] := Val( SubStr( _XX, 02, 1  ) )    // C”DIGO AG NCIA
		STR_NUM[8] := Val( SubStr( _XX, 03, 1  ) )    // C”DIGO AG NCIA
		STR_NUM[9] := Val( SubStr( _XX, 04, 1  ) )    // C”DIGO AG NCIA

		STR_NUM[10] := 0     // DIGITO VERIFICADOR 1

		//COD BENEFICIARIO	
		_XX := StrZero( Val(AllTrim(SEE->EE_CODEMP)),7 )
		STR_NUM[13] := Val( SubStr( _XX, 01, 1  ) ) //COD BENEFICIARIO
		STR_NUM[14] := Val( SubStr( _XX, 02, 1  ) ) //COD BENEFICIARIO
		STR_NUM[15] := Val( SubStr( _XX, 03, 1  ) ) //COD BENEFICIARIO
		STR_NUM[16] := Val( SubStr( _XX, 04, 1  ) ) //COD BENEFICIARIO
		STR_NUM[17] := Val( SubStr( _XX, 05, 1  ) ) //COD BENEFICIARIO
		STR_NUM[18] := Val( SubStr( _XX, 06, 1  ) ) //COD BENEFICIARIO
		STR_NUM[19] := Val( SubStr( _XX, 07, 1  ) ) //COD BENEFICIARIO


		//nosso numero
		_XX := StrZero( Val( SubStr( SE1->E1_NUMBCO, 1, 7 )  + SubStr( SE1->E1_NUMBCO, 9, 1 ) ), 8 )
		STR_NUM[20] := Val( SubStr( _XX, 1, 1  ) )  //nosso numero

		STR_NUM[21] := 0  // DIGITO VERIFICADOR 2

		STR_NUM[22] := Val( SubStr( _XX, 2, 1  ) )  //nosso numero
		STR_NUM[23] := Val( SubStr( _XX, 3, 1  ) )  //nosso numero
		STR_NUM[24] := Val( SubStr( _XX, 4, 1  ) )  //nosso numero
		STR_NUM[25] := Val( SubStr( _XX, 5, 1  ) )  //nosso numero
		STR_NUM[26] := Val( SubStr( _XX, 6, 1  ) )  //nosso numero
		STR_NUM[27] := Val( SubStr( _XX, 7, 1  ) )  //nosso numero
		STR_NUM[28] := Val( SubStr( _XX, 8, 1  ) )  //nosso numero


		If Empty(SE1->E1_PARCELA)
			STR_NUM[29] := 0  //PARCELA
			STR_NUM[30] := 0  //PARCELA
			STR_NUM[31] := 1  //PARCELA
		Else
			_XX := StrZero( Val( SE1->E1_PARCELA),3)
			STR_NUM[29] := Val( SubStr( _XX, 1, 1  ) )  //PARCELA
			STR_NUM[30] := Val( SubStr( _XX, 2, 1  ) )  //PARCELA
			STR_NUM[31] := Val( SubStr( _XX, 3, 1  ) )  //PARCELA
		EndIf

		STR_NUM[32] := 0  // DIGITO VERIFICADOR 3
		STR_NUM[33] := 0  // DIGITO VERIFICADOR 4 COD BARRA

		//FATOR DE VENCIMENTO
		_XX := Str( SE1->E1_VENCTO  -  CToD( "03/07/2000" ) + 1000, 4, 0 )
		STR_NUM[34] := Val( SubStr( _XX, 01, 1  ) )
		STR_NUM[35] := Val( SubStr( _XX, 02, 1  ) )
		STR_NUM[36] := Val( SubStr( _XX, 03, 1  ) )
		STR_NUM[37] := Val( SubStr( _XX, 04, 1  ) )

		//valor
		_XX := StrZero( ( SE1->E1_SALDO  -  SE1->E1_DECRESC )  * 100, 10 )
		STR_NUM[38] := Val( SubStr( _XX, 01, 1  ) )
		STR_NUM[39] := Val( SubStr( _XX, 02, 1  ) )
		STR_NUM[40] := Val( SubStr( _XX, 03, 1  ) )
		STR_NUM[41] := Val( SubStr( _XX, 04, 1  ) )
		STR_NUM[42] := Val( SubStr( _XX, 05, 1  ) )
		STR_NUM[43] := Val( SubStr( _XX, 06, 1  ) )
		STR_NUM[44] := Val( SubStr( _XX, 07, 1  ) )
		STR_NUM[45] := Val( SubStr( _XX, 08, 1  ) )
		STR_NUM[46] := Val( SubStr( _XX, 09, 1  ) )
		STR_NUM[47] := Val( SubStr( _XX, 10, 1  ) )


		//----------------------------------- DIGITO VERIFICADOR 1
		_AA1:=9
		_XX:=0
		_BB1:=2
		DO WHILE _AA1>=1
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX:=_XX+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX:=_XX+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1-1
		ENDDO
		IF _XX<10
			_YY:=_XX
		ELSE
			_YY:=mod(_XX,10)
		ENDIF
		IF _YY==0
			_XX:=0
		ELSE
			_XX:=10-_YY
		ENDIF

		//*----------------------------------- DIGITO VERIFICADOR 2
		_AA1:=20
		_XX1:=0
		_BB1:=2
		DO WHILE _AA1>=11
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1-1
		ENDDO
		IF _XX1<10
			_YY:=_XX1
		ELSE
			_YY:=mod(_XX1,10)
		ENDIF
		IF _YY==0
			_XX1:=0
		ELSE
			_XX1:=10-_YY
		ENDIF

		//*----------------------------------- DIGITO VERIFICADOR 3
		_AA1:=31
		_XX2:=0
		_BB1:=2
		DO WHILE _AA1>=22
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1-1
		ENDDO
		IF _XX2<10
			_YY:=_XX2
		ELSE
			_YY:=mod(_XX2,10)
		ENDIF
		IF _YY==0
			_XX2:=0
		ELSE
			_XX2:=10-_YY
		ENDIF

		_xBarSDV:="7569" + cValToChar(STR_NUM[34]) + cValToChar(STR_NUM[35]) + cValToChar(STR_NUM[36]) + cValToChar(STR_NUM[37]) + cValToChar(STR_NUM[38]) + cValToChar(STR_NUM[39]) + cValToChar(STR_NUM[40]) + cValToChar(STR_NUM[41]) + cValToChar(STR_NUM[42]) ;
		+ cValToChar(STR_NUM[43]) + cValToChar(STR_NUM[44]) + cValToChar(STR_NUM[45]) + cValToChar(STR_NUM[46]) + cValToChar(STR_NUM[47]) + cValToChar(STR_NUM[5]) +  cValToChar(STR_NUM[6]) +  cValToChar(STR_NUM[7]) +  cValToChar(STR_NUM[8]) + cValToChar(STR_NUM[9]) ;
		+ cValToChar(STR_NUM[11]) + cValToChar(STR_NUM[12]) + cValToChar(STR_NUM[13]) + cValToChar(STR_NUM[14]) + cValToChar(STR_NUM[15]) + cValToChar(STR_NUM[16]) + cValToChar(STR_NUM[17]) + cValToChar(STR_NUM[18]) + cValToChar(STR_NUM[19]) ;
		+ cValToChar(STR_NUM[20]) + cValToChar(STR_NUM[22]) + cValToChar(STR_NUM[23]) + cValToChar(STR_NUM[24]) + cValToChar(STR_NUM[25]) + cValToChar(STR_NUM[26]) + cValToChar(STR_NUM[27]) + cValToChar(STR_NUM[28]) ;
		+ cValToChar(STR_NUM[29]) + cValToChar(STR_NUM[30]) + cValToChar(STR_NUM[31])

		_nDigCd := (val(subs(_xBarSDV,01,1)) * 4) + (val(subs(_xBarSDV,02,1)) * 3) +;
		(val(subs(_xBarSDV,03,1)) * 2) + (val(subs(_xBarSDV,04,1)) * 9) +;
		(val(subs(_xBarSDV,05,1)) * 8) + (val(subs(_xBarSDV,06,1)) * 7) +;
		(val(subs(_xBarSDV,07,1)) * 6) + (val(subs(_xBarSDV,08,1)) * 5) +;
		(val(subs(_xBarSDV,09,1)) * 4) + (val(subs(_xBarSDV,10,1)) * 3) +;
		(val(subs(_xBarSDV,11,1)) * 2) + (val(subs(_xBarSDV,12,1)) * 9) +;
		(val(subs(_xBarSDV,13,1)) * 8) + (val(subs(_xBarSDV,14,1)) * 7) +;
		(val(subs(_xBarSDV,15,1)) * 6) + (val(subs(_xBarSDV,16,1)) * 5) +;
		(val(subs(_xBarSDV,17,1)) * 4) + (val(subs(_xBarSDV,18,1)) * 3) +;
		(val(subs(_xBarSDV,19,1)) * 2) + (val(subs(_xBarSDV,20,1)) * 9) +;
		(val(subs(_xBarSDV,21,1)) * 8) + (val(subs(_xBarSDV,22,1)) * 7) +;
		(val(subs(_xBarSDV,23,1)) * 6) + (val(subs(_xBarSDV,24,1)) * 5) +;
		(val(subs(_xBarSDV,25,1)) * 4) + (val(subs(_xBarSDV,26,1)) * 3) +;
		(val(subs(_xBarSDV,27,1)) * 2) + (val(subs(_xBarSDV,28,1)) * 9) +;
		(val(subs(_xBarSDV,29,1)) * 8) + (val(subs(_xBarSDV,30,1)) * 7) +;
		(val(subs(_xBarSDV,31,1)) * 6) + (val(subs(_xBarSDV,32,1)) * 5) +;
		(val(subs(_xBarSDV,33,1)) * 4) + (val(subs(_xBarSDV,34,1)) * 3) +;
		(val(subs(_xBarSDV,35,1)) * 2) + (val(subs(_xBarSDV,36,1)) * 9) +;
		(val(subs(_xBarSDV,37,1)) * 8) + (val(subs(_xBarSDV,38,1)) * 7) +;
		(val(subs(_xBarSDV,39,1)) * 6) + (val(subs(_xBarSDV,40,1)) * 5) +;
		(val(subs(_xBarSDV,41,1)) * 4) + (val(subs(_xBarSDV,42,1)) * 3) +;
		(val(subs(_xBarSDV,43,1)) * 2)

		_nDigCd := Mod(_nDigCd,11)

		_nDigCd := 11 - _nDigCd

		_cCodBar:="7569" + cValToChar(_nDigCd) + cValToChar(STR_NUM[34]) + cValToChar(STR_NUM[35]) + cValToChar(STR_NUM[36]) + cValToChar(STR_NUM[37]) + cValToChar(STR_NUM[38]) + cValToChar(STR_NUM[39]) + cValToChar(STR_NUM[40]) + cValToChar(STR_NUM[41]) + cValToChar(STR_NUM[42]) ;
		+ cValToChar(STR_NUM[43]) + cValToChar(STR_NUM[44]) + cValToChar(STR_NUM[45]) + cValToChar(STR_NUM[46]) + cValToChar(STR_NUM[47]) + cValToChar(STR_NUM[5]) +  cValToChar(STR_NUM[6]) +  cValToChar(STR_NUM[7]) +  cValToChar(STR_NUM[8]) + cValToChar(STR_NUM[9]) ;
		+ cValToChar(STR_NUM[11]) + cValToChar(STR_NUM[12]) + cValToChar(STR_NUM[13]) + cValToChar(STR_NUM[14]) + cValToChar(STR_NUM[15]) + cValToChar(STR_NUM[16]) + cValToChar(STR_NUM[17]) + cValToChar(STR_NUM[18]) + cValToChar(STR_NUM[19]) ;
		+ cValToChar(STR_NUM[20]) + cValToChar(STR_NUM[22]) + cValToChar(STR_NUM[23]) + cValToChar(STR_NUM[24]) + cValToChar(STR_NUM[25]) + cValToChar(STR_NUM[26]) + cValToChar(STR_NUM[27]) + cValToChar(STR_NUM[28]) ;
		+ cValToChar(STR_NUM[29]) + cValToChar(STR_NUM[30]) + cValToChar(STR_NUM[31])

		_cCampo1 := '7569' + substr(_cCodBar,20,1)  +  substr(_cCodBar,21,4) + cValToChar(_XX)
		_cCampo2 := substr(_cCodBar,25,2)  + substr(_cCodBar,27,7) + substr(_cCodBar,34,1) + cValToChar(_XX1)
		_cCampo3 := substr(_cCodBar,35,7)  + substr(_cCodBar,42,3) + cValToChar(_XX2)
		_cCampo4 := cValToChar(_nDigCd)				// digito verificador do cÛdigo de barras
		_cCampo5 := substr(_cCodBar,6,4) + substr(_cCodBar,10,10)	// valor

		_xCodBar := tran(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999  99999.999999  99999.999999  9  99999999999999')


		MEMOWRITE("C:\TEMP\TESTESICOOB.TXT", _xCodbar + ' - ' + _ccodbar)

		CASE SE1->E1_PORTADO == "041"  // Banrisul


		nI := 1

		While nI <= 44

			STR_NUM[nI] := 1

			nI := nI + 1

		End

		_nFator := SE1->E1_VENCTO - CTOD("07/10/1997")
		_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
		_XX := Str(_nFator, 4 )  + StrZero( ( SE1->E1_SALDO  -  SE1->E1_DECRESC )  * 100, 10, 0 )
		STR_NUM[01] := 0
		STR_NUM[02] := 4
		STR_NUM[03] := 1
		STR_NUM[04] := 9    // MOEDA
		STR_NUM[06] := Val( SubStr( _XX, 01, 1  ) )
		STR_NUM[07] := Val( SubStr( _XX, 02, 1  ) )
		STR_NUM[08] := Val( SubStr( _XX, 03, 1  ) )
		STR_NUM[09] := Val( SubStr( _XX, 04, 1  ) )
		STR_NUM[10] := Val( SubStr( _XX, 05, 1  ) )
		STR_NUM[11] := Val( SubStr( _XX, 06, 1  ) )
		STR_NUM[12] := Val( SubStr( _XX, 07, 1  ) )
		STR_NUM[13] := Val( SubStr( _XX, 08, 1  ) )
		STR_NUM[14] := Val( SubStr( _XX, 09, 1  ) )
		STR_NUM[15] := Val( SubStr( _XX, 10, 1  ) )
		STR_NUM[16] := Val( SubStr( _XX, 11, 1  ) )
		STR_NUM[17] := Val( SubStr( _XX, 12, 1  ) )
		STR_NUM[18] := Val( SubStr( _XX, 13, 1  ) )
		STR_NUM[19] := Val( SubStr( _XX, 14, 1  ) )
		STR_NUM[20] := 2
		STR_NUM[21] := 1

		_XX := SubStr( SEE->EE_AGENCIA, 1, 4 )
		STR_NUM[22] := Val( SubStr( _XX, 1, 1  ) )
		STR_NUM[23] := Val( SubStr( _XX, 2, 1  ) )
		STR_NUM[24] := Val( SubStr( _XX, 3, 1  ) )
		STR_NUM[25] := Val( SubStr( _XX, 4, 1  ) )

		_XX := SubStr( SEE->EE_CODEMP, 1, 7 )
		STR_NUM[26] := Val( SubStr( _XX, 1, 1  ) )
		STR_NUM[27] := Val( SubStr( _XX, 2, 1  ) )
		STR_NUM[28] := Val( SubStr( _XX, 3, 1  ) )
		STR_NUM[29] := Val( SubStr( _XX, 4, 1  ) )
		STR_NUM[30] := Val( SubStr( _XX, 5, 1  ) )
		STR_NUM[31] := Val( SubStr( _XX, 6, 1  ) )
		STR_NUM[32] := Val( SubStr( _XX, 7, 1  ) )

		_XX := SubStr( SE1->E1_NUMBCO, 1, 8 )
		STR_NUM[33] := Val( SubStr( _XX, 1, 1  ) )
		STR_NUM[34] := Val( SubStr( _XX, 2, 1  ) )
		STR_NUM[35] := Val( SubStr( _XX, 3, 1  ) )
		STR_NUM[36] := Val( SubStr( _XX, 4, 1  ) )
		STR_NUM[37] := Val( SubStr( _XX, 5, 1  ) )
		STR_NUM[38] := Val( SubStr( _XX, 6, 1  ) )
		STR_NUM[39] := Val( SubStr( _XX, 7, 1  ) )
		STR_NUM[40] := Val( SubStr( _XX, 8, 1  ) )
		STR_NUM[41] := 4
		STR_NUM[42] := 0

		////////////////////////////////////////////// DIG Mod 10
		_AA1 := 20
		_XX1 := 0
		_BB1 := 2

		While _AA1 <= 42

			_XX1 := _XX1 + ( STR_NUM[_AA1] * _BB1 - IIf( STR_NUM[_AA1] * _BB1 > 9, 9, 0  ) )

			If _BB1 == 1

				_BB1 := 2

			Else

				_BB1 := 1

			EndIf

			_AA1 := _AA1 + 1

		End

		If _XX1 < 10

			_YY := _XX1

		Else

			_YY := Mod( _XX1, 10 )

		EndIf

		If _YY == 0

			_XX1 := 0

		Else

			_XX1 := 10 - _YY

		EndIf

		STR_NUM[43] := _XX1


		////////////////////////////////////////////// DIG Mod 11
		_XX := 43
		_yy := 2
		_ZZ := 0

		While _XX  >= 20

			If _yy > 7

				_YY := 2

			EndIf

			_ZZ := _ZZ + ( STR_NUM[_xx] * _YY )
			_YY := _YY + 1
			_XX := _XX - 1

		End

		If _ZZ<11

			_XX2 := _ZZ

		Else

			_XX2 := Mod( _ZZ, 11 )

		EndIf

		If _XX2 == 1

			If STR_NUM[43] + 1 == 10

				STR_NUM[43] := 0

			Else

				STR_NUM[43] := STR_NUM[43] + 1

			EndIf

			_XX := 43
			_yy := 2
			_ZZ := 0

			While _XX  >= 20

				If _yy > 7

					_YY := 2

				EndIf

				_ZZ := _ZZ + ( STR_NUM[_xx] * _YY )
				_YY := _YY + 1
				_XX := _XX - 1

			End

			If _ZZ<11

				_XX2 := _ZZ

			Else

				_XX2 := Mod( _ZZ, 11 )

			EndIf

		EndIf

		If _XX2 <>  0

			_XX2 := 11 - _XX2

		EndIf

		STR_NUM[44] := _XX2


		/////////////////////////////////// CALCULO DIGITO POS. 5
		_XX := 44
		_yy := 2
		_ZZ := 0

		While _XX <>  0

			If _yy > 9

				_YY := 2

			EndIf

			If _XX == 5

				_XX := _XX - 1

			EndIf

			_ZZ := _ZZ + ( STR_NUM[_xx] * _YY )
			_YY := _YY + 1
			_XX := _XX - 1

		End

		If _ZZ<11

			_DIG5 := _ZZ

		Else

			_DIG5 := Mod( _ZZ, 11 )

		EndIf

		If _DIG5 <>  0

			_DIG5 := 11 - _DIG5

		EndIf

		If _DIG5 == 10

			_DIG5 := 1

		EndIf

		If _DIG5 == 11

			_DIG5 := 1

		EndIf

		If _DIG5 == 0

			_DIG5 := 1

		EndIf

		STR_NUM[5] := _DIG5
		/////////////////////////////////// CALCULO DIGITO POS. 5

		//////////////////////////////////// DIGITO VERIfICADOR 1
		_XX := ( 0 * 2 )  + ( 4 * 1 )  + ( 1 * 2 )  + ( 9 * 1 )  + ( 2 * 2 )  + ( 1 * 1 )
		_XX := _XX + Val( SubStr( SEE->EE_AGENCIA, 1, 1  ) ) * 2 - IIf( Val( SubStr( SEE->EE_AGENCIA, 1, 1  ) ) * 2 > 9, 9, 0 )
		_XX := _XX + Val( SubStr( SEE->EE_AGENCIA, 2, 1  ) ) * 1 - IIf( Val( SubStr( SEE->EE_AGENCIA, 2, 1  ) ) * 1 > 9, 9, 0 )
		_XX := _XX + Val( SubStr( SEE->EE_AGENCIA, 3, 1  ) ) * 2 - IIf( Val( SubStr( SEE->EE_AGENCIA, 3, 1  ) ) * 2 > 9, 9, 0 )

		If _XX < 10

			_YY := _XX

		Else

			_YY := Mod( _XX, 10 )

		EndIf

		If _YY == 0

			_XX := 0

		Else

			_XX := 10 - _YY

		EndIf

		//////////////////////////////////// DIGITO VERIfICADOR 2
		_XX1 :=        Val( SubStr( SEE->EE_CODEMP, 04, 1  ) ) * 1 - IIf( Val( SubStr( SEE->EE_CODEMP, 04, 1  ) ) * 1 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SEE->EE_CODEMP, 05, 1  ) ) * 2 - IIf( Val( SubStr( SEE->EE_CODEMP, 05, 1  ) ) * 2 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SEE->EE_CODEMP, 06, 1  ) ) * 1 - IIf( Val( SubStr( SEE->EE_CODEMP, 06, 1  ) ) * 1 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SEE->EE_CODEMP, 07, 1  ) ) * 2 - IIf( Val( SubStr( SEE->EE_CODEMP, 07, 1  ) ) * 2 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SEE->EE_CODEMP, 08, 1  ) ) * 1 - IIf( Val( SubStr( SEE->EE_CODEMP, 08, 1  ) ) * 1 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SEE->EE_CODEMP, 09, 1  ) ) * 2 - IIf( Val( SubStr( SEE->EE_CODEMP, 09, 1  ) ) * 2 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SEE->EE_CODEMP, 10, 1  ) ) * 1 - IIf( Val( SubStr( SEE->EE_CODEMP, 10, 1  ) ) * 1 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 1, 1  ) ) * 2 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 1, 1  ) ) * 2 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 2, 1  ) ) * 1 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 2, 1  ) ) * 1 > 9, 9, 0 )
		_XX1 := _XX1 + Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 3, 1  ) ) * 2 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 3, 1  ) ) * 2 > 9, 9, 0 )

		If _XX1 < 10

			_YY := _XX1

		Else

			_YY := Mod( _XX1, 10 )

		EndIf

		If _YY == 0

			_XX1 := 0

		Else

			_XX1 := 10 - _YY

		EndIf

		//////////////////////////////////// DIGITO VERIfICADOR 3
		_XX2 :=        Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 4, 1  ) ) * 1 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 4, 1  ) ) * 1 > 9, 9, 0 )
		_XX2 := _XX2 + Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 5, 1  ) ) * 2 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 5, 1  ) ) * 2 > 9, 9, 0 )
		_XX2 := _XX2 + Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 6, 1  ) ) * 1 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 6, 1  ) ) * 1 > 9, 9, 0 )
		_XX2 := _XX2 + Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 7, 1  ) ) * 2 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 7, 1  ) ) * 2 > 9, 9, 0 )
		_XX2 := _XX2 + Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 8, 1  ) ) * 1 - IIf( Val( SubStr( SubStr( SE1->E1_NUMBCO, 1, 8 ), 8, 1  ) ) * 1 > 9, 9, 0 )
		_XX2 := _XX2 + ( 0 * 2 )  + ( 4 * 1 )  + ( 1 * 2 )
		_XX2 := _XX2 + STR_NUM[43] * 1 - IIf( STR_NUM[43] * 1 > 9, 9, 0 )
		_XX2 := _XX2 + STR_NUM[44] * 2 - IIf( STR_NUM[44] * 2 > 9, 9, 0 )

		If _XX2 < 10

			_YY := _XX2

		Else

			_YY := Mod( _XX2, 10 )

		EndIf

		If _YY == 0

			_XX2 := 0

		Else

			_XX2 := 10 - _YY

		EndIf

		_ccodbar := ""

		For nJ := 1 To 44

			_ccodbar := _ccodbar + STR( STR_NUM[nJ], 1, 0 )

		Next

		cCampo1 := "041921" + SubStr( SEE->EE_AGENCIA, 1, 3 ) + DvDigit( "041921" + SubStr( SEE->EE_AGENCIA, 1, 3 ) )
		cCampo2 := SubStr( SEE->EE_AGENCIA, 4, 1 ) + SubStr( SEE->EE_CODEMP, 1, 7 ) + SubStr( SE1->E1_NUMBCO, 1, 2 ) + DvDigit( SubStr( SEE->EE_AGENCIA, 4, 1 ) + SubStr( SEE->EE_CODEMP, 1, 7 ) + SubStr( SE1->E1_NUMBCO, 1, 2  ) )
		cCampo3 := SubStr( SE1->E1_NUMBCO, 3, 6 ) + "40" + SubStr( _ccodbar, 43, 2 ) + DvDigit( SubStr( SE1->E1_NUMBCO, 3, 6 ) + "40" + SubStr( _ccodbar, 43, 2 ) )
		cCampo4 := SubStr( _ccodbar, 5, 1 )// digito verIficador do cÛdigo de barras
		cCampo5 := SubStr( _ccodbar, 6, 4 ) + StrZero( ( SE1->E1_SALDO  -  SE1->E1_DECRESC )  * 100, 10 )// valor

		//linha digit·vel
		_xCodBar := Transform( cCampo1 + cCampo2 + cCampo3 + cCampo4 + cCampo5, "@R 99999.99999  99999.999999  99999.999999  9  99999999999999" )

		MEMOWRITE("C:\TEMP\TESTEBANRI.TXT", _xCodbar + chr(13) + _ccodbar)


		CASE SE1->E1_PORTADO == "341"   // Itau

		i:=1
		Do While i<= 44
			STR_NUM[i] := 0
			i:=i+1
		Enddo

		STR_NUM[1]:=3
		STR_NUM[2]:=4
		STR_NUM[3]:=1
		STR_NUM[4]:=9    // MOEDA
		_nFator := SE1->E1_VENCTO - CTOD("07/10/1997")
		_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
		_XX := str(_nFator,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10,0)
		STR_NUM[6]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[7]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[8]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[9]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[10]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[11]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[12]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[13]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[14]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[15]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[16]:=VAL(SUBSTR(_XX,11,1))
		STR_NUM[17]:=VAL(SUBSTR(_XX,12,1))
		STR_NUM[18]:=VAL(SUBSTR(_XX,13,1))
		STR_NUM[19]:=VAL(SUBSTR(_XX,14,1))

		_XX:=left(SE1->E1_NUMBCO,11)  + right(alltrim(SE1->E1_NUMBCO),1)

		STR_NUM[20]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[21]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[22]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[23]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[24]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[25]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[26]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[27]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[28]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[29]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[30]:=VAL(SUBSTR(_XX,11,1))
		STR_NUM[31]:=VAL(SUBSTR(_XX,12,1))
		_XX:=substr(SEE->EE_AGENCIA,1,4)
		STR_NUM[32]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[33]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[34]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[35]:=VAL(SUBSTR(_XX,4,1))
		_XX:=substr(SEE->EE_CONTA,1,6)
		STR_NUM[36]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[37]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[38]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[39]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[40]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[41]:=VAL(SEE->EE_DVCTA)

		//--------------------------------- CALCULO DIGITO POS. 5
		_xx:=44
		_yy:=2
		_ZZ:=0
		do while _XX<>0
			if _yy>9
				_YY:=2
			Endif
			IF _XX==5
				_XX:=_XX-1
			ENDIF
			_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
			_YY:=_YY+1
			_XX:=_XX-1
		enddo
		IF _ZZ<11
			_DIG5:=_ZZ
		ELSE
			_DIG5:=MOD(_ZZ,11)
		ENDIF
		IF _DIG5<>0
			_DIG5:=11-_DIG5
		ENDIF
		IF _DIG5==10
			_DIG5:=1
		ENDIF
		IF _DIG5==11
			_DIG5:=1
		ENDIF
		IF _DIG5==0
			_DIG5:=1
		ENDIF
		STR_NUM[5]:=_DIG5

		//----------------------------------- DIGITO VERIFICADOR 1
		_XX:=(2*2)+(3*1)+(5)+(9*1)
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),1,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),2,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),3,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),4,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),5,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		IF _XX<10
			_YY:=_XX
		ELSE
			_YY:=mod(_XX,10)
		ENDIF
		IF _YY==0
			_XX:=0
		ELSE
			_XX:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 2
		_AA1:=25
		_XX1:=0
		_BB1:=1
		DO WHILE _AA1<=34
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX1<10
			_YY:=_XX1
		ELSE
			_YY:=mod(_XX1,10)
		ENDIF
		IF _YY==0
			_XX1:=0
		ELSE
			_XX1:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 3
		_AA1:=35
		_XX2:=0
		_BB1:=1
		DO WHILE _AA1<=44
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX2<10
			_YY:=_XX2
		ELSE
			_YY:=mod(_XX2,10)
		ENDIF
		IF _YY==0
			_XX2:=0
		ELSE
			_XX2:=10-_YY
		ENDIF

		_Flag1:=1
		_ccodbar:=""
		FOR _j:=1 to 44
			_ccodbar:=_ccodbar+STR(STR_NUM[_j],1,0)
		NEXT

		_cCampo1 := '3419' + substr(_cCodBar,20,5)  	+ DvDigit('3419' + substr(_cCodBar,20,5))
		_cCampo2 := substr(_cCodBar,25,10)			 	+ DvDigit(substr(_cCodBar,25,10))
		_cCampo3 := substr(_cCodBar,35,10) 				+ DvDigit(substr(_cCodBar,35,10))
		_cCampo4 := substr(_cCodBar,5,1)					// digito verificador do cÛdigo de barras
		_cCampo5 := substr(_cCodBar,6,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)	// valor

		_xCodBar := tran(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')

		MEMOWRITE("C:\TEMP\TESTEITAU.TXT", _xCodbar + chr(13) + _ccodbar)
		
		CASE SE1->E1_PORTADO == "399"   // HSBC
		i:=1
		Do While i<= 44
			STR_NUM[i] := 0
			i:=i+1
		Enddo

		STR_NUM[1]:=3
		STR_NUM[2]:=9
		STR_NUM[3]:=9
		STR_NUM[4]:=9    // MOEDA
		_nFator := SE1->E1_VENCTO - CTOD("07/10/1997")
		_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
		_XX := str(_nFator,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10,0)
		STR_NUM[6]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[7]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[8]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[9]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[10]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[11]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[12]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[13]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[14]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[15]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[16]:=VAL(SUBSTR(_XX,11,1))
		STR_NUM[17]:=VAL(SUBSTR(_XX,12,1))
		STR_NUM[18]:=VAL(SUBSTR(_XX,13,1))
		STR_NUM[19]:=VAL(SUBSTR(_XX,14,1))


		_XX:=left(SE1->E1_NUMBCO,10)  + right(alltrim(SE1->E1_NUMBCO),1)

		STR_NUM[20]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[21]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[22]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[23]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[24]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[25]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[26]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[27]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[28]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[29]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[30]:=VAL(SUBSTR(_XX,11,1))

		_XX:=alltrim(SEE->EE_CODEMP)
		STR_NUM[31]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[32]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[33]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[34]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[35]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[36]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[37]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[38]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[39]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[40]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[41]:=VAL(SUBSTR(_XX,11,1))
		STR_NUM[42]:=0
		STR_NUM[43]:=0
		STR_NUM[44]:=1
		//--------------------------------- CALCULO DIGITO POS. 5
		_xx:=44
		_yy:=2
		_ZZ:=0
		do while _XX<>0
			if _yy>9
				_YY:=2
			Endif
			IF _XX==5
				_XX:=_XX-1
			ENDIF
			_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
			_YY:=_YY+1
			_XX:=_XX-1
		enddo
		IF _ZZ<11
			_DIG5:=_ZZ
		ELSE
			_DIG5:=MOD(_ZZ,11)
		ENDIF
		IF _DIG5<>0
			_DIG5:=11-_DIG5
		ENDIF
		IF _DIG5==10
			_DIG5:=1
		ENDIF
		IF _DIG5==11
			_DIG5:=1
		ENDIF
		IF _DIG5==0
			_DIG5:=1
		ENDIF
		STR_NUM[5]:=_DIG5

		//----------------------------------- DIGITO VERIFICADOR 1
		_XX:=(3*2)+(8*1)+(9)+(9*1)
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),1,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),2,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),3,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),4,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),5,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		IF _XX<10
			_YY:=_XX
		ELSE
			_YY:=mod(_XX,10)
		ENDIF
		IF _YY==0
			_XX:=0
		ELSE
			_XX:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 2
		_AA1:=25
		_XX1:=0
		_BB1:=1
		DO WHILE _AA1<=34
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX1<10
			_YY:=_XX1
		ELSE
			_YY:=mod(_XX1,10)
		ENDIF
		IF _YY==0
			_XX1:=0
		ELSE
			_XX1:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 3
		_AA1:=35
		_XX2:=0
		_BB1:=1
		DO WHILE _AA1<=44
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX2<10
			_YY:=_XX2
		ELSE
			_YY:=mod(_XX2,10)
		ENDIF
		IF _YY==0
			_XX2:=0
		ELSE
			_XX2:=10-_YY
		ENDIF

		_Flag1:=1
		_ccodbar:=""
		FOR _j:=1 to 44
			_ccodbar:=_ccodbar+STR(STR_NUM[_j],1,0)
		NEXT

		_cCampo1 := '3999' + substr(_cCodBar,20,5)  	+ DvDigit('3999' + substr(_cCodBar,20,5))
		_cCampo2 := substr(_cCodBar,25,10)			 	+ DvDigit(substr(_cCodBar,25,10))
		_cCampo3 := substr(_cCodBar,35,10) 				+ DvDigit(substr(_cCodBar,35,10))
		_cCampo4 := substr(_cCodBar,5,1)					// digito verificador do cÛdigo de barras
		_cCampo5 := substr(_cCodBar,6,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10)	// valor

		MEMOWRITE("C:\TEMP\TESTEHSBC.TXT", _xCodbar + chr(13) + _ccodbar)


		_xCodBar := tran(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999  99999.999999  99999.999999  9  99999999999999')




		CASE SE1->E1_PORTADO == "033"   // SANTANDER


		i:=1
		Do While i<= 44
			STR_NUM[i] := 0
			i:=i+1
		Enddo

		STR_NUM[1]:=0
		STR_NUM[2]:=3
		STR_NUM[3]:=3
		STR_NUM[4]:=9    // MOEDA
		_nFator := SE1->E1_VENCTO - CTOD("07/10/1997")
		_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
		_XX := strzero(_nFator,4) + strzero((SE1->E1_SALDO - SE1->E1_DECRESC)*100,10,0)
		STR_NUM[6]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[7]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[8]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[9]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[10]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[11]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[12]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[13]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[14]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[15]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[16]:=VAL(SUBSTR(_XX,11,1))
		STR_NUM[17]:=VAL(SUBSTR(_XX,12,1))
		STR_NUM[18]:=VAL(SUBSTR(_XX,13,1))
		STR_NUM[19]:=VAL(SUBSTR(_XX,14,1))

		_XX:="9"+alltrim(SEE->EE_CODEMP)
		STR_NUM[20]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[21]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[22]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[23]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[24]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[25]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[26]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[27]:=VAL(SUBSTR(_XX,8,1))

		_XX:=STRZERO(VAL(SE1->E1_NUMBCO),13)
		STR_NUM[28]:=VAL(SUBSTR(_XX,1,1))
		STR_NUM[29]:=VAL(SUBSTR(_XX,2,1))
		STR_NUM[30]:=VAL(SUBSTR(_XX,3,1))
		STR_NUM[31]:=VAL(SUBSTR(_XX,4,1))
		STR_NUM[32]:=VAL(SUBSTR(_XX,5,1))
		STR_NUM[33]:=VAL(SUBSTR(_XX,6,1))
		STR_NUM[34]:=VAL(SUBSTR(_XX,7,1))
		STR_NUM[35]:=VAL(SUBSTR(_XX,8,1))
		STR_NUM[36]:=VAL(SUBSTR(_XX,9,1))
		STR_NUM[37]:=VAL(SUBSTR(_XX,10,1))
		STR_NUM[38]:=VAL(SUBSTR(_XX,11,1))
		STR_NUM[39]:=VAL(SUBSTR(_XX,12,1))
		STR_NUM[40]:=VAL(SUBSTR(_XX,13,1))
		STR_NUM[41]:=0
		STR_NUM[42]:=1
		STR_NUM[43]:=0
		STR_NUM[44]:=1
		//--------------------------------- CALCULO DIGITO POS. 5
		_xx:=44
		_yy:=2
		_ZZ:=0
		do while _XX<>0
			if _yy>9
				_YY:=2
			Endif
			IF _XX==5
				_XX:=_XX-1
			ENDIF
			_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
			_YY:=_YY+1
			_XX:=_XX-1
		enddo
		IF _ZZ<11
			_DIG5:=_ZZ
		ELSE
			_DIG5:=MOD(_ZZ,11)
		ENDIF
		IF _DIG5<>0
			_DIG5:=11-_DIG5
		ENDIF
		IF _DIG5==10
			_DIG5:=1
		ENDIF
		IF _DIG5==11
			_DIG5:=1
		ENDIF
		IF _DIG5==0
			_DIG5:=1
		ENDIF
		STR_NUM[5]:=_DIG5

		//----------------------------------- DIGITO VERIFICADOR 1
		_XX:=(3*2)+(8*1)+(9)+(9*1)
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),1,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),2,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),3,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),4,1))*1
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),5,1))*2
		IF _wX1>9
			_wY1:=LEFT(STR(_wX1,2,0),1)
			_wY2:=RIGHT(STR(_wX1,2,0),1)
			_XX:=_XX+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX:=_XX+_wX1
		ENDIF
		IF _XX<10
			_YY:=_XX
		ELSE
			_YY:=mod(_XX,10)
		ENDIF
		IF _YY==0
			_XX:=0
		ELSE
			_XX:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 2
		_AA1:=25
		_XX1:=0
		_BB1:=1
		DO WHILE _AA1<=34
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX1<10
			_YY:=_XX1
		ELSE
			_YY:=mod(_XX1,10)
		ENDIF
		IF _YY==0
			_XX1:=0
		ELSE
			_XX1:=10-_YY
		ENDIF
		//---------------------------------- DIGITO VERIFICADOR 3
		_AA1:=35
		_XX2:=0
		_BB1:=1
		DO WHILE _AA1<=44
			IF STR_NUM[_AA1]*_BB1>9
				_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
				_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
			ELSE
				_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
			ENDIF
			IF _BB1==1
				_BB1:=2
			ELSE
				_BB1:=1
			ENDIF
			_AA1:=_AA1+1
		ENDDO
		IF _XX2<10
			_YY:=_XX2
		ELSE
			_YY:=mod(_XX2,10)
		ENDIF
		IF _YY==0
			_XX2:=0
		ELSE
			_XX2:=10-_YY
		ENDIF

		_Flag1:=1
		_ccodbar:=""
		FOR _j:=1 to 44
			_ccodbar:=_ccodbar+STR(STR_NUM[_j],1,0)
		NEXT

		_cCampo1 := '0339' + substr(_cCodBar,20,5)  	+ DvDigit('0339' + substr(_cCodBar,20,5))
		_cCampo2 := substr(_cCodBar,25,10)			 	+ DvDigit(substr(_cCodBar,25,10))
		_cCampo3 := substr(_cCodBar,35,10) 				+ DvDigit(substr(_cCodBar,35,10))
		_cCampo4 := substr(_cCodBar,5,1)			    // digito verificador do cÛdigo de barras
		_cCampo5 := substr(_cCodBar,6,14)               // fator vencto + valor

		_xCodBar := LEFT(_cCampo1,5)+"."+RIGHT(_cCampo1,5)+" "+LEFT(_cCampo2,5)+"."+RIGHT(_cCampo2,6)+" "+LEFT(_cCampo3,5)+"."+RIGHT(_cCampo3,6)+" "+_cCampo4+"  "+_cCampo5

		MEMOWRITE("C:\TEMP\TESTESANT.TXT", _ccodbar + chr(13) + _xCodBar)

		CASE SE1->E1_PORTADO == "104"   // Caixa

		if SEE->EE_POSCONV = '2' //Convenio 17 PosiÁoes Nosso Numero

			//	_aCaixa  := Ret_cBarra(Subs(aDadosBanco[1],1,3)+"9", AllTrim(SEE->EE_AGENCIA), AllTrim(SEE->EE_CONTA)+ALLTRIM(SEE->EE_DVCTA), ALLTRIM(SEE->EE_CODEMP), "12", AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA),;
			//		(SE1->E1_SALDO), SE1->E1_VENCTO, Alltrim(SEE->EE_CODEMP), alltrim(SE1->E1_NUMBCO), Iif(SE1->E1_DECRESC > 0 .OR. SE1->E1_DESCFIN > 0,.t.,.f.), SE1->E1_PARCELA, SEE->EE_AGENCIA+SEE->EE_DVAGE, 2)

			_aCaixa := Ret_cBarra( ;
			SubStr( aDadosBanco[1], 1, 3 )  + "9", ;
			SubStr( aDadosBanco[3], 1, 4 ), ;
			aDadosBanco[4], ;
			aDadosBanco[5], ;
			"12", ;
			AllTrim( SE1->E1_NUM )  + AllTrim( SE1->E1_PARCELA ), ;
			( SE1->E1_SALDO ), ;
			SE1->E1_VENCTO, ;
			substr(AllTrim( SEE->EE_CODEMP ), 1,6), ;
			AllTrim( SE1->E1_NUMBCO ), ;
			IIf( SE1->E1_DECRESC  >  0 .OR. SE1->E1_DESCFIN  >  0, .t., .f. ), ;
			SE1->E1_PARCELA, ;
			aDadosBanco[3], ;
			2;
			)


		else
			_aCaixa  := Ret_cBarra(Subs(aDadosBanco[1],1,3)+"9", AllTrim(SEE->EE_AGENCIA), AllTrim(SEE->EE_CONTA)+ALLTRIM(SEE->EE_DVCTA), ALLTRIM(SEE->EE_CODEMP), "12", AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA),;
			(SE1->E1_SALDO), SE1->E1_VENCTO, Alltrim(SEE->EE_FIDENTI), alltrim(SE1->E1_NUMBCO), Iif(SE1->E1_DECRESC > 0 .OR. SE1->E1_DESCFIN > 0,.t.,.f.), SE1->E1_PARCELA, SEE->EE_AGENCIA+SEE->EE_DVAGE, 1)

		endif

		_ccodbar := _aCaixa[1]
		_xCodBar := _aCaixa[2]
		MEMOWRITE("C:\TEMP\TESTECAIXA.TXT", _xCodbar + chr(13) + _ccodbar)

		OTHERWISE
		If SE1->E1_PORTADO <> "099"
			MsgBox("Banco / Tipo Formulario Nao Disponivel!","ATENCAO!!!","STOP")
		Endif
	ENDCASE

	DbSelectArea("SE1")

Return({_ccodbar,_xCODBAR})

/*
calcula o digito verificador da linha digitavel
*/
Static Function DvDigit(_cCampo)
Local _nJ := 0
Local _nI := 0
_cRet := ' '

If SE1->E1_PORTADO == '001' .or. SE1->E1_PORTADO == '341'.or. SE1->E1_PORTADO == '041' .or. SE1->E1_PORTADO == '399' .OR. SE1->E1_PORTADO == '237'  .OR. SE1->E1_PORTADO == '748'
    _nSoma  := 0
    _nFator := 2
    For _nI := len(_cCampo) to 1 step -1
        _nMult := _nFator * val(substr(_cCampo,_nI,1))
        If _nMult > 9
            _nMult := 0
            For _nJ := 1 to 2
                _nMult += val(substr(strzero(_nFator * val(substr(_cCampo,_nI,1)),2),_nJ,1))
            Next
        EndIf
        _nSoma += _nMult
        _nFator := iif(_nFator == 1,2,1)
    Next
    _cRet  := str(mod((_nSoma * 9), 10),1)
Endif
Return(_cRet)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Static Function NOSSONUMERO()
	/////////////////////////////

	DbSelectArea("SE1")
	_cBolImp := "" 					//para gerar numero do banco mesmo se o boleto ja tiver sido impresso
	RecLock("SE1",.F.)
	DO CASE
		CASE SE1->E1_PORTADO=="001"
		if SEE->EE_POSCONV == '6'
			_char2:=ALLTRIM(SEE->EE_CODEMP)+StrZero(_nNumBco,05,0)
			Z_DVBCO()
			SE1->E1_NUMBCO:= ALLTRIM(SEE->EE_CODEMP)+StrZero(_nNumBco,05,0) +"-"+_char2
			_nNumBco := _nNumBco + 1
		else
			SE1->E1_NUMBCO:= ALLTRIM(SEE->EE_CODEMP)+StrZero(_nNumBco,10,0)
			_nNumBco := _nNumBco + 1
		endif

		CASE SE1->E1_PORTADO == "033"		// SANTANDER
		_char2:=StrZero(_nNumBco,10,0)
		Z_DVBCO()
		SE1->E1_NUMBCO:=StrZero(_nNumBco,10,0)+_char2
		_nNumBco:=_nNumBco+1

		CASE SE1->E1_PORTADO=="104"
		if SEE->EE_POSCONV != '2'
			_char2:="9" + StrZero(_nNumBco,09,0)
			Z_DVBCO()
			SE1->E1_NUMBCO:="9" + StrZero(_nNumBco,09,0)+"-"+_char2
			_nNumBco:=_nNumBco+1
		else

			_char2:="14" + StrZero(_nNumBco,15,0)
			Z_DVBCO()
			SE1->E1_NUMBCO:="14" + StrZero(_nNumBco,15,0)+_char2
			_nNumBco:=_nNumBco+1

		endif

		CASE SE1->E1_PORTADO == "041"
		_char2 := StrZero(_nNumBco,08,0)
		Z_DVBCO()
		SE1->E1_NUMBCO:= StrZero(_nNumBco,08,0)+"-"+_char2
		_nNumBco := _nNumBco + 1
		CASE SE1->E1_PORTADO == "237"            // Bradesco

		_char2:=alltrim(SEE->EE_CODCART) +StrZero(_nNumBco,11,0)
		Z_DVBCO()
		SE1->E1_NUMBCO:=Alltrim(SEE->EE_CODCART) +StrZero(_nNumBco,11,0)+"-"+_char2
		_nNumBco := _nNumBco + 1

		CASE SE1->E1_PORTADO == "341"         //Ita˙
		//_char2:=LEFT(SEE->EE_AGENCIA,4)+LEFT(SEE->EE_CONTA,5)+LEFT(STR(_nNumBco,11,0),3)+RIGHT(STR(_nNumBco,11,0),8)
		_char2:=LEFT(SEE->EE_AGENCIA,4)+LEFT(SEE->EE_CONTA,5)+ LEFT(SEE->EE_CODCART,3) + RIGHT(STR(_nNumBco,11,0),8)
		Z_DVBCO()
		//SE1->E1_NUMBCO:= StrZero(_nNumBco,11,0)+"-"+_char2
		SE1->E1_NUMBCO:= LEFT(SEE->EE_CODCART,3) + StrZero(_nNumBco,8,0)+"-"+_char2
		_nNumBco:=_nNumBco+1

		CASE SE1->E1_PORTADO == "399"		// hsbc

		_char2:=StrZero(_nNumBco,10,0)
		Z_DVBCO()
		SE1->E1_NUMBCO:=StrZero(_nNumBco,10,0)+_char2

		_nNumBco:=_nNumBco+1

		CASE SE1->E1_PORTADO == "748"		// sicredi
		_cAno:= ""
		_cAno := (alltrim(str(year(ddatabase))))

		//_char2:=Substr(_cAno,3,2)+ "2"+StrZero(_nNumBco,05,0)
		_char2:= alltrim(SEE->EE_AGENCIA) +  alltrim(SEE->EE_CODEMP) + Substr(_cAno,3,2)+ "2"+StrZero(_nNumBco,05,0)

		Z_DVBCO()
		SE1->E1_NUMBCO:=Substr(_cAno,3,2)+ "/2"+StrZero(_nNumBco,05,0)+"-"+_char2
		_nNumBco:=_nNumBco+1
		CASE SE1->E1_PORTADO == "756"

		_char2:= alltrim(SEE->EE_AGENCIA) + StrZero(Val(SEE->EE_CODEMP),10)+ StrZero(_nNumBco,7,0)
		Z_DVBCO()
		SE1->E1_NUMBCO:= StrZero(_nNumBco,7,0)+"-"+cValToChar(_char2)
		_nNumBco:=_nNumBco+1
	ENDCASE

	SE1->E1_BOLIMP :="S"
	MsUnLock()

	If empty(_cBolImp)
		TcSqlExec("UPDATE "+RetSqlName('SEE')+" set EE_FAXATU = '"+ALLTRIM(STR(_nNumBco))+"' WHERE R_E_C_N_O_ = "+ALLTRIM(STR(_nRecno)))
	EndIf

Return


//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥ Chamada da Funcao Z_DVBCO()                                         ≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
// Syntax: Z_DVBCO( <expC1>,<expC2> )  && cod. banco e Nosso Numero
// Return: Retorna <expN1> - Retorna Digito Verificador p/ Banco
Static FUNCTION Z_DVBCO()
	* Syntax: Z_DVBCO( <expC1>,<expC2> )  && cod. banco e Nosso Numero
	* Return: Retorna <expN1> - Retorna Digito Verificador p/ Banco
	do case
		case mv_par09=="237"

		_num3 :=(val(subs(_char2,1,1)) * 2) + (val(subs(_char2,2,1)) * 7)

		_num3 :=_num3 +(val(subs(_char2,3,1)) * 6) + (val(subs(_char2,4,1)) * 5) +;
		(val(subs(_char2,5,1)) * 4) + (val(subs(_char2,6,1)) * 3) +;
		(val(subs(_char2,7,1)) * 2) + (val(subs(_char2,8,1)) * 7)

		_num3:=_num3+  (val(subs(_char2,9,1)) * 6) + (val(subs(_char2,10,1)) * 5) +;
		(val(subs(_char2,11,1)) * 4) + (val(subs(_char2,12,1)) * 3) +;
		(val(subs(_char2,13,1)) * 2)

		_num2  := mod(_num3,11)

		if (_num2 == 0) .or. (_num2 == 1)
			if (_num2 == 0)
				_char2 := "0"
			else
				_char2 := "P"
			endif
		else
			_num4  := 11 - _num2
			_char2 := str(_num4,1)
		endif


		case mv_par09=="001"  && P/ BANCO DO BRASIL
		_num3 := (val(subs(_char2,1,1)) * 7) +;
		(val(subs(_char2,2,1)) * 8) + (val(subs(_char2,3,1)) * 9) +;
		(val(subs(_char2,4,1)) * 2) + (val(subs(_char2,5,1)) * 3) +;
		(val(subs(_char2,6,1)) * 4) + (val(subs(_char2,7,1)) * 5)
		_num3:=_num3+  (val(subs(_char2,8,1)) * 6) + (val(subs(_char2,9,1)) * 7) +;
		(val(subs(_char2,10,1)) * 8) + (val(subs(_char2,11,1)) * 9)
		_num2  := mod(_num3,11)
		if _num2==10
			_char2:="X"
		else
			_char2:=str(_num2,1)
		endif

		//SANTANDER
		case mv_par09=="033"
		_num3 := (val(subs(_char2,1,1)) * 5) +;
		(val(subs(_char2,2,1)) * 4) + (val(subs(_char2,3,1)) * 3) +;
		(val(subs(_char2,4,1)) * 2) + (val(subs(_char2,5,1)) * 7) +;
		(val(subs(_char2,6,1)) * 6) + (val(subs(_char2,7,1)) * 5)
		_num3:=_num3+  (val(subs(_char2,8,1)) * 4) + (val(subs(_char2,9,1)) * 3) +;
		(val(subs(_char2,10,1)) * 2)
		_num2  := Mod(_num3,11)
		if _num2==0 .or. _num2==1
			_char2:="0"
		else
			_char2:=str(11-_num2,1)
		endif

		case mv_par09=="041"    && P/ BANRISUL
		_num3 := (val(subs(_char2,1,1)) * 1) - iif(val(subs(_char2,1,1)) * 1 >9,9,0) +;
		(val(subs(_char2,2,1)) * 2) - iif(val(subs(_char2,2,1)) * 2 >9,9,0) +;
		(val(subs(_char2,3,1)) * 1) - iif(val(subs(_char2,3,1)) * 1 >9,9,0) +;
		(val(subs(_char2,4,1)) * 2) - iif(val(subs(_char2,4,1)) * 2 >9,9,0) +;
		(val(subs(_char2,5,1)) * 1) - iif(val(subs(_char2,5,1)) * 1 >9,9,0)
		_num3:=_num3+ (val(subs(_char2,6,1)) * 2) - iif(val(subs(_char2,6,1)) * 2 >9,9,0) +;
		(val(subs(_char2,7,1)) * 1) - iif(val(subs(_char2,7,1)) * 1 >9,9,0) +;
		(val(subs(_char2,8,1)) * 2) - iif(val(subs(_char2,8,1)) * 2 >9,9,0)
		if _num3<10
			_num2:=_num3
		else
			_num2 := mod(_num3,10)
		endif
		if _num2 == 0
			_num4 := 0
		else
			_num4 := 10 - _num2
		endif
		_char2 := _char2+str(_num4,1)
		_num3 := (val(subs(_char2,1,1)) * 4) +;
		(val(subs(_char2,2,1)) * 3) + (val(subs(_char2,3,1)) * 2) +;
		(val(subs(_char2,4,1)) * 7) + (val(subs(_char2,5,1)) * 6) +;
		(val(subs(_char2,6,1)) * 5) + (val(subs(_char2,7,1)) * 4) +;
		(val(subs(_char2,8,1)) * 3) + (val(subs(_char2,9,1)) * 2)
		if _num3<11
			_num2:=_num3
		else
			_num2 := mod(_num3,11)
		endif
		if _num2 == 1
			IF VAL(RIGHT(_CHAR2,1))+1==10
				_CHAR2:=LEFT(_CHAR2,8)+"0"
			ELSE
				_CHAR2:=LEFT(_CHAR2,8)+STR(VAL(RIGHT(_CHAR2,1))+1,1)
			ENDIF
			_num3 := (val(subs(_char2,1,1)) * 4) +;
			(val(subs(_char2,2,1)) * 3) + (val(subs(_char2,3,1)) * 2) +;
			(val(subs(_char2,4,1)) * 7) + (val(subs(_char2,5,1)) * 6) +;
			(val(subs(_char2,6,1)) * 5) + (val(subs(_char2,7,1)) * 4) +;
			(val(subs(_char2,8,1)) * 3) + (val(subs(_char2,9,1)) * 2)
			if _num3<11
				_num2:=_num3
			else
				_num2 := mod(_num3,11)
			endif
		endif
		if _num2 == 0
			_num4 := 0
		else
			_num4 := 11 - _num2
		endif
		_char2 := right(_char2,1)+str(_num4,1)

		case mv_par09=="399"  && P/ HSBC Bamerindus
		_num3 := (val(subs(_char2,1,1)) * 5) +;
		(val(subs(_char2,2,1)) * 4) + (val(subs(_char2,3,1)) * 3) +;
		(val(subs(_char2,4,1)) * 2) + (val(subs(_char2,5,1)) * 7) +;
		(val(subs(_char2,6,1)) * 6) + (val(subs(_char2,7,1)) * 5)
		_num3:=_num3+  (val(subs(_char2,8,1)) * 4) + (val(subs(_char2,9,1)) * 3) +;
		(val(subs(_char2,10,1)) * 2)
		_num2  := Mod(_num3,11)
		if _num2==0 .or. _num2==1
			_char2:="0"
		else
			_char2:=str(11-_num2,1)
		endif

		case mv_par09=="748"  && P/ BANCO SiCREDI
		/*_num3 := (val(subs(_char2,01,1)) * 9) +;
		(val(subs(_char2,02,1)) * 8) +;
		(val(subs(_char2,03,1)) * 7) +;
		(val(subs(_char2,04,1)) * 6) +;
		(val(subs(_char2,05,1)) * 5) +;
		(val(subs(_char2,06,1)) * 4) +;
		(val(subs(_char2,07,1)) * 3) +;
		(val(subs(_char2,08,1)) * 2) + 138//176 + 9
		*/

		_num3 := (val(subs(_char2,01,1)) * 4) +;
		(val(subs(_char2,02,1)) * 3) +;
		(val(subs(_char2,03,1)) * 2) +;
		(val(subs(_char2,04,1)) * 9) +;
		(val(subs(_char2,05,1)) * 8) +;
		(val(subs(_char2,06,1)) * 7) +;
		(val(subs(_char2,07,1)) * 6) +;
		(val(subs(_char2,08,1)) * 5) +;
		(val(subs(_char2,09,1)) * 4) +;
		(val(subs(_char2,10,1)) * 3) +;
		(val(subs(_char2,11,1)) * 2) +;
		(val(subs(_char2,12,1)) * 9) +;
		(val(subs(_char2,13,1)) * 8) +;
		(val(subs(_char2,14,1)) * 7) +;
		(val(subs(_char2,15,1)) * 6) +;
		(val(subs(_char2,16,1)) * 5) +;
		(val(subs(_char2,17,1)) * 4) +;
		(val(subs(_char2,18,1)) * 3) +;
		(val(subs(_char2,19,1)) * 2)

		_num2 := int(_num3/11)

		_num2 := _num2 * 11

		_num2 := _num3 - _num2

		if _num2 == 0
			_num4 := 0
		else
			_num4 := 11 - _num2
		endif
		if _num4 == 10 .OR. _num4 == 11
			_num4 := 0
		endif

		_char2 := str(_num4,1)


		case mv_par09=="341"  && P/ ITAU

		_num3 :=  iif((val(subs(_char2,01,1)) * 1)<9,(val(subs(_char2,01,1)) * 1),val(substr(str((val(subs(_char2,01,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,01,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,02,1)) * 2)<9,(val(subs(_char2,02,1)) * 2),val(substr(str((val(subs(_char2,02,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,02,1)) * 2),2,0),2,1))) +;
		iif((val(subs(_char2,03,1)) * 1)<9,(val(subs(_char2,03,1)) * 1),val(substr(str((val(subs(_char2,03,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,03,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,04,1)) * 2)<9,(val(subs(_char2,04,1)) * 2),val(substr(str((val(subs(_char2,04,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,04,1)) * 2),2,0),2,1))) +;
		iif((val(subs(_char2,05,1)) * 1)<9,(val(subs(_char2,05,1)) * 1),val(substr(str((val(subs(_char2,05,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,05,1)) * 1),2,0),2,1)))

		_num3 :=  _num3+iif((val(subs(_char2,06,1)) * 2)<9,(val(subs(_char2,06,1)) * 2),val(substr(str((val(subs(_char2,06,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,06,1)) * 2),2,0),2,1))) +;
		iif((val(subs(_char2,07,1)) * 1)<9,(val(subs(_char2,07,1)) * 1),val(substr(str((val(subs(_char2,07,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,07,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,08,1)) * 2)<9,(val(subs(_char2,08,1)) * 2),val(substr(str((val(subs(_char2,08,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,08,1)) * 2),2,0),2,1))) +;
		iif((val(subs(_char2,09,1)) * 1)<9,(val(subs(_char2,09,1)) * 1),val(substr(str((val(subs(_char2,09,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,09,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,10,1)) * 2)<9,(val(subs(_char2,10,1)) * 2),val(substr(str((val(subs(_char2,10,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,10,1)) * 2),2,0),2,1)))

		_num3 :=  _num3+iif((val(subs(_char2,11,1)) * 1)<9,(val(subs(_char2,11,1)) * 1),val(substr(str((val(subs(_char2,11,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,11,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,12,1)) * 2)<9,(val(subs(_char2,12,1)) * 2),val(substr(str((val(subs(_char2,12,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,12,1)) * 2),2,0),2,1))) +;
		iif((val(subs(_char2,13,1)) * 1)<9,(val(subs(_char2,13,1)) * 1),val(substr(str((val(subs(_char2,13,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,13,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,14,1)) * 2)<9,(val(subs(_char2,14,1)) * 2),val(substr(str((val(subs(_char2,14,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,14,1)) * 2),2,0),2,1))) +;
		iif((val(subs(_char2,15,1)) * 1)<9,(val(subs(_char2,15,1)) * 1),val(substr(str((val(subs(_char2,15,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,15,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,16,1)) * 2)<9,(val(subs(_char2,16,1)) * 2),val(substr(str((val(subs(_char2,16,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,16,1)) * 2),2,0),2,1)))

		_num3 :=  _num3+iif((val(subs(_char2,17,1)) * 1)<9,(val(subs(_char2,17,1)) * 1),val(substr(str((val(subs(_char2,17,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,17,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,18,1)) * 2)<9,(val(subs(_char2,18,1)) * 2),val(substr(str((val(subs(_char2,18,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,18,1)) * 2),2,0),2,1))) +;
		iif((val(subs(_char2,19,1)) * 1)<9,(val(subs(_char2,19,1)) * 1),val(substr(str((val(subs(_char2,19,1)) * 1),2,0),1,1))+val(substr(str((val(subs(_char2,19,1)) * 1),2,0),2,1))) +;
		iif((val(subs(_char2,20,1)) * 2)<9,(val(subs(_char2,20,1)) * 2),val(substr(str((val(subs(_char2,20,1)) * 2),2,0),1,1))+val(substr(str((val(subs(_char2,20,1)) * 2),2,0),2,1)))

		_num2  := (_num3/10)
		_num4  := (_num2-int(_num2))*10
		if _num4==0
			_char2 := "0"
		else
			_char2 := STR(10-_num4,1)
		endif

		case mv_par09 == '104'
		if SEE->EE_POSCONV != '2'
			_num3 := (val(subs(_char2,01,1)) * 3) + (val(subs(_char2,02,1)) * 2) +;
			(val(subs(_char2,03,1)) * 9) + (val(subs(_char2,04,1)) * 8) +;
			(val(subs(_char2,05,1)) * 7) + (val(subs(_char2,06,1)) * 6) +;
			(val(subs(_char2,07,1)) * 5) + (val(subs(_char2,08,1)) * 4) +;
			(val(subs(_char2,09,1)) * 3) + (val(subs(_char2,10,1)) * 2)

			_num2  := (_num3/11)+.09
			_num4  := right(ltrim(str(_num2,12,2)),2)
			_num5  := 11-(val(left(_num4,1)))
			_char2 := iif(_num5<=9,str(_num5,1),str(iif(_num4="00",1,0),1))

		else

			_num3 := modulo11(_char2,"104")

			_char2 := _num3

		endif
		case mv_par09 == '756'
		_num3 := (val(subs(_char2,01,1)) * 3) + (val(subs(_char2,02,1)) * 1) +;
		(val(subs(_char2,03,1)) * 9) + (val(subs(_char2,04,1)) * 7) +;
		(val(subs(_char2,05,1)) * 3) + (val(subs(_char2,06,1)) * 1) +;
		(val(subs(_char2,07,1)) * 9) + (val(subs(_char2,08,1)) * 7) +;
		(val(subs(_char2,09,1)) * 3) + (val(subs(_char2,10,1)) * 1) +;
		(val(subs(_char2,11,1)) * 9) + (val(subs(_char2,12,1)) * 7) +;
		(val(subs(_char2,13,1)) * 3) + (val(subs(_char2,14,1)) * 1) +;
		(val(subs(_char2,15,1)) * 9) + (val(subs(_char2,16,1)) * 7) +;
		(val(subs(_char2,17,1)) * 3) + (val(subs(_char2,18,1)) * 1) +;
		(val(subs(_char2,19,1)) * 9) + (val(subs(_char2,20,1)) * 7) +;
		(val(subs(_char2,21,1)) * 3)

		_num3 := MOD(_num3,11)

		If _num3 <= 1
			_char2 := 0
		Else
			_char2 := ABS(11-_num3)
		EndIf

		/*

		Para o c·lculo do dÌgito verificador do nosso n˙mero, dever· ser utilizada a fÛrmula abaixo:
		N˙mero da Cooperativa    9(4) ñ vide planilha "Capa" deste arquivo 
		CÛdigo do Cliente   9(10) ñ vide planilha "Capa" deste arquivo
		Nosso N˙mero   9(7) ñ Iniciado em 1
		Constante para c·lculo  = 3197

		a) Concatenar na seq¸Íncia completando com zero ‡ esquerda. 
		Ex.:N˙mero da Cooperativa  = 0001
		N˙mero do Cliente  = 1-9
		Nosso N˙mero  = 21
		000100000000190000021

		b) Alinhar a constante com a seq¸Íncia repetindo de traz para frente.
		Ex.: 000100000000190000021
		319731973197319731973

		c) Multiplicar cada componente da seq¸Íncia com o seu correspondente da constante e somar os resultados.
		Ex.: 1*7 + 1*3 + 9*1 + 2*7 + 1*3 = 36

		d) Calcular o Resto atravÈs do MÛdulo 11.
		Ex.: 36/11 = 3, resto = 3

		e) O resto da divis„o dever· ser subtraÌdo de 11 achando assim o DV (Se o Resto for igual a 0 ou 1 ent„o o DV È igual a 0).
		Ex.: 11 ñ 3 = 8, ent„o Nosso N˙mero + DV = 21-8

		*/			
	endcase
return

//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥ CHAMADA DA FUNCAO RET_CBARRA()                                  ≥
//≥ Retorna os strings para inpress„o do Boleto                     ≥
//≥ CB = String para o cÛd.barras, RN=String com o n˙mero digit·vel ≥
//≥ CobranÁa n„o identificada, n˙mero do boleto = TÌtulo + Parcela  ≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor,dVenc,cConvenio,cSeq,_lTemDesc,cParcela,_cAgCompleta, cTipoConv)
	Local cValorFim := StrZero( nValor * 100, 10 )
	Local cNNumSDig := ""
	Local cCpoLivre := ""
	Local cCBSemDig := ""
	Local cCodBarra := ""
	Local cNNum := ""
	Local cFatVenc := ""
	Local cNossoNum := ""
	Local _nFator := 0

	cParcela := fNParcela( cParcela )
	_nFator := dVenc - CTOD("07/10/1997")
	_nFator := IIf(_nFator > 9999,_nFator-9000,_nFator)
	cFatVenc  := StrZero(_nFator, 4 )// Fator Vencimento  -  POSICAO DE 06 A 09

	If cTipoConv == 1

		cNNumSDig := SubStr( cSeq, 1, 10 )

		cNNum := cNNumSDig + fModulo11( cNNumSDig, SubStr( cBanco, 1, 3  ) ) // Nosso Numero

		cNossoNum := cNNumSDig + "-" +  fModulo11( cNNumSDig, SubStr( cBanco, 1, 3  ) )// Nosso Numero para impressao

		cCpoLivre := SubStr( AllTrim( cConvenio ), 1, 15 )  +  cNNumSDig

	Else

		cNNumSDig := SubStr( cSeq, 1, 17 )

		cNNum     := cNNumSDig + fModulo11( cNNumSDig, SubStr( cBanco, 1, 3  ) )// Nosso Numero

		cNossoNum := cNNumSDig + "-" +  fModulo11( cNNumSDig, SubStr( cBanco, 1, 3  ) )// Nosso Numero para impressao

		cCpoLivre := cConvenio + fModulo11( cConvenio, SubStr( cBanco, 1, 3  ) ) + SubStr( cNNumSDig, 3, 3 )  + "1" +  SubStr( cNNumSDig, 6, 3 )  + "4" + SubStr( cNNumSDig, 9 )

		cCpoLivre := cCpoLivre + fModulo11( cCpoLivre, SubStr( cBanco, 1, 3  ) )

	EndIf


	// codigos de barras
	cCBSemDig := cBanco + cFatVenc + cValorFim + cCpoLivre// Dados para Calcular o Dig VerIficador Geral

	cCodBarra := cBanco + fM11Caixa( cCBSemDig, SubStr( cBanco, 1, 3  ) )  + cFatVenc + cValorFim + cCpoLivre// Codigo de Barras Completo

	cPrCpo   := cBanco + SubStr( cCodBarra, 20, 5 )// Digito VerIficador do Primeiro Campo
	cDvPrCpo := AllTrim( Str( fModulo10( cPrCpo  ) ) )

	cSgCpo   := SubStr( cCodBarra, 25, 10 )// Digito VerIficador do Segundo Campo
	cDvSgCpo := AllTrim( Str( fModulo10( cSgCpo  ) ) )

	cTrCpo   := SubStr( cCodBarra, 35, 10 )// Digito VerIficador do Terceiro Campo
	cDvTrCpo := AllTrim( Str( fModulo10( cTrCpo  ) ) )

	cDvGeral := SubStr( cCodBarra, 5, 1 )// Digito VerIficador Geral

	//Linha Digitavel
	cLinDig := SubStr( cPrCpo, 1, 5 )  + "." + SubStr( cPrCpo, 6, 4 )  + cDvPrCpo + " "// Primeiro campo
	cLinDig  += SubStr( cSgCpo, 1, 5 )  + "." + SubStr( cSgCpo, 6, 5 )  + cDvSgCpo + " "// Segundo campo
	cLinDig  += SubStr( cTrCpo, 1, 5 )  + "." + SubStr( cTrCpo, 6, 5 )  + cDvTrCpo + " "// Terceiro campo
	cLinDig  += " " + cDvGeral// Dig verIficador geral
	cLinDig  += "  " + SubStr( cCodBarra, 6, 4 )  + SubStr( cCodBarra, 10, 10 )// Fator de vencimento e valor nominal do titulo



Return({cCodBarra,cLinDig,cNossoNum})

/*/{Protheus.doc} ffModulo10
Chamada da Funcao fModulo10()
@type function
@author Claudio H. Ferreira
@since 10/06/2013
@version 1.0
@param cData, caractere, fator para calculo do Modulo10
@Return D, Digito verificador
/*/
Static Function fModulo10( cData  )
	Local L, D, P := 0
	Local B := .F.

	L := Len( cData  )

	B := .T.

	D := 0

	While L  >  0

		P := Val(  SubStr( cData, L, 1 ) )

		If ( B  )

			P := P * 2

			If P  >  9

				P := P  -  9

			EndIf

		EndIf

		D := D + P

		L := L  -  1

		B := !B

	End

	D := 10  -  ( Mod( D, 10  ) )

	If D = 10

		D := 0

	EndIf

Return D

/*/{Protheus.doc} fNParcela
Retorna cÛdigo da  parcela
@type function
@author Claudio H. Ferreira\Everson da Costa Almeida
@since 10/06/2013
@version 1.0
@param cParcela, character, Codigo Parcela
@return cRet, Codigo Parcela
/*/
Static Function fNParcela( cParcela )
	Local cRet := ""

	If ASC( cParcela ) >=  65 .OR. ASC( cParcela ) <= 90

		cRet := StrZero( Val( Chr( ASC( cParcela )  - 16  ) ) , 2 )

	Else

		cRet := StrZero( Val( cParcela ), 2 )

	EndIf

Return cRet


/*/{Protheus.doc} fM11Caixa
Retorna cÛdigo da  parcela
@type function
@author Claudio H. Ferreira\Everson da Costa Almeida
@since 10/06/2013
@version 1.0
@param cBar100DV, character, Codigo de Barras 100 DV
@param cBanc, character, Codigo Banco
@return D, DÌgito Verificador
/*/
Static Function fM11Caixa( cdata, cBanc )
	Local L, D, P := 0

	If cBanc == "104"       // CAIXA

		L := Len( cdata )

		D := 0

		P := 1

		While L  >  0

			P := P + 1

			D := D + ( Val( SubStr( cData, L, 1  ) ) * P )

			If P = 9

				P := 1

			Endif

			L := L  -  1

		End

		D := 11  -  ( Mod( D, 11  ) )

		If ( D  >  9 )  .OR. ( D == 0 )  .OR. ( D == 1 )

			D := 1

		Endif

		D := AllTrim( Str( D  ) )

	EndIf

Return D


/*/{Protheus.doc} fModulo11
Chamada Mod11
@type function
@author Claudio H. Ferreira\Everson da Costa Almeida
@since 10/06/2013
@version 1.0
@param cData, character, ??
@param cBanc, character, Codigo Banco
@return D, DÌgito Verificador
/*/
Static Function fModulo11( cData, cBanc )
	Local L, D, P := 0

	If cBanc == "104"       // CAIXA

		L := Len( cdata )

		D := 0

		P := 1

		While L  >  0

			P := P + 1

			D := D + ( Val( SubStr( cData, L, 1  ) ) * P )

			If P = 9

				P := 1

			Endif

			L := L  -  1

		End

		D := 11  -  ( Mod( D, 11  ) )

		If ( D  >  9 )

			D := 0

		Endif

		D := AllTrim( Str( D  ) )

	EndIf

Return( D )


/*
CHAMADA DA FUNCAO MODULO11()
*/
Static Function Modulo11(cData,cBanc)

Local L, D, P := 0

If cBanc == "104"       // CAIXA
    L := Len(cdata)
    D := 0
    P := 1
    While L > 0
        P := P + 1
        D := D + (Val(SubStr(cData, L, 1)) * P)
        If P = 9
            P := 1
        End
        L := L - 1
    End
    D := 11 - (mod(D,11))

    If (D > 9)
        D := 0
    End

    D := AllTrim(Str(D))
endif
Return(D)
