(* $Header: /SQL Toys/units/SqlConverters.pas 59    19-12-14 12:31 Tomek $
   (c) Tomasz Gierka, github.com/SqlToys, 2015.06.14                          *)
{--------------------------------------  --------------------------------------}
unit SqlConverters;

interface

uses GtTokenizers, SqlNode, SqlLister;

const { converters settings values, same as icon numbers }
  SQCV_NONE     = 0;
  SQCV_GROUP    = 1;
  SQCV_ADD      = 2;
  SQCV_REMOVE   = 3;
  SQCV_UPPER    = 4;
  SQCV_LOWER    = 5;
  SQCV_SHORT    = 6;
  SQCV_LONG     = 7;

  { converter groups }
  SQCG_NONE     = 0;
  SQCG_MAX      = 9;

  SQCG_INTEND   = 1;
  SQCG_CASES    = 2;
  SQCG_KEYWORD  = 3;
  SQCG_LINES    = 4;
  SQCG_EMPTY    = 5;
  SQCG_SPACES   = 6;
  SQCG_OTHER    = 7;

  { converters = converter items }
  SQCC_NONE              =  0;
  SQCC_MAX               = 16;

  SQCC_INT_CLAUSE_BODY   = 1;
  SQCC_INT_CLAUSE_RGHT   = 2;

  SQCC_CASE_KEYWORD      = 1;   // gtttKeyword
  SQCC_CASE_TABLE        = 2;   // gtttIdentifier, gtlsTable
  SQCC_CASE_TABLE_ALIAS  = 3;   // gtttIdentifier, gtlsTableAlias
  SQCC_CASE_COLUMN       = 4;   // gtttIdentifier, gtlsColumn
  SQCC_CASE_COLUMN_ALIAS = 5;   // gtttIdentifier, gtlsColumnAlias
//SQCC_CASE_COLUMN_QUOTE = 6;
  SQCC_CASE_PARAM        = 7;   // gtttIdentifier, gtlsParameter
  SQCC_CASE_FUNC         = 8;   // gtttIdentifier, gtlsFunction     \/ gtlsAggrFunction
//SQCC_CASE_IDENT        = 9;   // gtttIdentifier, ????????????

  SQCC_CASE_VIEW         =10;   // gtttIdentifier, gtlsView
  SQCC_CASE_CONSTRAINT   =11;   // gtttIdentifier, gtlsConstraint
  SQCC_CASE_SYNONYM      =12;   // gtttIdentifier, gtlsSynonym
  SQCC_CASE_TRANSACTION  =13;   // gtttIdentifier, gtlsTransaction
  SQCC_CASE_FUN_PARAM    =14;   // gtttIdentifier, gtlsFunParameter
  SQCC_CASE_EXTQ_ALIAS   =15;   // gtttIdentifier, gtlsExtQueryAliasOrTable
  SQCC_CASE_IDENTIFIER   =16;   // gtttIdentifier, gtlsIdentifier

  SQCC_KWD_AS_TABLES     = 1;
  SQCC_KWD_AS_COLUMNS    = 2;
  SQCC_KWD_INT           = 3;
  SQCC_KWD_INNER         = 4;
  SQCC_KWD_OUTER         = 5;
  SQCC_JOIN_ON_LEFT      = 6;
  SQCC_KWD_ORDER_LEN     = 7;
  SQCC_KWD_ORDER_DEF     = 8;

  SQCC_LINE_CLAUSE        =  1;
  SQCC_LINE_BEF_EXPR_RIGHT=  2;
  SQCC_LINE_BEF_EXPR_LEFT =  3;
  SQCC_LINE_BEF_EXPR_1ST  =  4;
  SQCC_LINE_BEF_COND      =  5;
  SQCC_LINE_CASE_CASE     =  6;
  SQCC_LINE_CASE_WHEN     =  7; {should be subnode}
  SQCC_LINE_CASE_THEN     =  8; {should be subnode}
  SQCC_LINE_CASE_ELSE     =  9; {should be subnode}
//SQCC_LINE_CASE_END      =  9; {should be subnode}
  SQCC_LINE_BEF_CONSTR    = 10;
//SQCC_LINE_AFT_CONSTR    = 11;

//SQCC_EMPTY_BEF_CLAUSE  = 1;
//SQCC_EXC_SUBQUERY      = 2; {should be subnode}
//SQCC_EXC_SHORT_QUERY   = 3; {should be subnode}
  SQCC_EMPTY_AROUND_UNION= 1;
  SQCC_EMPTY_CMPLX_CONSTR= 2;

  SQCC_SPACE_BEF_SEMICOLON       = 1;
  SQCC_SPACE_BEF_COMMA           = 2;
  SQCC_SPACE_AFT_COMMA           = 3;
  SQCC_SPACE_AROUND_OPER         = 4;
  SQCC_SPACE_AROUND_OPER_MATH    = 5;
  SQCC_SPACE_AROUND_OPER_CONC    = 6;
  SQCC_SPACE_INSIDE_BRACKET      = 7;
  SQCC_SPACE_INSIDE_BRACKET_SPF  = 8;
  SQCC_SPACE_INSIDE_BRACKET_DATA = 9;
  SQCC_SPACE_OUTSIDE_BRACKET     =10;

  SQCC_OTH_SEMICOLON     = 1;
  SQCC_OTH_SEMICOLON_SQ  = 2;

procedure TokenListConvertExecute( aGroup, aItem, aState: Integer; aTokenList: TGtLexTokenList; aNode: TGtSqlNode );
procedure SyntaxTreeConvertExecute( aGroup, aItem, aState: Integer; aNode: TGtSqlNode );

implementation

uses SysUtils, SqlCommon;

{----------------------------------- General ----------------------------------}

{ adds semicolon to query }
procedure SqlToysConvert_Semicolon_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind in [gtsiDml, gtsiDdl, gtsiDcl, gtsiTcl]) then aNode.KeywordAuxAdd( gttkSemicolon );
end;

{ removes semicolon from query }
procedure SqlToysConvert_Semicolon_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind in [gtsiDml, gtsiDdl, gtsiDcl, gtsiTcl]) then aNode.KeywordAuxRemove( gttkSemicolon );
end;

{ adds semicolon to single query }
procedure SqlToysConvert_Semicolon_SingleQuery_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind in [gtsiDml, gtsiDdl, gtsiDcl, gtsiTcl]) and
     (aNode.Owner.Kind = gtsiQueryList) and (aNode.Owner.Count = 1)
      then aNode.KeywordAuxAdd( gttkSemicolon );
end;

{ removed semicolon from single query }
procedure SqlToysConvert_Semicolon_SingleQuery_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind in [gtsiDml, gtsiDdl, gtsiDcl, gtsiTcl]) and
     (aNode.Owner.Kind = gtsiQueryList) and (aNode.Owner.Count = 1)
      then aNode.KeywordAuxRemove( gttkSemicolon );
