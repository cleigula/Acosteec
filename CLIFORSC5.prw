/*=================================================================================================
* Programa...: CLIFORSC5.PRW  
* Descricao..: Função para identificar no Browse o Cliente ou o Fornecedor
* Obs........: conforme o tipo da Nota de Entrada  
* Autor......: Mauricio Dani
* Data.......: 10/2020
*--------------------------------------------------------------------------------------------------
*/
USER FUNCTION CLIFORSC5()

Local cAreaAnt:=alias(),;
aAreaSA1:=SA1->(Getarea()),;
aAreaSA2:=SA2->(Getarea())
Local nNome

IF M->C5_TIPO $ 'B\D'
   nNome:=POSICIONE("SA2",1,XFILIAL("SA2")+M->C5_CLIENTE,"A2_NOME")                       
  
Else

	nNome:=POSICIONE("SA1",1,XFILIAL("SA1")+M->C5_CLIENTE,"A1_NOME") 
Endif
 
// Restaura o ambiente
Restarea(aAreaSA1)
Restarea(aAreaSA2)
dbSelectArea(cAreaAnt) 
return (nNome)
