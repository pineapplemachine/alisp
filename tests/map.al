// test: Construct an empty map with curly braces
// output: true
({}:empty?)

// test: Construct an empty map by invoking "map"
// output: true
((map):empty?)

// test: Behavior of empty map
(let m {})
(assert (is true (m:empty?)))
(assert (is 0 (m:length)))
(assert (is false (m:has :notpresent)))
(assert (is null (m:get :notpresent)))
(assert (eq [] (m:keys)))
(assert (eq [] (m:values)))

// test: Insertion into empty map
(let m {})
(m:set :key "hello")
(assert (not (m:empty?)))
(assert (is 1 (m:length)))
(assert (m:has :key))
(assert (eq "hello" (m:get :key)))

// test: Initialize maps with values
(let m0 {:x 0 :y 1})
(let m1 (map :x 0 :y 1))
(assert (is 0 (m0:get :x)))
(assert (is 1 (m0:get :y)))
(assert (is 0 (m1:get :x)))
(assert (is 1 (m1:get :y)))
(assert (eq m0 m1))

// test: List keys of a map
(let m {:x 0 :y 1 :z 2})
(let keys (m:keys))
(assert (is 3 (keys:length)))
(assert (keys:any (function [:e] (is e :x))))
(assert (keys:any (function [:e] (is e :y))))
(assert (keys:any (function [:e] (is e :z))))
(assert (keys:none (function [:e] (is e :w))))

// test: List values of a map
(let m {:x 0 :y 1 :z 2})
(let values (m:values))
(assert (is 3 (values:length)))
(assert (values:any (function [:e] (is e 0))))
(assert (values:any (function [:e] (is e 1))))
(assert (values:any (function [:e] (is e 2))))
(assert (values:none (function [:e] (is e 3))))

// test: Enumerate key, value pairs of a map
(let m {0 10 1 11 2 12 3 13 4 14})
(let len 0)
(m:each (function [:key :value] (do
    (assert (is value (sum 10 key)))
    (set len (inc len))
)))
(assert (is 5 len))

// test: Enumerate key, value pairs of an empty map
({}:each (function [] (assert)))

// test: Set multiple keys in a map at once
(let m {:x 0})
(m:set :y 1 :z 2)
(assert (eq m {:x 0 :y 1 :z 2}))

// test: Remove keys from a map
(let m {:x 0 :y 1 :z 2 :w 3})
(assert (is 4 (m:length)))
(m:remove :x)
(assert (is 3 (m:length)))
(assert (not (m:has :x)))
(m:remove :y :z)
(assert (is 1 (m:length)))
(assert (not (m:has :y)))
(assert (not (m:has :z)))
(m:remove :w)
(assert (m:empty?))

// test: Remove nonexistent key from a map
(let m {:x 0 :y 1})
(assert (is 2 (m:length)))
(m:remove :z)
(assert (eq m {:x 0 :y 1}))

// test: Removal of keys from a map returns the map itself
(let m {:x 0 :y 1})
(assert (is m (m:remove :x)))

// test: Merge maps with no inputs
(assert (eq {} (map:merge)))

// test: Merge maps with one input
(let m0 {:x 0 :y 1})
(let m1 (map:merge m0))
(assert (eq m0 m1))
(assert (isnot m0 m1))

// test: Merge maps with multiple inputs
(let m (map:merge {:x 0} {:y 1 :z 2} {} {:w 3}))
(assert (eq m {:x 0 :y 1 :z 2 :w 3}))

// test: Extend a map
(let m {:x 0 :y 1})
(m:extend {:z 2} {} {:w 3})
(assert (eq m {:x 0 :y 1 :z 2 :w 3}))

// test: Extend a map with no inputs
(let m {:x 0 :y 1})
(m:extend)
(assert (eq m {:x 0 :y 1}))

// test: Extending a map returns the map itself
(let m {})
(assert (is m (m:extend {:x 1})))

// test: Clone a map
(let m0 {:x 0 :y 1})
(let m1 (m0:clone))
(assert (eq m0 m1))
(assert (isnot m0 m1))
(m0:remove :x)
(assert (not (m0:has :x)))
(assert (m1:has :x))

// test: Clear all keys from a map
(let m {:x 0 :y 1 :z 2 :w 3})
(m:clear)
(assert (m:empty?))
(assert (is 0 (m:length)))

// test: Clearing keys in a map returns the map itself
(let m {})
(assert (is m (m:clear)))
