import std/[strutils, json, os]

type
  BuildConfig* = ref object
    outfile*: string
    outdir*: string
  
  AssemblyConfig* = ref object
    main*: string
    build*: BuildConfig
    test*: BuildConfig
  
  Config* = ref object
    name*: string
    version*: string
    author*: seq[string]
    assembly*: AssemblyConfig

proc interpolate*(s: string, name, version: string): string =
  s.replace("${name}", name).replace("${version}", version)

proc loadConfig*(path: string): Config =
  if not fileExists(path):
    raise newException(IOError, "Config file not found: " & path)
  
  let data = parseFile(path)
  result = Config(
    name: data["name"].getStr(),
    version: data["version"].getStr(),
    author: data["author"].getElems().mapIt(it.getStr()),
    assembly: AssemblyConfig(
      main: data["assembly"]["main"].getStr(),
      build: BuildConfig(
        outfile: data["assembly"]["build"]["outfile"].getStr(),
        outdir: data["assembly"]["build"]["outdir"].getStr()
      ),
      test: BuildConfig(
        outfile: data["assembly"]["test"]["outfile"].getStr(),
        outdir: data["assembly"]["test"]["outdir"].getStr()
      )
    )
  )