import ../../core/errors

proc errorWrongArgumentType*(file: string, line, col: int, expected: string, got: string) =
  let err = newCompilerError(
    "sendln: expected " & expected & ", got " & got,
    file, line, col
  )
  report(err)

proc errorMissingArgument*(file: string, line, col: int) =
  let err = newCompilerError(
    "sendln: missing argument",
    file, line, col
  )
  report(err)