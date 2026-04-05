import ../../core/context
import ../../core/ast
import ../../core/errors
import ../../core/symbols
import ../variable/errors as varErrors
import ./errors

import ../../core/context
import ../../core/ast
import ../../core/errors
import ../../core/symbols
import ../variable/errors as varErrors
import ./errors

proc semSendLn*(ctx: Context, node: ASTNode) =
  if node.args.len == 0:
    errorMissingArgument(ctx.mainFile, node.line, node.col)
  
  for arg in node.args:
    if arg.kind == akIdent:
      let sym = ctx.symtab.lookupSymbol(arg.identVal)
      if sym == nil:
        errorUnknownVariable(ctx.mainFile, node.line, node.col, arg.identVal)
      else:
        let originalName = arg.identVal
        case sym.varType
        of "int":
          arg.kind = akInt
          arg.intVal = 0
          arg.identVal = originalName  # сохраняем имя!
        of "str":
          arg.kind = akString
          arg.strVal = originalName
        of "char":
          arg.kind = akChar
          arg.charVal = '\0'
          arg.identVal = originalName  # сохраняем имя!
        of "float", "double":
          arg.kind = akFloat
          arg.floatVal = 0.0
          arg.identVal = originalName  # сохраняем имя!
        of "bool":
          arg.kind = akBool
          arg.boolVal = false
          arg.identVal = originalName  # сохраняем имя!
        else:
          arg.kind = akIdent