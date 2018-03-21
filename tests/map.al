(test "Construct an empty map" (do
    (assert ({}:empty?))
    (assert ((map):empty?))
))

(test "Verify behavior of an empty map" (do
    (let m {})
    (assert (is true (m:empty?)))
    (assert (is 0 (m:length)))
    (assert (is false (m:has :notpresent)))
    (assert (is null (m:get :notpresent)))
    (assert (eq [] (m:keys)))
    (assert (eq [] (m:values)))
))

(test "Insert into an empty map" (do
    (let m {})
    (m:set :key "hello")
    (assert (not (m:empty?)))
    (assert (is 1 (m:length)))
    (assert (m:has :key))
    (assert (eq "hello" (m:get :key)))
))

(test "Initialize a map with key, value pairs" (do
    (let m0 {:x 0 :y 1})
    (let m1 (map :x 0 :y 1))
    (assert (is 0 (m0:get :x)))
    (assert (is 1 (m0:get :y)))
    (assert (is 0 (m1:get :x)))
    (assert (is 1 (m1:get :y)))
    (assert (eq m0 m1))
))

(test "Get a list of keys that are in a map" (do
    (let m {:x 0 :y 1 :z 2})
    (let keys (m:keys))
    (assert (is 3 (keys:length)))
    (assert (keys:any (function [:e] (is e :x))))
    (assert (keys:any (function [:e] (is e :y))))
    (assert (keys:any (function [:e] (is e :z))))
    (assert (keys:none (function [:e] (is e :w))))
))

(test "Get a list of values that are in a map" (do
    (let m {:x 0 :y 1 :z 2})
    (let values (m:values))
    (assert (is 3 (values:length)))
    (assert (values:any (function [:e] (is e 0))))
    (assert (values:any (function [:e] (is e 1))))
    (assert (values:any (function [:e] (is e 2))))
    (assert (values:none (function [:e] (is e 3))))
))

(test "Enumerate the key, value pairs in an empty map" (do
    ({}:each (function [] (assert)))
))

(test "Enumerate the key, value pairs in a populated map" (do
    (let m {0 10 1 11 2 12 3 13 4 14})
    (let len 0)
    (m:each (function [:key :value] (do
        (assert (is value (sum 10 key)))
        (set len (inc len))
    )))
    (assert (is 5 len))
))

(test "Set multiple key, value pairs in a map with a single call" (do
    (let m {:x 0})
    (m:set :y 1 :z 2)
    (assert (eq m {:x 0 :y 1 :z 2}))
))

(test "Remove keys from a map" (do
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
))

(test "Attempt to remove a nonexistent key from a map" (do
    (let m {:x 0 :y 1})
    (assert (is 2 (m:length)))
    (m:remove :z)
    (assert (eq m {:x 0 :y 1}))
))

(test "Verify that a map's key removal method returns the map itself" (do
    (let m {:x 0 :y 1})
    (assert (is m (m:remove :x)))
))

(test "Merge maps, but with no input maps" (do
    (assert (eq {} (map:merge)))
))

(test "Merge maps, but with only one input map" (do
    // The produced map should be a copy of the original, not the original itself
    (let m0 {:x 0 :y 1})
    (let m1 (map:merge m0))
    (assert (eq m0 m1))
    (assert (isnot m0 m1))
))

(test "Merge multiple maps" (do
    (let m (map:merge {:x 0} {:y 1 :z 2} {} {:w 3}))
    (assert (eq m {:x 0 :y 1 :z 2 :w 3}))
))

(test "Extend a map, but with no input maps" (do
    (let m {:x 0 :y 1})
    (m:extend)
    (assert (eq m {:x 0 :y 1}))
))

(test "Extend a map using several other maps" (do
    (let m {:x 0 :y 1})
    (m:extend {:z 2} {} {:w 3})
    (assert (eq m {:x 0 :y 1 :z 2 :w 3}))
))

(test "Extend a map with the map itself as input" (do
    (let m {:x 0 :y 1})
    (m:extend m)
    (assert (eq m {:x 0 :y 1}))
))

(test "Extending a map returns the map itself" (do
    (let m {})
    (assert (is m (m:extend {:x 1})))
))

(test "Clone an empty map" (do
    (let m0 {})
    (let m1 (m0:clone))
    (assert (eq m0 m1))
    (assert (isnot m0 m1))
))

(test "Clone a populated map" (do
    (let m0 {:x 0 :y 1})
    (let m1 (m0:clone))
    (assert (eq m0 m1))
    (assert (isnot m0 m1))
    (m0:remove :x)
    (assert (not (m0:has :x)))
    (assert (m1:has :x))
))

(test "Clear all the keys in a map" (do
    (let m {:x 0 :y 1 :z 2 :w 3})
    (m:clear)
    (assert (m:empty?))
    (assert (is 0 (m:length)))
))

(test "Clearing the keys in a map returns that map itself" (do
    (let m {:x 0})
    (assert (is m (m:clear)))
))
