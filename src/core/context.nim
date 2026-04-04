import std/tables
import ./tokens

type
  FileContext* = ref object
    path*: string
    source*: string
    tokens*: seq[Token]
  
  Context* = ref object
    files*: Table[string, FileContext]
    mainFile*: string
    verbose*: bool

proc newContext*(): Context =
  Context(files: initTable[string, FileContext]())

proc addFile*(ctx: Context, path: string, source: string, tokens: seq[Token]) =
  ctx.files[path] = FileContext(path: path, source: source, tokens: tokens)