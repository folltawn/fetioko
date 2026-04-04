import std/[strutils]

const
  RESET = "\e[0m"
  FG_RED = "\e[31m"
  FG_GREEN = "\e[32m"
  FG_YELLOW = "\e[33m"
  FG_BLUE = "\e[34m"
  FG_CYAN = "\e[36m"
  FG_DARK_GRAY = "\e[90m"

type
  ErrorCode* = enum
    ecUnknown = 0x0000
    ecMissingSemicolon = 0x0001
    ecUnexpectedSemicolon = 0x0002
    ecUnknownFunction = 0x0003
    ecUnknownVariable = 0x0004
    ecUnknownPath = 0x0005
    ecUnknownModule = 0x0006
    ecWrongArgumentType = 0x0007      # новый код
    ecMissingArgument = 0x0008        # новый код

  CompilerError* = ref object of CatchableError
    code*: ErrorCode
    line*: int
    col*: int
    file*: string

var g_errorCount*: int = 0

proc getSourceLine(file: string, line: int): string =
  try:
    let lines = readFile(file).splitLines()
    if line > 0 and line <= lines.len:
      return lines[line - 1]
  except:
    discard
  return ""

proc report*(err: CompilerError) =
  inc g_errorCount
  
  let codeStr = case err.code
    of ecUnknown: "0x0000"
    of ecMissingSemicolon: "0x0001"
    of ecUnexpectedSemicolon: "0x0002"
    of ecUnknownFunction: "0x0003"
    of ecUnknownVariable: "0x0004"
    of ecUnknownPath: "0x0005"
    of ecUnknownModule: "0x0006"
    of ecWrongArgumentType: "0x0007"
    of ecMissingArgument: "0x0008"
  
  let msg = case err.code
    of ecUnknown: "Unknown."
    of ecMissingSemicolon: "Missing semicolon."
    of ecUnexpectedSemicolon: "Unexpected semicolon."
    of ecUnknownFunction: "Unknown function."
    of ecUnknownVariable: "Unknown varible."
    of ecUnknownPath: "Unknown path."
    of ecUnknownModule: "Unknown module."
    of ecWrongArgumentType: "Wrong argument type."
    of ecMissingArgument: "Missing argument."
  
  stdout.write(FG_RED & "ERROR. " & RESET)
  stdout.write(FG_YELLOW & codeStr & ": " & RESET)
  stdout.write(msg & "\n\n")
  
  stdout.write(FG_CYAN & "    | \\IN: " & RESET)
  stdout.write(err.file & ":" & $err.line & ":" & $err.col & "\n")
  stdout.write("    |\n")
  
  let lines = readFile(err.file).splitLines()
  
  let startLine = max(1, err.line - 2)
  let endLine = min(lines.len, err.line + 2)
  
  for i in startLine..endLine:
    let lineNum = i
    let lineContent = if i <= lines.len: lines[i-1] else: "<Empty>"
    
    if lineNum == err.line:
      stdout.write(FG_YELLOW & " " & $lineNum & " | " & RESET)
      stdout.write(lineContent & "\n")
      var arrow = "    | "
      for _ in 1..<err.col:
        arrow.add(" ")
      arrow.add("^")
      let remaining = lineContent.len - err.col + 1
      for _ in 0..<remaining:
        arrow.add("~")
      stdout.write(FG_GREEN & arrow & " Here (" & $err.line & ":" & $err.col & ")" & RESET & "\n")
    else:
      if lineContent == "" or lineContent == "<Empty>":
        stdout.write(FG_DARK_GRAY & " " & $lineNum & " | " & RESET)
        stdout.write(FG_DARK_GRAY & "<Empty>" & RESET & "\n")
      else:
        stdout.write(" " & $lineNum & " | " & lineContent & "\n")
  
  stdout.write("\n")

proc printErrorSummary*() =
  if g_errorCount > 0:
    stdout.write(FG_RED & "Total errors: " & $g_errorCount & "." & RESET & "\n")
  g_errorCount = 0

proc newCompilerError*(code: ErrorCode, file: string, line, col: int): CompilerError =
  CompilerError(
    msg: "",
    code: code,
    file: file,
    line: line,
    col: col
  )