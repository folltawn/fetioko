import std/strutils
import ../../core/ast

proc cValue(arg: SendLnArg): string =
  case arg.kind
  of akString:
    # Если strVal похоже на имя переменной (не в кавычках), то это переменная
    if arg.strVal.len > 0 and arg.strVal[0] != '"':
      return arg.strVal
    else:
      return "\"" & arg.strVal.replace("\"", "\\\"") & "\""
  of akInt:
    # Для int - если identVal не пустой, это переменная
    if arg.identVal.len > 0:
      return arg.identVal
    else:
      return $arg.intVal
  of akFloat:
    if arg.identVal.len > 0:
      return arg.identVal
    else:
      let s = $arg.floatVal
      if '.' in s:
        var trimmed = s
        while trimmed.len > 0 and trimmed[^1] == '0':
          trimmed = trimmed[0..^2]
        if trimmed.len > 0 and trimmed[^1] == '.':
          trimmed = trimmed[0..^2]
        return trimmed
      return s
  of akBool:
    if arg.identVal.len > 0:
      return arg.identVal
    else:
      return if arg.boolVal: "1" else: "0"
  of akChar:
    if arg.identVal.len > 0:
      return arg.identVal
    else:
      return "'" & $arg.charVal & "'"
  of akIdent:
    return arg.identVal

proc getFormat(arg: SendLnArg): string =
  case arg.kind
  of akString:
    if arg.strVal.len > 0 and arg.strVal[0] != '"':
      return "%s"
    else:
      return "%s"
  of akInt: return "%d"
  of akFloat: return "%g"
  of akBool: return "%d"
  of akChar: return "%c"
  of akIdent: return "%s"

proc genSendLn*(node: ASTNode): string =
  if node.concat:
    var result = "    "
    for arg in node.args:
      result.add("printf(\"" & getFormat(arg) & "\", " & cValue(arg) & ");")
    result.add("printf(\"\\n\");\n")
    return result
  else:
    if node.args.len == 1:
      let arg = node.args[0]
      return "    printf(\"" & getFormat(arg) & "\\n\", " & cValue(arg) & ");\n"
    else:
      return "    // TODO: multiple args without concat\n"