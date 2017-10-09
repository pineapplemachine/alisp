module alisp.context;

import mach.range : map, asarray;
import mach.text.text : text;

import alisp.map : LispMap;
import alisp.obj : LispObject, LispArguments, LispFunction, LispMethod, NativeFunction;

struct LispContext{
    LispContext* parent = null;
    LispContext* root = null;
    LispMap inScope;
    
    LispObject* BooleanType;
    LispObject* CharacterType;
    LispObject* NumberType;
    LispObject* KeywordType;
    LispObject* IdentifierType;
    LispObject* ExpressionType;
    LispObject* ListType;
    LispObject* MapType;
    LispObject* ObjectType;
    LispObject* NativeFunctionType;
    LispObject* LispFunctionType;
    LispObject* LispMethodType;
    
    LispObject* Null;
    LispObject* True;
    LispObject* False;
    LispObject* NullCharacter;
    LispObject* Zero;
    LispObject* One;
    LispObject* PosInfinity;
    LispObject* NegInfinity;
    LispObject* PosNaN;
    LispObject* NegNaN;
    
    LispObject* Constructor;
    
    size_t lispFunctionId = 0;
    
    void function(string message) logFunction;
    
    @property LispObject* NaN(){
        return this.PosNaN;
    }
    
    bool isLiteralType(LispObject* object){
        return (
            object.typeObject == this.Null ||
            object.typeObject == this.BooleanType ||
            object.typeObject == this.CharacterType ||
            object.typeObject == this.NumberType ||
            object.typeObject == this.KeywordType
        );
    }
    // Objects returning true absolutely must be copied
    // before they are changed in any way.
    bool isSharedLiteral(LispObject* object){
        return (
            object == this.Null ||
            object == this.True ||
            object == this.False ||
            object == this.NullCharacter ||
            object == this.Zero ||
            object == this.One ||
            object == this.PosInfinity ||
            object == this.NegInfinity ||
            object == this.PosNaN ||
            object == this.NegNaN
        );
    }
    
    this(LispContext* parent){
        this.parent = parent;
        if(parent){
            this.root = parent.root;
            this.inheritFrom(parent);
        }else{
            this.root = &this;
            this.initializeRootContext();
        }
    }
    
    void initializeRootContext(){
        // Initialize native types
        this.ObjectType = new LispObject(LispObject.Type.Object, null);
        this.ObjectType.typeObject = this.ObjectType;
        this.BooleanType = this.object();
        this.CharacterType = this.object();
        this.NumberType = this.object();
        this.IdentifierType = this.object();
        this.KeywordType = this.object();
        this.ExpressionType = this.object();
        this.ListType = this.object();
        this.MapType = this.object();
        this.NativeFunctionType = this.object();
        this.LispFunctionType = this.object();
        this.LispMethodType = this.object();
        // Initialize literals
        this.Null = new LispObject(LispObject.Type.Null, null);
        this.Null.typeObject = this.Null;
        this.True = new LispObject(true, this.BooleanType);
        this.False = new LispObject(false, this.BooleanType);
        this.NullCharacter = new LispObject(cast(dchar) 0, this.CharacterType);
        this.Zero = new LispObject(0, this.NumberType);
        this.One = new LispObject(1, this.NumberType);
        this.PosInfinity = new LispObject(LispObject.Number.infinity, this.NumberType);
        this.NegInfinity = new LispObject(-LispObject.Number.infinity, this.NumberType);
        this.PosNaN = new LispObject(LispObject.Number.nan, this.NumberType);
        this.NegNaN = new LispObject(-LispObject.Number.nan, this.NumberType);
        // Initialize common objects
        this.Constructor = this.keyword("invoke"d);
    }
    
