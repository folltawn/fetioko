import tables
import ./ast

type
  SymbolKind* = enum
    skVariable
    skFunction
    skConstant

  Symbol* = ref object
    name*: string
    kind*: SymbolKind
    varType*: string
    modifier*: VarModifier
    line*: int
    col*: int

  Scope* = ref object
    symbols*: Table[string, Symbol]
    parent*: Scope

  SymbolTable* = ref object
    globalScope*: Scope
    currentScope*: Scope

proc newScope*(parent: Scope = nil): Scope =
  Scope(symbols: initTable[string, Symbol](), parent: parent)

proc newSymbolTable*(): SymbolTable =
  let global = newScope()
  SymbolTable(globalScope: global, currentScope: global)

proc enterScope*(st: SymbolTable) =
  st.currentScope = newScope(st.currentScope)

proc exitScope*(st: SymbolTable) =
  if st.currentScope.parent != nil:
    st.currentScope = st.currentScope.parent

proc declareSymbol*(st: SymbolTable, name: string, kind: SymbolKind, varType: string, modifier: VarModifier, line, col: int): bool =
  if st.currentScope.symbols.hasKey(name):
    return false
  st.currentScope.symbols[name] = Symbol(
    name: name,
    kind: kind,
    varType: varType,
    modifier: modifier,
    line: line,
    col: col
  )
  return true

proc lookupSymbol*(st: SymbolTable, name: string): Symbol =
  var scope = st.currentScope
  while scope != nil:
    if scope.symbols.hasKey(name):
      return scope.symbols[name]
    scope = scope.parent
  return nil