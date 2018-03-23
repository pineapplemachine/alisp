module alisp.lib;

import core.stdc.math : signbit;
import core.stdc.stdio : stdin, stdout, stderr;
import mach.io.file.path : Path;
import mach.io.file.sys : FileHandle, fclose;
import mach.io.stdio : stdio;
import mach.io.stream.filestream : FileStream;
import mach.io.stream.io : read, write;
import mach.math : fisnan, fisinf, sqrt, abs, kahansum, e, pi, tau;
import mach.math : sin, cos, tan, asin, acos, atan, atan2, log;
import mach.range : map, asarray, product, reduce, mergesort;
import mach.text.utf : utf8encode;
import std.uni : toUpper, toLower;

import alisp.context : LispContext;
import alisp.list : LispList;
import alisp.map : LispMap;
import alisp.obj : LispObject, LispArguments, LispFunction, LispMethod;
import alisp.parse : parse, LispParseException;

import alisp.libutils;

auto listLength = function LispObject*(LispContext* context, LispArguments args){
    LispObject* list = context.evaluate(args[0]);
    if(list.isList()){
        return context.number(list.listLength);
    }else{
        return context.NaN;
    }
};
auto listEmpty = function LispObject*(LispContext* context, LispArguments args){
    LispObject* list = context.evaluate(args[0]);
    if(list.isList()){
        return context.boolean(list.listLength == 0);
    }else{
        return context.Null;
    }
};
auto mapLength = function LispObject*(LispContext* context, LispArguments args){
    LispObject* map = context.evaluate(args[0]);
    if(map.isMap()){
        return context.number(map.mapLength);
    }else{
        return context.NaN;
    }
};
auto mapEmpty = function LispObject*(LispContext* context, LispArguments args){
    LispObject* map = context.evaluate(args[0]);
    if(map.isMap()){
        return context.boolean(map.mapLength == 0);
    }else{
        return context.Null;
    }
};
auto invokeCallable = function LispObject*(LispContext* context, LispArguments args){
    if(args.length == 0){
        return context.Null;
    }
    LispObject* functionObject = context.evaluate(args[0]);
    if(!functionObject.isCallable()){
        return context.Null;
    }
    if(args.length == 1){
        return context.invoke(functionObject, []);
    }
    LispObject* argumentList = context.evaluate(args[1]);
    if(!argumentList.isList()){
        return context.Null;
    }
    return context.invoke(
        functionObject, argumentList.store.list.objects
    );
};

auto anyFunction = function LispObject*(LispContext* context, LispArguments args){
    LispObject* falsey = context.Null;
    foreach(arg; args){
        LispObject* value = context.evaluate(arg);
        if(value.toBoolean()) return value;
        falsey = value;
    }
    return falsey;
};
auto anyFunctionPredicate = function LispObject*(
    LispContext* context, LispArguments args, LispObject* predicate
){
    assert(predicate && predicate.isCallable());
    LispObject* falsey = context.Null;
    foreach(arg; args){
        LispObject* value = context.evaluate(arg);
        LispObject* match = context.invoke(predicate, [value]);
        if(match.toBoolean()) return match;
        falsey = match;
    }
    return falsey;
};

auto allFunction = function LispObject*(LispContext* context, LispArguments args){
    LispObject* truthy = context.Null;
    foreach(arg; args){
        LispObject* value = context.evaluate(arg);
        if(!value.toBoolean()) return value;
        truthy = value;
    }
    return truthy;
};
auto allFunctionPredicate = function LispObject*(
    LispContext* context, LispArguments args, LispObject* predicate
){
    assert(predicate && predicate.isCallable());
    LispObject* truthy = context.Null;
    foreach(arg; args){
        LispObject* value = context.evaluate(arg);
        LispObject* match = context.invoke(predicate, [value]);
        if(!match.toBoolean()) return match;
        truthy = match;
    }
    return truthy;
};

auto noneFunction = function LispObject*(LispContext* context, LispArguments args){
    foreach(arg; args){
        LispObject* value = context.evaluate(arg);
        if(value.toBoolean()) return context.False;
    }
    return context.True;
};
auto noneFunctionPredicate = function LispObject*(
    LispContext* context, LispArguments args, LispObject* predicate
){
    foreach(arg; args){
        LispObject* value = context.evaluate(arg);
        LispObject* match = context.invoke(predicate, [value]);
        if(match.toBoolean()) return context.False;
    }
    return context.True;
};

void registerBuiltins(LispContext* context){
    registerLiterals(context);
    registerTypes(context);
    registerAssignment(context);
    registerComparison(context);
    registerLogic(context);
    registerMath(context);
    registerControlFlow(context);
    registerImport(context);
    registerStandardIO(context);
    registerErrorHandling(context);
}

void registerLiterals(LispContext* context){
    context.register("null", context.Null);
    context.register("true", context.True);
    context.register("false", context.False);
    context.register("infinity", context.PosInfinity);
    context.register("+infinity", context.PosInfinity);
    context.register("-infinity", context.NegInfinity);
    context.register("NaN", context.PosNaN);
    context.register("+NaN", context.PosNaN);
    context.register("-NaN", context.NegNaN);
}

void registerTypes(LispContext* context){
    registerBooleanType(context);
    registerCharacterType(context);
    registerNumberType(context);
    registerIdentifierType(context);
    registerKeywordType(context);
    registerExpressionType(context);
    registerListType(context);
    registerMapType(context);
    registerObjectType(context);
    registerContextType(context);
    registerNativeFunctionType(context);
    registerLispFunctionType(context);
    registerLispMethodType(context);
    context.registerBuiltin("new",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* typeObject = context.evaluate(args[0]);
            LispObject* object = context.object(typeObject);
            if(args.length == 2){
                LispObject* basis = context.evaluate(args[1]);
                return new LispObject(
                    basis.type, typeObject, basis.store
                );
            }else if(args.length > 2){
                for(size_t i = 1; i + 1 < args.length; i += 2){
                    object.insert(
                        context.evaluate(args[i]), context.evaluate(args[i + 1])
                    );
                }
            }
            return object;
        }
    );
    context.registerBuiltin("typeof",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.evaluate(args[0]).typeObject;
        }
    );
    context.registerBuiltin("inherits?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            LispObject* type = context.evaluate(args[0]);
            LispObject* value = context.evaluate(args[1]);
            return context.boolean(value.instanceOf(type));
        }
    );
    context.registerBuiltin("null?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Null
            );
        }
    );
    context.registerBuiltin("boolean?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Boolean
            );
        }
    );
    context.registerBuiltin("character?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Character
            );
        }
    );
    context.registerBuiltin("number?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Number
            );
        }
    );
    context.registerBuiltin("keyword?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Keyword
            );
        }
    );
    context.registerBuiltin("context?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Context
            );
        }
    );
    context.registerBuiltin("list?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.List
            );
        }
    );
    context.registerBuiltin("map?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Map
            );
        }
    );
    context.registerBuiltin("object?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.Object
            );
        }
    );
    context.registerBuiltin("builtin?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.NativeFunction
            );
        }
    );
    context.registerBuiltin("function?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.LispFunction
            );
        }
    );
    context.registerBuiltin("method?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(
                context.evaluate(args[0]).type is LispObject.Type.LispMethod
            );
        }
    );
    context.registerBuiltin("invoke?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(context.evaluate(args[0]).isCallable());
        }
    );
}

