(test "Identifier is not valid before assignment" (do
    (try :error invalidIdentifier () (assert (isnot null error)))
))

(test "Assignment with let returns the assigned value" (do
    (assert (is (let x 100) 100))
))

(test "Identifier becomes valid after let assignment" (do
    (let x 200)
    (assert (is x 200))
))

(test "Identifier is valid even after let assignment to null" (do
    (let x null)
    (assert (is x null))
))

(test "Verify behavior of nested calls to let" (do
    (let x (let y 300))
    (assert (is x y 300))
))

(test "Assignments with let shadow other variables in outer scopes" (do
    (let x "outer")
    (let y ((function [] (do (let x "inner") x))))
    (assert (eq [x y] ["outer" "inner"]))
))
