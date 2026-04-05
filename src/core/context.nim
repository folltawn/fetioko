import std/tables
import ./tokens
import ./symbols

type
  FileContext* = ref object
    path*: string
    source*: string
    tokens*: seq[Token]
  
  Context* = ref object
    files*: Table[string, FileContext]
    mainFile*: string
    verbose*: bool
    symtab*: SymbolTable

proc newContext*(): Context =
  Context(files: initTable[string, FileContext]())

proc addFile*(ctx: Context, path: string, source: string, tokens: seq[Token]) =
  ctx.files[path] = FileContext(path: path, source: source, tokens: tokens)