void registerBooleanType(LispContext* context){
    context.register("boolean", context.BooleanType);
    context.registerBuiltin(context.BooleanType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            return (args.length && context.evaluate(args[0]).toBoolean() ?
                context.True : context.False
            );
        }
    );
}
    
void registerCharacterType(LispContext* context){
    context.register("character", context.CharacterType);
    context.registerBuiltin(context.CharacterType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.NullCharacter;
            }
            return context.character(context.evaluate(args[0]).toCharacter());
        }
    );
    context.registerBuiltin(context.CharacterType, "upper",
        function LispObject*(LispContext* context, LispArguments args){
            return context.character(toUpper(args[0].character));
        }
    );
    context.registerBuiltin(context.CharacterType, "lower",
        function LispObject*(LispContext* context, LispArguments args){
            return context.character(toLower(args[0].character));
        }
    );
};

void registerNumberType(LispContext* context){
    context.register("number", context.NumberType);
    context.registerBuiltin(context.NumberType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Zero;
            return context.number(context.evaluate(args[0]).toNumber());
        }
    );
    context.registerBuiltin(context.NumberType, "parse",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            LispObject* value = context.evaluate(args[0]);
            if(value.type is LispObject.Type.Number){
                return value;
            }
            dstring numberString = (value.type is LispObject.Type.Keyword ?
                value.keyword : context.stringify(value)
            );
            try{
                return context.number(parseNumber(numberString));
            }catch(Exception e){
                context.log(e);
                return context.NaN;
            }
        }
    );
    context.registerBuiltin(context.NumberType, "abs",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            const number = context.evaluate(args[0]).toNumber();
            return context.number(abs(number));
        }
    );
    context.registerBuiltin(context.NumberType, "negate",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            const number = context.evaluate(args[0]).toNumber();
            return context.number(-number);
        }
    );
    context.registerBuiltin(context.NumberType, "positive?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            const number = context.evaluate(args[0]).toNumber();
            return context.boolean(cast(bool) signbit(number));
        }
    );
    context.registerBuiltin(context.NumberType, "negative?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            const number = context.evaluate(args[0]).toNumber();
            return context.boolean(!signbit(number));
        }
    );
    context.registerBuiltin(context.NumberType, "zero?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.False;
            const number = context.evaluate(args[0]).toNumber();
            return context.boolean(number == 0);
        }
    );
    context.registerBuiltin(context.NumberType, "nonzero?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.False;
            const number = context.evaluate(args[0]).toNumber();
            return context.boolean(number != 0);
        }
    );
    context.registerBuiltin(context.NumberType, "finite?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.False;
            const number = context.evaluate(args[0]).toNumber();
            return context.boolean(!fisinf(number) && !fisnan(number));
        }
    );
    context.registerBuiltin(context.NumberType, "infinite?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.False;
            const number = context.evaluate(args[0]).toNumber();
            return context.boolean(fisinf(number));
        }
    );
    context.registerBuiltin(context.NumberType, "NaN?",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.False;
            const number = context.evaluate(args[0]).toNumber();
            return context.boolean(fisnan(number));
        }
    );
    context.registerBuiltin(context.NumberType, "gt",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* numberObject = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(compare(context.evaluate(args[i]), numberObject) >= 0){
                    return context.False;
                }
            }
            return context.True;
        }
    );
    context.registerBuiltin(context.NumberType, "gte",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* numberObject = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(compare(context.evaluate(args[i]), numberObject) > 0){
                    return context.False;
                }
            }
            return context.True;
        }
    );
    context.registerBuiltin(context.NumberType, "lt",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* numberObject = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(compare(numberObject, context.evaluate(args[i])) >= 0){
                    return context.False;
                }
            }
            return context.True;
        }
    );
    context.registerBuiltin(context.NumberType, "lte",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* numberObject = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(compare(numberObject, context.evaluate(args[i])) > 0){
                    return context.False;
                }
            }
            return context.True;
        }
    );
};

void registerKeywordType(LispContext* context){
    context.register("keyword", context.KeywordType);
    context.registerBuiltin(context.KeywordType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.keyword("");
            LispObject* value = context.evaluate(args[0]);
            if(value.type is LispObject.Type.Keyword){
                return value;
            }else{
                return context.keyword(context.stringify(value));
            }
        }
    );
};

void registerIdentifierType(LispContext* context){
    context.register("identifier", context.IdentifierType);
    context.registerBuiltin(context.IdentifierType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* identifier = context.identifier();
            foreach(arg; args){
                identifier.push(context.evaluate(arg));
            }
            return identifier;
        }
    );
    context.registerBuiltin(context.IdentifierType, "length", listLength);
    context.registerBuiltin(context.IdentifierType, "empty?", listEmpty);
    context.registerBuiltin(context.IdentifierType, "eval",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.evaluate(args[0]);
        }
    );
};

void registerExpressionType(LispContext* context){
    context.register("expression", context.ExpressionType);
    context.registerBuiltin(context.ExpressionType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* expression = context.expression();
            foreach(arg; args) expression.push(context.evaluate(arg));
            return expression;
        }
    );
    context.registerBuiltin(context.ExpressionType, "length", listLength);
    context.registerBuiltin(context.ExpressionType, "empty?", listEmpty);
    context.registerBuiltin(context.ExpressionType, "eval",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.evaluate(context.evaluate(args[0]));
        }
    );
};

