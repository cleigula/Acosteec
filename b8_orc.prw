//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"
#Include 'Protheus.ch'
#Include "TOPCONN.CH"

//Variveis Estaticas
Static cTitulo := "Orcamentos"
Static cTabPai := "ZD1"
Static cTabFilho := "ZD2"
Static cTabNeto := "ZD3"


User Function b8_orc()
	Local aArea   := FWGetArea()
	Local oBrowse
	Private aRotina := {}
	private  cTotEsp,cTotPed := 0.00

	private oGeVit  := nil
	private oGeVtot := nil
	private cGeVit  := 0.00
	private cGeVtot := 0.00
	Private lMsErroAuto    := .F.
	Private lAutoErrNoFile := .F.

	private oSayVItem
	private oSayTot
	private cSayItem   := 'Valor total espessura'
	private cSayTot    := 'Valor total do orcamento'


	//Definicao do menu

	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cTabPai)
	oBrowse:SetDescription(cTitulo)
	oBrowse:DisableDetails()

	//Ativa a Browse
	oBrowse:Activate()

	FWRestArea(aArea)
Return Nil


Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.b8_orc" OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.b8_orc" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.b8_orc" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.b8_orc" OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Copiar"     ACTION "VIEWDEF.b8_orc" OPERATION 9 ACCESS 0

	ADD OPTION aRotina TITLE 'Importar CSV' ACTION 'u_ob_impex'    OPERATION 9 ACCESS 0 //OPERATION 5
	ADD OPTION aRotina TITLE 'Aprovação'    ACTION 'u_ob_opapr'     OPERATION 9 ACCESS 0 //OPERATION 5
	ADD OPTION aRotina TITLE 'Gerar Pedido' ACTION 'u_ob_gerped'    OPERATION 9 ACCESS 0 //OPERATION 5


Return aRotina



user function ob_impex()
	FWMsgRun(, {|oSay| bImpEx(oSay) }, "Processando", "Importando dados...")
return

user function ob_gerped()
	FWMsgRun(, {|oSay| bPed(oSay) }, "Processando", "Pedido de venda...")
return

