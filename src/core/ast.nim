type
  ASTKind* = enum
    nkSendLn
    nkReturn
    nkEOF
  
  ASTNode* = ref object
    line*: int
    col*: int
    case kind*: ASTKind
    of nkSendLn:
      args*: seq[SendLnArg]
      concat*: bool
    of nkReturn:
      retValue*: string
    of nkEOF:
      discard

  SendLnArgKind* = enum
    akString
    akInt
    akFloat
    akBool
    akIdent

  SendLnArg* = ref object
    case kind*: SendLnArgKind
    of akString:
      strVal*: string
    of akInt:
      intVal*: int
    of akFloat:
      floatVal*: float
    of akBool:
      boolVal*: bool
    of akIdent:
      identVal*: string