end;

{--------------------------------- Converters ---------------------------------}

{ procedure for SELECT expr list iteration }
procedure SqlToysConvert_ExprAlias_Iteration(aProc: TSqlNodeProcedure; aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprList, gtkwSelect) then begin
    aNode.ForEach( aProc, False, gtsiExpr );
    aNode.ForEach( aProc, False, gtsiExprTree );
  end else
  if aNode.Check(gtsiDml, gtkwSelect) then begin
    aNode.ForEach( aProc, False, gtsiExprList, gtkwSelect );
  end else
  if aNode.Check(gtsiQueryList) then begin
    aNode.ForEach( aProc, False, gtsiDml, gtkwSelect );
  end;
end;

{ procedure adds keyword AS to each top level expression in SELECT clause }
procedure SqlToysConvert_ExprAlias_AddKeyword_AS(aNode: TGtSqlNode);
var lAlias: TGtSqlNode;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExpr) or aNode.Check(gtsiExprTree) then begin
    lAlias := aNode.Find(gtsiNone, gtkwAs);
    if Assigned(lAlias) then lAlias.KeywordExt := gtkwAs;
  end else begin
    SqlToysConvert_ExprAlias_Iteration( SqlToysConvert_ExprAlias_AddKeyword_AS, aNode );
  end;
end;

{ procedure removes keyword AS from each top level expression in SELECT clause }
procedure SqlToysConvert_ExprAlias_RemoveKeyword_AS(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExpr) or aNode.Check(gtsiExprTree) then begin
    aNode.KeywordAuxRemove( gtkwAs );
  end else begin
    SqlToysConvert_ExprAlias_Iteration( SqlToysConvert_ExprAlias_RemoveKeyword_AS, aNode );
  end;
end;

{ procedure for tables in FROM, UPDATE or DELETE clause iteration }
procedure SqlToysConvert_TableAlias_Iteration(aProc: TSqlNodeProcedure; aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiClauseTables) then begin
    aNode.ForEach( aProc, False, gtsiTableRef );
  end else
  if aNode.Check(gtsiDml, gtkwSelect) then begin
    aNode.ForEach( aProc, False, gtsiClauseTables );
  end else
  if aNode.Check(gtsiQueryList) then begin
    aNode.ForEach( aProc, False, gtsiDml, gtkwSelect );
  end;
end;

{ procedure adds keyword AS to each table in FROM, UPDATE or DELETE clause }
procedure SqlToysConvert_TableAlias_AddKeyword_AS(aNode: TGtSqlNode);
var lAlias: TGtSqlNode;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiTableRef) then begin
    lAlias := aNode.Find(gtsiNone, gtkwAs);
    if Assigned(lAlias) then lAlias.KeywordExt := gtkwAs;
  end else begin
    SqlToysConvert_TableAlias_Iteration( SqlToysConvert_TableAlias_AddKeyword_AS, aNode );
  end;
end;

{ procedure removes keyword AS from each table in FROM, UPDATE or DELETE clause }
procedure SqlToysConvert_TableAlias_RemoveKeyword_AS(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiTableRef) then begin
    aNode.KeywordAuxRemove( gtkwAs );
  end else begin
    SqlToysConvert_TableAlias_Iteration( SqlToysConvert_TableAlias_RemoveKeyword_AS, aNode );
  end;
end;

{-------------------------- Intendation Converters ----------------------------}

{ converter add clause body space }
procedure SqlToysConvert_Intend_Clause_Body_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.IsClause then aNode.KeywordAuxAdd(gttkIntendClauseBody);
end;

{ converter add clause body space }
procedure SqlToysConvert_Intend_Clause_Body_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  aNode.KeywordAuxRemove(gttkIntendClauseBody);
end;

{------------------------------ Case Converters -------------------------------}

{ procedure changes tokencase to upper }
procedure TokenConvert_UpperCase(aToken: TGtLexToken);
begin
  if not Assigned(aToken) then Exit;

  aToken.TokenCase := gtcoUpperCase;
end;

{ procedure changes token case to lower }
procedure TokenConvert_LowerCase(aToken: TGtLexToken);
begin
  if not Assigned(aToken) then Exit;

  aToken.TokenCase := gtcoLowerCase;
end;