static function bPed(oSay)
	Local aArea    := FWGetArea()
	local  cQry:= ''
	local _aItens := {}
	local _aItbig := {}
	local _aAutoSC5 := {}
	local _aAutoSC6 := {}
	local _citem    := '00'
	local cTipProd  := ''
	local cNewCod   := ''
	local cProdBKP  := ''
	local lcont     := .t.
	local cDesNp    := ''
	local  _sTexto := "["+Substr(Time(),1,2)+":"+Substr(Time(),4,2)+"]  inicio do processo<br>"
	Local nCount     := 0
	Local aErroAuto  := {}
	Local cLogErro   := ""
	Local cCalIPI    := ''
	local cTes       := ''
	local nPrecVEn   := 0.00
	local nAlIpi     := 0.00


	if Alltrim(ZD1_COND) <> '' .and.  Alltrim(ZD1_NATURE) <>  '' .and. Alltrim(ZD1_VEND) <> '' .and.  Alltrim(ZD1_TES) <> ''
		oSay:SetText("Consultando dados...")
		ProcessMessages()

		cQry := " SELECT  ZD1_ORCAME, ZD1_CLIENT, ZD1_LOJA,ZD1_OCCLI,ZD2_ITEM, ZD1_TES,ZD1_VEND,ZD1_COND, ZD1_NATURE,ZD2_PRODUT,ZD2_TES,ZD3_ITEM,ZD3_QUANT, B1_UM,B1_DESC, ZD3_PBRUNI, ZD3_COD,ZD3_VLITEM FROM ZD1010 ZD1 "
		cQry += "  INNER JOIN ZD2010 ZD2 ON ZD2_ORCAME = '"+ ZD1->ZD1_ORCAME +"' AND ZD1_FILIAL = ZD2_FILIAL AND ZD2.D_E_L_E_T_ = '' "
		cQry += "  INNER JOIN ZD3010 ZD3 ON ZD3_ORCAME = '"+ ZD1->ZD1_ORCAME +"' AND ZD2_FILIAL = ZD3_FILIAL AND ZD2_PRODUT = ZD3_PRODUT "
		cQry += "  INNER JOIN SB1010 SB1 ON ZD2.ZD2_PRODUT = SB1.B1_COD AND SB1.D_E_L_E_T_ = '' "
		cQry += "  AND ZD3.D_E_L_E_T_ = ''  "
		cQry += "  WHERE ZD1.D_E_L_E_T_ = '' AND ZD1.ZD1_ORCAME = '"+ZD1->ZD1_ORCAME+"'  ORDER BY ZD2_ITEM,ZD3_ITEM"

		TCQUERY cQry NEW ALIAS "TRBC"

		If FWIsAdmin()
			ShowLog(cQry)
		EndIf

		cTipProd:=POSICIONE("SA1",1,XFILIAL("SA1")+TRBC->ZD1_CLIENT+TRBC->ZD1_LOJA,"A1_TIPFPRO")

		dbSelectArea('TRBC')
		dbgotop()
		AADD( _aAutoSC5, { "C5_TIPO"     , "N"         , Nil } )
		AADD( _aAutoSC5, { "C5_EMISSAO"  , dDataBase   , Nil } )
		AADD( _aAutoSC5, { "C5_CLIENTE"  , TRBC->ZD1_CLIENT         , Nil } )
		AADD( _aAutoSC5, { "C5_LOJACLI"  , TRBC->ZD1_LOJA         , Nil } )
		AADD( _aAutoSC5, { "C5_TIPOCLI"  , "F"             , Nil } )
		AADD( _aAutoSC5, { "C5_VEND1"    , TRBC->ZD1_VEND             , Nil } )
		AADD( _aAutoSC5, { "C5_CONDPAG"  , TRBC->ZD1_COND          , Nil } )
		AADD( _aAutoSC5, { "C5_NATUREZ"  , TRBC->ZD1_NATURE             , Nil } )

		While !eof() //.and. g < 2
			_aItens := {}
			_citem    := soma1(_citem)
			if lcont
				AADD(_aItens , {"C6_ITEM"    , _citem                        , Nil } )
				if cTipProd == '1'
					cNewCod:= veEst(TRBC->ZD2_PRODUT)
					IF cNewCod == TRBC->ZD2_PRODUT .and. cProdBKP <> cNewCod
						if FWAlertYesNo("O cliente possui configuração para usar estrutura.<br>	Nao encontrei a mesma para o produto <b>"+TRBC->ZD2_PRODUT+".<b><br>Deseja continuar e usar este codigo de produto ?", "Estrutura nao encontrada")
							lcont := .t.
						else
							lcont := .f.
						endif
					Endif
					cProdBKP:=cNewCod
				else
					cNewCod := TRBC->ZD2_PRODUT
				endif
				cDesNp   :=POSICIONE("SB1",1,xFilial("SB1")+ cNewCod ,"B1_DESC")

				cTes     := IIF(Alltrim(TRBC->ZD2_TES) <> '',TRBC->ZD2_TES,TRBC->ZD1_TES)
				
				cCalIPI  :=posicione("SF4",1,xFilial("SF4") + cTes,'F4_IPI')

				nPrecVEn := TRBC->ZD3_VLITEM / TRBC->ZD3_PBRUNI

				if cCalIPI == 'S'
					nAlIpi   :=POSICIONE("SB1",1,xFilial("SB1")+ cNewCod ,"B1_IPI")
					nPrecVEn := nPrecVEn / (1 + (nAlIpi/100))	
				endif

				dbSelectArea('TRBC')
				AADD(_aItens , {"C6_PRODUTO" , cNewCod, Nil } )
				AADD(_aItens , {"C6_PRODCLI" , TRBC->ZD3_COD,  Nil } )
				AADD(_aItens , {"C6_DESCRI"  , alltrim(cDesNp), Nil } )
				AADD(_aItens , {"C6_UM"      , TRBC->B1_UM, Nil } )
				AADD(_aItens , {"C6_QTDVEN"  , TRBC->ZD3_PBRUNI    , Nil } )
				AADD(_aItens , {"C6_PRCVEN"  ,  nPrecVEn  , Nil } )
				AADD(_aItens , {"C6_QTDLIB"  , TRBC->ZD3_PBRUNI , Nil } )
				AADD(_aItens , {"C6_ENTREG"  , dDatabase  , Nil } )
				AADD(_aItens , {"C6_TES"     , cTes, Nil } )
				AADD(_aItens , {"C6_UNSVEN"  , TRBC->ZD3_QUANT, Nil } )
				AADD(_aItens , {"C6_ITEMPC"  , TRBC->ZD1_OCCLI, Nil } )
				AADD(_aItens , {"C6_NUMPCOM" , TRBC->ZD1_OCCLI, Nil } )


				AADD(_aItbig , {cNewCod,TRBC->ZD3_COD,alltrim(cDesNp),TRBC->B1_UM,TRBC->ZD3_PBRUNI,TRBC->ZD3_VLITEM / TRBC->ZD3_PBRUNI,TRBC->ZD3_PBRUNI,dDatabase,TRBC->ZD1_TES,TRBC->ZD3_QUANT } )

				AADD( _aAutoSC6, AClone( _aItens ) )
			endif
			dbskip()
			//g:=g+1
		Enddo

		TRBC->(DbCloseArea())

		//u_ShowArray(_aAutoSC5)
		//u_ShowArray(_aAutoSC6)
		//u_ShowArray(_aItens)


		IF lcont
			oSay:SetText("Gerando pedido...")
			ProcessMessages()
			//if FWAlertYesNo("Deseja gerar pedido manual?", "geração de pedido")
			//if len(_aAutoSC6) > 80
			//o sistema fica extremamente lento quando os itens ultrapassam a quantidade de 100
			//	gravaPed(_aAutoSC5,_aItbig)
			//else
			Begin Transaction
				MsExecAuto({|x,y,z|MATA410(x,y,z)},_aAutoSC5,_aAutoSC6,3)
				//MATA410(_aAutoSC5,_aAutoSC6,3)
				If lMsErroAuto
					ConOut("Erro na inclusao!")
					aErroAuto := GetAutoGRLog()
					For nCount := 1 To Len(aErroAuto)
						cLogErro += StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " "
						ConOut(cLogErro)
					Next nCount
					FWAlertWarning(cLogErro, 'verifique dados')
					msgalert(cLogErro, 'Pedido gerado')
				else
					_sTexto += "["+Substr(Time(),1,2)+":"+Substr(Time(),4,2)+"]  Fim do processo<br>"
					_sTexto +=  'Pedido gerado <b>'+SC5->C5_NUM+'</b> com sucesso'
					//FWAlertSuccess('Pedido gerado <b>'+SC5->C5_NUM+'</b> com sucesso', 'Pedido gerado')
					FWAlertSuccess(_sTexto, 'Pedido gerado')  // no cloud deixou de aparecer essa mensatgem
					msgalert(_sTexto, 'Pedido gerado')
					RecLock('ZD1', .f.)
					ZD1->ZD1_PEDIDO   := SC5->C5_NUM
					ZD1->(MsUnlock())
				endif

			End Transaction
			//endif
		endif
		FWRestArea(aArea)
	else
		FWAlertWarning("Verifique os campos <b><TES, Condição de pagamento, Natureza e vendedor>'</b> na aba Faturamento", "Campos faltantes")
	endif