void registerListType(LispContext* context){
    context.register("list", context.ListType);
    context.registerBuiltin(context.ListType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* list = context.list();
            foreach(arg; args) list.push(context.evaluate(arg));
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "length", listLength);
    context.registerBuiltin(context.ListType, "empty?", listEmpty);
    context.registerBuiltin(context.ListType, "at",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            const floatIndex = context.evaluate(args[1]).toNumber();
            if(floatIndex < 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            const index = cast(size_t) floatIndex;
            if(
                !list.isList() || index != floatIndex ||
                index >= list.listLength
            ){
                return context.Null;
            }else{
                return list.store.list[index];
            }
        }
    );
    context.registerBuiltin(context.ListType, "insert",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            const floatIndex = context.evaluate(args[1]).toNumber();
            if(floatIndex < 0) return list;
            const index = cast(size_t) floatIndex;
            if(list.isList() && index == floatIndex && index <= list.listLength){
                LispObject*[] insertions = (
                    args[2 .. $].map!(i => context.evaluate(i)).asarray()
                );
                list.list.insert(index, insertions);
            }
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "remove",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            const floatIndex = context.evaluate(args[1]).toNumber();
            if(floatIndex < 0) return list;
            const index = cast(size_t) floatIndex;
            if(list.isList() && index == floatIndex && index <= list.listLength){
                list.list.remove(index);
            }
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "push",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(list.isList()){
                for(size_t i = 1; i < args.length; i++){
                    list.push(context.evaluate(args[i]));
                }
            }
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "pop",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(!list.isList() || list.listLength == 0){
                return context.Null;
            }else{
                return list.list.pop();
            }
        }
    );
    context.registerBuiltin(context.ListType, "clone",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(!list.isList()){
                return context.Null;
            }
            LispObject*[] result = new LispObject*[list.listLength];
            for(size_t i = 0; i < list.listLength; i++){
                result[i] = list.list[i];
            }
            return context.list(result);
        }
    );
    context.registerBuiltin(context.ListType, "slice",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(!list.isList()){
                return context.Null;
            }
            LispObject.Number low = 0;
            LispObject.Number high = (
                cast(LispObject.Number) list.listLength
            );
            if(args.length > 1){
                low = context.evaluate(args[1]).toNumber();
            }
            if(args.length > 2){
                high = context.evaluate(args[2]).toNumber();
            }
            if(fisnan(low)){
                low = 0;
            }
            if(fisnan(high)){
                high = list.listLength;
            }
            long lowInt = cast(long) low;
            long highInt = cast(long) high;
            LispObject*[] repeatNull(N)(N times){
                LispObject*[] nulls = new LispObject*[cast(size_t) times];
                for(size_t i = 0; i < cast(size_t) times; i++){
                    nulls[i] = context.Null;
                }
                return nulls;
            }
            if(highInt <= lowInt){
                return context.list();
            }else if(highInt < 0 || lowInt >= list.listLength){
                return context.list(LispList(repeatNull(highInt - lowInt)));
            }else if(lowInt >= 0 && highInt <= list.listLength){
                return context.list(list.store.list[
                    cast(size_t) lowInt .. cast(size_t) highInt
                ]);
            }else if(lowInt >= 0){
                return context.list(LispList(
                    list.list[cast(size_t) lowInt .. $].objects ~
                    repeatNull(cast(size_t) highInt - list.listLength)
                ));
            }else if(highInt <= list.listLength){
                return context.list(LispList(
                    repeatNull(cast(size_t) -lowInt) ~
                    list.list[0 .. cast(size_t) highInt].objects
                ));
            }else{
                return context.list(LispList(
                    repeatNull(cast(size_t) -lowInt) ~ list.list.copy().objects ~
                    repeatNull(cast(size_t) highInt - list.listLength)
                ));
            }
        }
    );
    context.registerBuiltin(context.ListType, "concat",
        function LispObject*(LispContext* context, LispArguments args){
            LispList result;
            foreach(arg; args){
                LispObject* argObject = context.evaluate(arg);
                if(argObject.isList()) result.extend(argObject.list);
            }
            return context.list(result);
        }
    );
    context.registerBuiltin(context.ListType, "extend",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(list.isList()){
                for(size_t i = 1; i < args.length; i++){
                    LispObject* argObject = context.evaluate(args[i]);
                    if(argObject.isList()) list.list.extend(argObject.list);
                }
            }
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "clear",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(list.isList()) list.list.clear();
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "reverse",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(list.isList()){
                for(size_t i = 0; i < list.listLength / 2; i++){
                    LispObject* t = list.store.list[i];
                    list.store.list[i] = (
                        list.store.list[list.listLength - i - 1]
                    );
                    list.store.list[list.listLength - i - 1] = t;
                }
            }
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "sort",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(list.isList()){
                if(args.length > 1){
                    LispObject* sortFunction = context.evaluate(args[1]);
                    if(sortFunction.isCallable()){
                        mergesort!((a, b) =>
                            context.invoke(sortFunction, [a, b]).toBoolean()
                        )(list.list.objects);
                    }
                }else{
                    mergesort!((a, b) => compare(a, b) < 0)(list.list.objects);
                }
            }
            return list;
        }
    );
    context.registerBuiltin(context.ListType, "each",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(args.length == 1 || !list.isList()){
                return context.Null;
            }
            LispObject* callback = context.evaluate(args[1]);
            if(!callback.isCallable()){
                return context.Null;
            }
            LispObject* result = context.Null;
            for(size_t i = 0; i < list.listLength; i++){
                result = context.invoke(callback, [list.store.list[i]]);
            }
            return result;
        }
    );
    context.registerBuiltin(context.ListType, "map",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(args.length == 1 || !list.isList()){
                return context.Null;
            }
            LispObject* transform = context.evaluate(args[1]);
            if(!transform.isCallable()){
                return context.Null;
            }
            LispObject*[] newList = new LispObject*[list.listLength];
            for(size_t i = 0; i < list.listLength; i++){
                newList[i] = context.invoke(transform, [list.store.list[i]]);
            }
            return context.list(newList);
        }
    );
    context.registerBuiltin(context.ListType, "filter",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(args.length == 1 || !list.isList()){
                return context.Null;
            }
            LispObject* filter = context.evaluate(args[1]);
            if(!filter.isCallable()){
                return context.Null;
            }
            LispObject*[] newList;
            for(size_t i = 0; i < list.listLength; i++){
                bool match = context.invoke(filter, [list.store.list[i]]).toBoolean();
                if(match) newList ~= list.store.list[i];
            }
            return context.list(newList);
        }
    );
    context.registerBuiltin(context.ListType, "reduce",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(args.length == 1 || !list.isList() || list.listLength == 0){
                return context.Null;
            }
            LispObject* combine = context.evaluate(args[1]);
            if(!combine.isCallable()){
                return context.Null;
            }else if(list.listLength == 1){
                return list.store.list[0];
            }
            LispObject* accumulator = list.store.list[0];
            for(size_t i = 1; i < list.listLength; i++){
                accumulator = context.invoke(combine, [
                    accumulator, list.store.list[i]
                ]);
            }
            return accumulator;
        }
    );
    context.registerBuiltin(context.ListType, "any",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(!list.isList()) return context.Null;
            if(args.length == 1){
                return anyFunction(context, list.list.objects);
            }else{
                return anyFunctionPredicate(
                    context, list.list.objects, context.evaluate(args[1])
                );
            }
        }
    );
    context.registerBuiltin(context.ListType, "all",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(!list.isList()) return context.Null;
            if(args.length == 1){
                return allFunction(context, list.list.objects);
            }else{
                return allFunctionPredicate(
                    context, list.list.objects, context.evaluate(args[1])
                );
            }
        }
    );
    context.registerBuiltin(context.ListType, "none",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* list = context.evaluate(args[0]);
            if(!list.isList()) return context.Null;
            if(args.length == 1){
                return noneFunction(context, list.list.objects);
            }else{
                return noneFunctionPredicate(
                    context, list.list.objects, context.evaluate(args[1])
                );
            }
        }
    );
    context.registerBuiltin(context.ListType, "upper",
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* list = context.evaluate(args[0]);
            return context.list(context.stringify(list).toUpper().map!(
                i => context.character(i)).asarray()
            );
        }
    );
    context.registerBuiltin(context.ListType, "lower",
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* list = context.evaluate(args[0]);
            return context.list(context.stringify(list).toLower().map!(
                i => context.character(i)).asarray()
            );
        }
    );
};

