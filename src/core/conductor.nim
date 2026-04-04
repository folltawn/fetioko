import std/[os, strformat, tables, sequtils]
import ./context, ./lexer, ./parser, ./config, ./errors
import ../constructs/sendln/sem, ../constructs/sendln/codegen

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
      let err = newCompilerError("Lexer error: " & t.lexeme, path, t.line, t.col)
      report(err)
      quit(1)
  result = tokens

proc compileFile(c: Conductor, path: string): string =
  c.log("Compiling: " & path)
  
  # Tokenize
  let tokens = c.tokenizeFile(path)
  c.ctx.addFile(path, readFile(path), tokens)
  
  # Parse
  var parser = initParser(c.ctx, tokens)
  let ast = parser.parse()
  
  # Semantic analysis
  for node in ast:
    case node.kind
    of nkSendLn:
      semSendLn(c.ctx, node)
    else:
      discard
  
  # Code generation
  var ccode = "#include <stdio.h>\n\n"
  for node in ast:
    case node.kind
    of nkSendLn:
      ccode.add(genSendLn(node))
    of nkReturn:
      ccode.add("return " & node.retValue & ";\n")
    else:
      discard
  
  result = ccode

proc build*(c: Conductor) =
  c.log("Building project: " & c.config.name)
  
  let mainPath = c.config.assembly.main
  if not fileExists(mainPath):
    echo "Error: Main file not found: ", mainPath
    quit(1)
  
  c.ctx.mainFile = mainPath
  let ccode = c.compileFile(mainPath)
  
  # Add main function wrapper
  let fullC = ccode & "\nint main() {\n    // TODO: call user main\n    return 0;\n}\n"
  
  # Create output directory
  let outdir = c.config.assembly.build.outdir
  createDir(outdir)
  
  let outfile = interpolate(c.config.assembly.build.outfile, c.config.name, c.config.version)
  let cPath = outdir / (outfile & ".c")
  let exePath = outdir / outfile
  
  # Write C file
  writeFile(cPath, fullC)
  echo "Generated: ", cPath
  
  if c.saveC:
    echo "C source saved to: ", cPath
  else:
    # Compile with GCC
    let compileCmd = "gcc " & cPath & " -o " & exePath
    echo "Compiling: ", compileCmd
    let ret = execShellCmd(compileCmd)
    if ret != 0:
      echo "Compilation failed"
      quit(1)
    echo "Build complete: ", exePath
  
  # Cleanup if not savec
  if not c.saveC:
    removeFile(cPath)

proc test*(c: Conductor) =
  c.log("Testing project: " & c.config.name)
  # Similar to build but with test config
  echo "Test mode not fully implemented yet"