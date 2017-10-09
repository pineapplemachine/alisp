module alisp.obj;

import mach.math : fidentical, fisnan;
import mach.range : map, join, all, asarray;
import mach.text.numeric : WriteFloatSettings, writefloat;
import mach.text.utf : utf8decode;
import mach.traits : hash;

import alisp.context : LispContext;
import alisp.escape : escapeCharacter;
import alisp.map : LispMap;

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

alias LispList = LispObject*[];

// This allows hashes to always be exactly represented by doubles
alias LispObjectHash = uint;

struct LispFunction{
    size_t uniqueId = 0;
    LispContext* parentContext;
    LispObject*[] argumentList;
    LispObject* expressionBody;
    
    LispObject* evaluate(LispContext* context, LispArguments arguments){
        LispContext functionContext = new LispContext(this.parentContext);
        size_t i = 0;
        for(; i < this.argumentList.length && i < arguments.length; i++){
            functionContext.register(
                this.argumentList[i], context.evaluate(arguments[i])
            );
        }
        for(; i < this.argumentList.length; i++){
            functionContext.register(this.argumentList[i], context.Null);
        }
        if(i < arguments.length){
            functionContext.register(
                "@"d, parentContext.list(arguments[i .. $])
            );
        }
        return functionContext.evaluate(this.expressionBody);
    }
}

struct LispMethod{
    LispObject* contextObject;
    LispObject* functionObject;
    
    LispObject* evaluate(LispContext* context, LispArguments arguments){
        return context.invoke(
            this.functionObject, this.contextObject ~ arguments
        );
    }
}

LispObjectHash listHash(LispList list){
    LispObjectHash value = 0;
    foreach(element; list){
        value = value ^ element.toHash();
        value += 2560;
    }
    return value;
}

