#Include "Totvs.ch"
#Include "FWMVCDef.ch"
#Include 'Protheus.ch'
#Include "TOPCONN.CH"
#include "TBICONN.CH"

user function OB_CRM()

	Local oBrowse
	Local cQrZD4	:= ''
	Local cQrZD5	:= ''

	//1=Aberto;2=Efetuado;3=Perdido;4=Com Atividades;5=Com Atividades Vencidas;6=CANCELADA
	cQrZD4 := "UPDATE " + RetSqlName('ZD4') 
	cQrZD4 += CRLF + "SET ZD4_STATUS = CASE WHEN FIMATRAZADO > 0 THEN '5' ELSE "
	cQrZD4 += CRLF + "CASE WHEN ABERTAS > 0 THEN '4' ELSE '1' END END"
	
	cQrZD4 += CRLF + "FROM ("
	cQrZD4 += CRLF + "SELECT ZD4_FILIAL FILIAL, ZD4_CODCRM CODCRM, "
	
	cQrZD4 += CRLF + "(SELECT COUNT(*)"
	cQrZD4 += CRLF + "FROM " + RetSqlName('ZD5') + " ZD5 (NOLOCK)"
	cQrZD4 += CRLF + "WHERE ZD5_FILIAL		= ZD4_FILIAL"
	cQrZD4 += CRLF + "AND ZD5_CODCRM		= ZD5_CODCRM"
	cQrZD4 += CRLF + "AND ZD5_DTINI			= ''"
	cQrZD4 += CRLF + "AND ZD5_DTFIM			= ''"
	cQrZD4 += CRLF + "AND ZD5_DTCANC		= ''"
	cQrZD4 += CRLF + "AND ZD5.D_E_L_E_T_	= ' ') ABERTAS," 

	cQrZD4 += CRLF + "(SELECT COUNT(*) "
	cQrZD4 += CRLF + "FROM " + RetSqlName('ZD5') + " ZD5 (NOLOCK)"
	cQrZD4 += CRLF + "WHERE ZD5_FILIAL		= ZD4_FILIAL"
	cQrZD4 += CRLF + "AND ZD5_CODCRM		= ZD5_CODCRM"
	cQrZD4 += CRLF + "AND ZD5_DTINI			>= ZD5_PRVINI"
	cQrZD4 += CRLF + "AND ZD5_DTFIM			<> ''"
	cQrZD4 += CRLF + "AND ZD5_DTCANC		= ''"
	cQrZD4 += CRLF + "AND ZD5.D_E_L_E_T_	= ' ') INICIOATRAZADO,"
	
	cQrZD4 += CRLF + "(SELECT COUNT(*)"
	cQrZD4 += CRLF + "FROM " + RetSqlName('ZD5') + " ZD5 (NOLOCK)"
	cQrZD4 += CRLF + "WHERE ZD5_FILIAL		= ZD4_FILIAL"
	cQrZD4 += CRLF + "AND ZD5_CODCRM		= ZD5_CODCRM"
	cQrZD4 += CRLF + "AND ZD5_DTFIM			= ''"
	cQrZD4 += CRLF + "AND ZD5_PRVFIM		< '" + dtos(date()) + "'"
	cQrZD4 += CRLF + "AND ZD5_DTCANC		= ''"
	cQrZD4 += CRLF + "AND ZD5.D_E_L_E_T_	= ' ') FIMATRAZADO" 

	cQrZD4 += CRLF + "FROM " + RetSqlName('ZD4') + " ZD4 (NOLOCK)"
	cQrZD4 += CRLF + "WHERE ZD4_STATUS		IN ('4','5')"
	cQrZD4 += CRLF + "AND ZD4.D_E_L_E_T_	= ' ') A"

	cQrZD4 += CRLF + "WHERE ZD4_FILIAL		= FILIAL"
	cQrZD4 += CRLF + "AND ZD4_CODCRM		= CODCRM"
	cQrZD4 += CRLF + "AND D_E_L_E_T_	= ' '"

	//	1=Aguardando Início;2=Em Andamento;3=Atrasada;4=Concluída;5=Cancelada                                                           
	cQrZD5 := CRLF + "UPDATE " + RetSqlName('ZD5') 
	cQrZD5 += CRLF + "SET ZD5_STATUS = "
	cQrZD5 += CRLF + "CASE WHEN ZD5_DTCANC <> ' ' THEN '7' ELSE"
	cQrZD5 += CRLF + "CASE WHEN ZD5_DTFIM <> ' ' AND ZD5_DTFIM > ZD5_PRVFIM THEN '6' ELSE"
	cQrZD5 += CRLF + "CASE WHEN ZD5_DTFIM <> ' ' AND ZD5_DTFIM <= ZD5_PRVFIM THEN '5' ELSE"
	cQrZD5 += CRLF + "CASE WHEN ZD5_DTFIM = ' ' AND ZD5_DTINI <> ' ' AND ZD5_PRVFIM > '" + DTOS(date()) + "' THEN '4' ELSE"
	cQrZD5 += CRLF + "CASE WHEN ZD5_DTFIM = ' ' AND ZD5_DTINI <> ' ' AND ZD5_PRVFIM <= '" + DTOS(date()) + "' THEN '3' ELSE"
	cQrZD5 += CRLF + "CASE WHEN ZD5_DTFIM = ' ' AND ZD5_DTINI = ' ' AND ZD5_PRVINI > '" + DTOS(date()) + "' THEN '2' ELSE"
	cQrZD5 += CRLF + "CASE WHEN ZD5_DTFIM = ' ' AND ZD5_DTINI = ' ' AND ZD5_PRVINI <= '" + DTOS(date()) + "' THEN '1' ELSE '1' END END END END END END END"
	cQrZD5 += CRLF + "WHERE D_E_L_E_T_ = ' '"

	//MsAguarde({|| TcSqlExec(cQrZD4 + cQrZD5)},'Atualizando status...')
	nret := TcSqlExec(cQrZD4 + cQrZD5)
	
	Private aRotina := {}

	//Definicao do menu
	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('ZD4')
	oBrowse:SetDescription("CRM")
	oBrowse:DisableDetails()

	//1=Aberto;2=Efetuado;3=Perdido;4=Com Atividades;5=Com Atividades Vencidas;6=CANCELADA
	oBrowse:AddLegend( "ZD4->ZD4_STATUS == '1'", "Green",	"Aberto" )
	oBrowse:AddLegend( "ZD4->ZD4_STATUS == '2'", "Blue",	"Efetuado" )
	oBrowse:AddLegend( "ZD4->ZD4_STATUS == '3'", "Black",	"Perdido" )
	oBrowse:AddLegend( "ZD4->ZD4_STATUS == '4'", "Yellow",	"Com Atividades" )
	oBrowse:AddLegend( "ZD4->ZD4_STATUS == '5'", "Red",		"Atividades Vencidas" )
	oBrowse:AddLegend( "ZD4->ZD4_STATUS == '6'", "Gray",	"Canceladas" )
   
	//Ativa a Browse
	oBrowse:Activate()

