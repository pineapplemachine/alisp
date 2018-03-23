(test "Do returns null when no expressions were provided" (do
    (assert (is null (do)))
))

(test "Do evaluates a series of expressions and returns the output of the last expression" (do
    (let n null)
    (assert (is :last (do
        (set n :first)
        (set n :last)
    )))
    (assert (is 3 (do
        0
        1
        2
        3
    )))
))

(test "When returns null when it received no expressions" (do
    (assert (is null (when)))
    (assert (is null (when true)))
    (assert (is null (when false)))
))

(test "When unconditionally evaluates its condition, when provided" (do
    (let x null)
    (when (let x true))
    (assert (is true x))
    (when (let x false))
    (assert (is false x))
    (when (let x infinity) null)
    (assert (is infinity x))
))

(test "When ignores its expressions when the condition is not satisfied" (do
    (when false (assert))
))

(test "When evaluates its expressions when the condition is satisfied" (do
    (let x 0)
    (let y 0)
    (when true (set x 1) (set y 2))
    (assert (is 1 x))
    (assert (is 2 y))
))

(test "When returns null when the condition was not satisfied" (do
    (assert (is null (when false 1)))
))

(test "When returns the output of the last expression when the condition was satisfied" (do
    (assert (is :last (when true :first :last)))
))

(test "If returns null when it receives no arguments" (do
    (assert (is null (if)))
))

(test "If returns unconditionally evaluates its condition, when provided" (do
    (let x null)
    (if (let x true))
    (assert (is true x))
    (if (let x false))
    (assert (is false x))
    (if (let x infinity) null)
    (assert (is infinity x))
))

(test "If does not evaluate its first expression when the condition was not satisfied" (do
    (if false (assert))
    (if false (assert) null)
))

(test "If evaluates its first expression when the condition was satisfied" (do
    (let x null)
    (if true (let x true))
    (assert (is true x))
    (if true (let x false) (let x NaN))
    (assert (is false x))
))

(test "If does not evaluate its second expression when the condition was satisfied" (do
    (if true null (assert))
))

(test "If evaluates its second expression when the condition was not satisfied" (do
    (let x null)
    (if false null (let x true))
    (assert (is true x))
))

(test "Switch returns null when it received no arguments" (do
    (assert (is null (switch)))
))

(test "Switch returns null when none of its conditions were satisfied and no default expression was given" (do
    (assert (is null (switch
        0 (assert)
        false (assert)
        NaN (assert)
    )))
))

(test "Switch evaluates the first expression whose condition was met, and no others" (do
    (assert (is :met (switch
        0 (assert)
        true :met
        NaN (assert)
        // This condition and its expression are not evaluated
        true (assert)
    )))
))

(test "Switch stops evaluating conditions upon finding the first satisfied condition" (do
    (assert (is :met (switch
        true :met
        // Neither condition nor expression are ever evaluated
        (assert) (assert)
    )))
))

(test "Switch evaluates the default expression when there were no conditional expressions" (do
    (assert (is 1 (switch
        1
    )))
))

(test "Switch evaluates the default expression when no conditions were satisfied" (do
    (assert (is :default (switch
        false (assert)
        null (assert)
        :default
    )))
))

(test "Switch does not evaluate the default expression when a condition was met" (do
    (assert (is :first (switch
        true :first
        (assert)
    )))
))

(test "Until returns null when it received no arguments" (do
    (assert (is null (until)))
))

(test "Until returns null when the condition was met from the start" (do
    (assert (is null (until true)))
    (assert (is null (until true :loop)))
))

(test "Until does not evaluate the body expression when the condition was met from the start" (do
    (until true (assert))
))

(test "Until loops the body expression until the condition is satisfied" (do
    (let x 0)
    (until (is 5 x)
        (set x (sum 1 x))
    )
    (assert (is 5 x))
))

(test "Until evaluates the condition until met, even in the absence of an expression" (do
    (let x 0)
    (until (is 5 (set x (sum 1 x))))
    (assert (is 5 x))
))

(test "Until returns the output from the final evaluation of the loop body" (do
    (let x 0)
    (assert (is 15 (until (is 10 x) (do
        (set x (sum 1 x))
        (sum 5 x)
    ))))
))

(test "While returns null when it received no arguments" (do
    (assert (is null (while)))
))

(test "While returns null when the condition was unmet from the start" (do
    (assert (is null (while false)))
    (assert (is null (while false :loop)))
))

(test "While does not evaluate the body expression when the condition was unmet from the start" (do
    (while false (assert))
))

(test "While loops the body expression while the condition is satisfied" (do
    (let x 0)
    (while (isnot 5 x)
        (set x (sum 1 x))
    )
    (assert (is 5 x))
))

(test "While evaluates the condition while met, even in the absence of an expression" (do
    (let x 0)
    (while (isnot 5 (set x (sum 1 x))))
    (assert (is 5 x))
))

(test "While returns the output from the final evaluation of the loop body" (do
    (let x 0)
    (assert (is 15 (while (isnot 10 x) (do
        (set x (sum 1 x))
        (sum 5 x)
    ))))
))
