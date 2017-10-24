// test: Outputs null with no inputs
// output: null
(any)

// test: Outputs first input with one input
// output: [null true false 0 1]
[
    (any null)
    (any true)
    (any false)
    (any 0)
    (any 1)
]

// test: Outputs first truthy input
// output: 2
(any 0 NaN null 0 '\0' 2 10 null)

// test: Outputs last falsey input
// output: '\0'
(any 0 false null NaN '\0')
