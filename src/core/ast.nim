import ./tokens

type
  ASTKind* = enum
    nkSendLn
    nkReturn
    nkFunction
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
    of nkFunction:
      pub*: bool
      returnType*: string
      name*: string
      params*: seq[Param]
      body*: seq[ASTNode]
    of nkEOF:
      discard

  Param* = ref object
    name*: string
    paramType*: string

  SendLnArgKind* = enum
    akString
    akInt
    akFloat
    akBool
    akIdent

  SendLnArg* = ref object
    kind*: SendLnArgKind
    strVal*: string
    intVal*: int
    floatVal*: float
    boolVal*: bool
    identVal*: string