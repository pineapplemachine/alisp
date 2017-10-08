# Alisp

Alisp is a member of the [lisp family](https://en.wikipedia.org/wiki/Lisp_(programming_language)) of programming languages created by Sophie Kirschner (sophiek@pineapplemachine.com).

This repository offers a reference implementation of the Alisp programming language in the form of a repl and interpreter written in [D](https://dlang.org/). It also includes a complete [language specification](alisp.md).

This implementation depends on [mach.d](https://github.com/pineapplemachine/mach.d). It was last tested with [commit c5cf976](https://github.com/pineapplemachine/mach.d/commit/c5cf9761db81a364436f0c0a31321d26ff467f66).

To build Alisp from source, it is recommended that you use [rdmd](https://dlang.org/rdmd.html) to compile `main.d` in this repository with the directory contaning `mach` referred to with an `-I` flag, for example `rdmd -I"path/to/mach.d" "alisp/main.d"`.

Here are some Alisp code examples:

``` clojure
>> "hello world!"
hello world!
```

``` clojure
>> (let collatz (function [:n] (do
..   (let seq [n])
..   (while (isnot n 1)
..     (seq:push (set n (if (modulo n 2)
..       (sum 1 (mult 3 n))
..       (div n 2)
..     )))
..   )
.. )))
(function [:n] (do (let seq (list n)) (while (isnot n 1) (seq:push (set n (if (modulo n 2) (sum 1 (mult 3 n)) (div n 2)))))))
>> (collatz 5)
[5 16 8 4 2 1]
>> (collatz 17)
[17 52 26 13 40 20 10 5 16 8 4 2 1]
```
