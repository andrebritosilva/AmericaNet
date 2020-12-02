User Function Compl01()

Local aPWiz	  := {}
Local aPNts	  := {}
Local aRetWiz := {}
Local aRetNts := {}
Local cSxb    := ""
Local aArea   := GetArea()

AtuAmSX6()	
	
If IsIncallstack("MATA910")
	aTpNota 	:= {"Entrada"} // Tipos de nota
Else
	aTpNota 	:= {"Saida"} // Tipos de nota
EndIf

aAdd(aPWiz,{ 1,"Filial de: "   ,Space(8),"","","SM0","",9 ,.T.})
aAdd(aPWiz,{ 1,"Filial ate: "  ,Space(8),"","","SM0","",9 ,.T.})
aAdd(aPWiz,{ 1,"Data de: "     ,Ctod(""),"","","",  ,60,.F.})
aAdd(aPWiz,{ 1,"Data ate: "    ,Ctod(""),"","","",  ,60,.F.})
aAdd(aPWiz,{ 2,"Tipo de Nota"  ,""      ,aTpNota,60,"",.T.}) 
//aAdd(aPWiz,{ 1,"Nota de: "     ,Space(9),"","","SF102","",9 ,.T.})//SF202 (Saida) / SF102(Entrada)
//aAdd(aPWiz,{ 1,"Nota ate: "    ,Space(9),"","","SF102","",9 ,.T.})
aAdd(aRetWiz,Space(8))
aAdd(aRetWiz,Space(8))
aAdd(aRetWiz,Ctod(""))
aAdd(aRetWiz,Ctod(""))
aAdd(aRetWiz,"")
//aAdd(aRetWiz,Space(9))
//aAdd(aRetWiz,Space(9))

ParamBox(aPWiz,"Parâmetros Complementos",@aRetWiz,,,,,,,"Filial",.T.,.T.) 


If aRetWiz[5] == "Entrada"
	cSxb :=  "SD1"//"SF102" //Entrada
Else
	cSxb :=  "SD2"//"SF202" //Saída
EndIf

aAdd(aPNts,{ 1,"Nota de: "     ,Space(9),"","",cSxb,"",9 ,.F.})//SF202 (Saida) / SF102(Entrada)
aAdd(aPNts,{ 1,"Nota ate: "    ,Space(9),"","",cSxb,"",9 ,.F.})

aAdd(aRetNts,Space(9))
aAdd(aRetNts,Space(9))

ParamBox(aPNts,"Parâmetros Complementos",@aRetNts,,,,,,,"Nota",.T.,.T.)   

If aRetWiz[5] == "Entrada"//Documentos de Entrada
	TmpExpSD1(aRetWiz[1],aRetWiz[2],aRetWiz[3],aRetWiz[4],aRetWiz[5],aRetNts[1], aRetNts[2])
Else //Documentos de Saída
	TmpExpSD2(aRetWiz[1],aRetWiz[2],aRetWiz[3],aRetWiz[4],aRetWiz[5],aRetNts[1], aRetNts[2])
EndIf

RestArea(aArea)

Return .T.

//--------------------------------------------------
/*/{Protheus.doc} TmpExpSD1
Monta Tabela Temporaria SD1 (America Net)

@author André Brito
@since 07/03/2019
@version P12.1.17
 
@return 
/*/
//--------------------------------------------------

Function TmpExpSD1(cFilDe, cFilAte, dDataIn, dDataFim, cTpNota, cNotaDe, cNotaAte)

Local aFields     := {}
Local nI
Local cAlias      := "AliasCsv"
Local cQuery      := ""
Local aRet        := {}
Local aStruTab    := {}
Local cArqTmp     := "AliasCsv"
Local aEmpDados   := {}
Local cAliAux     := GetNextAlias()
Local aCampos     := {}
Local cCgc        := ""
Local lRet        := .F.
Local lExiste     := .F.
Local cGrpClas    := SuperGetMV("MV_XGRPCO",.T.,"1")
Local cClassif    := SuperGetMV("MV_XCLACO",.T.,"01")
Local cTipServ    := SuperGetMV("MV_XTPCO" ,.T.,"0")
Local cClasCon    := SuperGetMV("MV_XCLCO" ,.T.,"99")
Local aArea       := GetArea()