{ adds space before token }
procedure TokenConvert_AddSpaceBefore(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.AddSpaceBeforeToken;
end;

{ adds space after token }
procedure TokenConvert_AddSpaceAfter(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.AddSpaceAfterToken;
end;

{ removes space before token }
procedure TokenConvert_RemoveSpaceBefore(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.RemoveSpaceBeforeToken;
end;

{ removes space after token }
procedure TokenConvert_RemoveSpaceAfter(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.RemoveSpaceAfterToken;
end;

{ adds keyword AS before token }
procedure TokenConvert_AddKeywordAS(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.AddKeywordBeforeToken(gtkwAs);
end;

{ removes keyword AS before token }
procedure TokenConvert_RemoveKeywordAS(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.RemoveKeywordBeforeToken(gtkwAs);
end;

{ adds keyword INNER before JOIN }
procedure TokenConvert_AddKeywordINNER(aToken: TGtLexToken);
var PrevToken: TGtLexToken;
begin
  if not Assigned(aToken) then Exit;
  if(aToken.TokenKind <> gtttKeyword) or (aToken.TokenDef <> gtkwJoin) then Exit;

  PrevToken := aToken.GetPrevToken(1);
  if not Assigned(PrevToken) then Exit;
  if(PrevToken.TokenKind <> gtttWhiteSpace) and (PrevToken.TokenKind <> gtttEndOfLine) then Exit;

  PrevToken := aToken.GetPrevToken(2);
  if not Assigned(PrevToken) then Exit;
  if(PrevToken.TokenKind = gtttKeyword) and (PrevToken.TokenDef = gtkwInner) then Exit;
  if(PrevToken.TokenKind = gtttKeyword) and (PrevToken.TokenDef = gtkwLeft)  then Exit;
  if(PrevToken.TokenKind = gtttKeyword) and (PrevToken.TokenDef = gtkwRight) then Exit;
  if(PrevToken.TokenKind = gtttKeyword) and (PrevToken.TokenDef = gtkwOuter) then Exit;

  aToken.AddKeywordBeforeToken(gtkwInner);
end;

{ removes keyword INNER before JOIN }
procedure TokenConvert_RemoveKeywordINNER(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.RemoveKeywordBeforeToken(gtkwInner);
end;

{ adds keyword INNER before JOIN }
procedure TokenConvert_AddKeywordOUTER(aToken: TGtLexToken);
var PrevToken: TGtLexToken;
begin
  if not Assigned(aToken) then Exit;
  if(aToken.TokenKind <> gtttKeyword) or (aToken.TokenDef <> gtkwJoin) then Exit;

  PrevToken := aToken.GetPrevToken(1);
  if not Assigned(PrevToken) then Exit;
  if(PrevToken.TokenKind <> gtttWhiteSpace) and (PrevToken.TokenKind <> gtttEndOfLine) then Exit;

  PrevToken := aToken.GetPrevToken(2);
  if not Assigned(PrevToken) then Exit;
  if(PrevToken.TokenKind = gtttKeyword) and (PrevToken.TokenDef = gtkwInner) then Exit;
  if(PrevToken.TokenKind = gtttKeyword) and (PrevToken.TokenDef = gtkwOuter) then Exit;
  if(PrevToken.TokenKind <> gtttKeyword) or (PrevToken.TokenDef <> gtkwLeft)
                                        and (PrevToken.TokenDef <> gtkwRight) then Exit;

  aToken.AddKeywordBeforeToken(gtkwOuter);
end;

{ removes keyword INNER before JOIN }
procedure TokenConvert_RemoveKeywordOUTER(aToken: TGtLexToken);
begin
  if Assigned(aToken) then aToken.RemoveKeywordBeforeToken(gtkwOuter);
end;

{ procedure changes upper case keywords to lower case }
procedure SqlToysConvert_CaseKeyword_Lower(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;
end;

{ procedure changes upper case keywords to lower case }
procedure SqlToysConvert_CaseKeyword_Upper(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Keyword <> gttkNone then aNode.Keyword := aNode.Keyword ;

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseKeyword_Upper, aNode );
end;

procedure SqlToysConvert_CaseTableName_Lower(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Kind = gtsiTableRef
    then aNode.Name := AnsiLowerCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseTableName_Lower, aNode );
end;

procedure SqlToysConvert_CaseTableName_Upper(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Kind = gtsiTableRef
    then aNode.Name := AnsiUpperCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseTableName_Upper, aNode );
end;

procedure SqlToysConvert_CaseTableAlias_Lower(aNode: TGtSqlNode);
var lAlias: TGtSqlNode;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Kind = gtsiTableRef then begin
    lAlias := aNode.Find(gtsiNone, gtkwAs);
    if Assigned(lAlias) then lAlias.Name := AnsiLowerCase( lAlias.Name );
  end;

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseTableAlias_Lower, aNode );
end;

procedure SqlToysConvert_CaseTableAlias_Upper(aNode: TGtSqlNode);
var lAlias: TGtSqlNode;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Kind = gtsiTableRef then begin
    lAlias := aNode.Find(gtsiNone, gtkwAs);
    if Assigned(lAlias) then lAlias.Name := AnsiUpperCase( lAlias.Name );
  end;

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseTableAlias_Upper, aNode );
end;

procedure SqlToysConvert_CaseColumnName_Lower(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Keyword <> gttkParameterName) and (aNode.Name <> '')
                             and (aNode.Keyword <> gtkwFunction)
    then aNode.Name := AnsiLowerCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseColumnName_Lower, aNode );
end;

procedure SqlToysConvert_CaseColumnName_Upper(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Keyword <> gttkParameterName) and (aNode.Name <> '')
                             and (aNode.Keyword <> gtkwFunction)
    then aNode.Name := AnsiUpperCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseColumnName_Upper, aNode );
end;

procedure SqlToysConvert_CaseColumnAlias_Lower(aNode: TGtSqlNode);
var lAlias: TGtSqlNode;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Kind = gtsiExprTree then begin
    lAlias := aNode.Find(gtsiNone, gtkwAs);
    if Assigned(lAlias) then lAlias.Name := AnsiLowerCase( lAlias.Name );
  end;

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseColumnAlias_Lower, aNode );
end;

procedure SqlToysConvert_CaseColumnAlias_Upper(aNode: TGtSqlNode);
var lAlias: TGtSqlNode;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Kind = gtsiExprTree then begin
    lAlias := aNode.Find(gtsiNone, gtkwAs);
    if Assigned(lAlias) then lAlias.Name := AnsiUpperCase( lAlias.Name );
  end;

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseColumnAlias_Upper, aNode );
end;

procedure SqlToysConvert_CaseParam_Lower(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Keyword = gttkParameterName) and (aNode.Name <> '')
    then aNode.Name := AnsiLowerCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseParam_Lower, aNode );
end;

procedure SqlToysConvert_CaseParam_Upper(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Keyword = gttkParameterName) and (aNode.Name <> '')
    then aNode.Name := AnsiUpperCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseParam_Upper, aNode );
end;

procedure SqlToysConvert_CaseFunc_Lower(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Name <> '') and (aNode.Keyword = gtkwFunction)
    then aNode.Name := AnsiLowerCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseFunc_Lower, aNode );
end;

procedure SqlToysConvert_CaseFunc_Upper(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Name <> '') and (aNode.Keyword = gtkwFunction)
    then aNode.Name := AnsiUpperCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseFunc_Upper, aNode );
end;

procedure SqlToysConvert_CaseIdentifier_Lower(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Name <> '') and (aNode.Keyword = gttkIdentifier)
    then aNode.Name := AnsiLowerCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseIdentifier_Lower, aNode );
end;

procedure SqlToysConvert_CaseIdentifier_Upper(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiExpr) and (aNode.Name <> '') and (aNode.Keyword = gttkIdentifier)
    then aNode.Name := AnsiUpperCase( aNode.Name );

//  SqlToysExec_ForEach_Node( SqlToysConvert_CaseIdentifier_Upper, aNode );
end;

{---------------------------- Sort Order Converters ---------------------------}

{ procedure for ORDER BY iteration }
procedure SqlToysConvert_SortOrder_Iteration(aProc: TSqlNodeProcedure; aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprList, gtkwOrder_By) then begin
    aNode.ForEach( aProc, False, gtsiExpr );
    aNode.ForEach( aProc, False, gtsiExprTree );
  end else
  if aNode.Check(gtsiDml, gtkwSelect) then begin
    aNode.ForEach( aProc, False, gtsiExprList, gtkwOrder_By );
  end else
  if aNode.Check(gtsiQueryList) then begin
    aNode.ForEach( aProc, False, gtsiDml, gtkwSelect );
  end;
end;

{ procedure removes uses short ASC/DESC keywords in ORDER BY clause }
procedure SqlToysConvert_SortOrder_ShortKeywords(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Check(gtsiExpr) or aNode.Check(gtsiExprTree))
  and aNode.Owner.Check(gtsiExprList) and (aNode.Owner.Keyword = gtkwOrder_By) then begin
    if aNode.KeywordAuxCheck(gtkwAscending) then begin
      aNode.KeywordAuxRemove(gtkwAscending);
      aNode.KeywordAuxAdd(gtkwAsc);
    end;
    if aNode.KeywordAuxCheck(gtkwDescending) then begin
      aNode.KeywordAuxRemove(gtkwDescending);
      aNode.KeywordAuxAdd(gtkwDesc);
    end;
  end else begin
    SqlToysConvert_SortOrder_Iteration( SqlToysConvert_SortOrder_ShortKeywords, aNode );
  end;
