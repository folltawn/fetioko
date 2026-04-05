import std/[os, parseopt, strutils]
import core/[conductor, config, errors]

const version = "A26.04.5"

proc printHelp() =
  echo """
Fetioko Compiler """ & version & """

Usage:
  fetioko build <path_to_config> [args]   Build project
  fetioko test <path_to_config> [args]    Run tests
  fetioko --help | -h                     Show this help
  fetioko --docs [lang]                   Show documentation link

Args for build/test:
  +savec      Save generated C files
  +log:"path" Save logs to file
  +verbose    Show all logs (default: only errors)
"""

proc printDocs(lang: string = "en") =
  if lang == "ru":
    echo "Документация: https://github.com/fetioko/docs/ru"
  else:
    echo "Documentation: https://github.com/fetioko/docs/en"

proc parseArgs(args: seq[string]): tuple[savec: bool, logfile: string, verbose: bool] =
  result = (false, "", false)
  for arg in args:
    if arg == "+savec":
      result.savec = true
    elif arg == "+verbose":
      result.verbose = true
    elif arg.startswith("+log:"):
      result.logfile = arg[5..^1]

proc main() =
  var p = initOptParser(commandLineParams())
  var cmd = ""
  var configPath = ""
  var extraArgs: seq[string] = @[]

  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      if cmd == "":
        cmd = key
      elif configPath == "":
        configPath = key
      else:
        extraArgs.add(key)
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h":
        printHelp()
        return
      of "docs", "d":
        printDocs(val)
        return
      else:
        echo "Unknown option: ", key
        printHelp()
        return
    of cmdEnd:
      discard

  if cmd == "":
    if paramCount() == 0:
      printHelp()
    return

  let args = parseArgs(extraArgs)
  
  if configPath == "":
    if fileExists("fetioko.upc"):
      configPath = "fetioko.upc"
    elif fileExists("fetioko.ini"):
      configPath = "fetioko.ini"
    elif fileExists("fetioko.yml"):
      configPath = "fetioko.yml"
      echo "Warning: YAML support is deprecated, use fetioko.upc"
    else:
      echo "Error: No config file found (fetioko.upc, fetioko.ini, or fetioko.yml)"
      quit(1)

  var conductor: Conductor = nil
  try:
    conductor = newConductor()
    conductor.config = loadConfig(configPath)
    
    if args.logfile != "":
      conductor.setLogFile(args.logfile)
    
    conductor.verbose = args.verbose
    conductor.saveC = args.savec
    
    case cmd
    of "build":
      conductor.build()
    of "test":
      conductor.test()
    else:
      echo "Unknown command: ", cmd
      printHelp()
      quit(1)
      
  except CatchableError as e:
    if conductor != nil and conductor.verbose:
      echo e.getStackTrace()
    else:
      if e of CompilerError:
        report(CompilerError(e))
      else:
        echo "Error: ", e.msg
    printErrorSummary()
    quit(1)

when isMainModule:
  main()