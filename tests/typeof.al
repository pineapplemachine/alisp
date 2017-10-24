// test: Null type
// output: true
(is null (typeof null))

// test: Boolean type
// output: true
(all
    (is boolean (typeof true))
    (is boolean (typeof false))
)

// test: Character type
// output: true
(all
    (is character (typeof 'x'))
    (is character (typeof 'y'))
    (is character (typeof 'Z'))
)

// test: Number type
// output: true
(all
    (is number (typeof 0))
    (is number (typeof 1))
    (is number (typeof -1))
    (is number (typeof infinity))
    (is number (typeof -infinity))
    (is number (typeof NaN))
)

// test: Keyword type
// output: true
(all
    (is keyword (typeof (keyword)))
    (is keyword (typeof :x))
    (is keyword (typeof :abc123))
)

// test: Context type
// output: true
(all
    (is context (typeof (context)))
)

// test: List type
// output: true
(all
    (is list (typeof []))
    (is list (typeof [1 2 3]))
)

// test: Identifier type
// output: true
(all
    (is identifier (typeof (identifier)))
    (is identifier (typeof (quote x)))
    (is identifier (typeof (quote some:identifier)))
    (is identifier (typeof (quote x:(1:abs):abs)))
)

// test: Expression type
// output: true
(all
    (is expression (typeof (quote ())))
    (is expression (typeof (quote (do 1))))
    (is expression (typeof (quote (sum 1 2 3))))
)

// test: Map type
// output: true
(all
    (is map (typeof {}))
    (is map (typeof {:x 0 :y 1}))
)

// test: Object type
// output: true
(all
    (is object (typeof object))
    (is object (typeof (object)))
    (is object (typeof (object :x 0 :y 1)))
)

// test: Function type
// output: true
(all
    (is function (typeof (function [] ())))
    (is function (typeof (function [] 1)))
    (is function (typeof (function [:x] x)))
)

// test: Method type
// output: true
(all
    (is method (typeof 0:abs))
    (is method (typeof []:length))
    (is method (typeof (method (quote some:identifier) list:length)))
)

// test: Builtin type
// output: true
(all
    (is builtin (typeof typeof))
    (is builtin (typeof is))
    (is builtin (typeof number:abs))
)

// test: Custom type
// output: true
(let MyType (object :x 0 :y 1))
(is MyType (typeof (new MyType)))
