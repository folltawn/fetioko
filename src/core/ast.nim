import ./tokens

type
  ASTKind* = enum
    nkSendLn
    nkReturn
    nkFunction
    nkVariable
    nkAssignment  # добавлено
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
      funcPub*: bool
      returnType*: string
      name*: string
      params*: seq[Param]
      body*: seq[ASTNode]
    of nkVariable:
      varPub*: bool
      modifier*: VarModifier
      varType*: string
      varName*: string
      value*: string
    of nkAssignment:
      assignName*: string
      assignValue*: string
    of nkEOF:
      discard

  VarModifier* = enum
    vmLet      # локальная неизменяемая
    vmVar      # локальная изменяемая
    vmConst    # глобальная неизменяемая (статическая внутри функции)

  Param* = ref object
    name*: string
    paramType*: string

  SendLnArgKind* = enum
    akString
    akInt
    akFloat
    akBool
    akChar
    akIdent

  SendLnArg* = ref object
    kind*: SendLnArgKind
    strVal*: string
    intVal*: int
    floatVal*: float
    boolVal*: bool
    charVal*: char
    identVal*: string