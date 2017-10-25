module alisp.obj;

import mach.math : fidentical, fisnan;
import mach.range : map, join, all, asarray;
import mach.text.numeric : WriteFloatSettings, writefloat;
import mach.text.utf : utf8decode;
import mach.traits : hash;

import alisp.context : LispContext;
import alisp.escape : escapeCharacter;
import alisp.list : LispList, listsEqual;
import alisp.map : LispMap, mapsEqual;

enum WriteFloatSettings LispFloatSettings = {
    PosNaNLiteral: "NaN",
    NegNaNLiteral: "-NaN",
    PosInfLiteral: "infinity",
    NegInfLiteral: "-infinity",
};

alias LispArguments = LispObject*[];

alias NativeFunction = LispObject* function(
    LispContext* context, LispArguments arguments
);

// This allows hashes to always be exactly represented by doubles
alias LispObjectHash = uint;

struct LispFunction{
    size_t uniqueId = 0;
    LispContext* parentContext;
    LispObject*[] argumentList;
    LispObject* expressionBody;
    
    LispObject* evaluate(LispContext* context, LispArguments arguments){
        assert(context && this.parentContext && this.expressionBody);
        LispContext* functionContext = new LispContext(this.parentContext);
        size_t i = 0;
        for(; i < this.argumentList.length && i < arguments.length; i++){
            LispObject* argumentObject = context.evaluate(arguments[i]);
            functionContext.register(this.argumentList[i], argumentObject);
            assert(argumentObject);
        }
        for(; i < this.argumentList.length; i++){
            functionContext.register(this.argumentList[i], context.Null);
        }
        if(i < arguments.length){
            LispObject*[] remainingArguments;
            for(; i < arguments.length; i++){
                LispObject* argumentObject = context.evaluate(arguments[i]);
                remainingArguments ~= argumentObject;
                assert(argumentObject);
            }
            functionContext.register(
                "@"d, this.parentContext.list(remainingArguments)
            );
        }else{
            functionContext.register(
                "@"d, this.parentContext.list()
            );
        }
        return functionContext.evaluate(this.expressionBody);
    }
}

struct LispMethod{
    LispObject* contextObject;
    LispObject* functionObject;
    
    LispObject* evaluate(LispContext* context, LispArguments arguments){
        assert(context && this.contextObject && this.functionObject);
        return context.invoke(
            this.functionObject, this.contextObject ~ arguments
        );
    }
}

LispObjectHash listHash(LispList list){
    LispObjectHash value = 0;
    foreach(element; list.objects){
        value = value ^ element.toHash();
        value += 2560;
    }
    return value;
}

LispObjectHash mapHash(LispMap* map){
    LispObjectHash value = 0;
    foreach(pair; map.asrange()){
        assert(pair.key && pair.value);
        value = value ^ (pair.key.toHash() * pair.value.toHash());
    }
    return value;
}

struct LispObject{
    // Dlang types of lisp primitive types
    alias Boolean = bool;
    alias Character = dchar;
    alias Number = double;
    alias Keyword = dstring;
    
    // Enumeration of primitive types
    static enum Type{
        Null,
        Boolean,
        Character,
        Number,
        Keyword,
        List,
        Map,
        Object,
        Context,
        NativeFunction,
        LispFunction,
        LispMethod,
    }
    
    // Union type to store the value of an object
    union Store{
        Boolean boolean;
        Character character;
        Number number;
        Keyword keyword;
        LispList list;
        LispMap* map;
        LispContext* context;
        NativeFunction nativeFunction;
        LispFunction lispFunction;
        LispMethod lispMethod;
    }
    
    // What primitive type the stored value is
    const Type type = Type.Null;
    // The value representing the type of this one
    LispObject* typeObject = null;
    // The value of the object
    Store store;
    
    LispObject* builtinIdentifier = null;
    
    this(in Type type){
        this.type = type;
    }
    this(in Type type, LispObject* typeObject){
        this.type = type;
        this.typeObject = typeObject;
    }
    this(in Type type, LispObject* typeObject, Store store){
        this.type = type;
        this.typeObject = typeObject;
        this.store = store;
    }
    
