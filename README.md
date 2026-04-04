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