#INCLUDE "TOTVS.CH"
//Fonte utilizado criação de tabelas que SX2, SX3 e SIX foram appendados.

User function CriaTabela(_param)
Default _param := "CTK"
RpcClearEnv()
RPCSetType(3)
RpcSetEnv("01","010101",,,"",GetEnvServer())

X31UPDTABLE(_param)
CHKFILE(_param)
X31UPDTABLE(_param)
CHKFILE(_param)
DbSelectArea(_param)

return .T.
