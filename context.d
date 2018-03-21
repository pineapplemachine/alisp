module alisp.context;

import mach.sys.memory : malloc, memfree;

import mach.range : map, all, asarray;
import mach.text.numeric : writefloat;
import mach.text.text : text;
import mach.text.utf : utf8decode;

import alisp.list : LispList;
import alisp.map : LispMap;
import alisp.obj : LispObject, LispArguments, LispFunction, LispMethod, NativeFunction;
import alisp.parse : encode, LispFloatSettings;

struct LispContext{
    LispContext* parent = null;
    LispContext* root = null;
    // Map identifier keys to values
    LispMap* inScope;
    // Special map for builtin functions
    LispMap* builtins;
    
    LispObject* BooleanType;
    LispObject* CharacterType;
    LispObject* NumberType;
    LispObject* KeywordType;
    LispObject* IdentifierType;
    LispObject* ExpressionType;
    LispObject* ListType;
    LispObject* MapType;
    LispObject* ObjectType;
    LispObject* ContextType;
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
    
    LispObject* Invoke;
    
    size_t lispFunctionId = 0;
    
    void delegate(in string message) logFunction;
    void delegate(LispContext* context, LispObject* identifier) onIdentifierError;
    void delegate(LispContext* context, LispObject* expression) onExpressionError;
    
    LispObject* error;
    LispObject* errorHandler;
    
    auto getLogFunction(){
        if(this.logFunction) return this.logFunction;
        LispContext* context = this.parent;
        while(context){
            if(context.logFunction){
                return context.logFunction;
            }
            context = context.parent;
        }
        return null;
    }
    auto getOnIdentifierError(){
        if(this.onIdentifierError) return this.onIdentifierError;
        LispContext* context = this.parent;
        while(context){
            if(context.onIdentifierError){
                return context.onIdentifierError;
            }
            context = context.parent;
        }
        return null;
    }
    auto getOnExpressionError(){
        if(this.onExpressionError) return this.onExpressionError;
        LispContext* context = this.parent;
        while(context){
            if(context.onExpressionError){
                return context.onExpressionError;
            }
            context = context.parent;
        }
        return null;
    }
    
    @property LispObject* NaN(){
        return this.PosNaN;
    }
    
