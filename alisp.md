# Alisp language specification 1.0

October 2017

## Context

Alisp is a lisp designed by Sophie Kirschner (sophiek@pineapplemachine.com).

## Objects

Alisp code is made up of objects. Alisp code is executed by evaluating an object or objects in order. Every type of Alisp object has a unique behavior when evaluated. 

Note that the type of every Alisp object is also itself an object.

The `null` object is used to represent failure states or the absence of any other value. The type of the `null` object is that object itself. `null` is a literal, meaning that when the `null` object is evaluated it produces itself.

The `true` and `false` objects belong to the `boolean` type. They represent a binary state. Like `null` they are literals, meaning that when they are evaluated they produce themselves.

A character object represents a single unicode code point. Characters are also literals.

A number object represents a numeric value. Number objects are also literals.

A keyword object is represented by a character string. A keyword, when evaluated normally, is a literal which produces itself. Keywords behave differently when they are members of identifiers.

A list object is an ordered sequence of other objects. A list is a literal, meaning that when it is evaluated it produces itself.

An identifier object is a special kind of list. An identifier is used to refer to other objects. When an identifier is evaluated, it produces the object to which the identifier refers. It is possible that an identifier may not refer to any existing object, in which case evaluation of the identifier produces `null`.

An expression object is another kind of list. An expression that contains no other objects, when evaluated, produces `null`. Otherwise the first object in the expression should be a callable object; when the expression is evaluated the first object is invoked using the remaining objects as arguments, and the result of that invokation is given by the expression. When the first object of an expression is not callable, the expression produces `null` when it is evaluated.

A map object is an unordered sequence of key, value pairs, where every key and every value is itself an object. Map objects are literals, meaning that when a map object is evaluated it produces itself.

A type object is a special kind of map. Its key, value pairs represent type attributes. Identifiers, through objects, may refer to the attributes belonging to that object's type. The key, value pair of a type object whose key is the keyword ":constructor" is treated specially. A type object with a constructor is callable; when the type object is invoked it produces the result of invoking its constructor with the same arguments.

A function object is a callable literal. It has two parts: A list of argument names and an expression body. The list of argument names describes with what keys arguments should be put into scope so that the expression body can access them when it is evaluated. The expression body is evaluated and its result produced any time the function is invoked.

A method object is also a callable literal. It has two parts: A context object and a callable object, such as a function or another method. Methods may be produced by identifiers when they refer to an attribute of an object's type. This allows the function attributes of types to be accessed and to behave like members of the object itself.

## Syntax

Here are how the different Alisp object types should be represented in code:

A symbol is any sequence of characters that on either side has a space ' ', a horizontal tab '\t', or a newline '\n', or that is preceded by an open parenthese '(' or bracket '[' or curly brace '{' or closing quote '\'' or '"' or a block comment end "*/", or is followed by a close parenthese ')' or a close bracket ']' or a close curly brace '}' or an opening quote '\'' or '"' or a line comment start "//" or a block comment start "/*".

An escaped character is any quoted character that is preceded by a backslash '\\'. The escaped character refers to the same character following the backslash (minus the backslash) except in these cases: '\0' represents the null character, '\r' a line feed, '\n' a carriage return or newline, '\t' a horizontal tab, '\v' a vertical tab, '\a' a bell code, '\e' an escape character, '\b' a backspace, and '\f' a formfeed character.

A quote is any text beginning with an uncommented and unquoted '\'' or '"' and ending with the same, unescaped character.

A line comment is any text beginning with an unquoted "//" and ending with the first newline '\n'.

A block comment is any text beginning with an unquoted "/*" and ending with the first "*/".

The null object is always referred to by the symbol `null`.

The true object is always referred to by the symbol `true` and the false object by `false`.

Character objects are enclosed within single quotes; for example, the symbol `'!'` refers to the character "!".

Number objects begin with `+`, `-`, `.`, or any decimal digit, and contain at least one decimal digit. They can also be represented in hexadecimal format by symbols beginning with `0x`. The `infinity`, `+infinity`, and `-infinity` symbols can represent variously-signed infinities and the `NaN`, `+NaN`, and `-NaN` symbols can represent variously-signed NaN values.

Keyword objects begin with a ':' except for when they appear inside an identifier, in which case they are any symbol that does not fit any of the other symbol requirements, typically an alphanumeric string.

Identifier objects are indicated by ':' characters placed in between symbols rather than at the beginning of one. Each object delimited by a ':' is a member of the identifier's list of objects. Symbols that do not fit any of the other requirements also cound as identifiers where the one symbol is treated as a keyword.

Expression objects are contained within balanced paretheses "()". The objects which appear within the parentheses are the members of that expression.

List literals are contained within balanced brackets "[]". The objects which appear within the brackets are the members of that list.

Map literals are contained within balanced curly braces "{}". The pairs of objects which appear within the curly braces are the key, value pairs of that map.

## Standard implementation values

`boolean` refers to the boolean type.

`boolean:constructor [:value]` returns `true` when the first argument is truthy, and `false` when the first argument was either not truthy or absent. The objects `true`, all characters except the null character '\0', all nonzero numbers and non-NaN numbers, all keywords, identifiers, lists, maps, types, functions, and methods are truthy. All other inputs are falsey, i.e. not truthy.

