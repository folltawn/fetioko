import ../../core/context
import ../../core/parser
import ./errors

proc semSendLn*(ctx: Context, node: ASTNode) =
  if node.args.len == 0:
    errorMissingArgument(ctx.mainFile, node.line, node.col)
  
  for arg in node.args:
    case arg.kind
    of akString, akInt, akFloat, akBool, akIdent:
      discard  # все типы валидны для sendln
    else:
      errorWrongArgumentType(ctx.mainFile, node.line, node.col, "literal or variable", "unknown")