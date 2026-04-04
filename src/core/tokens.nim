type
  TokenKind* = enum
    # Keywords
    tkSendLn, tkPub, tkReturn, tkUse, tkLet, tkVar, tkConst
    # Types
    tkInt, tkStr, tkFloat, tkChar, tkBool, tkDoubleType
    # Punctuation
    tkLParen, tkRParen, tkLBrace, tkRBrace, tkSemi, tkComma, tkDoubleColon, tkPipe, tkBang
    # Operators
    tkEq, tkPlus, tkMinus, tkMul, tkDiv
    # Values
    tkIdent, tkStringLit, tkIntLit, tkFloatLit, tkBoolLit, tkCharLit
    # Special
    tkEOF, tkError

  Token* = ref object
    kind*: TokenKind
    lexeme*: string
    line*: int
    col*: int

proc newToken*(kind: TokenKind, lexeme: string, line, col: int): Token =
  Token(kind: kind, lexeme: lexeme, line: line, col: col)

proc `$`*(t: Token): string =
  $t.kind & "(\"" & t.lexeme & "\"@" & $t.line & ":" & $t.col & ")"