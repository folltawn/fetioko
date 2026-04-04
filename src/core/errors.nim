import std/[strformat, terminal]

type
  ErrorLevel* = enum
    elError, elWarning, elInfo

  CompilerError* = ref object of CatchableError
    level*: ErrorLevel
    line*: int
    col*: int
    file*: string

proc report*(err: CompilerError) =
  styledEcho fgRed, "[", err.level, "] ", resetStyle, 
             fgYellow, err.file, ":", err.line, ":", err.col, resetStyle,
             " ", err.msg

proc newCompilerError*(msg: string, file: string, line, col: int): CompilerError =
  CompilerError(msg: msg, level: elError, file: file, line: line, col: col)