import std/[strutils, os, tables]

type
  BuildConfig* = ref object
    outfile*: string
    outdir*: string
  
  AssemblyConfig* = ref object
    main*: string
    build*: BuildConfig
    test*: BuildConfig
  
  Config* = ref object
    baseDir*: string
    name*: string
    version*: string
    author*: seq[string]
    assembly*: AssemblyConfig

proc interpolate*(s: string, name, version: string): string =
  s.replace("${name}", name).replace("${version}", version)

proc parseYaml*(path: string): Table[string, string] =
  result = initTable[string, string]()
  let lines = readFile(path).splitLines()
  
  for line in lines:
    let stripped = line.strip()
    if stripped.len == 0 or stripped.startsWith("#"):
      continue
    
    let colonPos = stripped.find(':')
    if colonPos == -1:
      continue
    
    let key = stripped[0..<colonPos].strip()
    var value = stripped[colonPos+1..^1].strip()
    
    # Удаляем кавычки
    if value.len >= 2 and value[0] == '"' and value[^1] == '"':
      value = value[1..^2]
    
    if value.len > 0:
      result[key] = value

proc loadConfig*(path: string): Config =
  if not fileExists(path):
    raise newException(IOError, "Config file not found: " & path)
  
  let data = parseYaml(path)
  let baseDir = parentDir(path)
  
  # Парсим авторов (может быть массив)
  var authors: seq[string] = @[]
  let authorStr = data.getOrDefault("author", "")
  if authorStr.startsWith("[") and authorStr.endsWith("]"):
    let inner = authorStr[1..^2]
    for a in inner.split(','):
      var clean = a.strip()
      if clean.len >= 2 and clean[0] == '"' and clean[^1] == '"':
        clean = clean[1..^2]
      authors.add(clean)
  elif authorStr.len > 0:
    authors.add(authorStr)
  
  result = Config(
    baseDir: baseDir,
    name: data.getOrDefault("name", ""),
    version: data.getOrDefault("version", ""),
    author: authors,
    assembly: AssemblyConfig(
      main: data.getOrDefault("main", ""),
      build: BuildConfig(
        outfile: data.getOrDefault("outfile", "${name}-${version}"),
        outdir: data.getOrDefault("outdir", "bin")
      ),
      test: BuildConfig(
        outfile: data.getOrDefault("test_outfile", "test_${name}_${version}"),
        outdir: data.getOrDefault("test_outdir", "test")
      )
    )
  )
  
  # Проверка обязательных полей
  if result.name == "":
    raise newException(ValueError, "name is required in config")
  if result.version == "":
    raise newException(ValueError, "version is required in config")
  if result.assembly.main == "":
    raise newException(ValueError, "main is required in config")