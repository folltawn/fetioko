# fetioko

int anything() {
    const::double y = 3.14;
    sendln(y);
    return 0;
}

anything(); // создает y
anything(); // не создает y

---

ERROR. 0x0001: Missing semicolon.
    | \IN: F:/fetioko/example/1/main.ftk:3:13
    |
  1 | sendln!("Hello" | " world");
  2 | sendln!(42);
  3 | sendln!(3.14)
    |             ^ Here (3:13)
  4 | sendln!(true);
  5 | <Empty>
    |

Total errors: 1.

<Empty> темно-серым цветом

Коды ошибок:

0x0000: Unknown.
0x0001: Missing semicolon.
0x0002: Unexpected semicolon.
0x0003: Unknown function.
0x0004: Unknown varible.
0x0005: Unknown path.
0x0006: Unknown module.

Так же важно:


  1 |
    |
^^^^
1234

  12 |
     |
^^^^^
12345

  123 |
      |
^^^^^^
123456

sendln!(); все встроенные в ядро методы с !


use <"module":{varname,func()} @aliase>; // from std; now can't be used
use <"module" @aliase>; // from std; now can't be used
use <"module":{varname,func()}>; // from std; now can't be used
use <"module">; // from std; now can't be used
use {x, func()} from "../path/to/file";
use "../path/to/file" as aliase;
use "../path/to/file";

let::int x = 14; // local in area; can't be changed
var::str y = "hi"; // local in area; can be changed
const::char f = 'f'; // global in file; can't be changed
pub var::str y = "hi"; // can will be import
pub const::char f = 'f'; // can be imported

```
int fl() {
    const::int x = 14;
    return 0;
}

fl();
sendln!(x);
fl(); // новая переменная x не будет создана, т.к. уже существует const x
sendln!(x);
```


fetioko.upc (UPC = Ultimate Project Configuration):
```
name:("my-app2")
version:("0.1.0")
author:[]
main:("main.ftk")
build.outfile:("${name}-${version}")
build.outdir:("bin")
test.outfile:("test_${name}_${version}")
test.outdir:("test")
```