end;

{ procedure removes uses long ASCENDING/DESCENDING keywords in ORDER BY clause }
procedure SqlToysConvert_SortOrder_LongKeywords(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Check(gtsiExpr) or aNode.Check(gtsiExprTree))
  and aNode.Owner.Check(gtsiExprList) and (aNode.Owner.Keyword = gtkwOrder_By) then begin
    if aNode.KeywordAuxCheck(gtkwAsc) then begin
      aNode.KeywordAuxRemove(gtkwAsc);
      aNode.KeywordAuxAdd(gtkwAscending);
    end;
    if aNode.KeywordAuxCheck(gtkwDesc) then begin
      aNode.KeywordAuxRemove(gtkwDesc);
      aNode.KeywordAuxAdd(gtkwDescending);
    end;
  end else begin
    SqlToysConvert_SortOrder_Iteration( SqlToysConvert_SortOrder_LongKeywords, aNode );
  end;
end;

{ procedure adds ASC keywords in ORDER BY clause with no sort order specified }
procedure SqlToysConvert_SortOrder_AddDefaultKeywords(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Check(gtsiExpr) or aNode.Check(gtsiExprTree))
  and aNode.Owner.Check(gtsiExprList) and (aNode.Owner.Keyword = gtkwOrder_By) then begin
    if not aNode.KeywordAuxCheck(gtkwAsc, gtkwAscending, gtkwDesc, gtkwDescending)
      then aNode.KeywordAuxAdd(gtkwAscending);
  end else begin
    SqlToysConvert_SortOrder_Iteration( SqlToysConvert_SortOrder_AddDefaultKeywords, aNode );
  end;
end;

{ procedure removes ASC keywords in ORDER BY clause }
procedure SqlToysConvert_SortOrder_RemoveDefaultKeywords(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Check(gtsiExpr) or aNode.Check(gtsiExprTree))
  and aNode.Owner.Check(gtsiExprList) and (aNode.Owner.Keyword = gtkwOrder_By) then begin
    aNode.KeywordAuxRemove(gtkwAsc);
    aNode.KeywordAuxRemove(gtkwAscending);
  end else begin
    SqlToysConvert_SortOrder_Iteration( SqlToysConvert_SortOrder_RemoveDefaultKeywords, aNode );
  end;
end;

{---------------------------- Datatype Converters -----------------------------}

{ converter changes datatype keyword from INT to INTEGER }
procedure SqlToysConvert_DataType_IntToInteger(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Keyword {DataType} = gtkwInt then begin
    aNode.Keyword {DataType} := gtkwInteger;
  end;

//  SqlToysExec_ForEach_DeepInside ( SqlToysConvert_DataType_IntToInteger, aNode );
end;

{ converter changes datatype keyword from INTEGER to INT }
procedure SqlToysConvert_DataType_IntegerToInt(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Keyword {DataType} = gtkwInteger then begin
    aNode.Keyword {DataType} := gtkwInt;
  end;

//  SqlToysExec_ForEach_DeepInside ( SqlToysConvert_DataType_IntegerToInt, aNode );
end;

{------------------------------- JOIN Converters ------------------------------}

{ converter changes JOIN to INNER JOIN }
procedure SqlToysConvert_Joins_AddInner(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Keyword {Operand} = gtkwInner then aNode.KeywordExt := gtkwInner_Join;

//  SqlToysExec_ForEach_DeepInside ( SqlToysConvert_Joins_AddInner, aNode );
end;

{ converter changes INNER JOIN to JOIN }
procedure SqlToysConvert_Joins_RemoveInner(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Keyword {Operand} = gtkwInner then aNode.KeywordExt := gtkwJoin;

//  SqlToysExec_ForEach_DeepInside ( SqlToysConvert_Joins_RemoveInner, aNode );
end;

{ converter changes LEFT/RIGHT JOIN to LEFT/RIGHT OUTER JOIN }
procedure SqlToysConvert_Joins_AddOuter(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Keyword = gtkwLeft) then aNode.KeywordExt := gtkwLeft_Outer_Join else
  if (aNode.Keyword = gtkwRight)then aNode.KeywordExt := gtkwRight_Outer_Join else
  if (aNode.Keyword = gtkwFull) then aNode.KeywordExt := gtkwFull_Outer_Join;

//  SqlToysExec_ForEach_DeepInside ( SqlToysConvert_Joins_AddOuter, aNode );
end;

{ converter changes LEFT/RIGHT OUTER JOIN to LEFT/RIGHT JOIN }
procedure SqlToysConvert_Joins_RemoveOuter(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Keyword = gtkwLeft) then aNode.KeywordExt := gtkwLeft_Join else
  if (aNode.Keyword = gtkwRight)then aNode.KeywordExt := gtkwRight_Join else
  if (aNode.Keyword = gtkwFull) then aNode.KeywordExt := gtkwFull_Join;

//  SqlToysExec_ForEach_DeepInside ( SqlToysConvert_Joins_RemoveOuter, aNode );
end;

{-------------------------- JOIN condition Converters -------------------------}

{ converts join condition }
procedure SqlToysConvert_JoinCond_RefToLeft(aNode: TGtSqlNode);
var sTableNameOrAlias: String;

  procedure CheckAndSwapCondExpressions(aCond: TGtSqlNode);
  begin
    if not Assigned(aCond) then Exit;
    if aCond.Kind <> gtsiCond then Exit;
    if aCond.Keyword {Operand} <> gttkEqual then Exit;
    if aCond.Count <> 2 then Exit;

    if aCond[0].ExprHasReferenceTo(sTableNameOrAlias) then Exit;
    if not aCond[1].ExprHasReferenceTo(sTableNameOrAlias) then Exit;

    { swaps condition sides }
    aCond[0].Name := '2';
    aCond[1].Name := '1';
  end;

  procedure CondTreeGoDeepInside(aCondTree: TGtSqlNode);
  var i: Integer;
  begin
    if not Assigned(aCondTree) then Exit;

    for i := 0 to aCondTree.Count - 1 do
      if aCondTree[i].Kind = gtsiCond then CheckAndSwapCondExpressions(aCondTree[i]) else
      if aCondTree[i].Kind = gtsiCondTree then CondTreeGoDeepInside(aCondTree[i]);
  end;

begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiCondTree) and (aNode.Keyword = gtkwOn) then begin
    sTableNameOrAlias := aNode.OwnerTableNameOrAlias ;
    CondTreeGoDeepInside(aNode);
  end;
end;

{--------------------------------- Empty lines --------------------------------}

{ procedure adds empty line before clause }
//procedure SqlToysConvert_EmptyLine_Clause_Add(aNode: TGtSqlNode);
//begin
//  if not Assigned(aNode) then Exit;
//
//  if aNode.IsClause and not aNode.IsSubQuery {and not aNode.IsShortQuery}
//    then aNode.KeywordAuxAdd(gttkEmptyLineBefore);
//end;

{ procedure removes empty line before clause }
//procedure SqlToysConvert_EmptyLine_Clause_Remove(aNode: TGtSqlNode);
//begin
//  if not Assigned(aNode) then Exit;
//
//  if aNode.IsClause and not aNode.IsSubQuery {and not aNode.IsShortQuery}
//    then aNode.KeywordAuxRemove(gttkEmptyLineBefore);
//end;

{ procedure adds empty line before clause in subqueries }
//procedure SqlToysConvert_EmptyLine_ClauseSubquery_Add(aNode: TGtSqlNode);
//begin
//  if not Assigned(aNode) then Exit;
//
//  if (aNode.Owner.Kind = gtsiDml) and aNode.IsSubQuery {and not aNode.IsShortQuery} and aNode.IsClause
//    then aNode.KeywordAuxAdd(gttkEmptyLineBefore);
//end;

{ procedure removes empty line before clause in subqueries }
//procedure SqlToysConvert_EmptyLine_ClauseSubquery_Remove(aNode: TGtSqlNode);
//begin
//  if not Assigned(aNode) then Exit;
//
//  if (aNode.Owner.Kind = gtsiDml) and aNode.IsSubQuery {and not aNode.IsShortQuery} and aNode.IsClause
//    then aNode.KeywordAuxRemove(gttkEmptyLineBefore);
//end;

{ procedure adds empty line around UNION, MINUS, etc }
procedure SqlToysConvert_EmptyLine_Union_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiUnions) then begin
    aNode.KeywordAuxAdd(gttkEmptyLineBefore);
    aNode.KeywordAuxAdd(gttkEmptyLineAfter);
  end;
end;

{ procedure adds empty line around UNION, MINUS, etc }
procedure SqlToysConvert_EmptyLine_Union_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if (aNode.Kind = gtsiUnions) then begin
    aNode.KeywordAuxRemove(gttkEmptyLineBefore);
    aNode.KeywordAuxRemove(gttkEmptyLineAfter);
  end;
end;

{ procedure adds empty line before clause keyword }
procedure SqlToysConvert_NewLine_Clause_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.IsClause then aNode.KeywordAuxAdd(gttkNewLineBefore);
end;

{ procedure adds empty line before clause keyword }
procedure SqlToysConvert_NewLine_Clause_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.IsClause then aNode.KeywordAuxRemove(gttkNewLineBefore);
end;

{ procedure adds empty line before CASE }
procedure SqlToysConvert_NewLine_Case_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExpr, gtkwCase) then aNode.KeywordAuxAdd(gttkNewLineBefore);
end;

{ procedure removes empty line before CASE }
procedure SqlToysConvert_NewLine_Case_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExpr, gtkwCase) then aNode.KeywordAuxRemove(gttkNewLineBefore);
end;