//SD1->D1_DOC,SD1->D1_SERIE,SF1->F1_ESPECIE,SD1->D1_FORNECE,SD1->D1_LOJA,"E",SD1->D1_TIPO,SD1->D1_CF
AADD(aCampos,{"D1_FILIAL"   ,"C",TamSX3("D1_FILIAL")[1],0})
AADD(aCampos,{"D1_DOC"      ,"C",TamSX3("D1_DOC")[1],0})
AADD(aCampos,{"D1_SERIE"    ,"C",TamSX3("D1_SERIE" )[1],0})
AADD(aCampos,{"D1_FORNECE"  ,"C",TamSX3("D1_COD" )[1],0})
AADD(aCampos,{"D1_LOJA"     ,"C",TamSX3("D1_LOJA" )[1],0})
AADD(aCampos,{"D1_TIPO"     ,"C",TamSX3("D1_TIPO" )[1],0})

cQuery := "SELECT * FROM "
cQuery += RetSqlName("SD1") + " SD1 "
cQuery += " WHERE "
cQuery += " D1_FILIAL   Between '" + cFilDe    + "' AND '" + cFilAte  + "' " 
cQuery += " AND D1_EMISSAO  Between '" + DTOS(dDataIn)   + "' AND '" + DTOS(dDataFim)  + "' "
If cTpNota == "Entrada"
	cQuery += " AND D1_TES <= 500  " 
ElseIf cTpNota == "Saida"
	cQuery += " AND D1_TES > 500  "
EndIf
cQuery += " AND D1_DOC      Between '" + cNotaDe    + "' AND '" + cNotaAte  + "' "  
cQuery += " AND D_E_L_E_T_ = ' ' "

cQuery := ChangeQuery(cQuery) 

//MsgInfo(cQuery," Grav. Comp. ")
 
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliAux,.T.,.T.)

DbselectArea("SD1")
dbGoTop()

DbSelectArea("SFX")
SFX->(DbSetOrder(1))

BEGIN TRANSACTION

Do While !(cAliAux)->(Eof())
	lRet := .T.
	lExiste	:= SFX->(dbSeek(xFilial("SFX") + "E" + (cAliAux)->D1_SERIE + (cAliAux)->D1_DOC + (cAliAux)->D1_FORNECE + (cAliAux)->D1_LOJA + (cAliAux)->D1_ITEM + (cAliAux)->D1_COD))
	If lExiste
		RecLock("SFX",.F.)
	Else
		RecLock("SFX",.T.)
	EndIf
	SFX->FX_FILIAL     := Alltrim((cAliAux)->D1_FILIAL)
	SFX->FX_TIPOMOV    := "E" 
	SFX->FX_DOC        := Alltrim((cAliAux)->D1_DOC)
	SFX->FX_SERIE      := Alltrim((cAliAux)->D1_SERIE)
	//SFX->FX_ESPECIE  := Alltrim((cAliAux)->Verificar)
	SFX->FX_CLIFOR     := Alltrim((cAliAux)->D1_FORNECE)
	SFX->FX_LOJA       := Alltrim((cAliAux)->D1_LOJA)
	SFX->FX_ITEM       := Alltrim((cAliAux)->D1_ITEM)
	SFX->FX_COD        := Alltrim((cAliAux)->D1_COD)
	/*SFX->FX_TPCLASS  := Alltrim((cAliAux)->Verificar)*/
	SFX->FX_CLASCON    := cClasCon
	SFX->FX_GRPCLAS    := cGrpClas
	SFX->FX_CLASSIF    := cClassif 
	/*SFX->FX_VALTERC  := Alltrim((cAliAux)->Verificar)
	SFX->FX_TIPOREC    := Alltrim((cAliAux)->Verificar)
	SFX->FX_RECEP      := Alltrim((cAliAux)->Verificar)
	SFX->FX_LOJAREC    := Alltrim((cAliAux)->Verificar)*/
	SFX->FX_TIPSERV    := cTipServ
	SFX->FX_DTINI      := dDataIn
	SFX->FX_DTFIM      := dDataFim
	/*SFX->FX_PERFIS   := Alltrim((cAliAux)->Verificar)
	SFX->FX_AREATER    := Alltrim((cAliAux)->Verificar)
	SFX->FX_TERMINA    := Alltrim((cAliAux)->Verificar)
	SFX->FX_VOL115     := Alltrim((cAliAux)->Verificar)
	SFX->FX_CHV115     := Alltrim((cAliAux)->Verificar)*/
	//SFX->FX_TPASSIN  := AmTpAss1((cAliAux)->D1_FORNECE, (cAliAux)->D1_LOJA)
	/*SFX->FX_ESTREC   := Alltrim((cAliAux)->Verificar)
	SFX->FX_CODUNC     := Alltrim((cAliAux)->Verificar)
	SFX->FX_ESTHIPO    := Alltrim((cAliAux)->Verificar)
	SFX->FX_ESTIMOTI   := Alltrim((cAliAux)->Verificar)
	SFX->FX_ESTCONT    := Alltrim((cAliAux)->Verificar)
	SFX->FX_CLASSIT    := Alltrim((cAliAux)->Verificar)*/
	SFX->FX_SDOC       := Alltrim((cAliAux)->D1_DOC)
	MsUnLock()
	(cAliAux)->(dbskip())