    this(in Boolean boolean, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.Boolean;
        this.typeObject = typeObject;
        this.store.boolean = boolean;
    }
    this(in Character character, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.Character;
        this.typeObject = typeObject;
        this.store.character = cast(dchar) character;
    }
    this(in Number number, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.Number;
        this.typeObject = typeObject;
        this.store.number = number;
    }
    this(in dstring keyword, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.Keyword;
        this.typeObject = typeObject;
        this.store.keyword = keyword;
    }
    this(LispList list, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.List;
        this.typeObject = typeObject;
        this.store.list = list;
    }
    this(LispMap* map, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.Map;
        this.typeObject = typeObject;
        this.store.map = map;
    }
    this(LispMap* map, Type type, LispObject* typeObject){
        assert(typeObject);
        this.type = type;
        this.typeObject = typeObject;
        this.store.map = map;
    }
    this(LispContext* context, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.Context;
        this.typeObject = typeObject;
        this.store.context = context;
    }
    this(in NativeFunction nativeFunction, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.NativeFunction;
        this.typeObject = typeObject;
        this.store.nativeFunction = nativeFunction;
    }
    this(LispFunction lispFunction, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.LispFunction;
        this.typeObject = typeObject;
        this.store.lispFunction = lispFunction;
    }
    this(LispMethod method, LispObject* typeObject){
        assert(typeObject);
        this.type = Type.LispMethod;
        this.typeObject = typeObject;
        this.store.lispMethod = method;
    }

    bool isList() const{
        return this.type is Type.List;
    }
    bool isMap() const{
        return this.type is Type.Map || this.type is Type.Object;
    }
    bool isCallable() const{
        return (
            this.type is Type.Object || this.type is Type.NativeFunction ||
            this.type is Type.LispFunction || this.type is Type.LispMethod
        );
    }
    
    bool instanceOf(LispObject* typeObject){
        assert(typeObject);
        LispObject* object = &this;
        while(object.typeObject != typeObject && object.typeObject != object){
            object = object.typeObject;
        }
        return object.typeObject == typeObject;
    }
    auto getAttribute(LispObject* attribute){
        assert(attribute);
        struct Result{
            bool rootAttribute;
            LispObject* object;
        }
        if(this.typeObject == &this){
            return Result(true, this.type is Type.Object ?
                this.store.map.get(attribute) : null
            );
        }
        LispObject* object = &this;
        LispObject* result = null;
        // Should not actually be possible to construct a cyclic type chain
        // where the cycle appears anywhere but at the root.
        //LispObject*[] visitedStack;
        while(true){
            if(object.type is Type.Object){
                result = object.store.map.get(attribute);
            }
            if(result || object.typeObject == object){
                break;
            }
            object = object.typeObject;
            //foreach(visited; visitedStack){
            //    if(object.identical(visited) || object.cyclicIdentical(visited)){
            //        return Result(false, null);
            //    }
            //}
            //visitedStack ~= object;
        }
        return Result(object == &this, result);
    }
    
    LispObject*[] identifyObject(LispObject* object, LispObject*[] visitedStack = null){
        assert(object);
        if(this.type !is Type.Object){
            return null;
        }
        foreach(visited; visitedStack){
            if(this.map is visited.map) return null;
        }
        foreach(pair; this.map.asrange()){
            assert(pair.key && pair.value);
            if(pair.value.identical(object)) return [pair.key];
        }
        LispObject*[] nextVisited = visitedStack ~ &this;
        foreach(pair; this.map.asrange()){
            if(LispObject*[] path = pair.value.identifyObject(object, nextVisited)){
                return pair.key ~ path;
            }
        }
        return null;
    }
    
