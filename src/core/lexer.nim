import std/[strutils, tables]
import ./tokens

type
  Lexer* = ref object
    source: string
    pos: int
    line: int
    col: int
    ch: char

const Keywords = {
  "sendln": tkSendLn, "pub": tkPub, "return": tkReturn, "use": tkUse,
  "let": tkLet, "var": tkVar, "const": tkConst,
  "int": tkInt, "str": tkStr, "float": tkFloat, "char": tkChar,
  "bool": tkBool, "double": tkDoubleType,
  "true": tkBoolLit, "false": tkBoolLit
}.toTable()

proc initLexer*(source: string): Lexer =
  Lexer(source: source, pos: 0, line: 1, col: 1, ch: if source.len > 0: source[0] else: '\0')

proc peek(l: Lexer): char =
  if l.pos + 1 < l.source.len: l.source[l.pos + 1] else: '\0'

proc advance(l: Lexer) =
  if l.ch == '\n':
    inc l.line
    l.col = 1
  else:
    inc l.col
  inc l.pos
  l.ch = if l.pos < l.source.len: l.source[l.pos] else: '\0'

proc skipWhitespace(l: Lexer) =
  while l.ch in {' ', '\t', '\r', '\n'}:
    l.advance()

proc readIdent(l: Lexer): Token =
  let startLine = l.line
  let startCol = l.col
  var ident = ""
  while l.ch.isAlphaNumeric() or l.ch == '_':
    ident.add(l.ch)
    l.advance()
  let kind = Keywords.get(ident, tkIdent)
  newToken(kind, ident, startLine, startCol)

proc readNumber(l: Lexer): Token =
  let startLine = l.line
  let startCol = l.col
  var num = ""
  var isFloat = false
  while l.ch.isDigit() or l.ch == '.':
    if l.ch == '.':
      if isFloat: break
      isFloat = true
    num.add(l.ch)
    l.advance()
  let kind = if isFloat: tkFloatLit else: tkIntLit
  newToken(kind, num, startLine, startCol)

proc readString(l: Lexer): Token =
  let startLine = l.line
  let startCol = l.col
  l.advance()
  var str = ""
  while l.ch != '"' and l.ch != '\0':
    if l.ch == '\\':
      l.advance()
      case l.ch
      of 'n': str.add('\n')
      of 't': str.add('\t')
      of '\\': str.add('\\')
      of '"': str.add('"')
      else: str.add(l.ch)
    else:
      str.add(l.ch)
    l.advance()
  if l.ch == '"':
    l.advance()
  newToken(tkStringLit, str, startLine, startCol)

proc getNextToken*(l: Lexer): Token =
  l.skipWhitespace()
  let startLine = l.line
  let startCol = l.col
  case l.ch
  of '\0': newToken(tkEOF, "", startLine, startCol)
  of 'a'..'z', 'A'..'Z', '_': l.readIdent()
  of '0'..'9': l.readNumber()
  of '"': l.readString()
  of '(': l.advance(); newToken(tkLParen, "(", startLine, startCol)
  of ')': l.advance(); newToken(tkRParen, ")", startLine, startCol)
  of '{': l.advance(); newToken(tkLBrace, "{", startLine, startCol)
  of '}': l.advance(); newToken(tkRBrace, "}", startLine, startCol)
  of ';': l.advance(); newToken(tkSemi, ";", startLine, startCol)
  of ',': l.advance(); newToken(tkComma, ",", startLine, startCol)
  of '=': l.advance(); newToken(tkEq, "=", startLine, startCol)
  of '|': l.advance(); newToken(tkPipe, "|", startLine, startCol)
  of '+': l.advance(); newToken(tkPlus, "+", startLine, startCol)
  of '-': l.advance(); newToken(tkMinus, "-", startLine, startCol)
  of '*': l.advance(); newToken(tkMul, "*", startLine, startCol)
  of '/': l.advance(); newToken(tkDiv, "/", startLine, startCol)
  of ':':
    l.advance()
    if l.ch == ':':
      l.advance()
      newToken(tkDoubleColon, "::", startLine, startCol)
    else:
      newToken(tkError, ":", startLine, startCol)
  else:
    newToken(tkError, $l.ch, startLine, startCol)