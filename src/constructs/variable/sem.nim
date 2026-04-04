import ../../core/context
import ../../core/ast
import ../../core/errors
import std/tables

var g_constants*: Table[string, ASTNode]  # глобальные константы
var g_staticVars*: Table[string, ASTNode] # статические переменные внутри функций

proc semVariable*(ctx: Context, node: ASTNode, inFunction: bool) =
  case node.modifier
  of vmLet:
    if node.value == "":
      let err = newCompilerError(ecMissingArgument, ctx.mainFile, node.line, node.col)
      report(err)
  of vmVar:
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