void registerMapType(LispContext* context){
    context.register("map", context.MapType);
    context.registerBuiltin(context.MapType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            size_t i = args.length & 1;
            LispObject* map = (i == 0 ? context.map() : context.object(
                context.evaluate(args[0])
            ));
            for(; i + 1 < args.length; i += 2){
                map.insert(
                    context.evaluate(args[i]), context.evaluate(args[i + 1])
                );
            }
            return map;
        }
    );
    context.registerBuiltin(context.MapType, "length", mapLength);
    context.registerBuiltin(context.MapType, "empty?", mapEmpty);
    context.registerBuiltin(context.MapType, "has",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.False;
            }else if(args.length == 1){
                return context.True;
            }
            LispObject* map = context.evaluate(args[0]);
            if(!map.isMap()){
                return context.False;
            }
            for(size_t i = 1; i < args.length; i++){
                LispObject* key = context.evaluate(args[i]);
                if(!map.get(key)) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin(context.MapType, "get",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2){
                return context.Null;
            }
            LispObject* map = context.evaluate(args[0]);
            if(map.isMap()){
                LispObject* key = context.evaluate(args[1]);
                LispObject* value = map.get(key);
                return value ? value : context.Null;
            }else{
                return context.Null;
            }
        }
    );
    context.registerBuiltin(context.MapType, "set",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }
            LispObject* map = context.evaluate(args[0]);
            if(map.isMap()){
                for(size_t i = 1; i + 1 < args.length; i += 2){
                    LispObject* key = context.evaluate(args[i]);
                    LispObject* value = context.evaluate(args[i + 1]);
                    map.insert(key, value);
                }
            }
            return map;
        }
    );
    context.registerBuiltin(context.MapType, "remove",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }
            LispObject* map = context.evaluate(args[0]);
            if(!map.isMap()){
                return map;
            }
            for(size_t i = 1; i < args.length; i++){
                LispObject* key = context.evaluate(args[i]);
                map.remove(key);
            }
            return map;
        }
    );
    context.registerBuiltin(context.MapType, "each",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* map = context.evaluate(args[0]);
            if(args.length == 1 || !map.isMap()){
                return context.Null;
            }
            LispObject* callback = context.evaluate(args[1]);
            if(!callback.isCallable()){
                return context.Null;
            }
            LispObject* result = context.Null;
            foreach(pair; map.maprange()){
                result = context.invoke(callback, [pair.key, pair.value]);
            }
            return result;
        }
    );
    context.registerBuiltin(context.MapType, "keys",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* map = context.evaluate(args[0]);
            if(!map.isMap()){
                return context.Null;
            }
            LispObject*[] list;
            foreach(pair; map.maprange()){
                list ~= pair.key;
            }
            return context.list(list);
        }
    );
    context.registerBuiltin(context.MapType, "values",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* map = context.evaluate(args[0]);
            if(!map.isMap()){
                return context.Null;
            }
            LispObject*[] list;
            foreach(pair; map.maprange()){
                list ~= pair.value;
            }
            return context.list(list);
        }
    );
    context.registerBuiltin(context.MapType, "let",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* map = context.evaluate(args[0]);
            if(map.isMap()){
                foreach(pair; map.maprange()){
                    context.register(pair.key, pair.value);
                }
            }
            return map;
        }
    );
    context.registerBuiltin(context.MapType, "merge",
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* map = context.map();
            foreach(arg; args){
                LispObject* argObject = context.evaluate(arg);
                if(argObject.isMap()){
                    foreach(pair; argObject.maprange()){
                        map.insert(pair.key, pair.value);
                    }
                }
            }
            return map;
        }
    );
    context.registerBuiltin(context.MapType, "extend",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* map = context.evaluate(args[0]);
            if(map.isMap()){
                for(size_t i = 1; i < args.length; i++){
                    LispObject* argObject = context.evaluate(args[i]);
                    if(argObject.isMap() && argObject.map !is map.map){
                        foreach(pair; argObject.maprange()){
                            map.insert(pair.key, pair.value);
                        }
                    }
                }
            }
            return map;
        }
    );
    context.registerBuiltin(context.MapType, "clone",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* map = context.evaluate(args[0]);
            if(!map.isMap()) return context.Null;
            LispObject* newMap = context.map(new LispMap(map.map.size));
            foreach(pair; map.map.asrange()){
                newMap.map.insert(pair.key, pair.value);
            }
            return newMap;
        }
    );
    context.registerBuiltin(context.MapType, "clear",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* map = context.evaluate(args[0]);
            if(map.isMap()){
                map.store.map.reset();
            }
            return map;
        }
    );
};

void registerObjectType(LispContext* context){
    context.register("object", context.ObjectType);
    context.registerBuiltin(context.ObjectType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* type = context.object();
            for(size_t i = 0; i + 1 < args.length; i += 2){
                type.insert(
                    context.evaluate(args[i]), context.evaluate(args[i + 1])
                );
            }
            return type;
        }
    );
};

