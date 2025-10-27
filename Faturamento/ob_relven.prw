#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA    Chr(13)+Chr(10)

User Function ob_relven()

	ValidPerg()

return

Static Function RunMessage(oSay)

	Local oExcel := FWMsExcel():New()
	//Local cArquivo := GetTempPath()+'RTCVTEA.xml'  
	local cArquivo := '\1arqtrab\RTCVTEA.xml'  

	Private cPath   := AllTrim(GetTempPath())

	QryCOMPANT(oExcel)
	QryVTOTA(oExcel)
	QryCOMPATU(oExcel)

	//Criando o XML
	oExcel:Activate()
	oExcel:GetXMLFile(cArquivo)

	//Abrindo o excel e abrindo o arquivo xml

	oExcel := MsExcel():New()
	oExcel:WorkBooks:Open(cArquivo)
	oExcel:SetVisible(.T.)
	oExcel:Destroy()

	//C:\Program Files\LibreOffice\program\scalc.exe



Return

Static Function QryCOMPANT(oExcel)

	Local cQuery := ""
	Local cPlano := "Vendas Antigas"
	Local cTitulo := " "
	Local nB := 0
	Local _aColunas := {"Codigo","Loja","Nome","Data Ultima Compra","Valor Total Comprado"}
	Private _aDados := {}

	cQuery := "SELECT "+STR_PULA
	cQuery += "    A1.A1_COD AS Codigo,"+STR_PULA
	cQuery += "    A1.A1_LOJA AS Loja,"+STR_PULA
	cQuery += "    A1.A1_NOME AS Nome,"+STR_PULA
	cQuery += "    UltimaCompra.DataUltimaCompra,"+STR_PULA
	cQuery += "    CAST(ISNULL(TotalComprado.ValorTotal, 0) AS NUMERIC(18,2)) AS ValorTotalComprado"+STR_PULA
	cQuery += "FROM "+STR_PULA
	cQuery += "     "+RetSQLName('SA1')+" A1"+STR_PULA
	cQuery += "OUTER APPLY ("+STR_PULA
	cQuery += "    SELECT MAX(F2.F2_EMISSAO) AS DataUltimaCompra"+STR_PULA
	cQuery += "    FROM "+RetSQLName('SF2')+" F2"+STR_PULA
	cQuery += "    WHERE F2.F2_CLIENTE = A1.A1_COD"+STR_PULA
	cQuery += "      AND F2.F2_LOJA = A1.A1_LOJA"+STR_PULA
	cQuery += "      AND F2.D_E_L_E_T_ = ''"+STR_PULA
	cQuery += ") AS UltimaCompra"+STR_PULA
	cQuery += "OUTER APPLY ("+STR_PULA
	cQuery += "    SELECT SUM(ISNULL(E1.E1_VALOR, 0)) AS ValorTotal"+STR_PULA
	cQuery += "    FROM "+RetSQLName('SE1')+" E1"+STR_PULA
	cQuery += "    WHERE E1.E1_CLIENTE = A1.A1_COD"+STR_PULA
	cQuery += "      AND E1.E1_LOJA = A1.A1_LOJA"+STR_PULA

	IF ALLTRIM(MV_PAR02) <> ''
		cQuery += "		 AND E1.E1_TIPO IN "+FormatIn(alltrim(MV_PAR02),',')+STR_PULA
	ENDIF
	IF ALLTRIM(MV_PAR03) <> ''
		cQuery += "		 AND E1.E1_TIPO NOT IN "+FormatIn(alltrim(MV_PAR03),',')+STR_PULA
	ENDIF

	cQuery += "      AND E1.D_E_L_E_T_ = ''"+STR_PULA
	cQuery += ") AS TotalComprado"+STR_PULA
	cQuery += "WHERE "+STR_PULA
	cQuery += "    A1.D_E_L_E_T_ = ''"+STR_PULA
	cQuery += "    AND UltimaCompra.DataUltimaCompra IS NOT NULL"+STR_PULA
	cQuery += "    AND A1.A1_COD NOT IN ("+STR_PULA
	cQuery += "        SELECT F2_CLIENTE "+STR_PULA
	cQuery += "        FROM "+RetSQLName('SF2')+STR_PULA
	cQuery += "        WHERE F2_EMISSAO >= '"+DtoS(MV_PAR01)+"'"+STR_PULA
	cQuery += "          AND D_E_L_E_T_ = ''"+STR_PULA
	cQuery += "    )"+STR_PULA
	cQuery += "	AND ValorTotal > 0"+STR_PULA
	cQuery += "ORDER BY "+STR_PULA
	cQuery += "    ValorTotalComprado desc"+STR_PULA

	TCQuery cQuery New Alias "COMPANT"

	cTitulo := "Clientes que nao compraram depois de "+ dtoc(mv_par01) + ", quando foi a ultima compra e o total ja comprado"

	//Alterando atributos
	oExcel:SetFontSize(10)
	oExcel:SetFont("Arial")
	//oExcel:SetBgGeneralColor("#0000FF")
	oExcel:SetTitleBold(.T.)
	//oExcel:SetTitleFrColor("#F8F8FF")
	//oExcel:SetLineFrColor("#1E90FF")
	//oExcel:Set2LineFrColor("#00BFFF")

	oExcel:AddworkSheet(cPlano)
	oExcel:AddTable(cPlano,cTitulo)
	//Adicionando as colunas
	For nB:=1 to len(_aColunas)
		if nB <= 4
			//colunas de texto
			oExcel:AddColumn(cPlano,cTitulo,alltrim(_aColunas[nB]),1,1)
		else
			oExcel:AddColumn(cPlano,cTitulo,alltrim(_aColunas[nB]),1,3)
		endif
	next

	DbSelectArea('COMPANT')
	DbGoTop()
	Do While !eof()
		_aDados := {}
		AADD(_aDados, COMPANT->Codigo)
		AADD(_aDados, COMPANT->Loja)
		AADD(_aDados, COMPANT->Nome)
		AADD(_aDados, StoD(COMPANT->DataUltimaCompra))
		AADD(_aDados, COMPANT->ValorTotalComprado)

		//Pulando Registro
		oExcel:AddRow(cPlano,cTitulo,_aDados)
		DbSelectArea('COMPANT')
		DbSkip()
	EndDo
	COMPANT->(DbCloseArea())