{ procedure adds empty line before WHEN }
procedure SqlToysConvert_NewLine_When_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiCondTree, gtkwWhen) or aNode.Check(gtsiExprTree, gtkwWhen)
    then aNode.KeywordAuxAdd(gttkNewLineBefore);
end;

{ procedure removes empty line before WHEN }
procedure SqlToysConvert_NewLine_When_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiCondTree, gtkwWhen) or aNode.Check(gtsiExprTree, gtkwWhen)
    then aNode.KeywordAuxRemove(gttkNewLineBefore);
end;

{ procedure adds empty line before THEN }
procedure SqlToysConvert_NewLine_Then_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree, gtkwThen) then aNode.KeywordAuxAdd(gttkNewLineBefore);
end;

{ procedure removes empty line before THEN }
procedure SqlToysConvert_NewLine_Then_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree, gtkwThen) then aNode.KeywordAuxRemove(gttkNewLineBefore);
end;

{ procedure adds empty line before ELSE }
procedure SqlToysConvert_NewLine_Else_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree, gtkwElse) then aNode.KeywordAuxAdd(gttkNewLineBefore);
end;

{ procedure removes empty line before ELSE }
procedure SqlToysConvert_NewLine_Else_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree, gtkwElse) then aNode.KeywordAuxRemove(gttkNewLineBefore);
end;

{ adds empty line before CREATE TABLE CONSTRAINT }
procedure SqlToysConvert_NewLine_Bef_Constraint_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiConstraint) then aNode.KeywordAuxAdd(gttkNewLineBefore);
end;

{ removes empty line before CREATE TABLE CONSTRAINT }
procedure SqlToysConvert_NewLine_Bef_Constraint_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiConstraint) then aNode.KeywordAuxRemove(gttkNewLineBefore);
end;

{ adds new line before expression }
procedure SqlToysConvert_NewLine_Bef_Expression_Add(aNode: TGtSqlNode);
var lFirstToken: TGtLexToken;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree) and aNode.Owner.Check(gtsiExprList) and aNode.Owner.Owner.Check(gtsiDml) then begin
    lFirstToken := aNode.GetFirstToken;
    if not Assigned(lFirstToken) then Exit;

    lFirstToken.AddNewLineBeforeToken;
  end;
end;

{ removes new line before expression }
procedure SqlToysConvert_NewLine_Bef_Expression_Remove(aNode: TGtSqlNode);
var lFirstToken: TGtLexToken;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree) and aNode.Owner.Check(gtsiExprList) and aNode.Owner.Owner.Check(gtsiDml) then begin
    lFirstToken := aNode.GetFirstToken;
    if not Assigned(lFirstToken) then Exit;

    lFirstToken.RemoveNewLineBeforeToken;
  end;
end;

{ adds new line before expression with comma }
procedure SqlToysConvert_NewLine_Bef_Expression_Comma_Add (aNode: TGtSqlNode);
var lFirstToken, lPrevToken, lPrevToken2: TGtLexToken;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree) and aNode.Owner.Check(gtsiExprList) and aNode.Owner.Owner.Check(gtsiDml) then begin
    lFirstToken := aNode.GetFirstToken;
    if not Assigned(lFirstToken) then Exit;

    lPrevToken := lFirstToken.GetPrevToken(1);
    if not Assigned(lPrevToken) then Exit;

    if lPrevToken.TokenDef = gttkComma then begin
      lPrevToken.AddNewLineBeforeToken;
      Exit;
    end;
    if lPrevToken.TokenKind <> gtttWhiteSpace then Exit;

    lPrevToken2 := lPrevToken.GetPrevToken(1);
    if not Assigned(lPrevToken2) then Exit;
    if lPrevToken2.TokenDef <> gttkComma then Exit;

    lPrevToken2.AddNewLineBeforeToken;
  end;