    // Get a string representation (e.g. for debugging).
    dstring toString(){
        final switch(this.type){
            case Type.Null:
                return "null"d;
            case Type.Boolean:
                return this.store.boolean ? "true"d : "false"d;
            case Type.Character:
                return cast(dstring)['\'', this.store.character, '\''];
            case Type.Number:
                return cast(dstring) writefloat!LispFloatSettings(this.store.number).utf8decode().asarray();
            case Type.Keyword:
                return dchar(':') ~ this.store.keyword;
            case Type.List:
                if(
                    this.listLength &&
                    this.list.objects.all!(i => i.type is Type.Character)
                ){
                    return dchar('"') ~ cast(dstring)(
                        this.store.list.map!(i => 
                            escapeCharacter(i.store.character)
                        ).join().asarray()
                    ) ~ dchar('"');
                }else{
                    return dchar('[') ~ cast(dstring)(
                        this.store.list.map!(i => i.toString()).join(" "d).asarray()
                    ) ~ dchar(']');
                }
            case Type.Map:
                assert(this.store.map);
                return dchar('{') ~ cast(dstring)(
                    this.store.map.asrange().map!(pair =>
                        pair.key.toString() ~ ' ' ~ pair.value.toString()
                    ).join(" ").asarray()
                ) ~ dchar('}');
            case Type.Context:
                return "(context)"d;
            case Type.Object:
                if(this.store.map.length == 0){
                    return "(object)"d;
                }else{
                    return "(object "d ~ cast(dstring)(
                        this.store.map.asrange().map!(pair =>
                            pair.key.toString() ~ ' ' ~ pair.value.toString()
                        ).join(" "d).asarray()
                    ) ~ dchar(')');
                }
            case Type.NativeFunction:
                if(this.builtinIdentifier){
                    return "(builtin " ~ this.builtinIdentifier.toString() ~ ")";
                }else{
                    return "(builtin)"d;
                }
            case Type.LispFunction:
                return cast(dstring) ("(function ["d ~
                    this.store.lispFunction.argumentList.map!(i =>
                        i.toString()
                    ).join(" "d).asarray!dchar()
                ~ "] "d ~ this.store.lispFunction.expressionBody.toString()) ~ ')';
            case Type.LispMethod:
                return cast(dstring) ("(method "d ~
                    this.store.lispMethod.contextObject.toString() ~ ' ' ~
                    this.store.lispMethod.functionObject.toString() ~
                ')');
        }
    }
    
    bool cyclicIdentical(LispObject* value){
        return (
            this.isList && value.isList && this.list.objects is value.list.objects
        ) || (
            this.isMap && value.isMap && this.map is value.map
        );
    }
    
    // Strict equality comparison. Returns true when the inputs are exactly
    // the same.
    bool identical(LispObject* value){
        assert(value);
        if(&this == value){
            return true;
        }else if(this.type !is value.type || this.typeObject != value.typeObject){
            return false;
        }
        final switch(this.type){
            case Type.Null:
                return true;
            case Type.Boolean:
                return this.boolean == value.boolean;
            case Type.Character:
                return this.character == value.character;
            case Type.Number:
                return fidentical(this.number, value.number);
            case Type.Keyword:
                return this.keyword == value.keyword;
            case Type.List:
                return this.list.objects is value.list.objects;
            case Type.Map: goto case;
            case Type.Object:
                return this.map is value.map;
            case Type.Context:
                return this.context == value.context;
            case Type.NativeFunction:
                return this.nativeFunction == value.nativeFunction;
            case Type.LispFunction:
                return (
                    this.lispFunction.uniqueId ==
                    value.lispFunction.uniqueId
                );
            case Type.LispMethod:
                return this.lispMethod.contextObject.identical(
                    value.lispMethod.contextObject
                ) && this.lispMethod.functionObject.identical(
                    value.lispMethod.functionObject
                );
        }
    }
    
    // True when two objects should be considered the same key according to a map.
    bool sameKey(LispObject* value){
        assert(value);
        if(&this == value){
            return true;
        }else if(this.type !is value.type || this.typeObject != value.typeObject){
            return false;
        }
        final switch(this.type){
            case Type.Null:
                return true;
            case Type.Boolean:
                return this.boolean == value.boolean;
            case Type.Character:
                return this.character == value.character;
            case Type.Number:
                return fidentical(this.number, value.number);
            case Type.Keyword:
                return this.keyword == value.keyword;
            case Type.List:
                return listsEqual!((a, b) => {
                    assert(a && b);
                    return a.sameKey(b);
                })(
                    this.list, value.list
                );
            case Type.Map: goto case;
            case Type.Object:
                assert(this.map && value.map);
                return mapsEqual!((a, b) => {
                    assert(a && b);
                    return a.sameKey(b);
                })(
                    this.map, value.map
                );
            case Type.Context:
                return this.context == value.context;
            case Type.NativeFunction:
                return this.nativeFunction == value.nativeFunction;
            case Type.LispFunction:
                return (
                    this.lispFunction.uniqueId ==
                    value.lispFunction.uniqueId
                );
            case Type.LispMethod:
                return this.lispMethod.contextObject.identical(
                    value.lispMethod.contextObject
                ) && this.lispMethod.functionObject.identical(
                    value.lispMethod.functionObject
                );
        }
    }
    
