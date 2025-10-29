#INCLUDE "PROTHEUS.CH"

//Manipular as informações (variáveis) no relatório de retorno do Cnab a Receber (FINR650). 
//RETORNO É FEITO PELO PONTO DE ENTRADA F200VAR
User Function F650VAR()
	Local _cAlias := GetNextAlias()
	Local _cQuery  := ""
	_cQuery := " SELECT TOP 1 E1_IDCNAB AS TITULO FROM "+RetSqlname("SE1")+" WHERE (E1_PREFIXO+E1_NUM+E1_PARCELA = '"+cNumTit+"' OR E1_IDCNAB = '"+Alltrim(cNumTit)+"') AND D_E_L_E_T_ = '' ORDER BY E1_EMISSAO DESC "
	dbUseArea(.T., "TOPCONN", TcGenQry(, , _cQuery), _cAlias, .T., .T.)

	If (_cAlias)->(!EOF())
		cNumTit := (_cAlias)->TITULO
		(_cAlias)->(dbCloseArea())
		FErase(_cAlias+GetDBExtension())
		FErase(_cAlias+OrdBagExt())
	EndIf
Return
