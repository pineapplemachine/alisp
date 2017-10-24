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
    assert(value);
    final switch(value.type){
        case Type.Null:
            return false;
        case Type.Boolean: 
            return value.boolean;
        case Type.Character:
            return value.character != 0;
        case Type.Number:
            return value.number != 0 && !fisnan(value.number);
        case Type.Keyword:
        case Type.List:
        case Type.Map:
        case Type.Object:
        case Type.Context:
        case Type.NativeFunction:
        case Type.LispFunction:
        case Type.LispMethod:
            return true;
    }
}

LispObject.Character toCharacter(LispObject* value){
    assert(value);
    final switch(value.type){
        case Type.Boolean:
            return value.boolean ? 1 : 0;
        case Type.Character:
            return value.character;
        case Type.Number:
            return cast(LispObject.Character)(cast(uint) value.number);
        case Type.Null:
        case Type.Keyword:
        case Type.List:
        case Type.Map:
        case Type.Object:
        case Type.Context:
        case Type.NativeFunction:
        case Type.LispFunction:
        case Type.LispMethod:
            return LispObject.Character(0);
    }
}
    
LispObject.Number toNumber(LispObject* value){
    assert(value);
    final switch(value.type){
        case Type.Boolean:
            return value.boolean ? 1 : 0;
        case Type.Character:
            return cast(LispObject.Number) value.character;
        case Type.Number:
            return value.number;
        case Type.Null:
        case Type.Keyword:
        case Type.List:
        case Type.Map:
        case Type.Object:
        case Type.Context:
        case Type.NativeFunction:
        case Type.LispFunction:
        case Type.LispMethod:
            return LispObject.Number.nan;
    }
}

// Get whether two values are equal.
bool equal(LispObject* a, LispObject* b){
    assert(a && b);
    if(a == b){
        return a.type !is Type.Null && (
            a.type !is Type.Number || !fisnan(a.number)
        );
    }else if(a.type !is b.type || a.typeObject != b.typeObject){
        return false;
    }
    final switch(a.type){
        case Type.Null:
            return false;
        case Type.Boolean:
            return a.boolean == b.boolean;
        case Type.Character:
            return a.character == b.character;
        case Type.Number:
            return (!fisnan(a.number) &&
                fidentical(a.number, b.number)
            );
        case Type.Keyword:
            return a.keyword == b.keyword;
        case Type.List:
            if(a.listLength != b.listLength){
                return false;
            }
            for(size_t i = 0; i < a.listLength; i++){
                if(!equal(a.list[i], b.list[i])){
                    return false;
                }
            }
            return true;
        case Type.Map: goto case;
        case Type.Object:
            return b.isMap() && mapsEqual!equal(a.map, b.map);
        case Type.Context:
            return false;
        case Type.NativeFunction:
            return b.type is Type.NativeFunction && (
                a.nativeFunction == b.nativeFunction
            );
        case Type.LispFunction:
            return b.type is Type.LispFunction && (
                a.lispFunction.uniqueId == b.lispFunction.uniqueId
            );
        case Type.LispMethod:
            return b.type is Type.LispMethod && (
                a.lispMethod.contextObject.identical(
                    a.lispMethod.contextObject
                ) &&
                b.lispMethod.functionObject.identical(
                    b.lispMethod.functionObject
                )
            );
    }
}
    
// Get whether two values are alike, i.e. sort-of-equal.
bool like(LispObject* a, LispObject* b){
    assert(a && b);
    if(a == b){
        return true;
    }
    final switch(a.type){
        case Type.Null:
            switch(b.type){
                case Type.Null:
                    return true;
                case Type.Number:
                    return fisnan(b.number);
                default:
                    return false;
            }
        case Type.Boolean:
            switch(b.type){
                case Type.Boolean:
                    return a.boolean == b.boolean;
                case Type.Number:
                    return numberLikeBoolean(b.number, a.boolean);
                case Type.Character:
                    return characterLikeBoolean(b.character, a.boolean);
                default:
                    return false;
            }
        case Type.Character:
            switch(b.type){
                case Type.Boolean:
                    return characterLikeBoolean(a.character, b.boolean);
                case Type.Number:
                    return characterLikeNumber(a.character, b.number);
                case Type.Character:
                    return a.character == b.character;
                default:
                    return false;
            }
        case Type.Number:
            switch(b.type){
                case Type.Boolean:
                    return numberLikeBoolean(a.number, b.boolean);
                case Type.Number:
                    return (
                        fnearequal(a.number, b.number, LikeEpsilon) ||
                        (fisnan(a.number) && fisnan(b.number))
                    );
                case Type.Character:
                    return characterLikeNumber(b.character, a.number);
                default:
                    return false;
            }
        case Type.Keyword:
            return b.type is Type.Keyword && (
                a.keyword == b.keyword
            );
        case Type.List:
            if(!b.isList() || a.listLength != b.listLength){
                return false;
            }
            for(size_t i = 0; i < a.listLength; i++){
                if(!like(a.list[i], b.list[i])){
                    return false;
                }
            }
            return true;
        case Type.Map: goto case;
        case Type.Object:
            return b.isMap() && mapsEqual!like(a.map, b.map);
        case Type.Context:
            return false;
        case Type.NativeFunction:
            return b.type is Type.NativeFunction && (
                a.nativeFunction == b.nativeFunction
            );
        case Type.LispFunction:
            return b.type is Type.LispFunction && (
                a.lispFunction.uniqueId == b.lispFunction.uniqueId
            );
        case Type.LispMethod:
            return b.type is Type.LispMethod && (
                a.lispMethod.contextObject.identical(
                    a.lispMethod.contextObject
                ) &&
                b.lispMethod.functionObject.identical(
                    b.lispMethod.functionObject
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
    assert(a && b);
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
                    if(a.boolean) return b.boolean ? 0 : 1;
                    else return b.boolean ? -1 : 0;
                case Type.Character:
                    return compareValues(a.boolean ? 1 : 0, b.character);
                case Type.Number:
                    if(fisnan(b.number)){
                        return Incomparable;
                    }
                    return compareValues(a.boolean ? 1 : 0, b.number);
                default:
                    return Incomparable;
            }
        case Type.Character:
            switch(b.type){
                case Type.Boolean:
                    return compareValues(a.character, b.boolean ? 1 : 0);
                case Type.Character:
                    return compareValues(a.character, b.character);
                case Type.Number:
                    if(fisnan(b.number)){
                        return Incomparable;
                    }
                    return compareValues(cast(uint) a.character, b.number);
                default:
                    return Incomparable;
            }
        case Type.Number:
            switch(b.type){
                case Type.Boolean:
                    return compareValues(a.number, b.boolean ? 1 : 0);
                case Type.Character:
                    return compareValues(a.number, cast(uint) b.character);
                case Type.Number:
                    if(fisnan(a.number) || fisnan(b.number)){
                        return Incomparable;
                    }
                    return compareValues(a.number, b.number);
                default:
                    return Incomparable;
            }
        case Type.Keyword:
            return Incomparable;
        case Type.List:
            if(!b.isList()){
                return Incomparable;
            }
            for(size_t i = 0; i < a.listLength && i < b.listLength; i++){
                int order = compare(a.list[i], b.list[i]);
                if(order) return order;
            }
            return compareValues(a.listLength, b.listLength);
        case Type.Map: goto case;
        case Type.Object: goto case;
        case Type.Context: goto case;
        case Type.NativeFunction: goto case;
        case Type.LispFunction: goto case;
        case Type.LispMethod:
            return Incomparable;
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
