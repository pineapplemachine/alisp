(test "Not returns the logical negation of its input" (do
    (assert (is false (not true)))
    (assert (is true (not false)))
    (assert (is false (not 1)))
    (assert (is true (not NaN)))
))

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

(test "All returns null with no inputs" (do
    (assert (is null (all)))
))

(test "All returns the first input when there was only one input" (do
    (assert (is null (all null)))
    (assert (is true (all true)))
    (assert (is false (all false)))
    (assert (is 0 (all 0)))
    (assert (is 1 (all 1)))
))

(test "All returns the first falsey input" (do
    (assert (is '\0' (all '!' true '\0' false NaN 1)))
))

(test "All returns the last truthy input when there was no falsey input" (do
    (assert (is '!' (all 1 true [] '!')))
))

(test "None returns true with no inputs" (do
    (assert (is true (none)))
))

(test "None returns true when all inputs were falsey" (do
    (assert (is true (none false)))
    (assert (is true (none 0 false null NaN)))
))

(test "None returns true when any input was truthy" (do
    (assert (is false (none true)))
    (assert (is false (none false NaN true '\0')))
))