Return()

Static Function MenuDef()

	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar"	ACTION "VIEWDEF.OB_CRM"		OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"		ACTION "VIEWDEF.OB_CRM"		OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"		ACTION "U_CRMOPER('ALT')"	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"		ACTION "U_CRMOPER('EXC')"	OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Copiar"		ACTION "VIEWDEF.OB_CRM"		OPERATION 9 ACCESS 0
	ADD OPTION aRotina TITLE "Cancelar"		ACTION "U_CRMOPER('CANC')"	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Reativar"		ACTION "U_CRMOPER('REAT')"	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Efetivar"		ACTION "U_CRMOPER('EFET')"	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Perder"		ACTION "U_CRMOPER('PER)"	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Documentos"	ACTION "MSDOCUMENT"			OPERATION 4 ACCESS 0

Return(aRotina)

User Function CRMDOCS()
MsDocument('ZD4', 0, 4)
Return()

User Function CRMOPER(cOper)

	Local nRet			:= 0
	Local aStatus		:= {'ABE','EFET','PER','ATV','ATR','CANC','ALT','REAT','EXC'}
	Local aTitulos		:= {'ABE','Efetivacao','Perda','ATV','ATR','Cancelamento','Alteracao','Reativacao','Exclusão'}
	Local aStatAtu		:= {'Aberta','Efetivada','Perdida','Com atividades','Com atividades atrasadas','Cancelada'}
	Local nStatus		:= aScan(aStatus,cOper)
	Local cStatus		:= str(nStatus,1)
	Local cQuery		:= ''
	Local cAlias		:= GetNextAlias()
	Local nAtrasadas	:= 0
	Local nAbertas		:= 0

	PutGlbValue('cOperCRM', cOper)

	If cOper == 'EXC' .and. (ZD4->ZD4_STATUS $'23456' .or. ZD5->ZD5_FILIAL + ZD5->ZD5_CODCRM == ZD4->ZD4_FILIAL + ZD4->ZD4_CODCRM)
		cQuery := 'O CRM encontra-se no status de ' + aStatAtu[val(ZD4->ZD4_STATUS)]
		If ZD5->ZD5_FILIAL + ZD5->ZD5_CODCRM == ZD4->ZD4_FILIAL + ZD4->ZD4_CODCRM
			cQuery += CRLF + 'e possui atividade(s) j?adastrada(s)'
		EndIf
		MsgInfo(cQuery + '.','Exclus?n?permitida!!!')
		Return(nRet)
	EndIf

	If ZD4->ZD4_STATUS $'2356'
		If !MsgYesNo('O CRM encontra-se no status de ' + aStatAtu[val(ZD4->ZD4_STATUS)] + '.' + CRLF + CRLF + 'Deseja alterar?')
			Return(nRet)
		EndIf
	EndIf

	nRet := FwExecView(aTitulos[nStatus] + " de CRM" , "OB_CRM", 4, , {|| .t.}) //, ,  , , , oModel )

	PutGlbValue('cOperCRM','')

	If nRet == 0

		cQuery := "SELECT ZD4_FILIAL FILIAL, ZD4_CODCRM CODCRM, "
		
		cQuery += CRLF + "(SELECT COUNT(*) "
		cQuery += CRLF + "FROM " + RetSqlName('ZD5') + " ZD5 (NOLOCK)"
		cQuery += CRLF + "WHERE ZD5_FILIAL		= ZD4_FILIAL"
		cQuery += CRLF + "AND ZD5_CODCRM		= ZD5_CODCRM"
		cQuery += CRLF + "AND ZD5_DTINI			<> ' '"
		cQuery += CRLF + "AND ZD5_DTFIM			= ' '"
		cQuery += CRLF + "AND ZD5_PRVFIM		< '" + dtos(date()) + "'"
		cQuery += CRLF + "AND ZD5_DTCANC		= ' '"
		cQuery += CRLF + "AND ZD5.D_E_L_E_T_	= ' ') ATRASADAS," 

		cQuery += CRLF + "(SELECT COUNT(*) ABERTAS"
		cQuery += CRLF + "FROM " + RetSqlName('ZD5') + " ZD5 (NOLOCK)"
		cQuery += CRLF + "WHERE ZD5_FILIAL		= ZD4_FILIAL"
		cQuery += CRLF + "AND ZD5_CODCRM		= ZD5_CODCRM"
		cQuery += CRLF + "AND ZD5_DTINI			= ' '"
		cQuery += CRLF + "AND ZD5_DTFIM			= ' '"
		cQuery += CRLF + "AND ZD5_DTCANC		= ' '"
		cQuery += CRLF + "AND ZD5.D_E_L_E_T_	= ' ') ABERTAS"
		
		cQuery += CRLF + "FROM " + RetSqlName('ZD4') + " ZD4 (NOLOCK)"
		//1=Aberto;2=Efetuado;3=Perdido;4=Com Atividades;5=Com Atividades Vencidas;6=CANCELADA
		cQuery += CRLF + "WHERE ZD4_FILIAL		= '" + ZD4->ZD4_FILIAL  + "'"
		cQuery += CRLF + "AND ZD4_CODCRM		= '" + ZD4->ZD4_CODCRM  + "'"
		cQuery += CRLF + "AND ZD4.D_E_L_E_T_	= ' '"
		DbUseArea(.T.,"TOPCONN", TcGenQry(,,cQuery),cAlias,.T.,.F.)
		nAtrasadas	:= (cAlias)->ATRASADAS
		nAbertas 	:= (cAlias)->ABERTAS
		(cAlias)->(DbCloseArea())

		RecLock('ZD4',.f.)
		ZD4->ZD4_USALT 	:= upper(UsrFullName())
		ZD4->ZD4_DTALT 	:= Date()
		If cOPer $ 'CANC/EFET/PER'
			ZD4->ZD4_STATUS := cStatus
		ElseIf nAtrasadas > 0
			ZD4->ZD4_STATUS :=  '5'	// atrasado
		ElseIf nAbertas > 0
			ZD4->ZD4_STATUS :=  '4'	// com atividades
		Else
			ZD4->ZD4_STATUS :=  '1'	// aberta
		EndIf
		MsUnLock()

	EndIf

Return(nRet)



Static Function ModelDef()

	Local oStruCRM	:= FWFormStruct(1, 'ZD4')
	Local oStruAtv	:= FWFormStruct(1, 'ZD5')
	Local aRelCRM	:= {}
	
	Local oModel
	Local bPre			:= Nil
	Local bPos			:= Nil
	Local bCancel		:= Nil
	Local bCommit		:= nil
	Local bLinePos		:= {|| fCRMVlLin()}
	Local aCores 		:= {}
	Local bLegenda 		:= {||iif(ZD5->ZD5_STATUS $ '1234567', aCores[val(ZD5->ZD5_STATUS)],'BR_BRANCO')}

//	1=Aguardando In?o;2=In?io Atrasado;3=Em Andamento;4=Atrasada;5=Conclu?;6=Conclu? com Atraso;7=Cancelada                                                           

	aAdd(aCores, 'BR_AMARELO')
	aAdd(aCores, 'BR_AZUL')
	aAdd(aCores, 'BR_VERDE')
	aAdd(aCores, 'BR_VERMELHO')
	aAdd(aCores, 'BR_CINZA')
	aAdd(aCores, 'BR_LARANJA')
	aAdd(aCores, 'BR_PRETO')
	
	oStruAtv:AddField( ;
    '',;					// [01] C Titulo do campo
    '',;					// [02] C ToolTip do campo
    'ZD4_LEGEND',;			// [03] C identificador (ID) do Field
    'C',;					// [04] C Tipo do campo
    50,;					// [05] N Tamanho do campo
    0,;						// [06] N Decimal do campo
    NIL,;					// [07] B Code-block de valida? do campo
    NIL,;					// [08] B Code-block de valida? When do campo
    NIL,;					// [09] A Lista de valores permitido do campo
    NIL,;					// [10] L Indica se o campo tem preenchimento obrigat??
    bLegenda,;				// [11] B Code-block de inicializacao do campo
    NIL,;					// [12] L Indica se trata de um campo chave
    NIL,;					// [13] L Indica se o campo pode receber valor em uma opera? de update.
    .T.)					// [14] L Indica se o campo ?irtual 

	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("MOB_CRM", bPre, bPos, bCommit, bCancel)
	oModel:AddFields("ZD4CRM", /*cOwner*/, oStruCRM)

	oModel:AddGrid("ZD5ATV","ZD4CRM",oStruAtv,/*bLinePre*/, bLinePos,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
		
	//Fazendo o relacionamento CRM/ATIVIDADES
	aAdd(aRelCRM, {"ZD5_FILIAL", "FWxFilial('ZD5')"} )
	aAdd(aRelCRM, {"ZD5_CODCRM", "ZD4_CODCRM"})
	oModel:SetRelation("ZD5ATV", aRelCRM, ZD5->(IndexKey(1)))

    oModel:SetPrimaryKey({})
    oModel:SetDescription("CRM")
	oModel:GetModel("ZD4CRM"):SetDescription( "CRM")
	oModel:GetModel("ZD5ATV"):SetDescription( "Atividades CRM")
	oModel:GetModel("ZD5ATV"):SetOptional(.T.)

	oModel:GetModel("ZD4CRM"):SetFldNoCopy( { 'ZD4_CODCRM' } )

Return(oModel)

Static Function fCRMVlLin()
Local lRet := .t.
Local oModel := FwModelActive()

oModel:LoadValue('ZD5ATV','ZD5_USRALT',upper(UsrFullName()))
oModel:LoadValue('ZD5ATV','ZD5_DTALT', date())

Return(lRet)

User Function CRMValCp(cCampo)

Local lRet 		:= .t.
Local xCampo 	:= Nil
Local oModel 	:= FwModelActive()
Local oModelZD5	:= oModel:GetModel('ZD5ATV')
Local cErroMsg	:= ''

Default cCampo 	:= ReadVar()
cCampo := upper(replace(cCampo,'M->',''))
xCampo := FwFldGet(cCampo)

If cCampo == 'ZD5_DTINI' 
	If empty(xCampo)
		oModelZD5:LoadValue(cCampo,Date())
		xCampo := oModelZD5:GetValue(cCampo)
	EndIf
	If xCampo < date()
		cErroMsg := 'Data de Inicio nao pode ser menor que a data de hoje'
		lRet := .f.
	EndIf
ElseIf cCampo == 'ZD5_PRVINI' .and. FwFldGet(cCampo) < date()
	cErroMsg := 'Data de Previsao inicio nao pode ser menor que a data de hoje'
	lRet := .f.
ElseIf cCampo == 'ZD5_PRVFIM' .and. FwFldGet(cCampo) < date()
	cErroMsg := 'Data previsao conclusao nao ser menor que a data de hoje'
	lRet := .f.
ElseIf cCampo == 'ZD5_DTFIM' 	
	If empty(xCampo)
		oModelZD5:LoadValue(cCampo,Date())
		xCampo := oModelZD5:GetValue(cCampo)
	EndIf
	If FwFldGet(cCampo) > date()
		cErroMsg := 'Data de conclusao nao ser maior que a data de hoje'
		lRet := .f.
	EndIf
ElseIf cCampo == 'ZD5_DTCANC' 
	If empty(xCampo)
		oModelZD5:LoadValue(cCampo,Date())
		xCampo := oModelZD5:GetValue(cCampo)
	EndIf
	If FwFldGet(cCampo) > date()
		cErroMsg := 'Data de cancelamento nao pode ser menor que a data de hoje'
		lRet := .f.
	EndIf
EndIf

If !lRet
	oModel:SetErrorMessage("OB_CRM",cCampo ,"OB_CRM",cCampo,FwX3Titulo(cCampo),cErroMsg,"Um erro foi identificado")
EndIf

Return(lRet)

Static Function ViewDef()

	Local oModel 	:= FWLoadModel("OB_CRM")
	Local oStruCRM	:= FWFormStruct(2, 'ZD4')
	Local oStruAtv	:= FWFormStruct(2, 'ZD5')
	Local oView


    oStruAtv:AddField( ;		// Ord. Tipo Desc.
        'ZD4_LEGEND',;			// [01] C   Nome do Campo
        "00",;					// [02] C   Ordem
        AllTrim(''),;			// [03] C   Titulo do campo
        AllTrim(''),;			// [04] C   Descricao do campo
        {'Legenda' },;			// [05] A   Array com Help
        'C',;					// [06] C   Tipo do campo
        '@BMP',;				// [07] C   Picture
        NIL,;					// [08] B   Bloco de Picture Var
        '', ;					// [09] C   Consulta F3
        .T.,;					// [10] L   Indica se o campo ?lteravel
        NIL,;					// [11] C   Pasta do campo
        NIL,;					// [12] C   Agrupamento do campo
        NIL,;					// [13] A   Lista de valores permitido do campo (Combo)
        NIL,;					// [14] N   Tamanho maximo da maior op? do combo
        NIL,;					// [15] C   Inicializador de Browse
        .T.,;					// [16] L   Indica se o campo ?irtual
        NIL,;					// [17] C   Picture Variavel
        NIL) 

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField("VIEW_ZD4", oStruCRM	, "ZD4CRM")
	oView:AddGrid("VIEW_ZD5" , oStruAtv	, "ZD5ATV")

	oView:CreateHorizontalBox("CABEC_CRM",  75)
	oView:CreateHorizontalBox("GRID_ATV"	, 25)

	//Amarra as Abas aos Views de Struct criados
	oView:SetOwnerView('VIEW_ZD4', "CABEC_CRM")
	oView:SetOwnerView('VIEW_ZD5', "GRID_ATV")

	//Removendo campos
	oStruAtv:RemoveField("ZD5_FILENT")
	oStruAtv:RemoveField("ZD5_ENTIDA")
	oStruAtv:RemoveField("ZD5_CODCRM")

Return(oView)

User Function CRMStatus(dCanc, dPrvIni, dDtIni, dPrvFim, dDtFim)
Local cStatus := ''
//	1=Aguardando In?o;2=In?io Atrasado;3=Em Andamento;4=Atrasada;5=Conclu?;6=Conclu? com Atraso;7=Cancelada                                                           

If !empty(dCanc)
	cStatus := '7'
ElseIf !empty(dDtFim) .and. dDtFim > dPrvFim 
	cStatus := '6'
ElseIf !empty(dDtFim) .and. dDtFim <= dPrvFim 
	cStatus := '5'
ElseIf empty(dDtFim) .and. !empty(dDtIni) .and. dPrvFim <= date() 
	cStatus := '4'
ElseIf empty(dDtFim) .and. !empty(dDtIni) .and. dPrvFim > date() 
	cStatus := '3'
ElseIf empty(dDtFim) .and. empty(dDtIni) .and. dPrvIni < date() 
	cStatus := '2'
ElseIf empty(dDtFim) .and. empty(dDtIni) .and. dPrvIni >= date() 
	cStatus := '1'
EndIf

Return(cStatus)


User Function fCRMWhen(cCampo, lEmpty, cOper)

Local cOperCRM 	:= GetGlbValue('cOperCRM') 
Local lRet 		:= alltrim(cOperCRM) $ alltrim(cOPer)

If !empty(cCampo)
	 cCampo := FwFldGet(cCampo)
	lRet := (lEmpty .and. empty(cCampo)) .or. (!lEmpty .and. !empty(cCampo))
EndIf

/*
U_fCRMWhen('',.f.,'')					empty(GetGlbValue('cOperCRM'))	
U_fCRMWhen('',.f.,'CANC/PERD')			GetGlbValue('cOperCRM') $ 'CANC/PERD'
U_fCRMWhen('ZD5_PRVINI',.F.,'ALT')		GetGlbValue('cOperCRM') == 'ALT' .and. !empty(FwFldGet('ZD5_PRVINI'))
U_fCRMWhen('ZD5_DTFIM',.T.,'ALT')		GetGlbValue('cOperCRM') == 'ALT'.and. empty(FwFldGet('ZD5_DTFIM'))
U_fCRMWhen('ZD5_PRVFIM',.F.,'ALT')		GetGlbValue('cOperCRM') == 'ALT' .and. !empty(FwFldGet('ZD5_PRVFIM'))
U_fCRMWhen('ZD5_DTFIM',.T.,'ALT')		GetGlbValue('cOperCRM') == 'ALT' .and. empty(FwFldGet('ZD5_DTFIM'))
U_fCRMWhen('',.F.,'ALT')				GetGlbValue('cOperCRM') == 'ALT'
U_fCRMWhen('ZD5_DTINI',.T.,'ALT')		GetGlbValue('cOperCRM') == 'ALT' .and. empty(FwFldGet('ZD5_DTINI'))
*/

Return(lRet)
