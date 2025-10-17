#Include "Protheus.ch"

user function b8_meclip()

	local cObs := Alltrim(Posicione('SA1',1,xFilial('SA1') + M->C5_CLIENTE + M->C5_LOJACLI,'A1_OBS'))  
 	If cObs <> ''
		FWAlertWarning(MSMM(cObs,60), "Observacoes do cliente")
	endif
return (.t.)
