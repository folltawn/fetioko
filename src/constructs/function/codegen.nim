import ../../core/ast
import ../sendln/codegen as sendln

proc genFunction*(node: ASTNode): string =
  result = ""
  
  # Добавляем static для внутренних функций
  if not node.pub and node.name != "main":
    result.add("static ")
  
  result.add("int " & node.name & "(")
  
  # Параметры (пока пустые)
  if node.params.len == 0:
    result.add("void")
  else:
    for i, param in node.params:
      if i > 0:
        result.add(", ")
      result.add("int " & param.name)
  
  result.add(") {\n")
  
  # Генерируем тело
  for stmt in node.body:
    case stmt.kind
    of nkSendLn:
      result.add(sendln.genSendLn(stmt))
    of nkReturn:
      result.add("    return " & stmt.retValue & ";\n")
    else:
      discard
  
  result.add("}\n\n")