Return

Static Function QryVTOTA(oExcel)

	Local cQuery := ""
	Local cPlano := "Sintetico Vendas Atuais"
	Local cTitulo := " "
	Local nB := 0
	Local _aColunas := {"Codigo","Loja","Nome","Valor Total Titulos"}
	Private _aDados := {}

	cQuery := "SELECT "+STR_PULA
	cQuery += "    E1.E1_CLIENTE AS Codigo,"+STR_PULA
	cQuery += "    E1.E1_LOJA AS Loja,"+STR_PULA
	cQuery += "    MAX(A1.A1_NOME) AS Nome,"+STR_PULA
	cQuery += "    CAST(SUM(ISNULL(E1.E1_VALOR, 0)) AS NUMERIC(18,2)) AS VTotalTitulos"+STR_PULA
	cQuery += "FROM "+STR_PULA
	cQuery += "    "+RetSQLName('SE1')+" E1"+STR_PULA
	cQuery += "    INNER JOIN "+RetSQLName('SA1')+" A1 "+STR_PULA
	cQuery += "        ON A1.A1_COD = E1.E1_CLIENTE "+STR_PULA
	cQuery += "       AND A1.A1_LOJA = E1.E1_LOJA"+STR_PULA
	cQuery += "       AND A1.D_E_L_E_T_ = ''"+STR_PULA
	cQuery += "WHERE "+STR_PULA
	cQuery += "    E1.D_E_L_E_T_ = ''"+STR_PULA
	cQuery += "    AND E1.E1_EMISSAO >= '"+DtoS(MV_PAR01)+"'"+STR_PULA
	IF ALLTRIM(MV_PAR02) <> ''
		cQuery += "	AND E1.E1_TIPO IN "+FormatIn(alltrim(MV_PAR02),',')+STR_PULA
	endif

	IF ALLTRIM(MV_PAR03) <> ''
		cQuery += "	AND E1.E1_TIPO NOT IN "+FormatIn(alltrim(MV_PAR03),',')+STR_PULA
	endif
	cQuery += "GROUP BY "+STR_PULA
	cQuery += "    E1.E1_CLIENTE, E1.E1_LOJA, E1.E1_TIPO"+STR_PULA
	cQuery += "ORDER BY "+STR_PULA
	cQuery += "    VTotalTitulos desc;"+STR_PULA

	TCQuery cQuery New Alias "VTOTA"

	cTitulo := "Relatorio sintetico vendas a partir de "+dtoc(mv_par01)

	//Alterando atributos
	oExcel:SetFontSize(10)
	oExcel:SetFont("Arial")
	//oExcel:SetBgGeneralColor("#0000FF")
	oExcel:SetTitleBold(.T.)
	//oExcel:SetTitleFrColor("#F8F8FF")
	//oExcel:SetLineFrColor("#1E90FF")
	//oExcel:Set2LineFrColor("#00BFFF")

	oExcel:AddworkSheet(cPlano)
	oExcel:AddTable(cPlano,cTitulo)
	//Adicionando as colunas
	For nB:=1 to len(_aColunas)
		if nB <= 3
			//colunas de texto
			oExcel:AddColumn(cPlano,cTitulo,alltrim(_aColunas[nB]),1,1)
		else
			oExcel:AddColumn(cPlano,cTitulo,alltrim(_aColunas[nB]),1,3)
		endif
	next

	DbSelectArea('VTOTA')
	DbGoTop()
	Do While !eof()
		_aDados := {}
		AADD(_aDados, VTOTA->Codigo)
		AADD(_aDados, VTOTA->Loja)
		AADD(_aDados, alltrim(VTOTA->Nome))
		AADD(_aDados, VTOTA->VTotalTitulos)

		//Pulando Registro
		oExcel:AddRow(cPlano,cTitulo,_aDados)
		DbSelectArea('VTOTA')
		DbSkip()
	EndDo
	VTOTA->(DbCloseArea())

