module alisp.map;

import mach.math : pow2d;

import alisp.obj : LispObject;

bool mapsEqual(
    alias compareValues = (a, b) => a.sameKey(b)
)(LispMap a, LispMap b){
    if(a.length != b.length){
        return false;
    }
    foreach(LispMap.Bucket aBucket; a.buckets){
        foreach(LispMap.KeyValuePair aPair; aBucket){
            if(LispObject* bValue = b.get(aPair.key)){
                if(!compareValues(aPair.value, bValue)) return false;
            }else{
                return false;
            }
        }
    }
    foreach(LispMap.Bucket bBucket; b.buckets){
        foreach(LispMap.KeyValuePair bPair; bBucket){
            if(!a.get(bPair.key)) return false;
        }
    }
    return true;
}

struct LispMap{
    enum size_t DefaultSize = 6;
    
    struct KeyValuePair{
        size_t keyHash;
        LispObject* key;
        LispObject* value;
    }
    
    alias Bucket = KeyValuePair[];
    size_t size = 0;
    size_t hashMask = 0;
    size_t length = 0;
    Bucket* longestBucket = null;
    Bucket[] buckets;
    
    this(size_t size){
        this.setSize(size);
    }
    
    void reset(){
        this.setSize(DefaultSize);
    }
    void setSize(size_t size){
        this.size = size;
        this.hashMask = pow2d!size_t(this.size);
        this.length = 0;
        this.buckets = new Bucket[1 << size];
        this.longestBucket = &this.buckets[0];
    }
    void resize(size_t size){
        LispMap newMap = LispMap(size);
        foreach(bucket; this.buckets){
            foreach(pair; bucket){
                newMap.insert(pair);
            }
        }
        this.size = size;
        this.hashMask = newMap.hashMask;
        this.buckets = newMap.buckets;
        this.longestBucket = newMap.longestBucket;
    }
    
    LispObject* insert(LispObject* key, LispObject* value){
        return this.insert(KeyValuePair(key.toHash(), key, value));
    }
    LispObject* insert(KeyValuePair insertPair){
        if(!this.buckets.length){
            this.setSize(DefaultSize);
        }
        const bucketIndex = insertPair.keyHash & this.hashMask;
        Bucket bucket = this.buckets[bucketIndex];
        for(size_t i = 0; i < bucket.length; i++){
            KeyValuePair pair = bucket[i];
            if(insertPair.keyHash == pair.keyHash && insertPair.key.sameKey(pair.key)){
                bucket[i] = KeyValuePair(pair.keyHash, insertPair.key, insertPair.value);
                return pair.value;
            }
        }
        this.buckets[bucketIndex] ~= insertPair;
        if(bucket.length >= 16 && this.size < 12){
            this.resize(this.size + 2);
        }else if(bucket.length > this.longestBucket.length){
            this.longestBucket = &bucket;
        }
        this.length++;
        return null;
    }
    
    LispObject* get(LispObject* key){
        if(!this.buckets.length){
            return null;
        }
        const keyHash = key.toHash();
        Bucket bucket = this.buckets[keyHash & this.hashMask];
        foreach(KeyValuePair pair; bucket){
            if(keyHash == pair.keyHash && key.sameKey(pair.key)){
                return pair.value;
            }
        }
        return null;
    }
    
    LispObject* remove(LispObject* key){
        if(!this.buckets.length){
            return null;
        }
        const keyHash = key.toHash();
        const bucketIndex = keyHash & this.hashMask;
        Bucket bucket = this.buckets[bucketIndex];
        for(size_t i = 0; i < bucket.length; i++){
            KeyValuePair pair = bucket[i];
            if(keyHash == pair.keyHash && key.sameKey(pair.key)){
                this.buckets[bucketIndex] = (
                    this.buckets[bucketIndex][0 .. i] ~
                    this.buckets[bucketIndex][i + 1 .. $]
                );
                this.length--;
                return pair.value;
            }
        }
        return null;
    }
    
    bool opEquals(LispMap map){
        return mapsEqual(this, map);
    }
    
    LispMapRange asrange(){
        return LispMapRange(this);
    }
}

struct LispMapRange{
    LispMap lispMap;
    size_t i = 0, j = 0;
    
    this(LispMap lispMap){
        this.lispMap = lispMap;
        while(this.i < lispMap.buckets.length && !lispMap.buckets[this.i].length){
            this.i++;
        }
    }
    
    @property bool empty(){
        return this.i >= this.lispMap.buckets.length;
    }
    
    @property LispMap.KeyValuePair front(){
        return this.lispMap.buckets[this.i][this.j];
    }
    
    void popFront(){
        this.j++;
        if(this.j >= this.lispMap.buckets[this.i].length){
            this.j = 0;
            this.i++;
            while(this.i < lispMap.buckets.length && !lispMap.buckets[this.i].length){
                this.i++;
            }
        }
    }
}