end;

{ removes new line before expression with comma }
procedure SqlToysConvert_NewLine_Bef_Expression_Comma_Remove (aNode: TGtSqlNode);
var lFirstToken, lPrevToken, lPrevToken2: TGtLexToken;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree) and aNode.Owner.Check(gtsiExprList) and aNode.Owner.Owner.Check(gtsiDml) then begin
    lFirstToken := aNode.GetFirstToken;
    if not Assigned(lFirstToken) then Exit;

    lPrevToken := lFirstToken.GetPrevToken(1);
    if not Assigned(lPrevToken) then Exit;

    if lPrevToken.TokenDef = gttkComma then begin
      lPrevToken.RemoveNewLineBeforeToken;
      Exit;
    end;
    if lPrevToken.TokenKind <> gtttWhiteSpace then Exit;

    lPrevToken2 := lPrevToken.GetPrevToken(1);
    if not Assigned(lPrevToken2) then Exit;
    if lPrevToken2.TokenDef <> gttkComma then Exit;

    lPrevToken2.RemoveNewLineBeforeToken;
  end;
end;

{ adds new line before 1st expression when other expressions with comma on left }
procedure SqlToysConvert_NewLine_Bef_Expression_1st_Add (aNode: TGtSqlNode);
var lFirstToken, lPrevToken, lPrevToken2: TGtLexToken;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree) and aNode.Owner.Check(gtsiExprList) and
     aNode.Owner.Owner.Check(gtsiDml) and (aNode.Owner.Items[0] = aNode) then begin
    lFirstToken := aNode.GetFirstToken;
    if not Assigned(lFirstToken) then Exit;

    lPrevToken := lFirstToken.GetPrevToken(1);
    if not Assigned(lPrevToken) then Exit;
    if lPrevToken.TokenKind = gtttEndOfLine then Exit;
    if lPrevToken.TokenKind <> gtttWhiteSpace then begin
      lFirstToken.AddNewLineBeforeToken;
      Exit;
    end;

    lPrevToken2 := lPrevToken.GetPrevToken(1);
    if lPrevToken2.TokenKind = gtttEndOfLine then Exit;

    lFirstToken.AddNewLineBeforeToken;
  end;
end;

{ removes new line before 1st expression when other expressions with comma on left }
procedure SqlToysConvert_NewLine_Bef_Expression_1st_Remove (aNode: TGtSqlNode);
var lFirstToken, lPrevToken, lPrevToken2: TGtLexToken;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiExprTree) and aNode.Owner.Check(gtsiExprList) and
     aNode.Owner.Owner.Check(gtsiDml) and (aNode.Owner.Items[0] = aNode) then begin
    lFirstToken := aNode.GetFirstToken;
    if not Assigned(lFirstToken) then Exit;

    lPrevToken := lFirstToken.GetPrevToken(1);
    if not Assigned(lPrevToken) then Exit;
    if lPrevToken.TokenKind = gtttEndOfLine then begin
      lFirstToken.RemoveNewLineBeforeToken;
      Exit;
    end;
    if lPrevToken.TokenKind <> gtttWhiteSpace then Exit;

    lPrevToken2 := lPrevToken.GetPrevToken(1);
    if lPrevToken2.TokenKind = gtttEndOfLine then begin
      lPrevToken.RemoveNewLineBeforeToken;
    end;
  end;
end;

{ adds new line before condition }
procedure SqlToysConvert_NewLine_Bef_Condition_Add(aNode: TGtSqlNode);
var lFirstToken: TGtLexToken;
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiCond) and aNode.Owner.Check(gtsiCondTree) and aNode.Owner.Owner.Check(gtsiDml) then begin
    lFirstToken := aNode.GetFirstToken;
    if not Assigned(lFirstToken) then Exit;

    lFirstToken.AddNewLineBeforeToken;
  end;
end;

{ removes new line before condition }
procedure SqlToysConvert_NewLine_Bef_Condition_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;
end;

{ adds empty line before complex CONSTRAINT }
procedure SqlToysConvert_EmptyLine_Complex_Constraint_Add(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiConstraint) and not aNode.SingleColumnConstraint
    then aNode.KeywordAuxAdd(gttkEmptyLineBefore);
end;

{ removes empty line before complex CONSTRAINT }
procedure SqlToysConvert_EmptyLine_Complex_Constraint_Remove(aNode: TGtSqlNode);
begin
  if not Assigned(aNode) then Exit;

  if aNode.Check(gtsiConstraint) and not aNode.SingleColumnConstraint
    then aNode.KeywordAuxRemove(gttkEmptyLineBefore);
end;

{----------------------------------- General ----------------------------------}

{ executes token list converter }
procedure TokenListConvertExecute( aGroup, aItem, aState: Integer; aTokenList: TGtLexTokenList; aNode: TGtSqlNode );
begin
  case aGroup of
//  SQCG_GENERAL  : case aItem of
    SQCG_CASES    : case aItem of
                      SQCC_CASE_KEYWORD      : case aState of
                                                 SQCV_UPPER  : begin
                                                                 aTokenList.ForEachTokenKind     ( gtttKeyword, TokenConvert_UpperCase );
                                                                 aTokenList.ForEachTokenKindStyle( gtttWord, gtlsKeyword, TokenConvert_UpperCase );
                                                                end;
                                                 SQCV_LOWER  : begin
                                                                 aTokenList.ForEachTokenKind     ( gtttKeyword, TokenConvert_LowerCase );
                                                                 aTokenList.ForEachTokenKindStyle( gtttWord, gtlsKeyword, TokenConvert_LowerCase );
                                                               end;
                                               end;
                      SQCC_CASE_TABLE        : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTable, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTable, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_TABLE_ALIAS  : case aState of
                                                 SQCV_UPPER  : begin
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTableAlias, TokenConvert_UpperCase );
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTableAliasDef, TokenConvert_UpperCase );
                                                               end;
                                                 SQCV_LOWER  : begin
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTableAlias, TokenConvert_LowerCase );
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTableAliasDef, TokenConvert_LowerCase );
                                                               end;
                                               end;
                      SQCC_CASE_COLUMN       : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsColumn, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsColumn, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_COLUMN_ALIAS : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsColumnAlias, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsColumnAlias, TokenConvert_LowerCase );
                                               end;
