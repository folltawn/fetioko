import ../../core/ast

proc cType(nimType: string): string =
  case nimType
  of "int": return "int"
  of "str": return "char*"
  of "float": return "double"
  of "char": return "char"
  of "bool": return "int"
  of "double": return "double"
  else: return "int"

proc genVariable*(node: ASTNode, inFunction: bool): string =
  case node.modifier
  of vmLet:
    return "    const " & cType(node.varType) & " " & node.varName & " = " & node.value & ";\n"
  of vmVar:
    return "    " & cType(node.varType) & " " & node.varName & " = " & node.value & ";\n"
  of vmConst:
    if inFunction:
      return "    static const " & cType(node.varType) & " " & node.varName & " = " & node.value & ";\n"
    else:
      return "const " & cType(node.varType) & " " & node.varName & " = " & node.value & ";\n"

proc genAssignment*(node: ASTNode): string =
  return "    " & node.assignName & " = " & node.assignValue & ";\n"