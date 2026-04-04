import ./tokens
import ./context
import ../constructs/sendln/sem

type
  ASTKind* = enum
    nkSendLn, nkReturn, nkEOF
  
  ASTNode* = ref object
    kind*: ASTKind
    line*: int
    col*: int
    case*: ASTKind
    of nkSendLn:
      args*: seq[SendLnArg]
      concat*: bool
    of nkReturn:
      retValue*: string
    of nkEOF:
      discard

  SendLnArgKind* = enum
    akString, akInt, akFloat, akBool, akIdent

  SendLnArg* = ref object
    kind*: SendLnArgKind
    strVal*: string
    intVal*: int
    floatVal*: float
    boolVal*: bool
    identVal*: string

  Parser* = ref object
    ctx*: Context
    tokens*: seq[Token]
    pos*: int

proc current(p: Parser): Token =
  if p.pos < p.tokens.len: p.tokens[p.pos] else: nil

proc peek(p: Parser): Token =
  if p.pos + 1 < p.tokens.len: p.tokens[p.pos + 1] else: nil

proc advance(p: Parser) =
  inc p.pos

proc expect(p: Parser, kind: TokenKind): Token =
  if p.current.kind != kind:
    raise newCompilerError("Expected " & $kind & ", got " & $p.current.kind,
                          p.ctx.mainFile, p.current.line, p.current.col)
  result = p.current
  p.advance()

proc parseExpression(p: Parser): SendLnArg =
  let tok = p.current
  case tok.kind
  of tkStringLit:
    p.advance()
    SendLnArg(kind: akString, strVal: tok.lexeme)
  of tkIntLit:
    p.advance()
    SendLnArg(kind: akInt, intVal: parseInt(tok.lexeme))
  of tkFloatLit:
    p.advance()
    SendLnArg(kind: akFloat, floatVal: parseFloat(tok.lexeme))
  of tkBoolLit:
    p.advance()
    SendLnArg(kind: akBool, boolVal: tok.lexeme == "true")
  of tkIdent:
    p.advance()
    SendLnArg(kind: akIdent, identVal: tok.lexeme)
  else:
    raise newCompilerError("Expected expression", p.ctx.mainFile, tok.line, tok.col)

proc parseSendLn(p: Parser): ASTNode =
  let startToken = p.current
  p.expect(tkSendLn)
  p.expect(tkLParen)
  
  var args: seq[SendLnArg] = @[]
  var concat = false
  
  while p.current.kind != tkRParen:
    if p.current.kind == tkPipe:
      concat = true
      p.advance()
    else:
      args.add(p.parseExpression())
  
  p.expect(tkRParen)
  p.expect(tkSemi)
  
  ASTNode(
    kind: nkSendLn,
    line: startToken.line,
    col: startToken.col,
    args: args,
    concat: concat
  )

proc parseReturn(p: Parser): ASTNode =
  let startToken = p.current
  p.expect(tkReturn)
  var value = ""
  if p.current.kind != tkSemi:
    value = p.current.lexeme
    p.advance()
  p.expect(tkSemi)
  ASTNode(kind: nkReturn, line: startToken.line, col: startToken.col, retValue: value)

proc parse*(p: Parser): seq[ASTNode] =
  result = @[]
  while p.current.kind != tkEOF:
    case p.current.kind
    of tkSendLn:
      result.add(p.parseSendLn())
    of tkReturn:
      result.add(p.parseReturn())
    else:
      raise newCompilerError("Unexpected token: " & $p.current.kind,
                            p.ctx.mainFile, p.current.line, p.current.col)

proc initParser*(ctx: Context, tokens: seq[Token]): Parser =
  Parser(ctx: ctx, tokens: tokens, pos: 0)