//                    SQCC_CASE_COLUMN_QUOTE : case aState of
                      SQCC_CASE_PARAM        : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsParameter, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsParameter, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_FUNC         : case aState of
                                                 SQCV_UPPER  : begin
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsFunction, TokenConvert_UpperCase );
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsAggrFunction, TokenConvert_UpperCase );
                                                               end;
                                                 SQCV_LOWER  : begin
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsFunction, TokenConvert_LowerCase );
                                                                 aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsAggrFunction, TokenConvert_LowerCase );
                                                               end;
                                               end;
                      SQCC_CASE_VIEW         : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsView, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsView, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_CONSTRAINT   : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsConstraint, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsConstraint, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_SYNONYM      : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsSynonym, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsSynonym, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_TRANSACTION  : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTransaction, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTransaction, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_FUN_PARAM    : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsFunParameter, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsFunParameter, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_EXTQ_ALIAS   : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsExtQueryAliasOrTable, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsExtQueryAliasOrTable, TokenConvert_LowerCase );
                                               end;
                      SQCC_CASE_IDENTIFIER   : case aState of
                                                 SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsIdentifier, TokenConvert_UpperCase );
                                                 SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsIdentifier, TokenConvert_LowerCase );
                                               end;
                    end;
    SQCG_KEYWORD  : case aItem of
                      SQCC_KWD_AS_TABLES     : case aState of
                                                 SQCV_ADD    : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTableAliasDef, TokenConvert_AddKeywordAS );
                                                 SQCV_REMOVE : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTableAliasDef, TokenConvert_RemoveKeywordAS );
                                               end;
                      SQCC_KWD_AS_COLUMNS    : case aState of
                                                 SQCV_ADD    : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsColumnAlias, TokenConvert_AddKeywordAS );
                                                 SQCV_REMOVE : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsColumnAlias, TokenConvert_RemoveKeywordAS );
                                               end;
                      SQCC_KWD_INNER         : case aState of
                                                 SQCV_ADD    : aTokenList.ForEachTokenKeyword( gtkwJoin, TokenConvert_AddKeywordINNER );
                                                 SQCV_REMOVE : aTokenList.ForEachTokenKeyword( gtkwJoin, TokenConvert_RemoveKeywordINNER );
                                               end;
                      SQCC_KWD_OUTER         : case aState of
                                                 SQCV_ADD    : aTokenList.ForEachTokenKeyword( gtkwJoin, TokenConvert_AddKeywordOUTER );
                                                 SQCV_REMOVE : aTokenList.ForEachTokenKeyword( gtkwJoin, TokenConvert_RemoveKeywordOUTER );
                                               end;
//                      SQCC_JOIN_ON_LEFT      : case aState of
//                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_JoinCond_RefToLeft, True );
//                                               end;
                    end;
    SQCG_LINES    : case aItem of
                      SQCC_LINE_BEF_EXPR_RIGHT  : case aState of
                                                   SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_Add, True );
                                                   SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_Remove, True );
                                                  end;
                      SQCC_LINE_BEF_EXPR_LEFT   : case aState of
                                                   SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_Comma_Add, True );
                                                   SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_Comma_Remove, True );
                                                  end;
                      SQCC_LINE_BEF_EXPR_1ST   : case aState of
                                                   SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_1st_Add, True );
                                                   SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_1st_Remove, True );
                                                  end;
                      SQCC_LINE_BEF_COND        : case aState of
                                                   SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Bef_Condition_Add, True );
                                                   SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Bef_Condition_Remove, True );
                                                  end;
                    end;
//  SQCG_EMPTY    : case aItem of
    SQCG_SPACES   : case aItem of
                      SQCC_SPACE_BEF_SEMICOLON  : case aState of
                                                    SQCV_ADD    : aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsSemicolon, TokenConvert_AddSpaceBefore );
                                                    SQCV_REMOVE : aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsSemicolon, TokenConvert_RemoveSpaceBefore );
                                                  end;
                      SQCC_SPACE_BEF_COMMA      : case aState of
                                                    SQCV_ADD    : aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsComma, TokenConvert_AddSpaceBefore );
                                                    SQCV_REMOVE : aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsComma, TokenConvert_RemoveSpaceBefore );
                                                  end;
                      SQCC_SPACE_AFT_COMMA      : case aState of
                                                    SQCV_ADD    : aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsComma, TokenConvert_AddSpaceAfter );
                                                    SQCV_REMOVE : aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsComma, TokenConvert_RemoveSpaceAfter );
                                                  end;
                      SQCC_SPACE_AROUND_OPER    : case aState of
                                                    SQCV_ADD    : begin
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsOperator, TokenConvert_AddSpaceBefore );
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsOperator, TokenConvert_AddSpaceAfter );
                                                    end;
                                                    SQCV_REMOVE : begin
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsOperator, TokenConvert_RemoveSpaceBefore );
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsOperator, TokenConvert_RemoveSpaceAfter );
                                                    end;
                                                  end;
                      SQCC_SPACE_INSIDE_BRACKET : case aState of
                                                    SQCV_ADD    : begin
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketOpen1,  TokenConvert_AddSpaceAfter );
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketClose1, TokenConvert_AddSpaceBefore );
                                                    end;
                                                    SQCV_REMOVE : begin
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketOpen1,  TokenConvert_RemoveSpaceAfter );
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketClose1, TokenConvert_RemoveSpaceBefore );
                                                    end;
                                                  end;
                      SQCC_SPACE_OUTSIDE_BRACKET: case aState of
                                                    SQCV_ADD    : begin
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketOpen1,  TokenConvert_AddSpaceBefore );
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketClose1, TokenConvert_AddSpaceAfter );
                                                    end;
                                                    SQCV_REMOVE : begin
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketOpen1,  TokenConvert_RemoveSpaceBefore );
                                                      aTokenList.ForEachTokenKindStyle( gtttRelevant, gtlsBracketClose1, TokenConvert_RemoveSpaceAfter );
                                                    end;
                                                  end;
                    end;
  end;
end;

{ executes syntax tree converter }
procedure SyntaxTreeConvertExecute( aGroup, aItem, aState: Integer; aNode: TGtSqlNode );
begin
  case aGroup of
    SQCG_INTEND   : case aItem of
                      SQCC_INT_CLAUSE_BODY   : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_Intend_Clause_Body_Add,    True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_Intend_Clause_Body_Remove, True );

                                               end;
                      SQCC_INT_CLAUSE_RGHT   : case aState of
                                                 SQCV_ADD    : ;
                                                 SQCV_REMOVE : ;
                                               end;
                    end;
    SQCG_OTHER    : case aItem of
                      SQCC_OTH_SEMICOLON     : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_Semicolon_Add,    False {True} );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_Semicolon_Remove, False {True} );
                                               end;
                      SQCC_OTH_SEMICOLON_SQ  : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_Semicolon_SingleQuery_Add, False {True} );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_Semicolon_SingleQuery_Remove, False {True} );
                                               end;
                    end;
    SQCG_CASES    : case aItem of
                      SQCC_CASE_KEYWORD      : case aState of
                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseKeyword_Upper, True );
                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseKeyword_Lower, True );
                                               end;
                      SQCC_CASE_TABLE        : case aState of
                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseTableName_Upper, True );
                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseTableName_Lower, True );
                                               end;
                      SQCC_CASE_TABLE_ALIAS  : case aState of
                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseTableAlias_Upper, True );
                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseTableAlias_Lower, True );
                                               end;
                      SQCC_CASE_COLUMN       : case aState of
                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseColumnName_Upper, True );
                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseColumnName_Lower, True );
                                               end;
                      SQCC_CASE_COLUMN_ALIAS : case aState of
                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseColumnAlias_Upper, True );
                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseColumnAlias_Lower, True );
                                               end;
