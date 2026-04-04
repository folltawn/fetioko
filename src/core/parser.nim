import std/strutils
import ./tokens
import ./context
import ./errors
import ./ast

type
  Parser* = ref object
    ctx*: Context
    tokens*: seq[Token]
    pos*: int

proc current(p: Parser): Token =
  if p.pos < p.tokens.len:
    return p.tokens[p.pos]
  return nil

proc peek(p: Parser): Token =
  if p.pos + 1 < p.tokens.len:
    return p.tokens[p.pos + 1]
  return nil

proc advance(p: Parser) =
  inc p.pos

proc expect(p: Parser, kind: TokenKind): Token =
  let tok = p.current
  if tok == nil or tok.kind != kind:
    let err = newCompilerError(
      ecUnknown,
      p.ctx.mainFile,
      if tok != nil: tok.line else: 1,
      if tok != nil: tok.col else: 1
    )
    raise err
  p.advance()
  return tok

proc parseExpression(p: Parser): SendLnArg =
  let tok = p.current
  if tok == nil:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, 1, 1)
    raise err
  
  case tok.kind
  of tkStringLit:
    if tok.lexeme == "Unclosed string":
      let err = newCompilerError(ecMissingStringQuote, p.ctx.mainFile, tok.line, tok.col)
      report(err)
      printErrorSummary()
      quit(1)
    p.advance()
    return SendLnArg(kind: akString, strVal: tok.lexeme)
  of tkIntLit:
    p.advance()
    return SendLnArg(kind: akInt, intVal: parseInt(tok.lexeme))
  of tkFloatLit:
    p.advance()
    return SendLnArg(kind: akFloat, floatVal: parseFloat(tok.lexeme))
  of tkBoolLit:
    p.advance()
    return SendLnArg(kind: akBool, boolVal: tok.lexeme == "true")
  of tkCharLit:
    p.advance()
    let ch = if tok.lexeme.len > 0: tok.lexeme[0] else: '\0'
    return SendLnArg(kind: akChar, charVal: ch)
  of tkIdent:
    p.advance()
    return SendLnArg(kind: akIdent, identVal: tok.lexeme)
  else:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, tok.line, tok.col)
    raise err

proc parseSendLn(p: Parser): ASTNode =
  let startToken = p.current
  if startToken == nil:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, 1, 1)
    raise err
  
  discard p.expect(tkSendLn)
  
  if p.current != nil and p.current.kind == tkBang:
    p.advance()
  
  discard p.expect(tkLParen)
  
  var args: seq[SendLnArg] = @[]
  var concat = false
  
  while p.current != nil and p.current.kind != tkRParen:
    if p.current.kind == tkPipe:
      concat = true
      p.advance()
    else:
      args.add(p.parseExpression())
  
  # Запоминаем позицию закрывающей скобки
  let rparenToken = p.current
  if rparenToken == nil or rparenToken.kind != tkRParen:
    let err = newCompilerError(ecMissingRParen, p.ctx.mainFile, 
                               if rparenToken != nil: rparenToken.line else: startToken.line,
                               if rparenToken != nil: rparenToken.col else: startToken.col)
    raise err
  
  let rparenLine = rparenToken.line
  let rparenCol = rparenToken.col
  
  p.advance()  # пропускаем )
  
  # Проверяем точку с запятой СРАЗУ после скобки
  if p.current == nil or p.current.kind != tkSemi:
    # Ошибка на позиции закрывающей скобки + 1
    let err = newCompilerError(ecMissingSemicolon, p.ctx.mainFile, rparenLine, rparenCol + 1)
    report(err)
    printErrorSummary()
    quit(1)
  
  p.advance()  # пропускаем ;
  
  return ASTNode(
    kind: nkSendLn,
    line: startToken.line,
    col: startToken.col,
    args: args,
    concat: concat
  )

proc parseReturn(p: Parser): ASTNode =
  let startToken = p.current
  if startToken == nil:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, 1, 1)
    raise err
  
  discard p.expect(tkReturn)
  var value = ""
  if p.current != nil and p.current.kind != tkSemi:
    value = p.current.lexeme
    p.advance()
  discard p.expect(tkSemi)
  
  return ASTNode(
    kind: nkReturn,
    line: startToken.line,
    col: startToken.col,
    retValue: value
  )

proc parseVariable(p: Parser): ASTNode =
  let startToken = p.current
  var isPub = false
  
  # pub?
  if p.current != nil and p.current.kind == tkPub:
    isPub = true
    p.advance()
  
  # modifier (let, var, const)
  if p.current == nil or p.current.kind notin [tkLet, tkVar, tkConst]:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  
  let modifier = case p.current.kind
    of tkLet: vmLet
    of tkVar: vmVar
    of tkConst: vmConst
    else: vmLet
  
  p.advance()
  
  # ::
  if p.current == nil or p.current.kind != tkDoubleColon:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  p.advance()
  
  # type
  if p.current == nil or p.current.kind notin [tkInt, tkStr, tkFloat, tkChar, tkBool, tkDoubleType]:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  
  let varType = p.current.lexeme
  p.advance()
  
  # name
  if p.current == nil or p.current.kind != tkIdent:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  
  let varName = p.current.lexeme
  p.advance()
  
  # =
  if p.current == nil or p.current.kind != tkEq:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  p.advance()
  
  # value
  var value = ""
  if p.current != nil:
    case p.current.kind
    of tkIntLit:
      value = p.current.lexeme
    of tkStringLit:
      value = "\"" & p.current.lexeme & "\""
    of tkCharLit:
      value = "'" & p.current.lexeme & "'"
    of tkIdent:
      value = p.current.lexeme
    else:
      let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
      report(err)
      printErrorSummary()
      quit(1)
    p.advance()
  
  # ;
  if p.current == nil or p.current.kind != tkSemi:
    let err = newCompilerError(ecMissingSemicolon, p.ctx.mainFile, 
                               p.current.line, p.current.col)
    report(err)
    printErrorSummary()
    quit(1)
  p.advance()
  
  return ASTNode(
    kind: nkVariable,
    line: startToken.line,
    col: startToken.col,
    varPub: isPub,
    modifier: modifier,
    varType: varType,
    varName: varName,
    value: value
  )

