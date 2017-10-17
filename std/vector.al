(let zipMap (function [:fn] (do
    (let smallest (apply min (@:map list:length)))
    (if smallest (do
        (let i 0)
        (let result [])
        (while (isnot i smallest) (do
            (result:push (apply fn (@:map (function [:l] (l:at i)))))
            (let i (inc i))
        ))
        result
    ) null)
)))

// Construct a vector object of any dimensionality via `(vector x y z...)`.
(let vector (object
    :invoke (function []
        (apply vector:(if ((let size (@:length)):gt 4) :n size):invoke @)
    )
    
    :concat (function [:a :b] (apply vector (list:concat (a:list) (b:list))))
    
    :add (function [:a :b] (a:merge b sum))
    :sub (function [:a :b] (a:merge b sub))
    :mult (function [:a :b] (a:merge b mult))
    :div (function [:a :b] (a:merge b div))
    :dot (function [:a :b] ((a:merge b mult):apply sum))
    
    // Multiply components by a scalar value.
    :scale (function [:v :scalar] (v:mapwith mult scalar))
    // Get the unit vector parallel to this one.
    // The normal of the null vector is (vector NaN NaN ...)
    :normal (function [:v] (do
        (let hypot (v:hypot))
        (if (is hypot 0)
            (v:fill NaN)
            (v:mapwith div hypot)
        )
    ))
    
    :hypot (function [:v] (sqrt (v:hypotsq)))
    :hypotsq (function [:v] ((v:merge v mult):apply sum))
    :distance (function [:a :b] ((a:sub b):hypot))
    :distancesq (function [:a :b] ((a:sub b):hypotsq))
))

