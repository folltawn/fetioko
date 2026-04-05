import ../../core/errors

proc errorUnknownVariable*(file: string, line, col: int, name: string) =
  let err = newCompilerError(ecUnknownVariable, file, line, col)
  report(err)

proc errorVariableAlreadyExists*(file: string, line, col: int, name: string) =
  let err = newCompilerError(ecUnknown, file, line, col)  # или добавь новый код
  report(err)