// test: Identifier is not valid before assignment
// output: null
// error: identifier x
x

// test: Invocation returns assigned value
// output: 100
(set x 100)

// test: Assigned identifier becomes valid after assignment
// output: 200
(set x 200) x

// test: Identifier is valid even after assignment to null
// output: null
(set x null) null

// test: Nested calls
// output: true
(set x (set y 300)) (is x y 300)

// test: Overwrites variables in outer scopes
// output: ["inner" "inner"]
(set x "outer")
(set y ((function [] (do (set x "inner") x))))
[x y]