    void inheritFrom(LispContext* parent){
        this.BooleanType = parent.BooleanType;
        this.CharacterType = parent.CharacterType;
        this.NumberType = parent.NumberType;
        this.IdentifierType = parent.IdentifierType;
        this.KeywordType = parent.KeywordType;
        this.ExpressionType = parent.ExpressionType;
        this.ListType = parent.ListType;
        this.MapType = parent.MapType;
        this.ObjectType = parent.ObjectType;
        this.NativeFunctionType = parent.NativeFunctionType;
        this.LispFunctionType = parent.LispFunctionType;
        this.LispMethodType = parent.LispMethodType;
        this.Null = parent.Null;
        this.True = parent.True;
        this.False = parent.False;
        this.NullCharacter = parent.NullCharacter;
        this.Zero = parent.Zero;
        this.One = parent.One;
        this.PosInfinity = parent.PosInfinity;
        this.NegInfinity = parent.NegInfinity;
        this.PosNaN = parent.PosNaN;
        this.NegNaN = parent.NegNaN;
        this.Constructor = parent.Constructor;
    }
    
    void log(T...)(T values){
        if(this.root && this.root.logFunction){
            this.root.logFunction(text(values));
        }
    }
    void logWarning(T...)(T values){
        this.log("Warning: ", values);
    }
    void logError(T...)(T values){
        this.log("Error: ", values);
    }
    
    // Functions to create an object of a certain type
    LispObject* newValue(in LispObject.Type type, LispObject* typeObject){
        return new LispObject(type, typeObject);
    }
    LispObject* boolean(in bool value){
        return value ? this.True : this.False;
    }
    LispObject* character(in LispObject.Character value){
        if(value == 0) return this.NullCharacter;
        return new LispObject(value, this.CharacterType);
    }
    LispObject* number(in LispObject.Number value){
        return new LispObject(value, this.NumberType);
    }
    LispObject* keyword(in LispObject.Keyword value){
        return new LispObject(value, this.KeywordType);
    }
    LispObject* identifier(){
        return new LispObject(LispObject.Type.List, this.IdentifierType);
    }
    LispObject* identifier(LispObject.List value){
        return new LispObject(value, this.IdentifierType);
    }
    LispObject* identifier(in LispObject.Keyword value){
        return this.identifier([this.keyword(value)]);
    }
    LispObject* expression(){
        return new LispObject(LispObject.Type.List, this.ExpressionType);
    }
    LispObject* expression(LispObject.List value){
        return new LispObject(value, this.ExpressionType);
    }
    LispObject* list(){
        return new LispObject(LispObject.Type.List, this.ListType);
    }
    LispObject* list(LispObject.List value){
        return new LispObject(value, this.ListType);
    }
    LispObject* list(dstring text){
        return new LispObject(
            text.map!(ch => this.character(ch)).asarray(), this.ListType
        );
    }
    LispObject* map(){
        return new LispObject(LispObject.Type.Map, this.MapType);
    }
    LispObject* map(LispObject.Map value){
        return new LispObject(value, this.MapType);
    }
    LispObject* object(){
        return new LispObject(LispObject.Type.Object, this.ObjectType);
    }
    LispObject* nativeFunction(in NativeFunction value){
        return new LispObject(value, this.NativeFunctionType);
    }
    LispObject* lispFunction(LispFunction value){
        return new LispObject(value, this.LispFunctionType);
    }
    LispObject* lispMethod(LispMethod value){
        return new LispObject(value, this.LispMethodType);
    }
    
    size_t nextLispFunctionId(){
        return this.root.lispFunctionId++;
    }
    LispObject* lispFunction(LispObject* argumentList, LispObject* expressionBody){
        if(argumentList.isList()){
            return this.lispFunction(LispFunction(
                this.nextLispFunctionId(), &this,
                argumentList.store.list, expressionBody
            ));
        }else{
            return this.lispFunction(LispFunction(
                this.nextLispFunctionId(), &this, [], expressionBody
            ));
        }
    }
    
    LispObject* register(LispObject* key, LispObject* value){
        this.inScope.insert(key, value);
        return value;
    }
    LispObject* register(in dstring name, LispObject* value){
        this.inScope.insert(this.keyword(name), value);
        return value;
    }
    LispObject* registerFunction(in dstring name, in NativeFunction value){
        LispObject* functionObject = this.nativeFunction(value);
        this.register(name, functionObject);
        return functionObject;
    }
    