void registerContextType(LispContext* context){
    context.register("context", context.ContextType);
    // Get the current context
    context.registerBuiltin(context.ContextType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            return context.context();
        }
    );
    // Get the parent context
    context.registerBuiltin(context.ContextType, "parent",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* contextObject = context.evaluate(args[0]);
            if(contextObject.type !is LispObject.Type.Context){
                return context.Null;
            }
            return context.context(context.parent);
        }
    );
    // Get identifiers in scope as a map object
    // TODO: Fix this!
    context.registerBuiltin(context.ContextType, "scope",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.map(context.inScope);
            }
            LispObject* contextObject = context.evaluate(args[0]);
            if(contextObject.type !is LispObject.Type.Context){
                return context.Null;
            }
            LispObject* map = context.map(contextObject.context.inScope);
            return map;
        }
    );
    // Evaluate an object in this context
    context.registerBuiltin(context.ContextType, "eval",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            LispObject* contextObject = context.evaluate(args[0]);
            if(contextObject.type !is LispObject.Type.Context){
                return context.Null;
            }
            return contextObject.context.evaluate(args[1]);
        }
    );
    // Determine whether an identifier is valid in this context
    context.registerBuiltin(context.ContextType, "has",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            LispObject* contextObject = context.evaluate(args[0]);
            if(contextObject.type !is LispObject.Type.Context){
                return context.Null;
            }
            LispObject* identifier = context.evaluate(args[1]);
            // TODO
            return context.Null;
        }
    );
    // Get the value of an identifier in this context
    context.registerBuiltin(context.ContextType, "get",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            LispObject* contextObject = context.evaluate(args[0]);
            if(contextObject.type !is LispObject.Type.Context){
                return context.Null;
            }
            LispObject* identifier = context.evaluate(args[1]);
            // TODO
            return context.Null;
        }
    );
    // Set the value of an identifier in this context, shadowing parents
    context.registerBuiltin(context.ContextType, "let",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            LispObject* contextObject = context.evaluate(args[0]);
            if(contextObject.type !is LispObject.Type.Context){
                return context.Null;
            }
            LispObject* identifier = context.evaluate(args[1]);
            // TODO
            return context.Null;
        }
    );
    // Set the value of an identifier in this context, overwriting parents
    context.registerBuiltin(context.ContextType, "set",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            LispObject* contextObject = context.evaluate(args[0]);
            if(contextObject.type !is LispObject.Type.Context){
                return context.Null;
            }
            LispObject* identifier = context.evaluate(args[1]);
            // TODO
            return context.Null;
        }
    );
};

void registerNativeFunctionType(LispContext* context){
    context.register("builtin", context.NativeFunctionType);
    context.registerBuiltin(context.NativeFunctionType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* builtinObject = context.builtins.get(args[0]);
            return builtinObject ? builtinObject : context.Null;
        }
    );
};

void registerLispFunctionType(LispContext* context){
    context.registerBuiltin("apply",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }
            LispObject* functionObject = context.evaluate(args[0]);
            if(!functionObject.isCallable()){
                return context.Null;
            }
            if(args.length == 1){
                return context.invoke(functionObject, []);
            }
            LispObject* argumentList = context.evaluate(args[1]);
            if(!argumentList.isList()){
                return context.Null;
            }
            return context.invoke(
                functionObject, argumentList.list.objects
            );
        }
    );
    context.register("function", context.LispFunctionType);
    context.registerBuiltin(context.LispFunctionType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* argumentNames = context.evaluate(args[0]);
            if(!argumentNames.isList()){
                return context.newLispFunction(context.list(), args[1]);
            }else{
                return context.newLispFunction(argumentNames, args[1]);
            }
        }
    );
    context.registerBuiltin(context.LispFunctionType, "args",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* method = context.evaluate(args[0]);
            return (method.type is LispObject.Type.LispFunction ?
                context.list(method.store.lispFunction.argumentList) : context.Null
            );
        }
    );
    context.registerBuiltin(context.LispFunctionType, "body",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* method = context.evaluate(args[0]);
            return (method.type is LispObject.Type.LispFunction ?
                method.store.lispFunction.expressionBody : context.Null
            );
        }
    );
    context.registerBuiltin(context.LispFunctionType, "context",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* method = context.evaluate(args[0]);
            return (method.type is LispObject.Type.LispFunction ?
                context.context(method.store.lispFunction.parentContext) : context.Null
            );
        }
    );
};

void registerLispMethodType(LispContext* context){
    context.register("method", context.LispMethodType);
    context.registerBuiltin(context.LispMethodType, context.Invoke,
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.Null;
            LispObject* functionObject = context.evaluate(args[1]);
            if(!functionObject.isCallable()){
                return context.Null;
            }else{
                LispObject* contextObject = context.evaluate(args[0]);
                return context.lispMethod(LispMethod(
                    contextObject, functionObject
                ));
            }
        }
    );
    context.registerBuiltin(context.LispMethodType, "context",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* method = context.evaluate(args[0]);
            return (method.type is LispObject.Type.LispMethod ?
                method.store.lispMethod.contextObject : context.Null
            );
        }
    );
    context.registerBuiltin(context.LispMethodType, "function",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* method = context.evaluate(args[0]);
            return (method.type is LispObject.Type.LispMethod ?
                method.store.lispMethod.functionObject : context.Null
            );
        }
    );
};

void registerAssignment(LispContext* context){
    // Assign a value to an identifier.
    // The first argument must be an identifier.
    // The second argument may be a value to assign or omitted. When the second
    // argument is omitted, null is used as a default.
    // If the identifier already exists in another scope, then the new value
    // shadows the old one in the current scope.
    // If the value already exists in the current scope, then the value is
    // overwritten.
    context.registerBuiltin("let",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }else if(!args[0].isList()){
                context.identifierError(args[0]);
                return context.Null;
            }
            LispObject* value = (args.length > 1 ?
                context.evaluate(args[1]) : context.Null
            );
            if(args[0].store.list.length == 1){
                context.register(args[0].store.list[0], value);
            }else{
                LispContext.Identity identity = context.identify(args[0]);
                if(!identity.attribute){
                    context.identifierError(args[0]);
                    return context.Null;
                }else if(identity.contextObject){
                    if(identity.contextObject.type !is LispObject.Type.Object){
                        context.identifierError(args[0]);
                        return context.Null;
                    }
                    identity.contextObject.insert(identity.attribute, value);
                }else if(!identity.context || identity.context == context){
                    context.inScope.insert(identity.attribute, value);
                }else{
                    context.identifierError(args[0]);
                    return context.Null;
                }
            }
            return value;
        }
    );
    // Assign a value to an identifier.
    // The first argument must be an identifier.
    // The second argument must be the value to assign.
    // If the identifier already exists in any accessible scope, then
    // its value is overwritten.
    context.registerBuiltin("set",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1){
                return context.Null;
            }else if(!args[0].isList()){
                context.identifierError(args[0]);
                return context.Null;
            }
            LispObject* value = context.evaluate(args[1]);
            LispContext.Identity identity = context.identify(args[0]);
            if(!identity.attribute){
                context.identifierError(args[0]);
                return context.Null;
            }else if(identity.contextObject){
                if(!identity.contextObject.type !is LispObject.Type.Object){
                    context.identifierError(args[0]);
                    return context.Null;
                }
                identity.contextObject.insert(identity.attribute, value);
            }else if(identity.context){
                identity.context.inScope.insert(identity.attribute, value);
            }else{
                context.inScope.insert(identity.attribute, value);
            }
            return value;
        }
    );
    context.registerBuiltin("quote",
        function LispObject*(LispContext* context, LispArguments args){
            return args[0];
        }
    );
    context.registerBuiltin("return",
        function LispObject*(LispContext* context, LispArguments args){
            return context.evaluate(args[0]);
        }
    );
}