Enddo

If lRet
	MsgInfo("Complementos gravados com sucesso!"," Grav. Comp. ")
Else
	MsgInfo("Falha na gravação dos complementos!"," Grav. Comp. ")
	DisarmTransaction()
EndIf

(cAliAux)->(DbCloseArea())

END TRANSACTION

Return




//--------------------------------------------------
/*/{Protheus.doc} TmpExpSD2
Monta Tabela Temporaria SD2 (America Net)
Projeto Risco Sacado

@author André Brito
@since 07/03/2019
@version P12.1.17
 
@return 
/*/
//--------------------------------------------------

Static Function TmpExpSD2(cFilDe, cFilAte, dDataIn, dDataFim, cTpNota, cNotaDe, cNotaAte)

Local aFields     := {}
Local nI
Local cAlias      := "AliasCsv"
Local cQuery      := ""
Local aRet        := {}
Local aStruTab    := {}
Local cArqTmp     := "AliasCsv"
Local aEmpDados   := {}
Local cAliAux     := GetNextAlias()
Local aCampos     := {}
Local cCgc        := ""
Local lRet        := .F.
Local lExiste     := .F.
Local cGrpClas    := ("MV_XGRPCO",.T.,"1")
Local cClassif    := SuperGetMV("MV_XCLACO",.T.,"01")
Local cTipServ    := SuperGetMV("MV_XTPCO" ,.T.,"0")
Local cClasCon    := SuperGetMV("MV_XCLCO" ,.T.,"99")
Local aArea       := GetArea()

//SD1->D1_DOC,SD1->D1_SERIE,SF1->F1_ESPECIE,SD1->D1_FORNECE,SD1->D1_LOJA,"E",SD1->D1_TIPO,SD1->D1_CF
AADD(aCampos,{"D2_FILIAL"   ,"C",TamSX3("D2_FILIAL")[1],0})
AADD(aCampos,{"D2_DOC"      ,"C",TamSX3("D2_DOC")[1],0})
AADD(aCampos,{"D2_SERIE"    ,"C",TamSX3("D2_SERIE" )[1],0})
AADD(aCampos,{"D2_CLIENTE"  ,"C",TamSX3("D2_CLIENTE" )[1],0})
AADD(aCampos,{"D2_LOJA"     ,"C",TamSX3("D2_LOJA" )[1],0})
AADD(aCampos,{"D2_TIPO"     ,"C",TamSX3("D2_TIPO" )[1],0})

cQuery := "SELECT * FROM "
cQuery += RetSqlName("SD2") + " SD2 "
cQuery += " WHERE "
cQuery += " D2_FILIAL   Between '" + cFilDe    + "' AND '" + cFilAte  + "' " 
cQuery += " AND D2_EMISSAO  Between '" + DTOS(dDataIn)   + "' AND '" + DTOS(dDataFim)  + "' "
If cTpNota == "Entrada"
	cQuery += " AND D2_TES <= 500  " 
ElseIf cTpNota == "Saida"
	cQuery += " AND D2_TES > 500  "
EndIf
cQuery += " AND D2_DOC      Between '" + cNotaDe    + "' AND '" + cNotaAte  + "' "  
cQuery += " AND D_E_L_E_T_ = ' ' "

cQuery := ChangeQuery(cQuery) 

//MsgInfo(cQuery," Grav. Comp. ")
 
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliAux,.T.,.T.)


DbselectArea("SD2")
dbGoTop()


DbSelectArea("SFX")
SFX->(DbSetOrder(1))
SFX->( dbGoTop() )

