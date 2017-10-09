module alisp.libutils;

import mach.math : fnearequal, fidentical, fisnan;
import mach.range : map, join, all, asarray;
import mach.text.numeric : parsefloat, writefloat;
import mach.text.utf : utf8decode;

import alisp.map : mapsEqual;
import alisp.obj : LispObject, LispFloatSettings;

alias Type = LispObject.Type;

enum double LikeEpsilon = 1e-16;

bool characterLikeBoolean(in LispObject.Character character, in LispObject.Boolean boolean){
    return boolean == (character != 0);
}
bool characterLikeNumber(in LispObject.Character character, in LispObject.Number number){
    return cast(uint) number == character;
}
bool numberLikeBoolean(in LispObject.Number number, in LispObject.Boolean boolean){
    return boolean == (number != 0 && !fisnan(number));
}

LispObject.Boolean toBoolean(LispObject* value){
    final switch(value.type){
        case Type.Null:
            return false;
        case Type.Boolean: 
            return value.store.boolean;
        case Type.Character:
            return value.store.character != 0;
        case Type.Number:
            return value.store.number != 0 && !fisnan(value.store.number);
        case Type.Keyword:
        case Type.List:
        case Type.Map:
        case Type.Object:
        case Type.NativeFunction:
        case Type.LispFunction:
        case Type.LispMethod:
            return true;
    }
}

LispObject.Character toCharacter(LispObject* value){
    final switch(value.type){
        case Type.Boolean:
            return value.store.boolean ? 't' : 0;
        case Type.Character:
            return value.store.character;
        case Type.Number:
            return cast(LispObject.Character)(cast(uint) value.store.number);
        case Type.Null:
        case Type.Keyword:
        case Type.List:
        case Type.Map:
        case Type.Object:
        case Type.NativeFunction:
        case Type.LispFunction:
        case Type.LispMethod:
            return LispObject.Character(0);
    }
}
    
LispObject.Number toNumber(LispObject* value){
    final switch(value.type){
        case Type.Boolean:
            return value.store.boolean ? 1 : 0;
        case Type.Character:
            return cast(LispObject.Number) value.store.character;
        case Type.Number:
            return value.store.number;
        case Type.Null:
        case Type.Keyword:
        case Type.List:
        case Type.Map:
        case Type.Object:
        case Type.NativeFunction:
        case Type.LispFunction:
        case Type.LispMethod:
            return LispObject.Number.nan;
    }
}

// Get whether two values are equal.
bool equal(LispObject* a, LispObject* b){
    if(a == b){
        return a.type !is Type.Null && (
            a.type !is Type.Number || !fisnan(a.store.number)
        );
    }else if(a.type !is b.type || a.typeObject != b.typeObject){
        return false;
    }
    final switch(a.type){
        case Type.Null:
            return false;
        case Type.Boolean:
            return a.store.boolean == b.store.boolean;
        case Type.Character:
            return a.store.character == b.store.character;
        case Type.Number:
            return (!fisnan(a.store.number) &&
                fidentical(a.store.number, b.store.number)
            );
        case Type.Keyword:
            return a.store.keyword == b.store.keyword;
        case Type.List:
            if(a.store.list.length != b.store.list.length){
                return false;
            }
            for(size_t i = 0; i < a.store.list.length; i++){
                if(!equal(a.store.list[i], b.store.list[i])){
                    return false;
                }
            }
            return true;
        case Type.Map: goto case;
        case Type.Object:
            return b.isMap() && mapsEqual!equal(a.store.map, b.store.map);
        case Type.NativeFunction:
            return b.type is Type.NativeFunction && (
                a.store.nativeFunction == b.store.nativeFunction
            );
        case Type.LispFunction:
            return b.type is Type.LispFunction && (
                a.store.lispFunction.uniqueId == b.store.lispFunction.uniqueId
            );
        case Type.LispMethod:
            return b.type is Type.LispMethod && (
                a.store.lispMethod.contextObject.identical(
                    a.store.lispMethod.contextObject
                ) &&
                b.store.lispMethod.functionObject.identical(
                    b.store.lispMethod.functionObject
                )
            );
    }
}
    