void registerComparison(LispContext* context){
    context.registerBuiltin("is",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.True;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(!first.identical(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("isnot",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.False;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(first.identical(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("same",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.True;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(!first.sameKey(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("notsame",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.False;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(first.sameKey(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("eq",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.True;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(!first.equal(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("noteq",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.False;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(first.equal(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("like",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.True;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(!first.like(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("notlike",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.False;
            LispObject* first = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                if(first.like(context.evaluate(args[i]))) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("cmp",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length <= 1) return context.Null;
            auto result = compare(
                context.evaluate(args[0]), context.evaluate(args[1])
            );
            if(result == Incomparable){
                return context.Null;
            }else{
                return context.number(result);
            }
        }
    );
    context.registerBuiltin("asc",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.True;
            LispObject* prev = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                LispObject* next = context.evaluate(args[i]);
                if(compare(prev, next) > 0) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("desc",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.True;
            LispObject* prev = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                LispObject* next = context.evaluate(args[i]);
                if(compare(next, prev) > 0) return context.False;
            }
            return context.True;
        }
    );
    context.registerBuiltin("min",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* minimum = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                LispObject* value = context.evaluate(args[i]);
                auto result = compare(minimum, value);
                if(result == Incomparable){
                    return context.Null;
                }else if(result > 0){
                    minimum = value;
                }
            }
            return minimum;
        }
    );
    context.registerBuiltin("max",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* maximum = context.evaluate(args[0]);
            for(size_t i = 1; i < args.length; i++){
                LispObject* value = context.evaluate(args[i]);
                auto result = compare(maximum, value);
                if(result == Incomparable){
                    return context.Null;
                }else if(result < 0){
                    maximum = value;
                }
            }
            return maximum;
        }
    );
    context.registerBuiltin("hash",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.number(context.evaluate(args[0]).toHash());
        }
    );
}

void registerLogic(LispContext* context){
    context.registerBuiltin("not",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            return context.boolean(!context.evaluate(args[0]).toBoolean());
        }
    );
    context.registerBuiltin("any", anyFunction);
    context.registerBuiltin("all", allFunction);
    context.registerBuiltin("none", noneFunction);
}

void registerControlFlow(LispContext* context){
    context.registerBuiltin("do",
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* result = context.Null;
            foreach(arg; args) result = context.evaluate(arg);
            return result;
        }
    );
    context.registerBuiltin("when",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 1 || !context.evaluate(args[0]).toBoolean()){
                return context.Null;
            }else{
                LispObject* result = context.Null;
                foreach(arg; args[1 .. $]) result = context.evaluate(arg);
                return result;
            }
        }
    );
    context.registerBuiltin("if",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }else if(args.length == 1){
                context.evaluate(args[0]);
                return context.Null;
            }else if(args.length == 2){
                 bool condition = context.evaluate(args[0]).toBoolean();
                 return condition ? context.evaluate(args[1]) : context.Null;
            }else{
                bool condition = context.evaluate(args[0]).toBoolean();
                return context.evaluate(args[condition ? 1 : 2]);
            }
        }
    );
    context.registerBuiltin("switch",
        function LispObject*(LispContext* context, LispArguments args){
            size_t i = 0;
            for(; i + 1 < args.length; i += 2){
                if(context.evaluate(args[i]).toBoolean()){
                    return context.evaluate(args[i + 1]);
                }
            }
            if(i < args.length){
                return context.evaluate(args[i]);
            }
            return context.Null;
        }
    );
    context.registerBuiltin("until",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }else if(args.length == 1){
                while(!context.evaluate(args[0]).toBoolean()){}
                return context.Null;
            }else{
                LispObject* result = context.Null;
                while(!context.evaluate(args[0]).toBoolean()){
                    result = context.evaluate(args[1]);
                }
                return result;
            }
        }
    );
    context.registerBuiltin("while",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }else if(args.length == 1){
                while(context.evaluate(args[0]).toBoolean()){}
                return context.Null;
            }else{
                LispObject* result = context.Null;
                while(context.evaluate(args[0]).toBoolean()){
                    result = context.evaluate(args[1]);
                }
                return result;
            }
        }
    );
}

LispObject*[dstring] importedObjects;
LispObject* importLispModule(LispContext* context, dstring filePath){
    string importSource = cast(string) ( // Throws FileException
        Path(filePath).readfrom().asarray()
    );
    LispObject* importExpression = void;
    importExpression = context.parse( // Throws LispParseException
        importSource, cast(string) filePath.utf8encode().asarray()
    );
    LispContext* moduleContext = context.newChildContext();
    LispObject* moduleObject = moduleContext.evaluate(importExpression);
    // TODO: normalize paths before putting them in the table
    importedObjects[filePath] = moduleObject;
    return moduleObject;
}
void registerImport(LispContext* context){
    context.registerBuiltin("import",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            dstring filePath = context.stringify(
                context.evaluate(args[0])
            );
            if(LispObject** lispModule = filePath in importedObjects){
                return *lispModule;
            }
            try{
                return importLispModule(context, filePath);
            }catch(Exception e){
                context.logWarning("Import failed: ", e.msg);
                return context.Null;
            }
        }
    );
    context.registerBuiltin("reimport",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            dstring filePath = context.stringify(
                context.evaluate(args[0])
            );
            try{
                return importLispModule(context, filePath);
            }catch(Exception e){
                context.logWarning("Import failed: ", e.msg);
                return context.Null;
            }
        }
    );
}

LispObject* fileType;
FileHandle[] openedFiles;
auto stringifyArgs(LispContext* context, LispArguments args){
    struct Result{
        dstring text;
        LispObject* object;
    }
    Result result = Result("", context.Null);
    foreach(arg; args){
        result.object = context.evaluate(arg);
        result.text ~= context.stringify(result.object);
    }
    return result;
}
void registerStandardIO(LispContext* context){
    context.registerBuiltin("encode",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0){
                return context.Null;
            }
            return context.list(
                context.encode(context.evaluate(args[0]))
            );
        }
    );
    context.registerBuiltin("toString",
        function LispObject*(LispContext* context, LispArguments args){
            return context.list(stringifyArgs(context, args).text);
        }
    );
    context.registerBuiltin("print",
        function LispObject*(LispContext* context, LispArguments args){
            auto str = stringifyArgs(context, args);
            stdio.writeln(str.text);
            return str.object;
        }
    );
    fileType = context.register("File", context.object());
    context.register(fileType, "stdin", new LispObject(0.0, fileType));
    context.register(fileType, "stdout", new LispObject(1.0, fileType));
    context.register(fileType, "stderr", new LispObject(2.0, fileType));
    openedFiles = [stdin, stdout, stderr];
    context.registerBuiltin(fileType, "invoke",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            const filePath = context.stringify(
                context.evaluate(args[0])
            );
            string mode = "rb";
            size_t fileIndex = openedFiles.length;
            if(args.length > 1){
                mode = cast(string) context.stringify(
                    context.evaluate(args[1])
                );
            }
            try{
                openedFiles ~= Path(filePath).open(mode).target;
                return new LispObject(
                    cast(LispObject.Number) fileIndex, fileType
                );
            }catch(Exception e){
                return context.Null;
            }
        }
    );
    context.registerBuiltin(fileType, "close",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* fileObject = context.evaluate(args[0]);
            size_t fileIndex = cast(size_t) fileObject.toNumber();
            if(fileIndex < openedFiles.length && openedFiles[fileIndex]){
                fclose(openedFiles[fileIndex]);
                openedFiles[fileIndex] = null;
                return fileObject;
            }else{
                return context.Null;
            }
        }
    );
    context.registerBuiltin(fileType, "write",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* fileObject = context.evaluate(args[0]);
            size_t fileIndex = cast(size_t) fileObject.toNumber();
            if(fileIndex < openedFiles.length && openedFiles[fileIndex]){
                auto stream = FileStream(openedFiles[fileIndex]);
                for(size_t i = 1; i < args.length; i++){
                    stream.write(context.stringify(
                        context.evaluate(args[i])
                    ).utf8encode());
                }
                return fileObject;
            }else{
                return context.Null;
            }
        }
    );
    context.registerBuiltin(fileType, "writeln",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* fileObject = context.evaluate(args[0]);
            size_t fileIndex = cast(size_t) fileObject.toNumber();
            if(fileIndex < openedFiles.length && openedFiles[fileIndex]){
                auto stream = FileStream(openedFiles[fileIndex]);
                for(size_t i = 1; i < args.length; i++){
                    stream.write(context.stringify(
                        context.evaluate(args[i])
                    ).utf8encode());
                }
                stream.write('\n');
                return fileObject;
            }else{
                return context.Null;
            }
        }
    );
    context.registerBuiltin(fileType, "read",
        function LispObject*(LispContext* context, LispArguments args){
            return context.Null; // TODO
        }
    );
    context.registerBuiltin(fileType, "readln",
        function LispObject*(LispContext* context, LispArguments args){
            return context.Null; // TODO
        }
    );
}

