import ../../core/context
import ../../core/ast
import ../../core/errors
import ./errors

proc semFunction*(ctx: Context, node: ASTNode) =
  # Проверяем, что main имеет правильную сигнатуру
  if node.name == "main":
    if not node.funcPub:  # изменено с node.pub на node.funcPub
      errorWrongSignature(ctx.mainFile, node.line, node.col)
    if node.returnType != "int":
      errorWrongSignature(ctx.mainFile, node.line, node.col)
    if node.params.len > 0:
      errorWrongSignature(ctx.mainFile, node.line, node.col)
  
  # Проверяем, что функция возвращает значение (ВСЕГДА, даже main)
  var hasReturn = false
  for stmt in node.body:
    if stmt.kind == nkReturn:
      hasReturn = true
      break
  
  if not hasReturn:
    errorMissingReturn(ctx.mainFile, node.line, node.col)
  
  # Семантический анализ тела функции
  for stmt in node.body:
    case stmt.kind
    of nkSendLn:
      discard
    of nkReturn:
      if stmt.retValue == "":
        let err = newCompilerError(ecMissingReturn, ctx.mainFile, stmt.line, stmt.col)
        report(err)
    of nkVariable:
      # Переменные внутри функции обрабатываются в variable/sem.nim
      discard
    else:
      discard