// Get whether two values are alike, i.e. sort-of-equal.
bool like(LispObject* a, LispObject* b){
    if(a == b){
        return true;
    }
    final switch(a.type){
        case Type.Null:
            switch(b.type){
                case Type.Null:
                    return true;
                case Type.Number:
                    return fisnan(b.store.number);
                default:
                    return false;
            }
        case Type.Boolean:
            switch(b.type){
                case Type.Boolean:
                    return a.store.boolean == b.store.boolean;
                case Type.Number:
                    return numberLikeBoolean(b.store.number, a.store.boolean);
                case Type.Character:
                    return characterLikeBoolean(b.store.character, a.store.boolean);
                default:
                    return false;
            }
        case Type.Character:
            switch(b.type){
                case Type.Boolean:
                    return characterLikeBoolean(a.store.character, b.store.boolean);
                case Type.Number:
                    return characterLikeNumber(a.store.character, b.store.number);
                case Type.Character:
                    return a.store.character == b.store.character;
                default:
                    return false;
            }
        case Type.Number:
            switch(b.type){
                case Type.Boolean:
                    return numberLikeBoolean(a.store.number, b.store.boolean);
                case Type.Number:
                    return (
                        fnearequal(a.store.number, b.store.number, LikeEpsilon) ||
                        (fisnan(a.store.number) && fisnan(b.store.number))
                    );
                case Type.Character:
                    return characterLikeNumber(b.store.character, a.store.number);
                default:
                    return false;
            }
        case Type.Keyword:
            return b.type is Type.Keyword && (
                a.store.keyword == b.store.keyword
            );
        case Type.List:
            if(!b.isList() || a.store.list.length != b.store.list.length){
                return false;
            }
            for(size_t i = 0; i < a.store.list.length; i++){
                if(!like(a.store.list[i], b.store.list[i])){
                    return false;
                }
            }
            return true;
        case Type.Map: goto case;
        case Type.Object:
            return b.isMap() && mapsEqual!like(a.store.map, b.store.map);
        case Type.NativeFunction:
            return b.type is Type.NativeFunction && (
                a.store.nativeFunction == b.store.nativeFunction
            );
        case Type.LispFunction:
            return b.type is Type.LispFunction && (
                a.store.lispFunction.uniqueId == b.store.lispFunction.uniqueId
            );
        case Type.LispMethod:
            return b.type is Type.LispMethod && (
                a.store.lispMethod.contextObject.identical(
                    a.store.lispMethod.contextObject
                ) &&
                b.store.lispMethod.functionObject.identical(
                    b.store.lispMethod.functionObject
                )
            );
    }
}

// -1 when a precedes b
// +1 when a follows b
// 0 when a is the same as b
// +2 when a and b are incomparable
enum int Incomparable = 2;
int compareValues(A, B)(A a, B b){
    if(a < b) return -1;
    else if(a > b) return +1;
    else return 0;
}
int compare(LispObject* a, LispObject* b){
    if(b.type is Type.Null){
        return Incomparable;
    }else if(a == b){
        return 0;
    }
    final switch(a.type){
        case Type.Null:
            return Incomparable;
        case Type.Boolean:
            switch(b.type){
                case Type.Boolean:
                    if(a.store.boolean) return b.store.boolean ? 0 : 1;
                    else return b.store.boolean ? -1 : 0;
                case Type.Character:
                    return compareValues(a.store.boolean ? 1 : 0, b.store.character);
                case Type.Number:
                    if(fisnan(b.store.number)){
                        return Incomparable;
                    }
                    return compareValues(a.store.boolean ? 1 : 0, b.store.number);
                default:
                    return Incomparable;
            }
        case Type.Character:
            switch(b.type){
                case Type.Boolean:
                    return compareValues(a.store.character, b.store.boolean ? 1 : 0);
                case Type.Character:
                    return compareValues(a.store.character, b.store.character);
                case Type.Number:
                    if(fisnan(b.store.number)){
                        return Incomparable;
                    }
                    return compareValues(cast(uint) a.store.character, b.store.number);
                default:
                    return Incomparable;
            }
        case Type.Number:
            switch(b.type){
                case Type.Boolean:
                    return compareValues(a.store.number, b.store.boolean ? 1 : 0);
                case Type.Character:
                    return compareValues(a.store.number, cast(uint) b.store.character);
                case Type.Number:
                    if(fisnan(a.store.number) || fisnan(b.store.number)){
                        return Incomparable;
                    }
                    return compareValues(a.store.number, b.store.number);
                default:
                    return Incomparable;
            }
        case Type.Keyword:
            return Incomparable;
        case Type.List:
            if(!b.isList()){
                return Incomparable;
            }
            for(size_t i = 0; i < a.store.list.length && i < b.store.list.length; i++){
                int order = compare(a.store.list[i], b.store.list[i]);
                if(order) return order;
            }
            return compareValues(a.store.list.length, b.store.list.length);
        case Type.Map: goto case;
        case Type.Object: goto case;
        case Type.NativeFunction: goto case;
        case Type.LispFunction: goto case;
        case Type.LispMethod:
            return Incomparable;
    }
}

