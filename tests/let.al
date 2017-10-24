// test: Identifier is not valid before assignment
// output: null
// error: identifier x
x

// test: Invocation returns assigned value
// output: 100
(let x 100)

// test: Assigned identifier becomes valid after assignment
// output: 200
(let x 200) x

// test: Identifier is valid even after assignment to null
// output: null
(let x null) null

// test: Nested calls
// output: true
(let x (let y 300)) (is x y 300)

// test: Shadows variables in outer scopes
// output: ["outer" "inner"]
(let x "outer")
(let y ((function [] (do (let x "inner") x))))
[x y]