//                      SQCC_CASE_COLUMN_QUOTE : case aState of
//                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseColumnQuotedAlias_Upper, True );
//                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseColumnQuotedAlias_Lower, True );
//                                               end;
                      SQCC_CASE_PARAM        : case aState of
                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseParam_Upper, True );
                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseParam_Lower, True );
                                               end;
                      SQCC_CASE_FUNC         : case aState of
                                                 SQCV_UPPER  : aNode.ForEach( SqlToysConvert_CaseFunc_Upper, True );
                                                 SQCV_LOWER  : aNode.ForEach( SqlToysConvert_CaseFunc_Lower, True );
                                               end;
//                      SQCC_CASE_VIEW         : case aState of
//                                               SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsView, TokenConvert_UpperCase );
//                                               SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsView, TokenConvert_LowerCase );
//                                               end;
//                      SQCC_CASE_CONSTRAINT   : case aState of
//                                               SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsConstraint, TokenConvert_UpperCase );
//                                               SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsConstraint, TokenConvert_LowerCase );
//                                               end;
//                      SQCC_CASE_SYNONYM      : case aState of
//                                               SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsSynonym, TokenConvert_UpperCase );
//                                               SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsSynonym, TokenConvert_LowerCase );
//                                               end;
//                      SQCC_CASE_TRANSACTION  : case aState of
//                                               SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTransaction, TokenConvert_UpperCase );
//                                               SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsTransaction, TokenConvert_LowerCase );
//                                               end;
//                      SQCC_CASE_FUN_PARAM    : case aState of
//                                               SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsFunParameter, TokenConvert_UpperCase );
//                                               SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsFunParameter, TokenConvert_LowerCase );
//                                               end;
//                      SQCC_CASE_EXTQ_ALIAS   : case aState of
//                                               SQCV_UPPER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsExtQueryAliasOrTable, TokenConvert_UpperCase );
//                                               SQCV_LOWER  : aTokenList.ForEachTokenKindStyle( gtttIdentifier, gtlsExtQueryAliasOrTable, TokenConvert_LowerCase );
//                                               end;
                    end;
    SQCG_KEYWORD  : case aItem of
                      SQCC_KWD_AS_TABLES     : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_TableAlias_AddKeyword_AS, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_TableAlias_RemoveKeyword_AS, True );
                                               end;
                      SQCC_KWD_AS_COLUMNS    : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_ExprAlias_AddKeyword_AS, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_ExprAlias_RemoveKeyword_AS, True );
                                               end;
                      SQCC_KWD_INT           : case aState of
                                                 SQCV_SHORT  : aNode.ForEach( SqlToysConvert_DataType_IntegerToInt, True );
                                                 SQCV_LONG   : aNode.ForEach( SqlToysConvert_DataType_IntToInteger, True );
                                               end;
                      SQCC_KWD_INNER         : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_Joins_AddInner, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_Joins_RemoveInner, True );
                                               end;
                      SQCC_KWD_OUTER         : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_Joins_AddOuter, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_Joins_RemoveOuter, True );
                                               end;
                      SQCC_JOIN_ON_LEFT      : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_JoinCond_RefToLeft, True );
                                               end;
                      SQCC_KWD_ORDER_LEN     : case aState of
                                                 SQCV_SHORT  : aNode.ForEach( SqlToysConvert_SortOrder_ShortKeywords, True );
                                                 SQCV_LONG   : aNode.ForEach( SqlToysConvert_SortOrder_LongKeywords, True );
                                               end;
                      SQCC_KWD_ORDER_DEF     : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_SortOrder_AddDefaultKeywords, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_SortOrder_RemoveDefaultKeywords, True );
                      end;
                    end;
    SQCG_LINES    : case aItem of
                      SQCC_LINE_CLAUSE       : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Clause_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Clause_Remove, True );
                                               end;
                      SQCC_LINE_CASE_CASE    : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Case_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Case_Remove, True );
                                               end;
                      SQCC_LINE_CASE_WHEN    : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_When_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_When_Remove, True );
                                               end;
                      SQCC_LINE_CASE_THEN    : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Then_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Then_Remove, True );
                                               end;
                      SQCC_LINE_CASE_ELSE    : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Else_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Else_Remove, True );
                                               end;
//                      SQCC_LINE_CASE_END     : case aState of
//                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_End_Add, True );
//                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_End_Remove, True );
//                                               end;
                      SQCC_LINE_BEF_CONSTR   : case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Bef_Constraint_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Bef_Constraint_Remove, True );
                                               end;
//                      SQCC_LINE_AFT_CONSTR   : case aState of
//                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Aft_Constraint_Add, True );
//                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Aft_Constraint_Remove, True );
//                                               end;
//                      SQCC_LINE_BEF_EXPR        : case aState of
//                                                   SQCV_ADD    : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_Add, True );
//                                                   SQCV_REMOVE : aNode.ForEach( SqlToysConvert_NewLine_Bef_Expression_Remove, True );
//                                                  end;
                    end;
    SQCG_EMPTY    : case aItem of
//                      SQCC_EMPTY_BEF_CLAUSE  : case aState of
//                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_EmptyLine_Clause_Add, True );
//                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_EmptyLine_Clause_Remove, True );
//                                               end;
//                      SQCC_EXC_SUBQUERY      : case aState of
//                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_EmptyLine_ClauseSubquery_Add, True );
//                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_EmptyLine_ClauseSubquery_Remove, True );
//                                               end;
//                      SQCC_EXC_SHORT_QUERY   : case aState of
//                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_EmptyLine_ClauseShortQuery_Add, True );
//                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_EmptyLine_ClauseShortQuery_Remove, True );
//                                               end;
                      SQCC_EMPTY_AROUND_UNION: case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_EmptyLine_Union_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_EmptyLine_Union_Remove, True );
                                               end;
                      SQCC_EMPTY_CMPLX_CONSTR: case aState of
                                                 SQCV_ADD    : aNode.ForEach( SqlToysConvert_EmptyLine_Complex_Constraint_Add, True );
                                                 SQCV_REMOVE : aNode.ForEach( SqlToysConvert_EmptyLine_Complex_Constraint_Remove, True );
                                               end;
                    end;
  end;
end;

end.

