//Bibliotecas
#Include "Protheus.ch"

user function ob_func()
local aFuncao 	:= {}     // Para retornar a origem da função: FULL, USER, PARTNER, PATCH, TEMPLATE ou NONE
	Local aType		:= {}     // Para retornar o nome do arquivo onde foi declarada a função
	Local aFile		:= {}     // Para retornar o número da linha no arquivo onde foi declarada a função
	Local aLine		:= {}     // Para retornar o número da linha no arquivo onde foi declarada a função
	Local aDate		:= {}     // Para retornar a data da última modificação do código fonte compilado
	Local aTime		:= {}     // Para retornar a hora da última modificação do código fonte compilado

	aFuncao := GetFuncArray("U_ob_func", aType, aFile, aLine, aDate, aTime)
	If Len(aDate) > 0
		_cObs := "Função: "+Alltrim(aFuncao[1])+"."+chr(10)+Chr(13)+;
			"Data fonte: "+dtoc(aDate[1])+"."+chr(10)+Chr(13)+;
			"Hora fonte: "+aTime[1]+"."
		FWAlertSuccess(_cObs, "Dados da rotina")
	EndIf
return