BEGIN TRANSACTION

DelSfx(dDataIn, dDataFim)

Do While !(cAliAux)->(Eof())
	lRet := .T.
	
	lExiste	:= SFX->(dbSeek(xFilial("SFX") + "S" + (cAliAux)->D2_SERIE + (cAliAux)->D2_DOC + (cAliAux)->D2_CLIENTE + (cAliAux)->D2_LOJA + (cAliAux)->D2_ITEM))
	If lExiste
		RecLock("SFX",.F.)
	Else
		RecLock("SFX",.T.)
	EndIf
	SFX->FX_FILIAL     :=  Alltrim((cAliAux)->D2_FILIAL)
	SFX->FX_TIPOMOV    := "S" 
	SFX->FX_DOC        := Alltrim((cAliAux)->D2_DOC)
	SFX->FX_SERIE      := Alltrim((cAliAux)->D2_SERIE)
	//SFX->FX_ESPECIE  := Alltrim((cAliAux)->Verificar)
	SFX->FX_CLIFOR     := Alltrim((cAliAux)->D2_CLIENTE)
	SFX->FX_LOJA       := Alltrim((cAliAux)->D2_LOJA)
	SFX->FX_ITEM       := Alltrim((cAliAux)->D2_ITEM)
	SFX->FX_COD        := Alltrim((cAliAux)->D2_COD)
	//SFX->FX_TPCLASS  := Alltrim((cAliAux)->Verificar)
	SFX->FX_CLASCON    := cClasCon
	SFX->FX_GRPCLAS    := cGrpClas
	SFX->FX_CLASSIF    := cClassif 
	/*SFX->FX_VALTERC  := Alltrim((cAliAux)->Verificar)
	SFX->FX_TIPOREC    := Alltrim((cAliAux)->Verificar)*/
	SFX->FX_RECEP      := Alltrim((cAliAux)->D2_CLIENTE)
	//SFX->FX_LOJAREC    := Alltrim((cAliAux)->Verificar)
	SFX->FX_TIPSERV    := cTipServ
	SFX->FX_DTINI      := dDataIn
	SFX->FX_DTFIM      := dDataFim
	/*SFX->FX_PERFIS   := Alltrim((cAliAux)->Verificar)
	SFX->FX_AREATER    := Alltrim((cAliAux)->Verificar)
	SFX->FX_TERMINA    := Alltrim((cAliAux)->Verificar)
	SFX->FX_VOL115     := Alltrim((cAliAux)->Verificar)
	SFX->FX_CHV115     := Alltrim((cAliAux)->Verificar)*/
	SFX->FX_TPASSIN    := AmTpAss2((cAliAux)->D2_CLIENTE, (cAliAux)->D2_LOJA)
	/*SFX->FX_ESTREC   := Alltrim((cAliAux)->Verificar)
	SFX->FX_CODUNC     := Alltrim((cAliAux)->Verificar)
	SFX->FX_ESTHIPO    := Alltrim((cAliAux)->Verificar)
	SFX->FX_ESTIMOTI   := Alltrim((cAliAux)->Verificar)
	SFX->FX_ESTCONT    := Alltrim((cAliAux)->Verificar)
	SFX->FX_CLASSIT    := Alltrim((cAliAux)->Verificar)*/
	SFX->FX_SDOC       := Alltrim((cAliAux)->D2_DOC)
	MsUnLock()
	(cAliAux)->(dbskip())
Enddo

If lRet
	MsgInfo("Complementos gravados com sucesso!"," Grav. Comp. ")
Else
	MsgInfo("Falha na gravação dos complementos!"," Grav. Comp. ")
	DisarmTransaction()
EndIf

(cAliAux)->(DbCloseArea())

END TRANSACTION

Return

//--------------------------------------------------
/*/{Protheus.doc} AtuAmSX6
Ajuste de parametros (America Net)
Projeto SPED

@author André Brito
@since 07/03/2019
@version P12.1.17
 
@return 
/*/
//--------------------------------------------------

Static Function AtuAmSX6()

Local aSX6   	 := {}
Local aSX6Alter	 := {}
Local aEstrut	 := {}
Local nTamFilial := AmeSXG("033",2)
Local i 		 := 0
Local j          := 0
Local cAlias 	 := ''
Local aArea      := GetArea()

