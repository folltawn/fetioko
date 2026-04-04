import std/[strutils, os, sequtils, tables]

type
  Config* = ref object
    baseDir*: string
    name*: string
    version*: string
    author*: seq[string]
    main*: string
    buildOutfile*: string
    buildOutdir*: string
    testOutfile*: string
    testOutdir*: string

proc interpolate*(s: string, name, version: string): string =
  s.replace("${name}", name).replace("${version}", version)

proc loadConfig*(path: string): Config =
  if not fileExists(path):
    raise newException(IOError, "Config file not found: " & path)
  
  let baseDir = parentDir(path)
  let content = readFile(path)
  var data = initTable[string, string]()
  
  for line in content.splitLines():
    let stripped = line.strip()
    if stripped.len == 0 or stripped.startsWith("#"):
      continue
    
    let colonPos = stripped.find(':')
    if colonPos == -1:
      continue
    
    let key = stripped[0..<colonPos].strip()
    
    let openParen = stripped.find('(')
    let closeParen = stripped.find(')')
    if openParen == -1 or closeParen == -1:
      continue
    
    var value = stripped[openParen+1..<closeParen].strip()
    
    if value.len >= 2 and value[0] == '"' and value[^1] == '"':
      value = value[1..^2]
    
    data[key] = value
  
  var authors: seq[string] = @[]
  let authorStr = data.getOrDefault("author", "")
  if authorStr.startsWith("[") and authorStr.endsWith("]"):
    let inner = authorStr[1..^2]
    for a in inner.split(','):
      var clean = a.strip()
      if clean.len >= 2 and clean[0] == '"' and clean[^1] == '"':
        clean = clean[1..^2]
      if clean.len > 0:
        authors.add(clean)
  elif authorStr.len > 0:
    var clean = authorStr
    if clean.len >= 2 and clean[0] == '"' and clean[^1] == '"':
      clean = clean[1..^2]
    authors.add(clean)
  
  result = Config(
    baseDir: baseDir,
    name: data.getOrDefault("name", ""),
    version: data.getOrDefault("version", ""),
    author: authors,
    main: data.getOrDefault("main", ""),
    buildOutfile: data.getOrDefault("build.outfile", "${name}-${version}"),
    buildOutdir: data.getOrDefault("build.outdir", "bin"),
    testOutfile: data.getOrDefault("test.outfile", "test_${name}_${version}"),
    testOutdir: data.getOrDefault("test.outdir", "test")
  )
  
  if result.name == "":
    raise newException(ValueError, "name is required in config")
  if result.version == "":
    raise newException(ValueError, "version is required in config")
  if result.main == "":
    raise newException(ValueError, "main is required in config")