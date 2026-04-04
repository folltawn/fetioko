import std/strutils
import ../../core/ast

proc cValue(arg: SendLnArg): string =
  case arg.kind
  of akString:
    return "\"" & arg.strVal.replace("\"", "\\\"") & "\""
  of akInt:
    return $arg.intVal
  of akFloat:
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
    return if arg.boolVal: "1" else: "0"
  of akIdent:
    return arg.identVal

proc genSendLn*(node: ASTNode): string =
  if node.concat:
    var result = "    "
    for arg in node.args:
      case arg.kind
      of akString:
        result.add("printf(" & cValue(arg) & ");")
      of akInt:
        result.add("printf(\"%d\", " & cValue(arg) & ");")
      of akFloat:
        result.add("printf(\"%g\", " & cValue(arg) & ");")
      of akBool:
        result.add("printf(\"%d\", " & cValue(arg) & ");")
      of akIdent:
        result.add("printf(\"%s\", " & cValue(arg) & ");")
    result.add("printf(\"\\n\");\n")
    return result
  else:
    if node.args.len == 1:
      let arg = node.args[0]
      case arg.kind
      of akString:
        return "    printf(" & cValue(arg) & ");\n    printf(\"\\n\");\n"
      of akInt:
        return "    printf(\"%d\\n\", " & cValue(arg) & ");\n"
      of akFloat:
        return "    printf(\"%g\\n\", " & cValue(arg) & ");\n"
      of akBool:
        return "    printf(\"%d\\n\", " & cValue(arg) & ");\n"
      of akIdent:
        return "    printf(\"%s\\n\", " & cValue(arg) & ");\n"
    else:
      return "    // TODO: multiple args without concat\n"