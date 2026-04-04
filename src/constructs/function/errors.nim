import ../../core/errors

proc errorMissingReturn*(file: string, line, col: int) =
  let err = newCompilerError(ecMissingReturn, file, line, col)
  report(err)

proc errorWrongSignature*(file: string, line, col: int) =
  let err = newCompilerError(ecMainWrongSignature, file, line, col)
  report(err)

proc errorMainNotFound*(file: string, line, col: int) =
  let err = newCompilerError(ecMainNotFound, file, line, col)
  report(err)

proc errorVoidFunction*(file: string, line, col: int) =
  let err = newCompilerError(ecVoidFunction, file, line, col)
  report(err)