void registerMath(LispContext* context){
    LispObject* piObject = context.number(pi);
    context.register("pi", piObject);
    context.register("π", piObject);
    LispObject* tauObject = context.number(tau);
    context.register("tau", tauObject);
    context.register("τ", tauObject);
    context.registerBuiltin("inc",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(context.evaluate(args[0]).toNumber() + 1);
        }
    );
    context.registerBuiltin("dec",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(context.evaluate(args[0]).toNumber() - 1);
        }
    );
    context.registerBuiltin("sum",
        function LispObject*(LispContext* context, LispArguments args){
            return context.number(
                args.map!(i => context.evaluate(i).toNumber()).kahansum()
            );
        }
    );
    context.registerBuiltin("mult",
        function LispObject*(LispContext* context, LispArguments args){
            return context.number(
                args.map!(i => context.evaluate(i).toNumber()).product()
            );
        }
    );
    context.registerBuiltin("sub",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Zero;
            return context.number(
                args.map!(i => context.evaluate(i).toNumber()).reduce!(
                    (acc, next) => acc - next
                )
            );
        }
    );
    context.registerBuiltin("div",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.One;
            return context.number(
                args.map!(i => context.evaluate(i).toNumber()).reduce!(
                    (acc, next) => acc / next
                )
            );
        }
    );
    context.registerBuiltin("modulo",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.PosNaN;
            return context.number(
                context.evaluate(args[0]).toNumber %
                context.evaluate(args[1]).toNumber
            );
        }
    );
    context.registerBuiltin("pow",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.PosNaN;
            return context.number(
                context.evaluate(args[0]).toNumber ^^
                context.evaluate(args[1]).toNumber
            );
        }
    );
    context.registerBuiltin("sqrt",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(sqrt(context.evaluate(args[0]).toNumber()));
        }
    );
    context.registerBuiltin("sin",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(sin(context.evaluate(args[0]).toNumber()));
        }
    );
    context.registerBuiltin("cos",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(cos(context.evaluate(args[0]).toNumber()));
        }
    );
    context.registerBuiltin("tan",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(tan(context.evaluate(args[0]).toNumber()));
        }
    );
    context.registerBuiltin("asin",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(asin(context.evaluate(args[0]).toNumber()));
        }
    );
    context.registerBuiltin("acos",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(acos(context.evaluate(args[0]).toNumber()));
        }
    );
    context.registerBuiltin("atan",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.NaN;
            return context.number(atan(context.evaluate(args[0]).toNumber()));
        }
    );
    context.registerBuiltin("atan2",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.NaN;
            return context.number(atan2(
                context.evaluate(args[0]).toNumber(),
                context.evaluate(args[1]).toNumber()
            ));
        }
    );
    context.registerBuiltin("log2",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.NaN;
            return context.number(log!2(
                context.evaluate(args[0]).toNumber()
            ));
        }
    );
    context.registerBuiltin("log10",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.NaN;
            return context.number(log!10(
                context.evaluate(args[0]).toNumber()
            ));
        }
    );
    context.registerBuiltin("ln",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.NaN;
            return context.number(log!e(
                context.evaluate(args[0]).toNumber()
            ));
        }
    );
}

