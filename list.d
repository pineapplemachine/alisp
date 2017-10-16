module alisp.list;

import alisp.obj : LispObject;

import mach.io.stdio;

// TODO: Just use regular arrays!

bool listsEqual(
    alias compareValues = (a, b) => a.sameKey(b)
)(LispList a, LispList b){
    if(a.length != b.length){
        return false;
    }
    for(size_t i = 0; i < a.length; i++){
        if(!compareValues(a[i], b[i])){
            return false;
        }
    }
    return true;
}

struct LispList{
    LispObject*[] objects;
    
    @property size_t length() const{
        return this.objects.length;
    }
    
    size_t opDollar() const{
        return this.objects.length;
    }
    
    LispObject* opIndex(in size_t index){
        return this.objects[index];
    }
    void opIndexAssign(LispObject* object, in size_t index){
        this.objects[index] = object;
    }
    
    LispList opSlice(in size_t low, in size_t high){
        return LispList(this.objects[low .. high]);
    }
    
    void push(LispObject* object){
        this.objects ~= object;
    }
    
    LispObject* pop(){
        assert(this.objects.length);
        LispObject* object = this.objects[$ - 1];
        this.objects.length--;
        return object;
    }
    
    void insert(size_t index, LispObject* object){
        assert(index <= this.objects.length);
        this.objects = (
            this.objects[0 .. index] ~ object ~ this.objects[index .. $]
        );
    }
    void insert(in size_t index, LispObject*[] objects){
        assert(index <= this.objects.length);
        this.objects = (
            this.objects[0 .. index] ~ objects ~ this.objects[index .. $]
        );
    }
    
    void extend(LispList list){
        return this.extend(list.objects);
    }
    void extend(LispObject*[] objects){
        this.objects ~= objects;
    }
    
    void remove(in size_t index){
        assert(index <= this.objects.length);
        this.objects = (
            this.objects[0 .. index] ~ this.objects[index .. $]
        );
    }
    
    void clear(){
        this.objects.length = 0;
    }
    
    LispList copy(){
        return LispList(this.objects);
    }
    
    LispListRange asrange(){
        return LispListRange(this);
    }
}

struct LispListRange{
    LispList list;
    size_t index = 0;
    
    @property bool empty() const{
        return this.index >= this.list.length;
    }
    LispObject* front(){
        return this.list[this.index];
    }
    void popFront(){
        this.index++;
    }
}