Return


Static Function QryCOMPATU(oExcel)

	Local cQuery := ""
	Local cPlano := "Vendas Atuais "
	Local cTitulo := " "
	Local nB := 0
	Local _aColunas := {"Codigo","Loja","Nome","Numero","Parcela","Tipo NF","Valor Total Titulos","Em aberto"}
	Private _aDados := {}

	cQuery := "SELECT "+STR_PULA
	cQuery += "    E1.E1_CLIENTE AS Codigo,"+STR_PULA
	cQuery += "    E1.E1_LOJA AS Loja,"+STR_PULA
	cQuery += "    A1.A1_NOME AS Nome,"+STR_PULA
	cQuery += "    E1.E1_NUM as Numero,"+STR_PULA
	cQuery += "    E1.E1_PARCELA AS Parcela,"+STR_PULA
	cQuery += "    E1.E1_TIPO AS TipoNF,"+STR_PULA
	cQuery += "    CAST(SUM(ISNULL(E1.E1_VALOR, 0)) AS NUMERIC(18,2)) AS VTotalTitulos,"+STR_PULA
	cQuery += "    CAST(SUM(ISNULL(E1.E1_SALDO, 0)) AS NUMERIC(18,2)) AS VTotalEmAberto"+STR_PULA
	cQuery += "    
	cQuery += "FROM "+STR_PULA
	cQuery += "    "+RetSQLName('SE1')+" E1"+STR_PULA
	cQuery += "    INNER JOIN "+RetSQLName('SA1')+" A1 "+STR_PULA
	cQuery += "        ON A1.A1_COD = E1.E1_CLIENTE "+STR_PULA
	cQuery += "       AND A1.A1_LOJA = E1.E1_LOJA"+STR_PULA
	cQuery += "       AND A1.D_E_L_E_T_ = ''"+STR_PULA
	cQuery += "WHERE "+STR_PULA
	cQuery += "    E1.D_E_L_E_T_ = ''"+STR_PULA
	cQuery += "    AND E1.E1_EMISSAO >= '"+DtoS(MV_PAR01)+"'"+STR_PULA
	IF ALLTRIM(MV_PAR02) <> ''
		cQuery += "	AND E1.E1_TIPO IN "+FormatIn(alltrim(MV_PAR02),',')+STR_PULA
	ENDIF
	IF ALLTRIM(MV_PAR03) <> ''
		cQuery += "	AND E1.E1_TIPO NOT IN "+FormatIn(alltrim(MV_PAR03),',')+STR_PULA
	ENDIF
	cQuery += "GROUP BY "+STR_PULA
	cQuery += "    E1.E1_CLIENTE, E1.E1_LOJA,A1_NOME,E1_PARCELA, E1.E1_TIPO,E1_NUM"+STR_PULA
	cQuery += "ORDER BY "+STR_PULA
	cQuery += "    Codigo;"+STR_PULA

	TCQuery cQuery New Alias "COMPATU"

	cTitulo := "Relatorio analitico de Vendas a partir de "+dtoc(mv_par01)

	//Alterando atributos
	oExcel:SetFontSize(10)
	oExcel:SetFont("Arial")
	//oExcel:SetBgGeneralColor("#0000FF")
	oExcel:SetTitleBold(.T.)
	//oExcel:SetTitleFrColor("#F8F8FF")
	//oExcel:SetLineFrColor("#1E90FF")
	//oExcel:Set2LineFrColor("#00BFFF")

	oExcel:AddworkSheet(cPlano)
	oExcel:AddTable(cPlano,cTitulo)
	//Adicionando as colunas
	For nB:=1 to len(_aColunas)
		if nB < 6
			//colunas de texto
			oExcel:AddColumn(cPlano,cTitulo,alltrim(_aColunas[nB]),1,1)
		else
			oExcel:AddColumn(cPlano,cTitulo,alltrim(_aColunas[nB]),1,3)
		endif
	next

	DbSelectArea('COMPATU')
	DbGoTop()
	Do While !eof()
		_aDados := {}
		AADD(_aDados, COMPATU->Codigo)
		AADD(_aDados, COMPATU->Loja)
		AADD(_aDados, alltrim(COMPATU->Nome))
		AADD(_aDados, alltrim(COMPATU->Numero))
		AADD(_aDados, alltrim(COMPATU->Parcela))
		AADD(_aDados, alltrim(COMPATU->TipoNF))
		AADD(_aDados, COMPATU->VTotalTitulos)
		AADD(_aDados, COMPATU->VTotalEmAberto)
	
		//Pulando Registro
		oExcel:AddRow(cPlano,cTitulo,_aDados)
		DbSelectArea('COMPATU')
		DbSkip()
	EndDo
	COMPATU->(DbCloseArea())

Return

Static Function ValidPerg()

	Local aPergs   := {}
	Local aRet  := {}
	//Local lRet  := .T.
	Local dData  := CtoD('')
	Local cTipo  := Space(100)

	aAdd(aPergs, {1, "Data", dData,  "", ".T.", "", ".T.", 50, .T.})
	aAdd(aPergs, {1, "Tipos iguais a ? (sep usando ,)", cTipo,  "", ".T.", "", ".T.", 100, .F.})
	aAdd(aPergs, {1, "Tipos diferentes de : (sep usando ,)", cTipo,  "", ".T.", "", ".T.", 100, .F.})

	If !Empty(ParamBox(aPergs, "Informe os parametros",@aRet))
		FwMsgRun(NIL, {|oSay| RunMessage(oSay)}, "Processando", "Processando relatorio...")
	Else
		MsgAlert("Processo Cancelado pelo usuario","Cancel")
		Return
	EndIf

Return