return

STATIC function gravaPed(aSc5,aSc6)
	Local aArea   := FWGetArea()
	local _cItgp  := '00'
	local _c
	local cCli    := aSc5[3][2]
	local cLoja   := aSc5[4][2]
	local cEst    := POSICIONE("SA1",1,XFILIAL("SA1")+aSc5[3][2] + aSc5[4][2],"A1_EST")
	local cNomSC5 := POSICIONE("SA1",1,XFILIAL("SA1")+aSc5[3][2] + aSc5[4][2],"A1_NOME")

	local cCfini  := '5'
	local cPed    := GETSXENUM("SC5","C5_NUM")

	if cEst <> 'RS'
		cCfini := '6'
	EndIF

	dbselectArea('SC5')
	RecLock('SC5', .t.)
	SC5->C5_FILIAL  :=  xFilial("SC5")
	SC5->C5_NUM     := cPed
	SC5->C5_TIPO    := aSc5[1][2]
	SC5->C5_EMISSAO := aSc5[2][2]
	SC5->C5_CLIENTE := cCli
	SC5->C5_LOJACLI := cLoja
	SC5->C5_CLIENT  := cCli
	SC5->C5_LOJAENT := cLoja
	SC5->C5_MOEDA   := 1
	SC5->C5_TIPLIB  := '1'
	SC5->C5_TXMOEDA := 1.000
	SC5->C5_TPCARGA := '2'
	SC5->C5_TPCOMPL := '1'
	SC5->C5_TIPOCLI := aSc5[5][2]
	SC5->C5_VEND1   := aSc5[6][2]
	SC5->C5_CONDPAG := aSc5[7][2]
	SC5->C5_NATUREZ := aSc5[8][2]
	SC5->C5_GERAWMS := '1'
	SC5->C5_SOLOPC  := '1'
	SC5->C5_INDPRES := '0'
	SC5->C5_RET20G  := 'N'
	SC5->C5_SLENVT  := '2'
	SC5->C5_MSBLQL  := '2'
	SC5->C5_ZNOME   := cNomSC5
	SC5->(MsUnlock())

//	AADD(_aItbig , {cNewCod,TRBC->ZD3_COD,alltrim(TRBC->B1_DESC),TRBC->B1_UM,TRBC->ZD3_PBRUNI,TRBC->ZD3_VLITEM / TRBC->ZD3_PBRUNI,TRBC->ZD3_PBRUNI,dDatabase,TRBC->ZD1_TES,TRBC->ZD3_QUANT } )

	dbselectArea('SC6')
	for _c:= 1 to len(aSc6)
		RecLock('SC6', .t.)
		SC6->C6_FILIAL      :=  xFilial("SC6")
		SC6->C6_NUM      :=  cPed
		_cItgp:= soma1(_cItgp)
		SC6->C6_ITEM     := _cItgp
		SC6->C6_PRODUTO  :=  aSc6[_c][1]

		_cClas    := POSICIONE("SB1",1,xFilial("SB1")+ aSc6[_c][1] ,"B1_ORIGEM")

		SC6->C6_DESCRI  :=   aSc6[_c][3]
		SC6->C6_SEGUM    := 'PC'
		SC6->C6_LOCAL    := '02'
		SC6->C6_PRODCLI  := aSc6[_c][2]
		SC6->C6_UM       := aSc6[_c][4]
		SC6->C6_QTDVEN   := aSc6[_c][5]


		SC6->C6_PRCVEN   := aSc6[_c][6]
		SC6->C6_VALOR    := aSc6[_c][5] * aSc6[_c][6]
		SC6->C6_QTDLIB   := aSc6[_c][7]
		SC6->C6_ENTREG   := aSc6[_c][8]
		SC6->C6_TES      := aSc6[_c][9]

		cCF      := posicione("SF4",1,xFilial("SF4") + aSc6[_c][9],'F4_CF')
		cClasSF4 := posicione("SF4",1,xFilial("SF4") + aSc6[_c][9],'F4_SITTRIB')

		SC6->C6_CF       :=  cCfini+right(Alltrim(cCF),3)
		SC6->C6_CLASFIS  := Subs(_cClas,1,1) + cClasSF4
		SC6->C6_UNSVEN   :=  aSc6[_c][10]


		SC6->C6_SUGENTR := ddatabase
		SC6->C6_DTFIMNT := ddatabase
		SC6->C6_DATCPL  := ddatabase
		SC6->C6_INTROT  := '1'
		SC6->C6_RATEIO  := '2'
		SC6->C6_TPPROD  := '1'

		SC6->C6_CLI      := cCli
		SC6->C6_LOJA     := cLoja
		SC6->C6_ENTREG   := DDataBase
		SC6->C6_TPOP     := 'F'
		SC6->(MsUnlock())
	next
	ConfirmSX8()
	FWAlertSuccess('Pedido gerado <b>'+cPed+'</b> com sucesso', 'Pedido gerado')

	FWRestArea(aArea)