aEstrut:= { "X6_FIL","X6_VAR","X6_TIPO","X6_DESCRIC","X6_DSCSPA","X6_DSCENG","X6_DESC1","X6_DSCSPA1","X6_DSCENG1",;
			"X6_DESC2","X6_DSCSPA2","X6_DSCENG2","X6_CONTEUD","X6_CONTSPA","X6_CONadminTENG","X6_PROPRI","X6_PYME"}

AADD(aSX6,{ SPACE(nTamFilial),"MV_XGRPCO","C",;
"Conteúdo do campo FX_GRPCLAS","Conteúdo do campo FX_GRPCLAS","Conteúdo do campo FX_GRPCLAS",;
"Definicao 1(padrão)","Definicao 1(padrão)","Definicao 1(padrão)",;
"","","",;
"1","1","1",;
"S","S"})

AADD(aSX6,{ SPACE(nTamFilial),"MV_XCLACO","C",;
"Conteúdo do campo FX_CLASSIF","Conteúdo do campo FX_CLASSIF","Conteúdo do campo FX_CLASSIF",;
"Definicao 01(padrão)","Definicao 01(padrão)","Definicao 01(padrão)",;
"","","",;
"01","01","01",;
"S","S"})

AADD(aSX6,{ SPACE(nTamFilial),"MV_XTPCO","C",;
"Conteúdo do campo FX_TIPSERV","Conteúdo do campo FX_TIPSERV","Conteúdo do campo FX_TIPSERV",;
"Definicao 0(Telefonico)","Definicao 0(Telefonico)","Definicao 0(Telefonico)",;
"","","",;
"0","0","0",;
"S","S"})

AADD(aSX6,{ SPACE(nTamFilial),"MV_XCLCO","C",;
"Conteúdo do campo FX_CLASCON","Conteúdo do campo FX_CLASCON","Conteúdo do campo FX_CLASCON",;
"Definicao 99(padrão)","Definicao 99(padrão)","Definicao 99(padrão)",;
"","","",;
"99","99","99",;
"S","S"})

ProcRegua(Len(aSX6))

dbSelectArea("SX6")
dbSetOrder(1)
For i:= 1 To Len(aSX6)
	If !Empty(aSX6[i][2])
		If !DbSeek(aSX6[i,1]+aSX6[i,2])
			lSX6	:= .T.
			If !(aSX6[i,2]$cAlias)
				cAlias += aSX6[i,2]+"/"
			EndIf
			RecLock("SX6",.T.)
			For j:=1 To Len(aSX6[i])
				If !Empty(FieldName(FieldPos(aEstrut[j])))
					FieldPut(FieldPos(aEstrut[j]),aSX6[i,j])
				EndIf
			Next j
			
			dbCommit()
			MsUnLock()
			IncProc("Atualizando parametros") // //"Atualizando Parametros..."
		EndIf
	EndIf
Next i

Return


Static Function AmeSXG(cGrupo,nTamPad)
Local nSize := 0
Local aArea := GetArea()

DbSelectArea("SXG")
DbSetOrder(1)

IF DbSeek(cGrupo)
	nSize := SXG->XG_SIZE
Else
	nSize := nTamPad
Endif

RestArea(aArea)

Return nSize


Static Function AmTpAss1(cFornece,cLoja)

Local aArea    := GetArea()
Local cTipoAss := ""

DbSelectArea("SA2")
DbSetOrder(1)

If SA2->(dbSeek( xFilial("SA2") + cFornece + cLoja ))
//	cTipoAss := 
EndIf

RestArea(aArea)

Return cTipoAss


Static Function AmTpAss2(cCliente,cLoja)

Local aArea    := GetArea()
Local cTipoAss := ""

DbSelectArea("SA1")
DbSetOrder(1)

If SA1->(dbSeek( xFilial("SA1") + cCliente + cLoja ))
	cTipoAss := SA1->A1_TPUTI
EndIf

RestArea(aArea)

Return cTipoAss


Static Function DelSfx(dDataIn,dDataFim)

Local aArea    := GetArea()

DbSelectArea("SFX")
SFX->(DbSetOrder(1))
SFX->(dbGotop())

While !Eof() .And. (SFX->FX_DTINI >= dDataIn .And. SFX->FX_DTFIM <= dDataFim)
	RecLock("SFX",.F.,.T.)				
	SFX->(DbDelete())	
	msUnlock()
	DbSkip()
EndDo

RestArea(aArea)

Return