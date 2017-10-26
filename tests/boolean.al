// test: Boolean from null
// output: false
(boolean null)

// test: Boolean from false
// output: false
(boolean false)

// test: Boolean from true
// output: true
(boolean true)

// test: Boolean from null character
// output: false
(boolean '\0')

// test: Boolean from non-null characters
(assert (is true (boolean 'X')))
(assert (is true (boolean 'y')))
(assert (is true (boolean '0')))
(assert (is true (boolean 'f')))

// test: Boolean from zero
// output: false
(boolean 0)

// test: Boolean from NaN
// output: false
(boolean NaN)

// test: Booleans from nonzero non-NaN numbers
(assert (is true (boolean 1)))
(assert (is true (boolean -1)))
(assert (is true (boolean 0.1)))
(assert (is true (boolean infinity)))
(assert (is true (boolean -infinity)))

// test: Booleans from keywords
(assert (is true (boolean (keyword))))
(assert (is true (boolean :x)))
(assert (is true (boolean :0)))
(assert (is true (boolean :false)))

// test: Boolean from context
// output: true
(boolean (context))

// test: Booleans from lists
(assert (is true (boolean [])))
(assert (is true (boolean [1 2 3])))

// test: Booleans from identifiers
(assert (is true (boolean (identifier))))
(assert (is true (boolean (quote x:y))))

// test: Booleans from expressions
(assert (is true (boolean (quote ()))))
(assert (is true (boolean (quote (sum 1 2 3)))))

// test: Booleans from maps
(assert (is true (boolean {})))
(assert (is true (boolean {:x 0 :y 1})))

// test: Booleans from objects
(assert (is true (boolean boolean)))
(assert (is true (boolean (object))))
(assert (is true (boolean (object :x 0 :y 1))))

// test: Booleans from functions
(assert (is true (boolean (function [] ()))))
(assert (is true (boolean (function [:x] x))))

// test: Booleans from methods
(assert (is true (boolean 0:abs)))
(assert (is true (boolean []:length)))

// test: Booleans from builtins
(assert (is true (boolean is)))
(assert (is true (boolean all)))
(assert (is true (boolean number:abs)))

// test: Booleans from falsey type-coerced objects
(assert (is false (boolean (new object 0))))
(assert (is false (boolean (new map NaN))))

// test: Booleans from truthy type-coerced objects
(assert (is true (boolean (new list 1))))
(assert (is true (boolean (new number []))))
(assert (is true (boolean (new character (context)))))