// Get a human-readable string good for e.g. printing to the console
dstring stringify(LispObject* value){
    final switch(value.type){
        case Type.Null:
            return "null"d;
        case Type.Boolean:
            return value.store.boolean ? "true"d : "false"d;
        case Type.Character:
            return cast(dstring) [value.store.character];
        case Type.Number:
            return cast(dstring)(
                utf8decode(writefloat!LispFloatSettings(value.store.number)).asarray()
            );
        case Type.Keyword:
            return ':' ~ value.store.keyword;
        //case Type.Identifier:
        //    if(value.store.list.length == 0){
        //        return ""d;
        //    }
        //    dstring str = cast(dstring)(
        //        value.store.list.map!(
        //            i => i.toIdentifierString()
        //        ).join(":"d).asarray()
        //    );
        //    return str[0] == ':' ? str[1 .. $] : str;
        case Type.List:
            if(
                value.store.list.length &&
                value.store.list.all!(i => i.type is Type.Character)
            ){
                return cast(dstring)(
                    value.store.list.map!(i => i.store.character).asarray()
                );
            }else{
                return '[' ~ cast(dstring)(
                    value.store.list.map!(i => i.toString()).join(" "d).asarray()
                ) ~ ']';
            }
        //case Type.Expression:
        //    return '(' ~ cast(dstring)(
        //        value.store.list.map!(i => i.toString()).join(" "d).asarray()
        //    ) ~ ')';
        case Type.Map:
            return '{' ~ cast(dstring)(
                value.store.map.asrange().map!(pair =>
                    pair.key.toString() ~ ' ' ~ pair.value.toString()
                ).join(" "d).asarray()
            ) ~ '}';
        case Type.Object:
            if(value.store.map.length == 0){
                return "(object)"d;
            }else{
                return "(object "d ~ cast(dstring)(
                    value.store.map.asrange().map!(pair =>
                        pair.key.toString() ~ ' ' ~ pair.value.toString()
                    ).join(" "d).asarray()
                ) ~ ')';
            }
        case Type.NativeFunction:
            return "(builtin)"d;
        case Type.LispFunction:
            return cast(dstring) ("(function ["d ~
                value.store.lispFunction.argumentList.map!(i =>
                    i.toString()
                ).join(" "d).asarray()
            ~ "] "d ~ value.store.lispFunction.expressionBody.toString()) ~ ')';
        case Type.LispMethod:
            return cast(dstring) ("(method "d ~
                value.store.lispMethod.contextObject.toString() ~ ' ' ~
                value.store.lispMethod.functionObject.toString() ~
            ')');
    }
}

LispObject.Number parseNumber(in dstring value){
    if(value == "NaN" || value == "+NaN"){
        return LispObject.Number.nan;
    }else if(value == "-NaN"){
        return -LispObject.Number.nan;
    }else if(value == "infinity" || value == "+infinity"){
        return LispObject.Number.infinity;
    }else if(value == "-infinity"){
        return -LispObject.Number.infinity;
    }else{
        return parsefloat!(LispObject.Number)(value);
    }
}
