(test "Any returns null with no inputs" (do
    (assert (is null (any)))
))

(test "Any returns the first input when there was only one input" (do
    (assert (is null (any null)))
    (assert (is true (any true)))
    (assert (is false (any false)))
    (assert (is 0 (any 0)))
    (assert (is 1 (any 1)))
))

(test "Any returns the first truthy input" (do
    (assert (is 2 (any 0 NaN null 0 '\0' 2 10 null)))
))

(test "Any returns the last falsey input when there was no truthy input" (do
    (assert (is '\0' (any 0 false null NaN '\0')))
))