LispObjectHash mapHash(LispMap map){
    LispObjectHash value = 0;
    foreach(pair; map.asrange()){
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
    alias Identifier = LispList;
    alias Expression = LispList;
    alias List = LispList;
    alias Map = LispMap;
    
    // Enumeration of primitive types
    static enum Type{
        // Does not use storage
        Null,
        // store.boolean
        Boolean,
        // store.character
        Character,
        // store.number
        Number,
        // store.keyword
        Keyword,
        // store.list
        Identifier,
        Expression,
        List,
        // store.map
        Map,
        Type,
        // store.nativeFunction
        NativeFunction,
        // store.lispFunction
        LispFunction,
        // store.lispMethod
        LispMethod,
    }
    
    // Union type to store the value of an object
    union Store{
        Boolean boolean;
        Character character;
        Number number;
        Keyword keyword;
        List list;
        Map map;
        NativeFunction nativeFunction;
        LispFunction lispFunction;
        LispMethod lispMethod;
    }
    
    // What primitive type the stored value is
    Type type = Type.Null;
    // The value representing the type of this one
    LispObject* typeObject = null;
    // The value of the object
    Store store;
    
    LispMap attributes;
    
    this(in Type type, LispObject* typeObject){
        this.type = type;
        this.typeObject = typeObject is null ? &this : typeObject;
    }
    this(in Type type, LispObject* typeObject, Store store){
        this.type = type;
        this.typeObject = typeObject is null ? &this : typeObject;
        this.store = store;
    }
    this(in Boolean boolean, LispObject* typeObject){
        this.type = Type.Boolean;
        this.typeObject = typeObject;
        this.store.boolean = boolean;
    }
    this(in Character character, LispObject* typeObject){
        this.type = Type.Character;
        this.typeObject = typeObject;
        this.store.character = cast(dchar) character;
    }
    this(in Number number, LispObject* typeObject){
        this.type = Type.Number;
        this.typeObject = typeObject;
        this.store.number = number;
    }
    this(in dstring keyword, LispObject* typeObject){
        this.type = Type.Keyword;
        this.typeObject = typeObject;
        this.store.keyword = keyword;
    }
    this(List list, Type type, LispObject* typeObject){
        this.type = type;
        this.typeObject = typeObject;
        this.store.list = list;
    }
    this(Map map, LispObject* typeObject){
        this.type = Type.Map;
        this.typeObject = typeObject;
        this.store.map = map;
    }
    this(in NativeFunction nativeFunction, LispObject* typeObject){
        this.type = Type.NativeFunction;
        this.typeObject = typeObject;
        this.store.nativeFunction = nativeFunction;
    }
    this(LispFunction lispFunction, LispObject* typeObject){
        this.type = Type.LispFunction;
        this.typeObject = typeObject;
        this.store.lispFunction = lispFunction;
    }
    this(LispMethod method, LispObject* typeObject){
        this.type = Type.LispMethod;
        this.typeObject = typeObject;
        this.store.lispMethod = method;
    }
    
    bool isList() const{
        return (
            this.type is Type.Identifier ||
            this.type is Type.Expression ||
            this.type is Type.List
        );
    }
    bool isMap() const{
        return this.type is Type.Map;
    }
    bool isCallable() const{
        return (
            this.type is Type.Type || this.type is Type.NativeFunction ||
            this.type is Type.LispFunction || this.type is Type.LispMethod
        );
    }
    
    LispObject* copyShallow(){
        return new LispObject(this.type, this.typeObject, this.store);
    }
    LispObject* copyShallow(LispObject* typeObject){
        return new LispObject(this.type, typeObject, this.store);
    }
    
    auto getAttribute(LispObject* attribute){
        struct Result{
            bool rootAttribute;
            LispObject* object;
        }
        LispObject* object = &this;
        LispObject* result = object.attributes.get(attribute);
        while(!result && object.typeObject != object){
            object = object.typeObject;
            result = object.attributes.get(attribute);
        }
        return Result(object == &this, result);
    }
    
    dstring toIdentifierString(){
        if(this.type is Type.Keyword){
            return this.store.keyword;
        }else{
            return this.toString();
        }
    }
    
    // Get an exact one-to-one string representation.
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
            case Type.Identifier:
                if(this.store.list.length == 0){
                    return "(identifier)"d;
                }
                dstring str = cast(dstring)(
                    this.store.list.map!(
                        i => i.toIdentifierString()
                    ).join(":"d).asarray()
                );
                return str[0] == ':' ? str[1 .. $] : str;
            case Type.Expression:
                return dchar('(') ~ cast(dstring)(
                        this.store.list.map!(i => i.toString()).join(" "d).asarray()
                ) ~ dchar(')');
            case Type.List:
                if(
                    this.store.list.length &&
                    this.store.list.all!(i => i.type is Type.Character)
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
                return dchar('{') ~ cast(dstring)(
                    this.store.map.asrange().map!(pair =>
                        pair.key.toString() ~ ' ' ~ pair.value.toString()
                    ).join(" ").asarray()
                ) ~ dchar('}');
            case Type.Type:
                if(this.attributes.length == 0){
                    return "(type)"d;
                }else{
                    return "(type "d ~ cast(dstring)(
                        this.attributes.asrange().map!(pair =>
                            pair.key.toString() ~ ' ' ~ pair.value.toString()
                        ).join(" "d).asarray()
                    ) ~ dchar(')');
                }
            case Type.NativeFunction:
                return "(builtin)"d;
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
    
    // Strict equality comparison. Returns true when the inputs are exactly
    // the same.
    bool identical(LispObject* value){
        if(&this == value){
            return true;
        }else if(this.typeObject != value.typeObject){
            return false;
        }
        final switch(this.type){
            case Type.Null:
                return value.type is Type.Null;
            case Type.Boolean:
                return value.type is Type.Boolean && (
                    this.store.boolean == value.store.boolean
                );
            case Type.Character:
                return value.type is Type.Character && (
                    this.store.character == value.store.character
                );
            case Type.Number:
                return value.type is Type.Number && (
                    fidentical(this.store.number, value.store.number)
                );
            case Type.Keyword:
                return value.type is type.Keyword && (
                    this.store.keyword == value.store.keyword
                );
            case Type.Identifier: goto case;
            case Type.Expression: goto case;
            case Type.List: goto case;
            case Type.Map: goto case;
            case Type.Type:
                return false;
            case Type.NativeFunction:
                return value.type is Type.NativeFunction && (
                    this.store.nativeFunction == value.store.nativeFunction
                );
            case Type.LispFunction:
                return value.type is Type.LispFunction && (
                    this.store.lispFunction.uniqueId == value.store.lispFunction.uniqueId
                );
            case Type.LispMethod:
                return value.type is Type.LispMethod && (
                    this.store.lispMethod.contextObject.identical(
                        value.store.lispMethod.contextObject
                    ) &&
                    this.store.lispMethod.functionObject.identical(
                        value.store.lispMethod.functionObject
                    )
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
                valueHash = this.store.boolean;
                break;
            case Type.Character:
                valueHash = cast(LispObjectHash) this.store.character;
                break;
            case Type.Number:
                valueHash = cast(LispObjectHash) hash(this.store.number);
                break;
            case Type.Keyword:
                valueHash = cast(LispObjectHash) hash(this.store.keyword);
                break;
            case Type.Identifier: goto case;
            case Type.Expression: goto case;
            case Type.List:
                valueHash = listHash(this.store.list);
                break;
            case Type.Map: goto case;
            case Type.Type:
                valueHash = mapHash(this.store.map);
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
}
