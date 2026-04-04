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
  
  var kind = tkIdent
  if Keywords.hasKey(ident):
    kind = Keywords[ident]
  
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
  l.advance()  # skip opening quote
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
    l.advance()  # skip closing quote
    result = newToken(tkStringLit, str, startLine, startCol)
  else:
    # Дошли до конца файла, а кавычка не закрыта
    result = newToken(tkError, "Unclosed string", startLine, startCol)

proc getNextToken*(l: Lexer): Token =
  l.skipWhitespace()
  let startLine = l.line
  let startCol = l.col
  
  case l.ch
  of '\0':
    return newToken(tkEOF, "", startLine, startCol)
  of 'a'..'z', 'A'..'Z', '_':
    return l.readIdent()
  of '0'..'9':
    return l.readNumber()
  of '"':
    return l.readString()
  of '(':
    l.advance()
    return newToken(tkLParen, "(", startLine, startCol)
  of ')':
    l.advance()
    return newToken(tkRParen, ")", startLine, startCol)
  of '{':
    l.advance()
    return newToken(tkLBrace, "{", startLine, startCol)
  of '}':
    l.advance()
    return newToken(tkRBrace, "}", startLine, startCol)
  of ';':
    l.advance()
    return newToken(tkSemi, ";", startLine, startCol)
  of ',':
    l.advance()
    return newToken(tkComma, ",", startLine, startCol)
  of '=':
    l.advance()
    return newToken(tkEq, "=", startLine, startCol)
  of '|':
    l.advance()
    return newToken(tkPipe, "|", startLine, startCol)
  of '+':
    l.advance()
    return newToken(tkPlus, "+", startLine, startCol)
  of '-':
    l.advance()
    return newToken(tkMinus, "-", startLine, startCol)
  of '*':
    l.advance()
    return newToken(tkMul, "*", startLine, startCol)
  of '/':
    l.advance()
    if l.ch == '/':
      # Однострочный комментарий — пропускаем до конца строки
      while l.ch != '\n' and l.ch != '\0':
        l.advance()
      # После пропуска комментария продолжаем с новой строки
      return l.getNextToken()
    else:
      return newToken(tkDiv, "/", startLine, startCol)
  of '!':
    l.advance()
    return newToken(tkBang, "!", startLine, startCol)
  of ':':
    l.advance()
    if l.ch == ':':
      l.advance()
      return newToken(tkDoubleColon, "::", startLine, startCol)
    else:
      return newToken(tkError, ":", startLine, startCol)
  else:
    let err = l.ch
    l.advance()
    return newToken(tkError, $err, startLine, startCol)