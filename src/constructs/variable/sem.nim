import ../../core/context
import ../../core/ast
import ../../core/errors
import ../../core/symbols
import ./errors
import std/tables

var g_constants*: Table[string, ASTNode]
var g_staticVars*: Table[string, ASTNode]

proc semVariable*(ctx: Context, node: ASTNode, inFunction: bool) =
  let success = ctx.symtab.declareSymbol(
    node.varName,
    skVariable,
    node.varType,
    node.modifier,
    node.line,
    node.col
  )
  if not success:
    errorVariableAlreadyExists(ctx.mainFile, node.line, node.col, node.varName)
  
  case node.modifier
  of vmLet, vmVar:
    if node.value == "":
      let err = newCompilerError(ecMissingArgument, ctx.mainFile, node.line, node.col)
      report(err)
  of vmConst:
    if inFunction:
      if not g_staticVars.hasKey(node.varName):
        g_staticVars[node.varName] = node
    else:
      if not g_constants.hasKey(node.varName):
        g_constants[node.varName] = node