    LispObjectHash toHash(){
        LispObjectHash valueHash = void;
        final switch(this.type){
            case Type.Null:
                valueHash = 0;
                break;
            case Type.Boolean:
                valueHash = cast(LispObjectHash) this.boolean;
                break;
            case Type.Character:
                valueHash = cast(LispObjectHash) this.character;
                break;
            case Type.Number:
                valueHash = cast(LispObjectHash) hash(this.number);
                break;
            case Type.Keyword:
                valueHash = cast(LispObjectHash) hash(this.keyword);
                break;
            case Type.List:
                valueHash = listHash(this.store.list);
                break;
            case Type.Map: goto case;
            case Type.Object:
                assert(this.store.map);
                valueHash = mapHash(this.store.map);
                break;
            case Type.Context:
                assert(this.store.context);
                valueHash = cast(LispObjectHash) this.store.context;
                break;
            case Type.NativeFunction:
                // TODO: Verify behavior
                valueHash = cast(LispObjectHash) this.store.nativeFunction;
                break;
            case Type.LispFunction:
                valueHash = cast(LispObjectHash) this.store.lispFunction.uniqueId;
                break;
            case Type.LispMethod:
                valueHash = (
                    this.store.lispMethod.contextObject.toHash() ^
                    this.store.lispMethod.functionObject.toHash()
                );
                break;
        }
        return valueHash + (cast(LispObjectHash) this.typeObject);
    }
    
    void push(LispObject* object){
        assert(object);
        this.list.push(object);
    }
    void extend(LispList list){
        this.list.extend(list);
    }
    void extend(LispObject*[] list){
        this.list.extend(list);
    }
    
    @property ref Boolean boolean(){
        assert(this.type is Type.Boolean);
        return this.store.boolean;
    }
    @property ref Character character(){
        assert(this.type is Type.Character);
        return this.store.character;
    }
    @property ref Number number(){
        assert(this.type is Type.Number);
        return this.store.number;
    }
    @property ref Keyword keyword(){
        assert(this.type is Type.Keyword);
        return this.store.keyword;
    }
    @property ref LispList list(){
        assert(this.isList());
        return this.store.list;
    }
    @property ref LispMap* map(){
        assert(this.isMap());
        return this.store.map;
    }
    @property ref LispContext* context(){
        assert(this.type is Type.Context);
        return this.store.context;
    }
    @property ref NativeFunction nativeFunction(){
        assert(this.type is Type.NativeFunction);
        return this.store.nativeFunction;
    }
    @property ref LispFunction lispFunction(){
        assert(this.type is Type.LispFunction);
        return this.store.lispFunction;
    }
    @property ref LispMethod lispMethod(){
        assert(this.type is Type.LispMethod);
        return this.store.lispMethod;
    }
    
    auto maprange(){
        assert(this.isMap());
        return this.store.map.asrange();
    }
    LispObject* get(LispObject* key){
        assert(key && this.isMap());
        return this.store.map.get(key);
    }
    LispObject* insert(LispObject* key, LispObject* value){
        assert(key && value && this.isMap());
        return this.store.map.insert(key, value);
    }
    LispObject* remove(LispObject* key){
        assert(key && this.isMap());
        return this.store.map.remove(key);
    }
    
    @property size_t listLength() const{
        assert(this.isList());
        return this.store.list.length;
    }
    @property size_t mapLength() const{
        assert(this.isMap());
        return this.store.map.length;
    }
}
