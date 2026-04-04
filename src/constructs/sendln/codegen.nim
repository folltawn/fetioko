import ../../core/parser

proc cType(arg: SendLnArg): string =
  case arg.kind
  of akString: "char*"
  of akInt: "int"
  of akFloat: "double"
  of akBool: "int"
  of akIdent: ""  # will be resolved

proc cValue(arg: SendLnArg): string =
  case arg.kind
  of akString: "\"" & arg.strVal.replace("\"", "\\\"") & "\""
  of akInt: $arg.intVal
  of akFloat: $arg.floatVal
  of akBool: if arg.boolVal: "1" else: "0"
  of akIdent: arg.identVal

proc genSendLn*(node: ASTNode): string =
  if node.concat:
    # Конкатенация через | превращается в несколько вызовов printf
    var result = ""
    for arg in node.args:
      case arg.kind
      of akString:
        result.add("printf(" & cValue(arg) & ");\n")
      of akInt:
        result.add("printf(\"%d\", " & cValue(arg) & ");\n")
      of akFloat:
        result.add("printf(\"%f\", " & cValue(arg) & ");\n")
      of akBool:
        result.add("printf(\"%d\", " & cValue(arg) & ");\n")
      of akIdent:
        result.add("printf(\"%s\", " & cValue(arg) & ");\n")
    result.add("printf(\"\\n\");\n")
    result
  else:
    # Обычный sendln с одним аргументом
    if node.args.len == 1:
      let arg = node.args[0]
      case arg.kind
      of akString:
        "printf(" & cValue(arg) & ");\nprintf(\"\\n\");\n"
      of akInt:
        "printf(\"%d\\n\", " & cValue(arg) & ");\n"
      of akFloat:
        "printf(\"%f\\n\", " & cValue(arg) & ");\n"
      of akBool:
        "printf(\"%d\\n\", " & cValue(arg) & ");\n"
      of akIdent:
        "printf(\"%s\\n\", " & cValue(arg) & ");\n"
    else:
      # Множественные аргументы без конкатенации - пока не поддерживаем
      "// TODO: multiple args without concat\n"