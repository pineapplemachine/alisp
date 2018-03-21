(test "Assignment with set returns the assigned value" (do
    (assert (is (set x 100) 100))
))

(test "Identifier becomes valid after set assignment" (do
    (set x 200)
    (assert (is x 200))
))

(test "Identifier is valid even after set assignment to null" (do
    (set x null)
    (assert (is x null))
))

(test "Verify behavior of nested calls to set" (do
    (set x (set y 300))
    (assert (is x y 300))
))

(test "Assignments with set overwrites variables in outer scopes" (do
    (set x "outer")
    (set y ((function [] (do (set x "inner") x))))
    (assert (eq [x y] ["inner" "inner"]))
))