`character` refers to the character type.

`character:constructor [:value]` returns a character representation of the input: 't' for `true`, 'f' for `false`, a character itself for character inputs, the character with the code point described by a number input, and the null character '\0' for all other inputs.

`character:upper [:char]`

`character:lower [:char]`

`number` refers to the number type.

`number:constructor [:value]` returns a numeric representation of the input: 0 for `false`, 1 for `true`, the code point index of a character input, the number itself for number inputs, and NaN for all other inputs.

`number:parse [:string]` parses a number given an input list of characters. It returns `NaN` when a valid number is not represented.

`number:abs [:number]` returns the absolute value of a number.

`number:negate [:number]`

`number:positive? [:number]`

`number:negative? [:number]`

`number:zero? [:number]`

`number:nonzero? [:number]`

`number:finite? [:number]`

`number:infinite? [:number]`

`number:NaN? [:number]`

`keyword`

`keyword:constructor [:string]`

`identifier`

`identifier:constructor [:list]`

`identifier:length [:identifier]`

`identifier:empty? [:identifier]`

`identifier:eval [:identifier]`

`expression`

`expression:constructor [:list]`

`expression:length [:expression]`

`expression:empty? [:expression]`

`expression:eval [:expression]`

`list`

`list:constructor [@values]`

`list:length [:list]`

`list:empty? [:list]`

`list:at [:list :index]`

`list:insert [:list :index @values]`

`list:remove [:list :index]`

`list:push [:list @values]`

`list:pop [:list]`

`list:slice [:list :lowindex :highindex]`

`list:concat [@lists]`

`list:extend [:list @lists]`

`list:reverse [:list]`

`list:sort [:list :compare]`

`list:each [:list :callback]`

`list:map [:list :transform]`

`list:filter [:list :filter]`

`list:reduce [:list :combine]`

`list:clear [:list]`

`list:upper [:string]`

`list:lower [:string]`

`map`

`map:constructor [@pairs]`

`map:length [:map]`

`map:empty? [:map]`

`map:has [:map @keys]`

`map:get [:map :key]`

`map:set [:map @pairs]`

`map:remove [:map @pairs]`

`map:each [:map :callback]`

`map:keys [:map]`

`map:values [:map]`

`map:let [:map]`

`map:merge [@maps]`

`map:extend [:map @maps]`

`map:clear [:map]`

`type`

`builtin`

`builtin:call [:builtin]`

`function`

`function:constructor [:args :body]`

`function:call [:function]`

`function:args [:function]`

`function:body [:function]`

`method`

`method:constructor [:context :function]`

`method:call [:method]`

`method:context [:method]`

`method:function [:method]`

`new [:type] [:value]` produces an object with the same value as the input but with its type set to the specified object.

`typeof [:value]` returns the type object which represents the type of the input.

`let [identifier :value]`

`set [identifier :value]`

`is [:first @rest]` returns `true` when all of the inputs are exactly identical, or when there were one or fewer arguments. Returns `false` otherwise. Collections such as lists and maps are identical to themselves, but not to copies or other collections with identical contents.

`isnot [:first @rest]`

`eq [:first @rest]` returns `true` when the first argument is equal to all the others, or when there were one or fewer arguments. Returns `false` otherwise. Values of different types cannot be equal to one another, but collections such as lists and maps are equal to one another when their elements are all equal. Note that `null` and `NaN` are equal to nothing, not even themselves.

`noteq [:first @rest]`

`like [:first @rest]` returns `true` when the first argument is like all the others, or when there was one or fewer arguments. Returns `false` otherwise. Values of different types may be like each other if the values themselves are alike. Collections such as lists and maps are alike when their elements are all alike. Note that `null` and `NaN` are like themselves and each other, and that very similar but in fact different floating point values are alike.

`notlike [:first @rest]`

`cmp [:first :second]` expects two arguments. It returns -1 when the first value precedes the second, +1 when the first value follows the second, 0 when the values are equal, and `null` when the values are incomparable. `null` and `NaN` are incomparable with everything, and values of different types may be incomparable with each other.

`min [@values]`

`max [@values]`

`not [:value]`

`any [@values]`

`all [@values]`

`none [@values]`

`do [@objects]`

`when [:condition @objects]`

`if [:condition :trueobject :falseobject]`

`switch [@pairs]`

`until [:condition :body]`

`while [:condition :body]`

`import [:module]`

`encode [:object]`

`text [@values]`

`print [@values]`

`file`

`file:constructor [:path :mode]`

`file:stdin`

`file:stdout`

`file:stderr`

`file:close [:file]`

`file:write [:file @objects]`

`file:writeln [:file @objects]`

`file:readln [:file]`

`pi`

`tau`

`sum [@numbers]`

`mult [@numbers]`

`sub [:minuend @subtrahends]`

`div [:dividend @divisors]`

`modulo [:dividend :divisor]`

`pow [:base :exponent]`

`sin [:number]`

`cos [:number]`

`tan [:number]`

`asin [:number]`

`acos [:number]`

`atan [:number]`

`atan2 [:y :x]`