    bool isLiteralType(LispObject* object){
        assert(object);
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
        assert(object);
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
            this.builtins = new LispMap(8);
        }
        this.inScope = new LispMap(8);
    }
    
    LispContext* newChildContext(){
        return new LispContext(&this);
    }
    
    void initializeRootContext(){
        // Initialize native types
        this.ObjectType = new LispObject(LispObject.Type.Object, null);
        this.ObjectType.store.map = new LispMap();
        this.ObjectType.typeObject = this.ObjectType;
        this.BooleanType = this.object();
        this.CharacterType = this.object();
        this.NumberType = this.object();
        this.IdentifierType = this.object();
        this.KeywordType = this.object();
        this.ExpressionType = this.object();
        this.ListType = this.object();
        this.MapType = this.object();
        this.ContextType = this.object();
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
        this.PosInfinity = new LispObject(+LispObject.Number.infinity, this.NumberType);
        this.NegInfinity = new LispObject(-LispObject.Number.infinity, this.NumberType);
        this.PosNaN = new LispObject(+LispObject.Number.nan, this.NumberType);
        this.NegNaN = new LispObject(-LispObject.Number.nan, this.NumberType);
        // Initialize common objects
        this.Invoke = new LispObject("invoke"d, this.KeywordType);
    }
    
    void inheritFrom(LispContext* parent){
        assert(parent);
        this.BooleanType = parent.BooleanType;
        this.CharacterType = parent.CharacterType;
        this.NumberType = parent.NumberType;
        this.IdentifierType = parent.IdentifierType;
        this.KeywordType = parent.KeywordType;
        this.ExpressionType = parent.ExpressionType;
        this.ListType = parent.ListType;
        this.MapType = parent.MapType;
        this.ObjectType = parent.ObjectType;
        this.ContextType = parent.ContextType;
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
        this.Invoke = parent.Invoke;
    }
    
    void log(T...)(T values){
        if(auto log = this.getLogFunction()){
            log(text(values));
        }
    }
    void logWarning(T...)(T values){
        this.log("Warning: ", values);
    }
    void logError(T...)(T values){
        this.log("Error: ", values);
    }
    void identifierError(LispObject* identifier){
        if(auto callback = this.getOnIdentifierError()){
            callback(&this, identifier);
        }
    }
    void expressionError(LispObject* expression){
        if(auto callback = this.getOnExpressionError()){
            callback(&this, expression);
        }
    }
    
    // Indicate that an error has occurred in this context and should be raised
    // immediately to the parent context
    LispObject* handleError(LispObject* errorObject){
        if(this.errorHandler){
            assert(this.errorHandler.isCallable());
            return this.invoke(this.errorHandler, [errorObject]);
        }else{
            this.error = errorObject;
            if(this.parent){
                return this.parent.handleError(errorObject);
            }else{
                return this.Null;
            }
        }
    }
    
    dstring encode(LispObject* object, size_t truncate = size_t.max){
        assert(object);
        return .encode(&this, object, false, truncate);
    }
    // Get a human-readable string good for e.g. printing to the console
    dstring stringify(LispObject* object, size_t truncate = 3){
        assert(object);
        size_t trunc = truncate;
        while(true){
            dstring result = this.stringifyImpl(object, trunc);
            if(trunc == 0 || result.length <= 256 || (
                trunc == 1 && result.length <= 512
            )){
                return result;
            }
            trunc--;
        }
        return ""d;
    }
    dstring stringifyImpl(LispObject* object, size_t truncate){
        assert(object);
        switch(object.type){
            case LispObject.Type.Null:
                return "null"d;
            case LispObject.Type.Boolean:
                return object.boolean ? "true"d : "false"d;
            case LispObject.Type.Character:
                return cast(dstring) [object.character];
            case LispObject.Type.Number:
                return cast(dstring) utf8decode(
                    writefloat!LispFloatSettings(object.number)
                ).asarray();
            case LispObject.Type.Keyword:
                return ':' ~ object.keyword;
            case LispObject.Type.List:
                if(object.listLength && object.list.objects.all!(
                    i => i.type is LispObject.Type.Character
                )){
                    return cast(dstring) object.list.map!(
                        i => i.character
                    ).asarray();
                }
                goto default;
            case LispObject.Type.Object:
                LispObject* toString = this.getFunctionAttribute(
                    object, this.keyword("toString")
                );
                if(toString){
                    if(toString.isCallable()){
                        return this.stringifyImpl(
                            this.invoke(toString, []), size_t.max
                        );
                    }else{
                        return this.stringifyImpl(toString, size_t.max);
                    }
                }else{
                    return this.encode(object, truncate);
                }
            default:
                return this.encode(object, truncate);
        }
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
    LispObject* identifier(LispObject*[] value){
        return new LispObject(LispList(value), this.IdentifierType);
    }
    LispObject* identifier(LispList value){
        return new LispObject(value, this.IdentifierType);
    }
    LispObject* identifier(in LispObject.Keyword value){
        return this.identifier([this.keyword(value)]);
    }
    LispObject* expression(){
        return new LispObject(LispObject.Type.List, this.ExpressionType);
    }
    LispObject* expression(LispObject*[] value){
        return new LispObject(LispList(value), this.ExpressionType);
    }
    LispObject* expression(LispList value){
        return new LispObject(value, this.ExpressionType);
    }
    LispObject* list(){
        return new LispObject(LispObject.Type.List, this.ListType);
    }
    LispObject* list(LispObject*[] value){
        return new LispObject(LispList(value), this.ListType);
    }
    LispObject* list(LispList value){
        return new LispObject(value, this.ListType);
    }
    LispObject* list(dstring text){
        return new LispObject(
            LispList(text.map!(ch => this.character(ch)).asarray()), this.ListType
        );
    }
    LispObject* map(){
        return new LispObject(new LispMap(), LispObject.Type.Map, this.MapType);
    }
    LispObject* map(LispMap* value){
        return new LispObject(value, LispObject.Type.Map, this.MapType);
    }
    LispObject* object(){
        return new LispObject(new LispMap(), LispObject.Type.Object, this.ObjectType);
    }
    LispObject* object(LispMap* map){
        return new LispObject(map, LispObject.Type.Object, this.ObjectType);
    }
    LispObject* object(LispObject* typeObject){
        return new LispObject(new LispMap(), LispObject.Type.Object, typeObject);
    }
    LispObject* object(LispMap* map, LispObject* typeObject){
        return new LispObject(map, LispObject.Type.Object, typeObject);
    }
    LispObject* context(){
        return new LispObject(&this, this.ContextType);
    }
    LispObject* context(LispContext* context){
        return new LispObject(context, this.ContextType);
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
    
    LispObject* normalize(LispObject* object){
        final switch(object.type){
            case LispObject.Type.Null:
                return this.Null;
            case LispObject.Type.Boolean:
                return object.boolean ? this.True : this.False;
            case LispObject.Type.Character:
                return this.character(object.character);
            case LispObject.Type.Number:
                return this.number(object.number);
            case LispObject.Type.Keyword:
                return this.keyword(object.keyword);
            case LispObject.Type.List:
                return this.list(object.list);
            case LispObject.Type.Map:
                return this.map(object.map);
            case LispObject.Type.Object:
                return this.object(object.map);
            case LispObject.Type.Context:
                return this.context(object.context);
            case LispObject.Type.NativeFunction:
                return this.nativeFunction(object.nativeFunction);
            case LispObject.Type.LispFunction:
                return this.lispFunction(object.lispFunction);
            case LispObject.Type.LispMethod:
                return this.lispMethod(object.lispMethod);
        }
    }
    
    size_t nextLispFunctionId(){
        return this.root.lispFunctionId++;
    }
    LispObject* newLispFunction(LispObject* argumentList, LispObject* expressionBody){
        assert(argumentList && expressionBody);
        if(argumentList.isList()){
            return this.lispFunction(LispFunction(
                this.nextLispFunctionId(), &this,
                argumentList.list.objects, expressionBody
            ));
        }else{
            return this.lispFunction(LispFunction(
                this.nextLispFunctionId(), &this, [], expressionBody
            ));
        }
    }
    
    LispObject* register(LispObject* key, LispObject* value){
        assert(key && value);
        this.inScope.insert(key, value);
        return value;
    }
    LispObject* register(in dstring key, LispObject* value){
        return this.register(this.keyword(key), value);
    }
    LispObject* register(
        LispObject* withObject, LispObject* key, LispObject* value
    ){
        assert(withObject && key && value);
        withObject.insert(key, value);
        return value;
    }
    LispObject* register(
        LispObject* withObject, in dstring key, LispObject* value
    ){
        return this.register(withObject, this.keyword(key), value);
    }
    
    LispObject* registerBuiltin(LispObject* key, LispObject* value){
        assert(key && value);
        this.root.builtins.insert(key, value);
        return this.register(key, value);
    }
    LispObject* registerBuiltin(in dstring key, LispObject* value){
        LispObject* keyword = this.keyword(key);
        LispObject* object = this.registerBuiltin(keyword, value);
        object.builtinIdentifier = this.identifier([keyword]);
        return object;
    }
    LispObject* registerBuiltin(in dstring key, in NativeFunction value){
        LispObject* functionObject = this.nativeFunction(value);
        this.registerBuiltin(key, functionObject);
        return functionObject;
    }
    
    LispObject* registerBuiltin(
        LispObject* withObject, LispObject* key, LispObject* value
    ){
        assert(withObject && key && value);
        LispObject*[] identity = this.identifyObject(withObject);
        if(identity && identity.length){
            identity ~= key;
            LispObject* identifier = this.identifier(identity);
            this.root.builtins.insert(identifier, value);
            value.builtinIdentifier = identifier;
        }
        return this.register(withObject, key, value);
    }
    LispObject* registerBuiltin(
        LispObject* withObject, LispObject* key, in NativeFunction value
    ){
        LispObject* functionObject = this.nativeFunction(value);
        this.registerBuiltin(withObject, key, functionObject);
        return functionObject;
    }
    LispObject* registerBuiltin(LispObject* withObject, in dstring key, LispObject* value){
        LispObject* keyword = this.keyword(key);
        LispObject* object = this.registerBuiltin(withObject, keyword, value);
        return object;
    }
    LispObject* registerBuiltin(
        LispObject* withObject, in dstring key, in NativeFunction value
    ){
        return this.registerBuiltin(withObject, this.keyword(key), value);
    }
    
    struct Identity{
        LispContext* context;
        LispObject* contextObject;
        LispObject* value;
        LispObject* attribute;
    }
    Identity identify(LispObject* identifier){
        assert(identifier && identifier.isList());
        if(identifier.store.list.length == 0){
            return Identity(&this, this.Null);
        }
        LispObject* attribute = identifier.list[0];
        LispObject* lastValue = null;
        LispObject* value = this.evaluate(attribute);
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
        bool rootAttribute = true;
        for(size_t i = 1; i < identifier.listLength; i++){
            attribute = this.evaluate(identifier.list[i]);
            auto nextValue = value.getAttribute(attribute);
            rootAttribute = nextValue.rootAttribute;
            if(!nextValue.object){
                if(i == identifier.listLength - 1){
                    return Identity(context, value, null, attribute);
                }else{
                    return Identity(&this);
                }
            }
            lastValue = value;
            value = nextValue.object;
            assert(value);
        }
        assert(value);
        if(!rootAttribute && lastValue && value.isCallable()){
            LispObject* method = this.lispMethod(LispMethod(lastValue, value));
            return Identity(context, lastValue, method, attribute);
        }else{
            return Identity(context, lastValue, value, attribute);
        }
    }
    Identity identifyInScope(LispObject* key){
        assert(key);
        LispContext* context = &this;
        while(context){
            if(LispObject* value = context.inScope.get(key)){
                return Identity(context, null, value);
            }
            if(context == context.root) break;
            context = context.parent;
        }
        return Identity(null);
    }
    
    LispObject*[] identifyObject(LispObject* object){
        assert(object);
        foreach(pair; this.inScope.asrange()){
            if(pair.value.identical(object)) return [pair.key];
        }
        if(this.parent){
            return this.parent.identifyObject(object);
        }
        foreach(pair; this.inScope.asrange()){
            if(LispObject*[] path = pair.value.identifyObject(object)){
                return pair.key ~ path;
            }
        }
        return null;
    }
    
    // Evaluate an object.
    LispObject* evaluate(LispObject* object){
        assert(object);
        if(this.error !is null){
            return this.Null;
        }
        LispObject* typeObject = object.typeObject;
        while(true){
            if(typeObject is this.IdentifierType){
                return this.evaluateIdentifier(object);
            }else if(typeObject is this.ExpressionType){
                return this.evaluateExpression(object);
            }else if(typeObject.typeObject is typeObject){
                break;
            }
            typeObject = typeObject.typeObject;
        }
        return object;
    }
    LispObject* evaluateIdentifier(LispObject* identifier){
        assert(identifier);
        if(identifier.isList){
            if(identifier.listLength == 0){
                return this.Null;
            }
            Identity identity = this.identify(identifier);
            if(identity.value){
                return identity.value;
            }
        }else{
            Identity identity = this.identifyInScope(identifier);
            if(identity.value){
                return identity.value;
            }
        }
        this.identifierError(identifier);
        return this.Null;
    }
    LispObject* evaluateExpression(LispObject* expression){
        assert(expression);
        if(!expression.isList){
            this.expressionError(expression);
            return this.Null;
        }
        if(!expression.listLength){
            return this.Null;
        }
        LispObject* firstObject = this.evaluate(expression.list[0]);
        assert(firstObject);
        if(firstObject.isCallable()){
            return this.invoke(firstObject, expression.list.objects[1 .. $]);
        }else if(firstObject.type is LispObject.Type.Null){
            return firstObject;
        }else{
            this.expressionError(expression);
            return this.Null;
        }
    }
    
    LispObject* getFunctionAttribute(LispObject* object, LispObject* attribute){
        auto result = object.getAttribute(attribute);
        if(!result.rootAttribute && result.object && result.object.isCallable()){
            return this.lispMethod(LispMethod(object, result.object));
        }else{
            return result.object;
        }
    }
    // Invoke a callable object.
    LispObject* invoke(LispObject* functionObject, LispArguments arguments){
        assert(functionObject && functionObject.isCallable());
        if(functionObject.isMap()){
            LispObject* invoke = this.getFunctionAttribute(
                functionObject, this.Invoke
            );
            if(invoke && invoke.isCallable()){
                return this.invoke(invoke, arguments);
            }else{
                this.logWarning("Object can't be invoked.");
                return this.Null;
            }
        }else if(functionObject.type is LispObject.Type.NativeFunction){
            return functionObject.store.nativeFunction(&this, arguments);
        }else if(functionObject.type is LispObject.Type.LispFunction){
            return functionObject.lispFunction.evaluate(&this, arguments);
        }else{ // LispMethod
            return functionObject.lispMethod.evaluate(&this, arguments);
        }
    }
}
