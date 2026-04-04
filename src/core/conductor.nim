import std/[os, strformat, tables, sequtils, strutils, osproc]
import ./context, ./lexer, ./parser, ./config, ./errors, ./ast, ./tokens
import ../constructs/sendln/sem, ../constructs/sendln/codegen
import ../constructs/function/sem, ../constructs/function/codegen

type
  Conductor* = ref object
    ctx*: Context
    config*: Config
    saveC*: bool
    verbose*: bool
    logFile*: string

proc newConductor*(): Conductor =
  Conductor(ctx: newContext(), saveC: false, verbose: false)

proc setLogFile*(c: Conductor, path: string) =
  c.logFile = path

proc log(c: Conductor, msg: string) =
  if c.verbose:
    echo "[LOG] ", msg
  if c.logFile != "":
    writeFile(c.logFile, readFile(c.logFile) & msg & "\n")

proc tokenizeFile(c: Conductor, path: string): seq[Token] =
  c.log("Tokenizing: " & path)
  let source = readFile(path)
  var lexer = initLexer(source)
  var tokens: seq[Token] = @[]
  while true:
    let t = lexer.getNextToken()
    tokens.add(t)
    if t.kind == tkEOF:
      break
    if t.kind == tkError:
      let err = newCompilerError(ecUnknown, path, t.line, t.col)
      report(err)
      printErrorSummary()
      quit(1)
  result = tokens

proc compileFile(c: Conductor, path: string): string =
  c.log("Compiling: " & path)
  
  let tokens = c.tokenizeFile(path)
  c.ctx.addFile(path, readFile(path), tokens)
  
  var parser = initParser(c.ctx, tokens)
  let ast = parser.parse()
  
  # Семантический анализ
  for node in ast:
    case node.kind
    of nkSendLn:
      semSendLn(c.ctx, node)
    of nkFunction:
      semFunction(c.ctx, node)
    else:
      discard
  
  # Проверяем наличие main функции
  var mainFunc: ASTNode = nil
  for node in ast:
    if node.kind == nkFunction and node.name == "main":
      mainFunc = node
      break
  
  if mainFunc == nil:
    let err = newCompilerError(ecMainNotFound, path, 1, 1)
    report(err)
    printErrorSummary()
    quit(1)
  
  # Проверяем сигнатуру main
  if not mainFunc.pub or mainFunc.returnType != "int" or mainFunc.params.len > 0:
    let err = newCompilerError(ecMainWrongSignature, path, mainFunc.line, mainFunc.col)
    report(err)
    printErrorSummary()
    quit(1)
  
  # Генерация кода
  var functionsCode = ""
  for node in ast:
    case node.kind
    of nkFunction:
      functionsCode.add(genFunction(node))
    else:
      discard
  
  result = "#include <stdio.h>\n\n" & functionsCode

proc build*(c: Conductor) =
  c.log("Building project: " & c.config.name)
  
  let mainPath = c.config.baseDir / c.config.assembly.main
  
  if not fileExists(mainPath):
    let err = newCompilerError(ecUnknownPath, mainPath, 1, 1)
    report(err)
    printErrorSummary()
    quit(1)
  
  c.ctx.mainFile = mainPath
  let ccode = c.compileFile(mainPath)
  
  let outdir = c.config.baseDir / c.config.assembly.build.outdir
  createDir(outdir)
  
  let outfile = interpolate(c.config.assembly.build.outfile, c.config.name, c.config.version)
  let cPath = outdir / (outfile & ".c")
  let exePath = outdir / outfile
  
  writeFile(cPath, ccode)
  echo "Generated: ", cPath
  
  if c.saveC:
    echo "C source saved to: ", cPath
  else:
    let compileCmd = "gcc " & cPath & " -o " & exePath
    echo "Compiling: ", compileCmd
    let ret = execShellCmd(compileCmd)
    if ret != 0:
      echo "Compilation failed"
      quit(1)
    echo "Build complete: ", exePath
  
  if not c.saveC:
    removeFile(cPath)

proc test*(c: Conductor) =
  c.log("Testing project: " & c.config.name)
  
  let mainPath = c.config.baseDir / c.config.assembly.main
  
  if not fileExists(mainPath):
    let err = newCompilerError(ecUnknownPath, mainPath, 1, 1)
    report(err)
    printErrorSummary()
    quit(1)
  
  c.ctx.mainFile = mainPath
  let ccode = c.compileFile(mainPath)
  
  let outdir = c.config.baseDir / c.config.assembly.test.outdir
  createDir(outdir)
  
  let outfile = interpolate(c.config.assembly.test.outfile, c.config.name, c.config.version)
  let cPath = outdir / (outfile & ".c")
  let exePath = outdir / outfile
  
  writeFile(cPath, ccode)
  echo "Generated: ", cPath
  
  let compileCmd = "gcc " & cPath & " -o " & exePath
  echo "Compiling: ", compileCmd
  let ret = execShellCmd(compileCmd)
  if ret != 0:
    echo "Compilation failed"
    quit(1)
  echo "Test build complete: ", exePath
  
  echo "Running tests..."
  let output = execProcess(exePath)
  echo output