(let vector:0 (new vector
    :size 0
    :invoke (function [] (new vector:0))
    :fill (function [] (new vector:0))
    :list (function [] [])
    :map (function [:v] v)
    :mapwith (function [:v] v)
    :reduce (function [] null)
    :apply (function [:v :fn] (fn))
    :merge (function [:v] v)
    :at (function [] null)
    :normal (function [:v] v)
))
(let vector:1 (new vector
    :size 1
    :invoke (function [:x] (new vector:1 :x x))
    :fill (function [:x] (new vector:1 :x x))
    :list (function [:v] [v:x])
    :map (function [:v :fn] (new vector:1 :x (fn v:x)))
    :mapwith (function [:v :fn :x] (new vector:1 :x (fn v:x x)))
    :reduce (function [:v] v:x)
    :apply (function [:v :fn] (fn v:x))
    :merge (function [:v0 :v1 :fn] (new vector:1 :x (fn v0:x v1:x)))
    :at (function [:v :index] (if (is index 1) v:x null))
))
(let vector:2 (new vector
    :size 2
    :invoke (function [:x :y] (new vector:2 :x x :y y))
    :fill (function [:x] (new vector:2 :x x :y x))
    :list (function [:v] [v:x v:y])
    :map (function [:v :fn] (new vector:2 :x (fn v:x) :y (fn v:y)))
    :mapwith (function [:v :fn :x] (new vector:2
        :x (fn v:x x) :y (fn v:y x)
    ))
    :reduce (function [:v :fn] (fn v:x v:y))
    :apply (function [:v :fn] (fn v:x v:y))
    :merge (function [:v0 :v1 :fn] (new vector:2
        :x (fn v0:x v1:x)
        :y (fn v0:y v1:y)
    ))
    :at (function [:v :index] (switch
        (is index 1) v:x
        (is index 2) v:y
        null
    ))
    :angle (function [:v] (atan2 v:y v:x))
    :angleTo (function [:from :to]
        (atan2 (sub from:y to:y) (sub from:x to:x))
    )
))
(let vector:3 (new vector
    :size 3
    :invoke (function [:x :y :z] (new vector:3 :x x :y y :z z))
    :list (function [:v] [v:x v:y v:z])
    :map (function [:v :fn]
        (new vector:3 :x (fn v:x) :y (fn v:y) :z (fn v:z))
    )
    :mapwith (function [:v :fn :x] (new vector:1
        :x (fn v:x x) :y (fn v:y x) :z (fn v:z x)
    ))
    :reduce (function [:v :fn] (fn (fn v:x v:y) v:z))
    :apply (function [:v :fn] (fn v:x v:y v:z))
    :merge (function [:v0 :v1 :fn] (new vector:3
        :x (fn v0:x v1:x)
        :y (fn v0:y v1:y)
        :z (fn v0:z v1:z)
    ))
    :at (function [:v :index] (switch
        (is index 1) v:x
        (is index 2) v:y
        (is index 3) v:z
        null
    ))
    :cross (function [:a :b]
        (new vector:3
            :x (sub (mult (a:y) (b:z)) (mult (a:z) (b:y)))
            :y (sub (mult (a:z) (b:x)) (mult (a:x) (b:z)))
            :z (sub (mult (a:x) (b:y)) (mult (a:y) (b:x)))
        )
    )
))
(let vector:4 (new vector
    :size 4
    :invoke (function [:x :y :z :w] (new vector:4 :x x :y y :z z :w w))
    :list (function [:v] [v:x v:y v:z v:w])
    :map (function [:v :fn] 
        (new vector:4 :x (fn v:x) :y (fn v:y) :z (fn v:z) :w (fn v:w))
    )
    :mapwith (function [:v :fn :x] (new vector:1
        :x (fn v:x x) :y (fn v:y x) :z (fn v:z x) :w (fn v:w x)
    ))
    :reduce (function [:v :fn] (fn (fn (fn v:x v:y) v:z) v:w))
    :apply (function [:v :fn] (fn v:x v:y v:z v:w))
    :merge (function [:v0 :v1 :fn] (new vector:4
        :x (fn v0:x v1:x)
        :y (fn v0:y v1:y)
        :z (fn v0:z v1:z)
        :w (fn v0:w v1:w)
    ))
    :at (function [:v :index] (switch
        (is index 1) v:x
        (is index 2) v:y
        (is index 3) v:z
        (is index 4) v:w
        null
    ))
))
(let vector:n (new vector
    :invoke (function [] (new vector:n :size (@:length) :components @))
    :list (function [:v] (v:components:clone))
    :map (function [:v :fn] 
        (new vector:n :size v:size :components (v:components:map fn))
    )
    :mapwith (function [:v :fn :x] (new vector:1
        (new vector:n :size v:size
            :components (v:components:map (function [:c] (fn c x)))
        ))
    )
    :reduce (function [:v :fn] (v:components:reduce fn))
    :apply (function [:v :fn] (apply fn v:components))
    :merge (function [:v0 :v1 :fn] (new vector:n
        :size v0:size
        :components (zipMap fn v0:components v1:components)
    ))
    :at (function [:v :index] (v:components:at index))
))

// Dynamically add swizzling methods. For example:
// (vec:zy) is the same as (new vector:2 :x vec:z :y vec:y)
("xyzw":each (function [:ch0]
    ("xyzw":each (function [:ch1] (do
        (let vector:(keyword [ch0 ch1]) (function [:v] (new vector:2
            :x v:(keyword ch0) :y v:(keyword ch1)
        )))
        ("xyzw":each (function [:ch2] (do
            (let vector:(keyword [ch0 ch1 ch2]) (function [:v] (new vector:3
                :x v:(keyword ch0) :y v:(keyword ch1) :z v:(keyword ch2)
            )))
            ("xyzw":each (function [:ch3] (do
                (let vector:(keyword [ch0 ch1 ch2 ch3]) (function [:v] (new vector:4
                    :x v:(keyword ch0) :y v:(keyword ch1)
                    :z v:(keyword ch2) :w v:(keyword ch3)
                )))
            )))
        )))
    )))
))

vector