LispObject* errorType;
LispObject* identifierErrorType;
LispObject* expressionErrorType;
LispObject* assertErrorType;
LispObject* testErrorType;
LispObject* tryErrorHandler;
LispObject* testType;
LispObject* makeAssertError(LispContext* context, LispObject* object, LispObject* message){
    assert(context && object);
    LispMap* errorMap = new LispMap();
    errorMap.insert(context.keyword("object"), object);
    errorMap.insert(context.keyword("message"), (message ?
        message : context.list("Assertion error"d)
    ));
    return context.object(errorMap, assertErrorType);
}
//auto runTestFunction = function LispObject*(LispContext* context, LispArguments args){
//    LispObject* test = context.evaluate(args[0]);
//    if(!test.isMap()) return context.Null;
//    LispContext* testContext = new LispContext(context);
//};
void registerErrorHandling(LispContext* context){
    errorType = context.register("Error", context.object());
    context.registerBuiltin(errorType, "toString",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length == 0) return context.Null;
            LispObject* errorObject = context.evaluate(args[0]);
            if(errorObject.type is LispObject.Type.Object){
                LispObject* message = errorObject.getAttribute(
                    context.keyword("message")
                ).object;
                return message ? message : context.Null;
            }else{
                return context.Null;
            }
        }
    );
    identifierErrorType = context.register(
        "IdentifierError", context.object(errorType)
    );
    expressionErrorType = context.register(
        "ExpressionError", context.object(errorType)
    );
    assertErrorType = context.register(
        "AssertError", context.object(errorType)
    );
    testErrorType = context.register(
        "TestError", context.object(errorType)
    );
    context.onIdentifierError = delegate void(LispContext* context, LispObject* identifier){
        LispMap* errorMap = new LispMap();
        errorMap.insert(context.keyword("message"),
            context.list("Encountered invalid identifier " ~ context.encode(identifier))
        );
        errorMap.insert(context.keyword("identifier"),
            identifier
        );
        context.handleError(context.object(errorMap, identifierErrorType));
    };
    context.onExpressionError = delegate void(LispContext* context, LispObject* expression){
        LispMap* errorMap = new LispMap();
        errorMap.insert(context.keyword("message"),
            context.list("Encountered invalid expression.")
        );
        errorMap.insert(context.keyword("expression"),
            expression
        );
        context.handleError(context.object(errorMap, expressionErrorType));
    };
    context.registerBuiltin("throw",
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* error = args.length ? context.evaluate(args[0]) : context.Null;
            context.handleError(error);
            return error;
        }
    );
    context.registerBuiltin("try",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.Null;
            // Create an error handler
            LispMap* handlerMap = new LispMap();
            LispObject* errorName = context.evaluate(args[0]);
            handlerMap.insert(context.keyword("errorName"), errorName);
            handlerMap.insert(context.keyword("catch"),
                args.length > 2 ? args[2] : context.Null
            );
            handlerMap.insert(context.keyword("finally"),
                args.length > 3 ? args[3] : context.Null
            );
            handlerMap.insert(context.keyword("invoke"), context.nativeFunction(
                function LispObject*(LispContext* invokeContext, LispArguments invokeArgs){
                    LispObject* handler = invokeContext.evaluate(invokeArgs[0]);
                    if(!handler.isMap()){
                        return invokeContext.Null;
                    }
                    LispObject* error = (invokeArgs.length > 1 ?
                        invokeArgs[1] : invokeContext.Null
                    );
                    if(LispObject* errorName = handler.getAttribute(
                        invokeContext.keyword("errorName")
                    ).object){
                        invokeContext.register(errorName, error);
                    }
                    if(LispObject* catchBody = handler.getAttribute(
                        invokeContext.keyword("catch")
                    ).object){
                        LispObject* result = invokeContext.evaluate(catchBody);
                        if(!invokeContext.error) invokeContext.error = error;
                        return result;
                    }else{
                        invokeContext.error = error;
                        return invokeContext.Null;
                    }
                }
            ));
            LispObject* errorHandler = context.object(context.object(handlerMap));
            // Create a context
            LispContext* tryContext = new LispContext(context);
            tryContext.errorHandler = errorHandler;
            // Evaluate try expression
            LispObject* result = tryContext.evaluate(args[1]);
            // Evaluate finally expression
            if(args.length > 3){
                LispContext* finallyContext = new LispContext(context);
                finallyContext.register(errorName,
                    tryContext.error ? tryContext.error : context.Null
                );
                finallyContext.evaluate(args[3]);
            }
            return result;
        }
    );
    context.registerBuiltin("assert",
        function LispObject*(LispContext* context, LispArguments args){
            LispObject* object = (args.length ?
                context.evaluate(args[0]) : context.Null
            );
            if(!object.toBoolean()){
                context.handleError(makeAssertError(context, object,
                    args.length > 1 ? context.evaluate(args[1]) : null
                ));
            }
            return object;
        }
    );
    context.registerBuiltin("test",
        function LispObject*(LispContext* context, LispArguments args){
            return context.Null; // Do nothing
        }
    );
    //context.registerBuiltin(testType, "run",
    //});
    //context.registerBuiltin(testType, "invoke",
    //    function LispObject*(LispContext* context, LispArguments args){
    //        if(args.length == 0) return context.Null;
    //        LispObject* testName = context.Null;
    //        LispObject* testBody = context.Null;
    //        if(args.length == 1){
    //            testBody = context.evaluate(args[0]);
    //        }else{
    //            testName = context.evaluate(args[0]);
    //            testBody = context.evaluate(args[1]);
    //        }
    //        LispObject* testObject = new LispObject(new LispMap(), testType);
    //        testObject.map.insert("name", testName);
    //        testObject.map.insert("body", testName);
    //        testObject.map.insert("invoke", runTest);
            
    //        string mode = "rb";
    //        size_t fileIndex = openedFiles.length;
    //        if(args.length > 1){
    //            mode = cast(string) context.stringify(
    //                context.evaluate(args[1])
    //            );
    //        }
    //        try{
    //            openedFiles ~= Path(filePath).open(mode).target;
    //            return new LispObject(
    //                cast(LispObject.Number) fileIndex, fileType
    //            );
    //        }catch(Exception e){
    //            return context.Null;
    //        }
    //    }
    //);
}
