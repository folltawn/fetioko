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
    let err = newCompilerError(ecUnknown, p.ctx.mainFile, 
                               if rparenToken != nil: rparenToken.line else: startToken.line,
                               if rparenToken != nil: rparenToken.col else: startToken.col)
    raise err
  
  # Позиция для ошибки — сразу после закрывающей скобки
  let errorLine = rparenToken.line
  let errorCol = rparenToken.col + 1  # следующий символ после ')'
  
  p.advance()  # пропускаем tkRParen
  
  # Проверяем ;
  if p.current == nil or p.current.kind != tkSemi:
    let err = newCompilerError(ecMissingSemicolon, p.ctx.mainFile, errorLine, errorCol)
    report(err)
    printErrorSummary()
    quit(1)
  
  p.advance()
  
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

proc parseFunction(p: Parser): ASTNode =
  let startToken = p.current
  var isPub = false
  
  # pub?
  if p.current != nil and p.current.kind == tkPub:
    isPub = true
    p.advance()
  
  # return type (int, str, etc.)
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
  
  # parameters (
  discard p.expect(tkLParen)
  
  var params: seq[Param] = @[]
  # TODO: parse parameters
  
  discard p.expect(tkRParen)
  
  # body {
  discard p.expect(tkLBrace)
  
  var body: seq[ASTNode] = @[]
  while p.current != nil and p.current.kind != tkRBrace:
    case p.current.kind
    of tkSendLn:
      body.add(p.parseSendLn())
    of tkReturn:
      body.add(p.parseReturn())
    else:
      let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
      raise err
  
  discard p.expect(tkRBrace)
  
  # Проверяем, что функция возвращает значение
  var hasReturn = false
  for node in body:
    if node.kind == nkReturn:
      hasReturn = true
      break
  
  if not hasReturn and funcName != "main":
    let err = newCompilerError(ecMissingReturn, p.ctx.mainFile, startToken.line, startToken.col)
    report(err)
    quit(1)
  
  return ASTNode(
    kind: nkFunction,
    line: startToken.line,
    col: startToken.col,
    pub: isPub,
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
    of tkPub, tkInt, tkStr, tkFloat, tkChar, tkBool, tkDoubleType:
      result.add(p.parseFunction())
    else:
      let err = newCompilerError(ecUnknown, p.ctx.mainFile, p.current.line, p.current.col)
      raise err

proc initParser*(ctx: Context, tokens: seq[Token]): Parser =
  return Parser(ctx: ctx, tokens: tokens, pos: 0)