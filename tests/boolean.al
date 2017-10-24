// test: Boolean from null
// output: false
(boolean null)

// test: Boolean from true
// output: false
(boolean false)

// test: Boolean from true
// output: true
(boolean true)

// test: Boolean from null character
// output: false
(boolean '\0')

// test: Boolean from non-null characters
// output: true
(all
    (boolean 'X')
    (boolean 'y')
    (boolean '0')
    (boolean 'f')
)

// test: Boolean from zero
// output: false
(boolean 0)

// test: Boolean from NaN
// output: false
(boolean NaN)

// test: Booleans from nonzero non-NaN numbers
// output: true
(all
    (boolean 1)
    (boolean -1)
    (boolean 0.1)
    (boolean infinity)
    (boolean -infinity)
)

// test: Booleans from keywords
// output: true
(all
    (boolean (keyword))
    (boolean :x)
    (boolean :0)
    (boolean :false)
)

// test: Boolean from context
// output: true
(boolean (context))

// test: Booleans from lists
// output: true
(all
    (boolean [])
    (boolean [1 2 3])
)

// test: Booleans from identifiers
// output: true
(all
    (boolean (identifier))
    (boolean (quote x:y))
)

// test: Booleans from expressions
// output: true
(all
    (boolean (quote ()))
    (boolean (quote (sum 1 2 3)))
)

// test: Booleans from maps
// output: true
(all
    (boolean {})
    (boolean {:x 0 :y 1})
)

// test: Booleans from objects
// output: true
(all
    (boolean boolean)
    (boolean (object))
    (boolean (object :x 0 :y 1))
)

// test: Booleans from functions
// output: true
(all
    (boolean (function [] ()))
    (boolean (function [:x] x))
)

// test: Booleans from methods
// output: true
(all
    (boolean 0:abs)
    (boolean []:length)
)

// test: Booleans from builtins
// output: true
(all
    (boolean is)
    (boolean all)
    (boolean number:abs)
)

// test: Booleans from falsey type-coerced objects
// output: false
(any
    (boolean (new object 0))
    (boolean (new map NaN))
)

// test: Booleans from truthy type-coerced objects
// output: true
(all
    (boolean (new list 1))
    (boolean (new number []))
    (boolean (new character (context)))
)