proc parseAssignment(p: Parser): ASTNode =
  let startToken = p.current
  
  # name
  if p.current == nil or p.current.kind != tkIdent:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  
  let assignName = p.current.lexeme
  p.advance()
  
  # =
  if p.current == nil or p.current.kind != tkEq:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  p.advance()
  
  # value
  var assignValue = ""
  if p.current != nil:
    case p.current.kind
    of tkIntLit:
      assignValue = p.current.lexeme
    of tkStringLit:
      assignValue = "\"" & p.current.lexeme & "\""
    of tkCharLit:
      assignValue = "'" & p.current.lexeme & "'"
    of tkIdent:
      assignValue = p.current.lexeme
    else:
      let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
      report(err)
      printErrorSummary()
      quit(1)
    p.advance()
  
  # ;
  if p.current == nil or p.current.kind != tkSemi:
    let err = newCompilerError(ecMissingSemicolon, p.ctx.mainFile, 
                               p.current.line, p.current.col)
    report(err)
    printErrorSummary()
    quit(1)
  p.advance()
  
  return ASTNode(
    kind: nkAssignment,
    line: startToken.line,
    col: startToken.col,
    assignName: assignName,
    assignValue: assignValue
  )

proc parseFunction(p: Parser): ASTNode =
  let startToken = p.current
  var isPub = false
  
  # pub?
  if p.current != nil and p.current.kind == tkPub:
    isPub = true
    p.advance()
  
  # return type
  if p.current == nil or p.current.kind notin [tkInt, tkStr, tkFloat, tkChar, tkBool, tkDoubleType]:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  
  let returnType = p.current.lexeme
  p.advance()
  
  # function name
  if p.current == nil or p.current.kind != tkIdent:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  
  let funcName = p.current.lexeme
  p.advance()
  
  # (
  if p.current == nil or p.current.kind != tkLParen:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  p.advance()
  
  # parameters
  var params: seq[Param] = @[]
  while p.current != nil and p.current.kind != tkRParen:
    # параметры пока не поддерживаются
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  
  # )
  if p.current == nil or p.current.kind != tkRParen:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  p.advance()
  
  # {
  if p.current == nil or p.current.kind != tkLBrace:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  p.advance()
  
  # body
  var body: seq[ASTNode] = @[]
  while p.current != nil and p.current.kind != tkRBrace:
    case p.current.kind
    of tkSendLn:
      body.add(p.parseSendLn())
    of tkReturn:
      body.add(p.parseReturn())
    of tkLet, tkVar, tkConst:
      body.add(p.parseVariable())
    of tkIdent:
      let next = p.peek()
      if next != nil and next.kind == tkEq:
        body.add(p.parseAssignment())
      else:
        let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
        raise err
    else:
      let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
      raise err
  
  # }
  if p.current == nil or p.current.kind != tkRBrace:
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
    raise err
  p.advance()
  
  return ASTNode(
    kind: nkFunction,
    line: startToken.line,
    col: startToken.col,
    funcPub: isPub,
    returnType: returnType,
    name: funcName,
    params: params,
    body: body
  )

proc parse*(p: Parser): seq[ASTNode] =
  result = @[]
  while p.current != nil and p.current.kind != tkEOF:
    case p.current.kind
    of tkSendLn:
      result.add(p.parseSendLn())
    of tkReturn:
      result.add(p.parseReturn())
    of tkPub:
      let next = p.peek()
      if next != nil and next.kind in [tkInt, tkStr, tkFloat, tkChar, tkBool, tkDoubleType]:
        result.add(p.parseFunction())
      else:
        result.add(p.parseVariable())
    of tkLet, tkVar, tkConst:
      result.add(p.parseVariable())
    of tkInt, tkStr, tkFloat, tkChar, tkBool, tkDoubleType:
      let next = p.peek()
      if next != nil and next.kind == tkIdent:
        result.add(p.parseFunction())
      else:
        result.add(p.parseVariable())
    of tkIdent:
      # может быть присваивание или вызов функции
      let next = p.peek()
      if next != nil and next.kind == tkEq:
        result.add(p.parseAssignment())
      else:
        let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
        raise err
    else:
      let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
      raise err

proc initParser*(ctx: Context, tokens: seq[Token]): Parser =
  return Parser(ctx: ctx, tokens: tokens, pos: 0)