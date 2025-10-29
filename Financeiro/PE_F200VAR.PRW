#INCLUDE "PROTHEUS.CH"
 
//Manipular as informações (variáveis) no retorno do Cnab a Receber (FINA200). 
//https://tdn.totvs.com/pages/releaseview.action?pageId=235308494

//RELATORIO É PELO F650VAR

User Function F200VAR()
//local s1 := paramixb[1]
// Estrutura de aValores
// Numero do T¡tulo	- 01 
// data da Baixa	- 02
// Tipo do T¡tulo	- 03
// Nosso Numero		- 04
// Valor da Despesa	- 05
// Valor do Desconto- 06
// Valor do Abatimen- 07
// Valor Recebido   - 08
// Juros			- 09
// Multa			- 10
// Outras Despesas	- 11
// Valor do Credito	- 12
// Data Credito		- 13
// Ocorrencia		- 14
// Motivo da Baixa 	- 15
// Linha Inteira	- 16

//MANIPULA A VAIÁVEL cNumTit
Local _cAlias  := GetNextAlias()
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
