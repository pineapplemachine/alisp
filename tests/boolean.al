(test "Convert null to a boolean" (do
    (assert (is false (boolean null)))
))

(test "Convert booleans to booleans" (do
    (assert (is true (boolean true)))
    (assert (is false (boolean false)))
))

(test "Convert the null character to a boolean" (do
    (assert (is false (boolean '\0')))
))

(test "Convert non-null characters to booleans" (do
    (assert (is true (boolean 'X')))
    (assert (is true (boolean 'y')))
    (assert (is true (boolean '0')))
    (assert (is true (boolean 'f')))
))

(test "Convert the number zero to a boolean" (do
    (assert (is false (boolean 0)))
))

(test "Convert NaN to a boolean" (do
    (assert (is false (boolean NaN)))
))

(test "Convert positive and negative infinity to booleans" (do
    (assert (is true (boolean infinity)))
    (assert (is true (boolean -infinity)))
))

(test "Convert finite nonzero numbers to booleans" (do
    (assert (is true (boolean 1)))
    (assert (is true (boolean -1)))
    (assert (is true (boolean 0.1)))
    (assert (is true (boolean 12345)))
))

(test "Convert keywords to booleans" (do
    (assert (is true (boolean (keyword))))
    (assert (is true (boolean :x)))
    (assert (is true (boolean :0)))
    (assert (is true (boolean :true)))
    (assert (is true (boolean :false)))
))

(test "Convert the execution context to a boolean" (do
    (boolean (context))
))

(test "Convert lists to booleans" (do
    (assert (is true (boolean [])))
    (assert (is true (boolean [1 2 3])))
    (assert (is true (boolean "")))
    (assert (is true (boolean "hello!")))
))

(test "Convert identifiers to booleans" (do
    (assert (is true (boolean (identifier))))
    (assert (is true (boolean (quote x:y))))
))

(test "Convert expressions to booleans" (do
    (assert (is true (boolean (quote ()))))
    (assert (is true (boolean (quote (sum 1 2 3)))))
))

(test "Convert maps to booleans" (do
    (assert (is true (boolean {})))
    (assert (is true (boolean {:x 0 :y 1})))
))

(test "Convert objects to booleans" (do
    (assert (is true (boolean boolean)))
    (assert (is true (boolean (object))))
    (assert (is true (boolean (object :x 0 :y 1))))
))

(test "Convert functions to booleans" (do
    (assert (is true (boolean (function [] ()))))
    (assert (is true (boolean (function [:x] x))))
))

(test "Convert methods to booleans" (do
    (assert (is true (boolean 0:abs)))
    (assert (is true (boolean []:length)))
))

(test "Convert builtins to booleans" (do
    (assert (is true (boolean is)))
    (assert (is true (boolean all)))
    (assert (is true (boolean number:abs)))
))

(test "Convert type-coerced objects to booleans" (do
    // The original value is falsey
    (assert (is false (boolean (new object 0))))
    (assert (is false (boolean (new map NaN))))
    // The original value is truthy
    (assert (is true (boolean (new list 1))))
    (assert (is true (boolean (new number []))))
    (assert (is true (boolean (new character (context)))))
))
