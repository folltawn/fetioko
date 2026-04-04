import ../../core/errors

proc errorWrongArgumentType*(file: string, line, col: int, expected: string, got: string) =
  let err = newCompilerError(ecWrongArgumentType, file, line, col)
  report(err)

proc errorMissingArgument*(file: string, line, col: int) =
  let err = newCompilerError(ecMissingArgument, file, line, col)
  report(err)