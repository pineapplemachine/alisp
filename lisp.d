/+

Approachable Lisp

These are the primitive types:

Null: The null literal.
Boolean: True and false literals.
Character: A single unicode character.
Number: A floating point number.
Keyword: An identifier preceded by ':'.
List: An ordered sequence of other values.
Map: An association of values with other values.
Type: A special case of maps involved in identifier lookup.
Expression: A list whose first element is a function.
NativeFunction: A special case of expression which may accept arguments.

(let MyType (type
    :constructor (function [:str] str)
    :length (function [:this] (list:length this))
))

(let myTypeInstance (MyType "Hello"))



(print myTypeInstance:length)


(define MyType (type
    :length (function [:this] (list:length this))
))
(define myObject (object MyType "whatever"))
(myObject:length) // 8

+/

import alisp.map : LispMap;

// Parser and interpreter dependencies
import mach.math : pow2d, fidentical, fisnan;
import mach.range : map, join, all, asarray;
import mach.traits : hash, isNumeric, isCharacter;
import mach.text.ascii : isdigit, iswhitespace;
import mach.text.numeric : WriteFloatSettings, writefloat, parsefloat, parsehex;

import mach.text.utf : utf8encode, utf8decode;

// Repl and file loading dependencies
import mach.io : Path, stdio;
import core.stdc.stdlib : exit;
import core.stdc.signal : signal, SIGINT;

// Standard library dependencies
import mach.math : abs, kahansum;
import mach.range : product, reduce;
import std.uni : toUpper, toLower;













void registerBuiltins(LispContext* context){
    
    
    // Register primitive types.
    //context.register("null"d, context.Null);
    
    
    // Add default methods to primitive types.
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // Declare a function.
    // The first argument must be a list of keywords describing arguments names.
    // The second argument must be the expression which is evaluated when the
    // function is invoked; an invokation of the function produces whatever
    // value this expression produced with the given arguments.
    
    
    // The first argument must be the context object and the second
    // argument must be the associated type, function, method, or builtin.
    
    
    
    
    context.registerFunction("call"d,
        callFunction
    );
    
    
    
    // Get the type object which describes the type of a given value.
    // The function must receive one argument.
    

    // Output arguments to the console as a string.
    // Returns the value produced by evaluating the final argument, or
    // null if there were no arguments.
    
    
    
    
}

void main(){
    LispContext* context = new LispContext(null);
    registerBuiltins(context);
    repl(context);
    //stdio.writeln(context.evaluate(`10:abs x list:push one:two:3:four`).stringify());
}



/*
(let collatz (function [:n] (do
    (let seq [n])
    (while (noteq 1 n)
        (seq:push (set n (if (modulo n 2)
            (sum 1 (mult 3 n))
            (div n 2)
        )))
    )
)))

(let collatz (function [:n] (do
    (let seq [n])
    (while >(n !is 1)
        (seq:push (set n (if (modulo n 2)
            (sum 1 (mult 3 n))
            (div n 2)
        )))
    )
)))

*/