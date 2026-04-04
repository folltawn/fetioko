version     = "26.04.3"
description = "Compiler of Programming Language Fetioko"
author      = "Folltawn"
license     = "Apache-2.0"

bin         = @["ftk"]

requires "nim >= 2.0.0"

task build, "Build the project":
  exec "nim c -d:release --out:bin/fetioko src/ftk.nim"

task test, "Build the test project":
  exec "nim c -d:release --out:test/fetioko src/ftk.nim"

task clean, "Remove compiled files":
  when defined(windows):
    exec "del /q bin\\*"
    exec "rmdir bin"
  else:
    exec "rm -rf bin"