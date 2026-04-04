import ../../core/ast
import ../../core/errors
import ../sendln/codegen as sendln
import ../variable/codegen

proc genFunction*(node: ASTNode): string =
  result = ""
  
  # Добавляем static для внутренних функций
  if not node.funcPub and node.name != "main":  # изменено с node.pub на node.funcPub
    result.add("static ")
  
  result.add("int " & node.name & "(void) {\n")
  
  # Генерируем тело
  for stmt in node.body:
    case stmt.kind
    of nkSendLn:
        result.add(sendln.genSendLn(stmt))
    of nkReturn:
        result.add("    return " & stmt.retValue & ";\n")
    of nkVariable:
        result.add(genVariable(stmt, true))
    of nkAssignment:
        result.add(genAssignment(stmt))
    else:
        discard
  
  result.add("}\n\n")