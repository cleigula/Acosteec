#Include "Totvs.ch"
#Include 'Protheus.ch'
#Include "TOPCONN.CH"


User Function MT410TOK()
	Local lRet:= .T.
	
	//RecLock("SC5", .F.)
	//SC5->C5_USERF := Alltrim( UsrFullName(RetCodUsr()))
	//MsUnLock()

	if !IsLocked ("SC5", SC5->(Recno()))
		RecLock("SC5",.F.)
		C5_USERF := Alltrim( UsrFullName(RetCodUsr()))
		MsUnLock()
	Else
		M->C5_USERF := Alltrim( UsrFullName(RetCodUsr()))
	EndIf



Return lRet

User Function M410ALOK()

	Local lRet := .T.

	/*
	If ALTERA   //Alteração
		MsgAlert("ALTERAÇÂO - Pedido já faturado.","ATENÇÃO")
	ElseIf !INCLUI .And. !ALTERA    //Exclusão
		MsgAlert("EXCLUSÃO - Pedido já faturado.","ATENÇÃO")
	ElseIf INCLUI .And. IsInCallStack("A410COPIA")  //Cópia
		MsgAlert("CÓPIA - Pedido já faturado.","ATENÇÃO")
	EndIf
	*/


Return lRet