return


Static Function ModelDef()
	Local oStruPai := FWFormStruct(1, cTabPai)
	Local oStruFilho := FWFormStruct(1, cTabFilho)
	Local oStruNeto := FWFormStruct(1, cTabNeto)
	Local aRelFilho := {}
	Local aRelNeto := {}
	Local oModel
	Local bPre := Nil
	Local bPos := Nil
	Local bCancel := Nil
	Local bCommit := nil
	Local bLinePos := nil
	local nAtual  := 0
	Local aGatilhos := {}
	//Local bLinePos := {|oMod| u_z13bLinP(oModel)}

	oStruFilho:SetProperty("ZD2_ORCAME", MODEL_FIELD_OBRIGAT, .F.)
	oStruNeto:SetProperty("ZD3_ORCAME", MODEL_FIELD_OBRIGAT, .F.)
	oStruNeto:SetProperty("ZD3_PRODUT", MODEL_FIELD_OBRIGAT, .F.)


	//oStruPai:SetProperty('ZD1_VLFRET', MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,     'u_bCalpes(3)'))
	//oStruFilho:SetProperty('ZD2_PBRUTO', MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,   'u_bCalpes(1)'))
	//oStruFilho:SetProperty('ZD2_VLUNIT', MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,   'u_bCalpes(2)'))


	oStruNeto:SetProperty('ZD3_QUANT', MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,   'u_atuqgrd(1)'))
	oStruNeto:SetProperty('ZD3_PESLIQ', MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,   'u_atuqgrd(2)'))


	//Adicionando um gatilho campo neto
	/*
	aAdd(aGatilhos, ;
		FWStruTriggger(;
		"ZD3_QUANT",;                                //Campo Origem
	"ZD3_PBLTOT",;                              //Campo Destino
	"u_zd3xd2(1)",;                              //Regra de Preenchimento
	.F.,;                                       //Irá Posicionar?
	"",;                                        //Alias de Posicionamento
	0,;                                         //Índice de Posicionamento
	'',;                                        //Chave de Posicionamento
	NIL,;                                       //Condição para execução do gatilho
	"01";                                       //Sequência do gatilho
	);
		)

	aAdd(aGatilhos, ;
		FWStruTriggger(;
		"ZD3_PESLIQ",;                                //Campo Origem
	"ZD3_PBLTOT",;                                //Campo Destino
	"u_zd3xd2(2)",;                              //Regra de Preenchimento
	.F.,;                                       //Irá Posicionar?
	"",;                                        //Alias de Posicionamento
	0,;                                         //Índice de Posicionamento
	'',;                                        //Chave de Posicionamento
	NIL,;                                       //Condição para execução do gatilho
	"01";                                       //Sequência do gatilho
	);
		)



	aAdd(aGatilhos, ;
		FWStruTriggger(;
		"ZD3_PBRUNI",;                                //Campo Origem
	"ZD3_VLITEM",;                                //Campo Destino
	"u__vlitpre()",;                              //Regra de Preenchimento
	.F.,;                                       //Irá Posicionar?
	"",;                                        //Alias de Posicionamento
	0,;                                         //Índice de Posicionamento
	'',;                                        //Chave de Posicionamento
	NIL,;                                       //Condição para execução do gatilho
	"01";                                       //Sequência do gatilho
	);
		)
		*/

	//Percorrendo os gatilhos e adicionando na Struct
	For nAtual := 1 To Len(aGatilhos)
		oStruNeto:AddTrigger(;
			aGatilhos[nAtual][01],; //Campo Origem
		aGatilhos[nAtual][02],; //Campo Destino
		aGatilhos[nAtual][03],; //Bloco de código na validação da execução do gatilho
		aGatilhos[nAtual][04];  //Bloco de código de execução do gatilho
		)
	Next

	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("b8_orcM", bPre, bPos, bCommit, bCancel)
	oModel:AddFields("ZD1MASTER", /*cOwner*/, oStruPai)
	oModel:AddGrid("ZD2DETAIL","ZD1MASTER",oStruFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
	oModel:AddGrid("ZD3DETAIL","ZD2DETAIL",oStruNeto,/*bLinePre*/, bLinePos,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
	oModel:SetDescription("Modelo de dados - " + cTitulo)
	oModel:GetModel("ZD1MASTER"):SetDescription( "Dados do Orcamento")
	oModel:GetModel("ZD2DETAIL"):SetDescription( "Dados das espessuras")
	oModel:GetModel("ZD3DETAIL"):SetDescription( "Itens")
	oModel:SetPrimaryKey({})

	//Fazendo o relacionamento (pai e filho)
	aAdd(aRelFilho, {"ZD2_FILIAL", "FWxFilial('ZD2')"} )
	aAdd(aRelFilho, {"ZD2_ORCAME", "ZD1_ORCAME"})
	oModel:SetRelation("ZD2DETAIL", aRelFilho, ZD2->(IndexKey(1)))

	//Fazendo o relacionamento (filho e neto)
	aAdd(aRelNeto, {"ZD3_FILIAL", "FWxFilial('ZD3')"} )
	aAdd(aRelNeto, {"ZD3_ORCAME", "ZD1_ORCAME"})
	aAdd(aRelNeto, {"ZD3_PRODUT", "ZD2_PRODUT"})
	oModel:SetRelation("ZD3DETAIL", aRelNeto, ZD3->(IndexKey(1)))

	oModel:GetModel("ZD2DETAIL"):SetOptional(.T.)
	oModel:GetModel("ZD3DETAIL"):SetOptional(.T.)

	oModel:GetModel("ZD1MASTER"):SetFldNoCopy( { 'ZD1_ORCAME' } )

Return oModel

Static Function ViewDef()
	Local oModel := FWLoadModel("b8_orc")

	local cCpoFat := "ZD1_TES|ZD1_VEND|ZD1_NATURE|ZD1_PEDIDO|ZD1_VEND|ZD1_COND|ZD1_OCCLI"

	Local oStructPrin := FWFormStruct(2, cTabPai, {|cCampo| !AllTrim(cCampo) $ cCpoFat})
	Local oStructFat  := FWFormStruct(2, cTabPai, {|cCampo| AllTrim(cCampo) $ cCpoFat})
	Local oStruFilho  := FWFormStruct(2, cTabFilho)
	Local oStruNeto   := FWFormStruct(2, cTabNeto)
	Local oView

	oStructPrin:SetNoFolder()
	oStructFat:SetNoFolder()

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField("VIEW_PRIN", oStructPrin, "ZD1MASTER")
	oView:AddField("VIEW_OBSE", oStructFat, "ZD1MASTER")
	oView:AddGrid("VIEW_ZD2",  oStruFilho,  "ZD2DETAIL")
	oView:AddGrid("VIEW_ZD3",  oStruNeto,  "ZD3DETAIL")
	oView:AddOtherObject("VIEW_OTHER", {|oPanel| fCustom(oPanel)})

	oView:CreateHorizontalBox("CABEC_PAI", 25)
	oView:CreateHorizontalBox("GRID_FILHO", 25)
	oView:CreateHorizontalBox("GRID_NETO", 40)
	oView:CreateHorizontalBox("RODAP", 10)

	//Cria o controle de Abas
	oView:CreateFolder('ABAS','CABEC_PAI')
	oView:AddSheet('ABAS', 'ABA_PRIN', 'Dados gerais')
	oView:AddSheet('ABAS', 'ABA_OBSE', 'Faturamento')

	oView:CreateHorizontalBox( 'BOX_PRIN' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_PRIN')
	oView:CreateHorizontalBox( 'BOX_OBSE' ,100, /*owner*/, /*lUsePixel*/, 'ABAS', 'ABA_OBSE')


	//oView:SetOwnerView("VIEW_ZD1", "CABEC_PAI")
	//Amarra as Abas aos Views de Struct criados
	oView:SetOwnerView('VIEW_PRIN','BOX_PRIN')
	oView:SetOwnerView('VIEW_OBSE','BOX_OBSE')
	oView:SetOwnerView("VIEW_ZD2", "GRID_FILHO")
	oView:SetOwnerView("VIEW_ZD3", "GRID_NETO")
	oView:SetOwnerView("VIEW_OTHER", "RODAP")

	//Titulos
	//oView:EnableTitleView("VIEW_ZD1", "Dados do Orcamento")
	//oView:EnableTitleView("VIEW_PRIN", "Dados do Orcamento")
	oView:EnableTitleView("VIEW_ZD2", "Dados das espessuras")
	oView:EnableTitleView("VIEW_ZD3", "Itens")

	//Removendo campos (filho)
	oStruFilho:RemoveField("ZD2_ORCAME")

	//removendo campos (neto)
	oStruNeto:RemoveField("ZD3_PRODUT")
	oStruNeto:RemoveField("ZD3_ORCAME")


	//Adicionando campo incremental na grid (filho)
	oView:AddIncrementField("VIEW_ZD2", "ZD2_ITEM")

	//Adicionando campo incremental na grid (neto)
	oView:AddIncrementField("VIEW_ZD3", "ZD3_ITEM")

	//oView:addUserButton("Importa Excel", "MAGIC_BMP", {|| u_ob_impex()}, , , , .T.)

	/* sem criar abas

	Local oModel := FWLoadModel("b8_orc")
	Local oStruPai := FWFormStruct(2, cTabPai)

	Local oStruFilho  := FWFormStruct(2, cTabFilho)
	Local oStruNeto   := FWFormStruct(2, cTabNeto)
	Local oView


	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZD1", oStruPai, "ZD1MASTER")
	oView:AddGrid("VIEW_ZD2",  oStruFilho,  "ZD2DETAIL")
	oView:AddGrid("VIEW_ZD3",  oStruNeto,  "ZD3DETAIL")
	oView:AddOtherObject("VIEW_OTHER", {|oPanel| fCustom(oPanel)})


	oView:CreateHorizontalBox("CABEC_PAI", 25)
	oView:CreateHorizontalBox("GRID_FILHO", 25)
	oView:CreateHorizontalBox("GRID_NETO", 40)
	oView:CreateHorizontalBox("RODAP", 10)

	//Amarra as Abas aos Views de Struct criados
	oView:SetOwnerView("VIEW_ZD1", "CABEC_PAI")	
	oView:SetOwnerView("VIEW_ZD2", "GRID_FILHO")
	oView:SetOwnerView("VIEW_ZD3", "GRID_NETO")
	oView:SetOwnerView("VIEW_OTHER", "RODAP")

	*/

Return oView


static function  bImpEx(oSay)

	Local _cNomeArq := ""
	local lPrim := .t.
	local cItFil    := '001'
	Private _cArquivo := ""
	Private _nLinhas  := 1
	private lcontinua := .t.

	oSay:SetText("Consultando dados...")
	if existe(ZD1->ZD1_ORCAME)
		if FWAlertNoYes("Deseja sobrescrever os dados desse orçamento <Não / Sim>", "Orcamento com itens ja cadastrados")
			AtSql :=" UPDATE ZD2010 SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
			AtSql +=" WHERE ZD2_ORCAME = "+ ZD1->ZD1_ORCAME
			TCSQLExec(AtSql)

			AtSql :=" UPDATE ZD3010 SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
			AtSql +=" WHERE ZD3_ORCAME = '"+ ZD1->ZD1_ORCAME+"'"
			TCSQLExec(AtSql)

		else
			lcontinua := .f.
		endif

	endif

	if lcontinua
		//Importando o Excel
		_cNomeArq := cGetFile('Arquivo CSV|*.csv','Todos os Drives',0,'',.T.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.T.)
		oSay:SetText("Processando  Arquivo...")
		_cArquivo := FWFileReader():New(_cNomeArq)

		if !empty(_cArquivo) .and. (_cArquivo:Open())
			while (_cArquivo:hasLine())
				_aCampos := Separa(_cArquivo:GetLine(),";",.T.)

				if '003' $ _aCampos[1] .or. '004' $ _aCampos[1]  // quando nao for produto

					IF lPrim .or. cProdBKP <> _aCampos[1]
						cItneto := '001'
						dbselectArea('ZD2')
						RecLock('ZD2', .t.)
						ZD2->ZD2_ITEM   := cItFil
						ZD2->ZD2_ORCAME := ZD1->ZD1_ORCAME
						ZD2->ZD2_PRODUT := _aCampos[1]
						ZD2->ZD2_PBRUTO := val(replace(_aCampos[8],',','.'))
						ZD2->ZD2_PLIQTO := val(replace(_aCampos[7],',','.'))
						ZD2->ZD2_VLUNIT := val(replace(Alltrim(strtran(_aCampos[10],'R$','')),',','.'))
						ZD2->(MsUnlock())

						lPrim := .f.
						cItFil := soma1(cItFil)
					endif

					dbselectArea('ZD3')
					RecLock('ZD3', .t.)
					ZD3->ZD3_ITEM   := cItneto
					ZD3->ZD3_ORCAME := ZD1->ZD1_ORCAME
					ZD3->ZD3_PRODUT := _aCampos[1]
					ZD3->ZD3_COD    := Alltrim( _aCampos[3])
					ZD3->ZD3_QUANT  :=  val(replace(_aCampos[4],',','.'))
					ZD3->ZD3_PESLIQ :=  val(replace(_aCampos[5],',','.'))
					ZD3->ZD3_PBLTOT :=  val(replace(_aCampos[6],',','.'))
					ZD3->ZD3_PBRUNI :=  val(replace(_aCampos[9],',','.'))
					ZD3->ZD3_VLITEM :=  val(replace(Alltrim(strtran(_aCampos[11],'R$','')),',','.'))
					ZD3->(MsUnlock())

					cItneto := soma1(cItneto)
					_nLinhas++
					cProdBKP := _aCampos[1]
				endif


			enddo
			_cArquivo:Close()
			if _nLinhas > 1
				FWAlertSuccess("Foram importadas " + alltrim(str(_nLinhas)) + " linhas.", "Importação concluida com sucesso")
			endif
		endif
	endif

return()

static funcTion existe(cOrc)

	local lret := .f.
	local _sQuery := "  SELECT * FROM ZD2010 WHERE D_E_L_E_T_ = '' AND ZD2_ORCAME = '"+cOrc+"'"

	TcQuery _sQuery NEW ALIAS "TRB"
	dbSelectArea("TRB")
	DbGoTop()
	do while !eof()
		lret := .T.
		DbSkip()
	enddo
	dbCloseArea()

	_sQuery := "  SELECT * FROM ZD3010 WHERE D_E_L_E_T_ = '' AND ZD3_ORCAME = '"+cOrc+"'"

	TcQuery _sQuery NEW ALIAS "TRB"
	dbSelectArea("TRB")
	DbGoTop()
	do while !eof()
		lret := .T.
		DbSkip()
	enddo
	dbCloseArea()



return (lret)


static  function  ob_impex_bck()

	Local _cNomeArq := ""

	Private  oModelPad  := FWModelActive()
	Private oModelGrid  := oModelPad:GetModel('ZD2DETAIL')
	private cProd       := ''

	Private _cArquivo := ""
	Private _nLinhas  := 1
	//Pegando posições do aHeader



	//Importando o Excel
	_cNomeArq := cGetFile('Arquivo CSV|*.csv','Todos os Drives',0,'',.T.,GETF_LOCALHARD+GETF_NETWORKDRIVE,.T.)
	_cArquivo := FWFileReader():New(_cNomeArq)
	if !empty(_cArquivo) .and. (_cArquivo:Open())
		while (_cArquivo:hasLine())
			_aCampos := Separa(_cArquivo:GetLine(),";",.T.)

			if '003' $ _aCampos[1] .or. '004' $ _aCampos[1]  // quando nao for produto
				if _nLinhas == 1
					nLin := _nLinhas

				else
					if oModelGrid:AddLine() == _nLinhas
						nLin := _nLinhas
					else
						FWAlertWarning("Ocorreu erro ao adicionar linha, verifica se todos os campos foram preenchidos.", "Não é possível importar")
						_cArquivo:Close()
						return()
					endif

				endif
				//Define a linha que será utilizada
				oModelGrid:nLine := nLin

				if cProd <> '' .and. cProd <>  right("0000000000"+alltrim(_aCampos[1]),11)
					oModelPad:SetValue('ZD2DETAIL', 'ZD2_PRODUT', right("0000000000"+alltrim(_aCampos[1]),11))
					oModelPad:SetValue('ZD2DETAIL', 'ZD2_PBRUTO', val(replace(_aCampos[8],',','.')))
					oModelPad:SetValue('ZD2DETAIL', 'ZD2_PLIQTO', val(replace(_aCampos[7],',','.')))
					oModelPad:SetValue('ZD2DETAIL', 'ZD2_VLUNIT', val(replace(_aCampos[10],',','.')))
				endif

				_nLinhas++
			endif
		enddo


		_cArquivo:Close()
		if _nLinhas > 1
			FWAlertSuccess("Foram importadas " + alltrim(str(_nLinhas)) + " linhas.", "Importação concluida com sucesso")
		endif
	endif
	oModelGrid:GoLine(1)

return()


Static Function fCustom(oPanel)
	Local aArea   := FWGetArea()

	//Fontes
	Local cFontPad    := "Tahoma"

	Local oFontSub    := TFont():New(cFontPad, , -20)

	oSayTot    := TSay():New(010, 215, {|| cSayTot }, oPanel, "", oFontSub, , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	@ 12, 350   MSGET oGeVtot    var TransForm(cGeVtot,"@E 999,999.99")    size 45, 12  OF oPanel PIXEL  when .f.
	@ 12, 120  BUTTON oBtn PROMPT '&Calcular'      SIZE 060, 015  OF oPanel PIXEL ACTION  (FWMsgRun(, {|oSay| u_bCalpes(oSay) }, "Processando", "Recalculando orcamento")) //  ( _bAtuTo())


	cCssBtn1 := "QPushButton { background: #35ACCA; border: 1px solid #096A82;outline:0; border-radius: 5px; font: normal 12px Arial; padding: 6px;color: #ffffff;} QPushButton:pressed {background-color: #3AAECB;border-style: inset; border-color: #35ACCA; color: #ffffff; }"


	oBtn:SetCss(cCssBtn1)


	FWRestArea(aArea)
Return


user function bCalpes(oSay)

	Local aArea    := FWGetArea()
	local nAux     := 0.00
	local nTotpl   := 0.00
	local nTotpb   := 0.00
	local nVal     := 0.00
	local nVlFret  := 0.00
	local nVlcfre  := 0.00
	local nLinFilho,nLinNeto:= 0
	local nPesBtot := 0.00
	local nlAtuFil,nlAtuNeto := 0
	local nCalFre

	Local oGriFil,oGridNeto,oGriPai := Nil

	local oModel := FWModelActive()
	Local oView	 := FwViewActive()

	cGeVtot := 0.00

	oGriPai   := oModel:GetModel("ZD1MASTER")
	oGriFil   := oModel:GetModel("ZD2DETAIL")
	oGridNeto := oModel:GetModel("ZD3DETAIL")

	nlAtuFil  := oGriFil:nLine
	nlAtuNeto := oGridNeto:nLine

	For nLinFilho := 1 To oGriFil:Length()
		oGriFil:GoLine(nLinFilho)
		If !oGriFil:IsDeleted()
			//pego o peso bruto total de todos os itens (A)
			nPesBtot+= oGriFil:GetValue('ZD2_PBRUTO')
		EndIf
	Next nLinFilho

	//pego o vaLor do frete do orçamento (B)
	nCalFre:= oGriPai:GetValue('ZD1_CALFRE')

	IF nCalFre == '1'
		nVlFret:= oGriPai:GetValue('ZD1_VLFRET')
	endif


	For nLinFilho := 1 To oGriFil:Length()
		oGriFil:GoLine(nLinFilho)
		If !oGriFil:IsDeleted()
			//valor do peso liquido total (C)
			nTotpl := oGriFil:GetValue('ZD2_PLIQTO')


			//pego o peso bruto total da espessura (D) e o valor unitario da espessura(E)
			nVal   := oGriFil:GetValue('ZD2_VLUNIT')
			nTotpb := oGriFil:GetValue('ZD2_PBRUTO')

			For nLinNeto:= 1 To oGridNeto:Length()
				oGridNeto:GoLine(nLinNeto)
				If !oGridNeto:IsDeleted()
					// ZD3_PBLTOT é o peso total do item (F) entao o valor unitario é F / C * E
					nAux := oGridNeto:GetValue('ZD3_PBLTOT') / nTotpl * nTotpb
					oGridNeto:SetValue("ZD3_PBRUNI", nAux )
					//O valor do item é F * D
					oGridNeto:SetValue("ZD3_VLITEM", nAux  * nVal)

					/*quando tem frete eu pego o valor total do frete dividido pelo total do peso bruto
					multiplico pelo peso bruto unitario e somo com valor lembrando que o valor é o
					peso bruto unitario * o valor
					*/

					//quando tem frete o valor da mesma pode ser somado entao aos itens de cada espessura
					// ( frete do orçamento (B)  / peso bruto total de todos os itens (A) * peso total do item (F) ) + ( peso total do item (F) * O valor do item (D))
					// (B / A * F ) + (F * D)
					nVlcfre := ((nVlFret / nPesBtot) * nAux ) + (nAux  * nVal)

					//oGridNeto:SetValue("ZD3_VLITEM", nAux  * nVal)
					oGridNeto:SetValue("ZD3_VLITEM", nVlcfre)
					cGeVtot  += nVlcfre

					oView:Refresh()
				endif
			Next nLinNeto
		endif
	Next nLinFilho

	oGriFil:GoLine(nlAtuFil)
	oGridNeto:GoLine(nlAtuNeto)
	oGeVtot:Refresh()
	oView:Refresh()

	FWRestArea(aArea)

return(.t.)

User Function zd3xd2(nOp)
	Local aArea    := FWGetArea()
	Local nRetorno := 0.00
	local nVal     := 0.00

	local oModel := FWModelActive()
	oGridNeto := oModel:GetModel("ZD3DETAIL")

	if nOp == 1
		nVal:= oGridNeto:GetValue('ZD3_PESLIQ')
		nRetorno := M->ZD3_QUANT * nVal
	else
		nVal:= oGridNeto:GetValue('ZD3_QUANT')
		nRetorno := nVal * M->ZD3_PESLIQ
	endif

	FWRestArea(aArea)
Return nRetorno


user function atuqgrd(nOp)

	local _nx
	Local aArea        := FWGetArea()
	local nQuant       := 0.00
	local nPliq        := 0.00
	local _nLinhaAtu   := 0
	local nPliqTot     := 0.0
	local nVal         := 0.00
	local nVlFret      := 0.00
	local nVlcfre      := 0.00
	local nLinFilho    := 0
	local nPesBtot     := 0.00

	Local oGriFil,oGridNeto,oGriPai := Nil

	local oModel := FWModelActive()
	Local oView	 := FwViewActive()

	oGriPai   := oModel:GetModel("ZD1MASTER")
	oGriFil   := oModel:GetModel("ZD2DETAIL")
	oGridNeto := oModel:GetModel("ZD3DETAIL")

	nlAtuFil  := oGriFil:nLine
	For nLinFilho := 1 To oGriFil:Length()
		oGriFil:GoLine(nLinFilho)
		If !oGriFil:IsDeleted()
			nPesBtot+= oGriFil:GetValue('ZD2_PBRUTO')
		EndIf
	Next nLinFilho


	oGriFil:GoLine(nlAtuFil)


	nVlFret:= oGriPai:GetValue('ZD1_VLFRET')

	_nLinhaAtu := oGridNeto:nLine

	if nOp == 1
		nQuant :=  M->ZD3_QUANT
		nPliq  :=  oGridNeto:GetValue('ZD3_PESLIQ')
	else
		nQuant :=  oGridNeto:GetValue('ZD3_QUANT')
		nPliq  :=  M->ZD3_PESLIQ
	endif

	nVal   := oGriFil:GetValue('ZD2_VLUNIT')

	oGridNeto:SetValue("ZD3_PBLTOT", nPliq *  nQuant )


	For _nx:= 1 To oGridNeto:Length()
		oGridNeto:GoLine(_nx)
		If !oGridNeto:IsDeleted()
			nPliqTot +=  oGridNeto:GetValue('ZD3_PBLTOT')
		endif
	Next

	oGriFil:SetValue("ZD2_PLIQTO", nPliqTot )

	nPBruIt:= oGriFil:GetValue('ZD2_PBRUTO')


	For _nx:= 1 To oGridNeto:Length()
		oGridNeto:GoLine(_nx)
		If !oGridNeto:IsDeleted()
			nAux := oGridNeto:GetValue('ZD3_PBLTOT') / nPliqTot * nPBruIt
			oGridNeto:SetValue("ZD3_PBRUNI", nAux )

			/*quando tem frete eu pego o valor total do frete dividido pelo total do peso bruto
			multiplico pelo peso bruto unitario e somo com valor lembrando que o valor é o
			peso bruto unitario * o valor do item
			*/

			nVlcfre := ((nVlFret / nPesBtot) * nAux ) + (nAux  * nVal)


			//oGridNeto:SetValue("ZD3_VLITEM", nAux  * nVal)
			oGridNeto:SetValue("ZD3_VLITEM", nVlcfre)
			//oView:Refresh()
		endif
	Next


	oGridNeto:GoLine(1)
	oView:Refresh()
	oGridNeto:GoLine(_nLinhaAtu)
	oView:Refresh()

	FWRestArea(aArea)


return(.t.)


static function veEst(cCod)
	local cCodNew := cCod

	cQry := " SELECT  G1_COD FROM SG1010 WHERE D_E_L_E_T_ = '' AND G1_COMP = '"+cCod+"' AND G1_FIM >= '"+DTOS(DDATABASE)+"'"

	TCQUERY cQry NEW ALIAS "TRBS"


	dbSelectArea('TRBS')
	dbgotop()
	While !eof()
		cCodNew := TRBS->G1_COD
		dbskip()
	Enddo
	TRBS->(DbCloseArea())
return(cCodNew)

/*
User Function M410LIOK()
	Local nPosProd  := Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_PRODUTO" })
	local nPosItem  := Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_ITEM" })

	private  _sTexto := "["+Substr(Time(),1,2)+":"+Substr(Time(),4,2)+"]  Item: " + acols[n][nPosItem] +" Produto: "+ acols[n][nPosProd]
	msgalert(_sTexto,"atenção")

Return .t.
/*