    LispObject* register(LispObject* withObject, LispObject* key, LispObject* value){
        withObject.store.map.insert(key, value);
        return value;
    }
    LispObject* registerFunction(
        LispObject* withObject, LispObject* key, in NativeFunction value
    ){
        LispObject* functionObject = this.nativeFunction(value);
        this.register(withObject, key, functionObject);
        return functionObject;
    }
    LispObject* register(LispObject* withObject, in dstring key, LispObject* value){
        return this.register(withObject, this.keyword(key), value);
    }
    LispObject* registerFunction(
        LispObject* withObject, in dstring key, in NativeFunction value
    ){
        return this.registerFunction(withObject, this.keyword(key), value);
    }
    
    struct Identity{
        LispContext* context;
        LispObject* contextObject;
        LispObject* value;
        LispObject* attribute;
    }
    Identity identify(LispObject* identifier){
        assert(identifier.isList());
        if(identifier.store.list.length == 0){
            return Identity(&this, this.Null);
        }
        LispObject* attribute = null;
        LispObject* lastValue = null;
        LispObject* value = this.evaluate(identifier.store.list[0]);
        LispContext* context = &this;
        if(value.type is LispObject.Type.Keyword){
            Identity identity = this.identifyInScope(value);
            if(!identity.value || (
                !identity.context && value.type is LispObject.Type.Keyword
            )){
                return Identity(&this, null, null, value);
            }
            context = identity.context;
            value = identity.value;
        }
        bool rootAttribute = void;
        for(size_t i = 1; i < identifier.store.list.length; i++){
            attribute = this.evaluate(identifier.store.list[i]);
            auto nextValue = value.getAttribute(attribute);
            rootAttribute = nextValue.rootAttribute;
            if(!nextValue.object){
                if(i == identifier.store.list.length - 1){
                    return Identity(context, value, null, attribute);
                }else{
                    return Identity(&this);
                }
            }
            lastValue = value;
            value = nextValue.object;
        }
        if(!rootAttribute && lastValue && value.isCallable()){
            LispObject* method = this.lispMethod(LispMethod(lastValue, value));
            return Identity(context, lastValue, method, attribute);
        }else{
            return Identity(context, lastValue, value, attribute);
        }
    }
    Identity identifyInScope(LispObject* key){
        LispContext* context = &this;
        while(context){
            if(LispObject* value = context.inScope.get(key)){
                return Identity(context, null, value);
            }
            context = context.parent;
        }
        return Identity(null);
    }
    
    // Evaluate an object.
    LispObject* evaluate(LispObject* object){
        if(object.instanceOf(this.IdentifierType)){
            return this.evaluateIdentifier(object);
        }else if(!object.instanceOf(this.ExpressionType)){
            return object;
        }else{
            return this.evaluateExpression(object);
        }
    }
    LispObject* evaluateIdentifier(LispObject* identifier){
        assert(identifier.isList());
        Identity identity = this.identify(identifier);
        if(identity.value){
            return identity.value;
        }
        this.logWarning("Invalid identifier.");
        return this.Null;
    }
    LispObject* evaluateExpression(LispObject* expression){
        assert(expression.isList());
        if(expression.store.list.length == 0){
            return this.Null;
        }
        LispObject* firstObject = this.evaluate(expression.store.list[0]);
        //if(firstObject.instanceOf(this.IdentifierType)){
        //    firstObject = this.evaluateIdentifier(firstObject);
        //}
        if(firstObject.isCallable()){
            return this.invoke(firstObject, expression.store.list[1 .. $]);
        }else if(firstObject.type is LispObject.Type.Null){
            return firstObject;
        }else{
            this.logWarning("Malformed expression.");
            return this.Null;
        }
    }
    
    // Invoke a callable object.
    LispObject* invoke(LispObject* functionObject, LispArguments arguments){
        assert(functionObject.isCallable());
        if(functionObject.isMap()){
            LispObject* invoke = functionObject.store.map.get(this.Constructor);
            if(invoke && invoke.isCallable()){
                return this.invoke(invoke, arguments);
            }else{
                this.logWarning("Object can't be invoked.");
                return this.Null;
            }
        }else if(functionObject.type is LispObject.Type.NativeFunction){
            return functionObject.store.nativeFunction(&this, arguments);
        }else if(functionObject.type is LispObject.Type.LispFunction){
            return functionObject.store.lispFunction.evaluate(&this, arguments);
        }else{ // LispMethod
            return functionObject.store.lispMethod.evaluate(&this, arguments);
        }
    }
}
