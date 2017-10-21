module alisp.parse;

import mach.range : map, any, all, asarray;
import mach.text.ascii : isdigit, iswhitespace;
import mach.text.numeric : writefloat, parsefloat, parsehex;
import mach.text.text : text;
import mach.text.utf : utf8decode;

import alisp.escape : unescapeCharacter;
import alisp.context : LispContext;
import alisp.list : LispList;
import alisp.map : LispMap;
import alisp.obj : LispObject, LispFloatSettings;



class LispParseException: Exception{
    string lispFile = "";
    size_t lispLine = 0;
    
    this(
        string lispFile, size_t lispLine, string message, Throwable next = null,
        size_t line = __LINE__, string file = __FILE__
    ){
        this.lispFile = lispFile;
        this.lispLine = lispLine;
        if(lispFile.length && lispLine){
            super(text(
                "At ", lispFile, " line ", lispLine, ": ", message
            ), file, line, null);
        }else if(lispFile.length){
            super(text(
                "In ", lispFile, ": ", message
            ), file, line, null);
        }else if(lispLine){
            super(text(
                "On line ", lispLine, ": ", message
            ), file, line, null);
        }else{
            super(message, file, line, next);
        }
    }
}

LispObject* parseSymbol(
    LispContext* context, in string symbol, in bool inIdentifier
){
    if(symbol == "null"){
        return context.Null;
    }else if(symbol == "true"){
        return context.True;
    }else if(symbol == "false"){
        return context.False;
    }else if(symbol == "infinity" || symbol == "+infinity"){
        return context.PosInfinity;
    }else if(symbol == "-infinity"){
        return context.NegInfinity;
    }else if(symbol == "NaN" || symbol == "+NaN"){
        return context.PosNaN;
    }else if(symbol == "-NaN"){
        return context.NegNaN;
    }else if(symbol[0] == '\''){
        if(symbol.length < 3 || symbol[$ - 1] != '\''){
            throw new Exception("Malformed character literal.");
        }
        dchar ch = void;
        if(symbol[1] == '\\'){
            return context.character(unescapeCharacter(
                utf8decode(symbol[2 .. $ - 1]).front()
            ));
        }else{
            return context.character(
                utf8decode(symbol[1 .. $ - 1]).front()
            );
        }
    }else if(symbol[0] == '"'){
        if(symbol[$ - 1] != '"'){
            throw new Exception("Malformed string literal.");
        }
        LispObject* characters = context.list();
        bool escapeSequence = false;
        foreach(ch; utf8decode(symbol[1 .. $ - 1])){
            if(!escapeSequence && ch == '\\'){
                escapeSequence = true;
            }else{
                characters.push(context.character(
                    escapeSequence ? unescapeCharacter(ch) : ch
                ));
                escapeSequence = false;
            }
        }
        return characters;
    }else if(symbol[0] == ':'){
        return context.keyword(cast(dstring) utf8decode(symbol[1 .. $]).asarray());
    }else if(symbol[0] == '0' && symbol.length > 1 && symbol[1] == 'x'){
        if(symbol.length < 3){
            throw new Exception("Malformed hex literal.");
        }
        try{
            return context.number(cast(LispObject.Number) parsehex!ulong(symbol[2 .. $]));
        }catch(Exception e){
            throw new Exception("Malformed hex literal.");
        }
    }else if(isdigit(symbol[0])){
        try{
            return context.number(parsefloat!(LispObject.Number)(symbol));
        }catch(Exception e){
            throw new Exception("Malformed numeric literal.");
        }
    }else if(symbol[0] == '.' || symbol[0] == '+' || symbol[0] == '-'){
        for(size_t i = 1; i < symbol.length; i++){
            if(isdigit(symbol[i])){
                try{
                    return context.number(parsefloat!(LispObject.Number)(symbol));
                }catch(Exception e){
                    throw new Exception("Malformed numeric literal.");
                }
            }
        }
    }
    if(inIdentifier){
        return context.keyword(cast(dstring) utf8decode(symbol).asarray());
    }else{
        return context.identifier(cast(dstring) utf8decode(symbol).asarray());
    }
}

LispObject* parse(LispContext* context, in string source, in string filePath = ""){
    size_t lineNumber = 1;
    LispObject* currentNode = context.expression();
    LispObject*[] nodeStack = [currentNode];
    char[] parenStack = [];
    size_t[] lineNumberStack = [1];
    bool[] identifierStack = [false];
    size_t symbolBegin = 0;
    size_t symbolLineNumber = 1;
    bool escapeSequence = false;
    bool singleQuote = false;
    bool doubleQuote = false;
    bool lineComment = false;
    bool blockComment = false;
    void terminateSymbol(in size_t i){
        if(symbolBegin < i){
            const string symbol = source[symbolBegin .. i];
            LispObject* parsedSymbol;
            try{
                parsedSymbol = parseSymbol(
                    context, symbol, identifierStack[$ - 1]
                );
            }catch(Exception e){
                throw new LispParseException(
                    filePath, symbolLineNumber, e.msg, e
                );
            }
            currentNode.push(parsedSymbol);
        }
        symbolBegin = i + 1;
        symbolLineNumber = lineNumber;
    }
    void terminateIdentifier(){
        if(identifierStack[$ - 1]){
            lineNumberStack.length--;
            identifierStack.length--;
            parenStack.length--;
            nodeStack.length--;
            currentNode = nodeStack[$ - 1];
        }
    }
    for(size_t i = 0; i < source.length; i++){
        const ch = source[i];
        if(singleQuote){
            if(ch == '\'' && !escapeSequence){
                singleQuote = false;
                terminateSymbol(i + 1);
                symbolBegin = i + 1;
            }else if(ch == '\\'){
                escapeSequence = !escapeSequence;
            }else{
                escapeSequence = false;
                if(ch == '\n'){
                    lineNumber++;
                }
            }
        }else if(doubleQuote){
            if(ch == '\"' && !escapeSequence){
                doubleQuote = false;
                terminateSymbol(i + 1);
                symbolBegin = i + 1;
            }else if(ch == '\\'){
                escapeSequence = !escapeSequence;
            }else{
                escapeSequence = false;
                if(ch == '\n'){
                    lineNumber++;
                }
            }
        }else if(lineComment){
            if(ch == '\n'){
                lineNumber++;
                symbolBegin = i + 1;
                lineComment = false;
            }
        }else if(blockComment){
            if(ch == '\n'){
                lineNumber++;
            }else if(ch == '/' && source[i - 1] == '*'){
                symbolBegin = i + 1;
                blockComment = false;
            }
        }else if(ch == '\n'){
            terminateSymbol(i);
            terminateIdentifier();
            lineNumber++;
        }else if(ch == ' ' || ch == '\t'){
            terminateSymbol(i);
            terminateIdentifier();
        }else if(ch == '\''){
            terminateSymbol(i);
            symbolBegin = i;
            singleQuote = true;
        }else if(ch == '"'){
            terminateSymbol(i);
            symbolBegin = i;
            doubleQuote = true;
        }else if(ch == '/' && i + 1 < source.length && source[i + 1] == '/'){
            terminateSymbol(i);
            lineComment = true;
        }else if(ch == '/' && i + 1 < source.length && source[i + 1] == '*'){
            terminateSymbol(i);
            blockComment = true;
        }else if(ch == ':' && i > 0 && (
            source[i - 1] != ' ' && source[i - 1] != '\t' &&
            source[i - 1] != '\n' && source[i - 1] != '(' &&
            source[i - 1] != '[' && source[i - 1] != '{'
        )){
            terminateSymbol(i);
            if(!identifierStack[$ - 1] && currentNode.listLength){
                LispObject* lastSymbol = currentNode.store.list[$ - 1];
                if(lastSymbol.typeObject == context.IdentifierType &&
                    lastSymbol.isList && lastSymbol.list.length == 1 &&
                    lastSymbol.list[0].type is LispObject.Type.Keyword
                ){
                    currentNode = lastSymbol;
                    nodeStack ~= lastSymbol;
                }else{
                    LispObject* newNode = context.identifier([lastSymbol]);
                    currentNode.list[$ - 1] = newNode;
                    currentNode = newNode;
                    nodeStack ~= newNode;
                }
                lineNumberStack ~= lineNumber;
                identifierStack ~= true;
                parenStack ~= '\0';
            }
        }else if(ch == '(' || ch == '[' || ch == '{'){
            currentNode = context.expression();
            if(ch == '['){
                currentNode.push(context.identifier("list"d));
            }else if(ch == '{'){
                currentNode.push(context.identifier("map"d));
            }
            nodeStack ~= currentNode;
            lineNumberStack ~= lineNumber;
            identifierStack ~= false;
            parenStack ~= ch;
            symbolBegin = i + 1;
        }else if(ch == ')' || ch == ']' || ch == '}'){
            terminateSymbol(i);
            terminateIdentifier();
            if(nodeStack.length <= 1){
                if(ch == ')'){
                    throw new LispParseException(filePath, lineNumber,
                        "Unbalanced parentheses."
                    );
                }else if(ch == ']'){
                    throw new LispParseException(filePath, lineNumber,
                        "Unbalanced brackets."
                    );
                }else{
                    throw new LispParseException(filePath, lineNumber,
                        "Unbalanced curly braces."
                    );
                }
            }
            if(ch == ')' && parenStack[$ - 1] != '('){
                throw new LispParseException(filePath, lineNumber,
                    "Mismatched parentheses."
                );
            }else if(ch == ']' && parenStack[$ - 1] != '['){
                throw new LispParseException(filePath, lineNumber,
                    "Mismatched brackets."
                );
            }else if(ch == '}' && parenStack[$ - 1] != '{'){
                throw new LispParseException(filePath, lineNumber,
                    "Mismatched curly braces."
                );
            }
            lineNumberStack.length--;
            identifierStack.length--;
            parenStack.length--;
            nodeStack.length--;
            nodeStack[$ - 1].push(currentNode);
            currentNode = nodeStack[$ - 1];
        }
    }
    if(singleQuote){
        throw new LispParseException(filePath, lineNumber,
            "Unterminated character literal."
        );
    }else if(doubleQuote){
        throw new LispParseException(filePath, lineNumber,
            "Unterminated string literal."
        );
    }else if(!lineComment && !blockComment){
        terminateSymbol(source.length);
        terminateIdentifier();
    }
    if(nodeStack.length > 1){
        throw new LispParseException(
            filePath, lineNumberStack[$ - 1], "Unterminated expression"
        );
    }
    if(currentNode.listLength == 0){
        return null;
    }else if(currentNode.listLength == 1){
        return currentNode.list[0];
    }else{
        currentNode.list.insert(0, context.identifier("do"d));
        return currentNode;
    }
}

dstring encodeList(
    LispContext* context, LispList list, bool identifier,
    size_t truncate = size_t.max, size_t depth = 0,
    LispObject*[] visited = null
){
    return encodeList(context, list.objects, identifier, depth, truncate);
}
dstring encodeList(
    LispContext* context, LispObject*[] list, bool identifier,
    size_t truncate = size_t.max, size_t depth = 0,
    LispObject*[] visited = null
){
    assert(context);
    dstring result = "";
    foreach(child; list){
        assert(child);
        if(result.length) result ~= identifier ? ':' : ' ';
        result ~= encode(context, child, identifier, truncate, depth, visited);
    }
    return result;
}
dstring encodeMap(
    LispContext* context, LispMap* map,
    size_t truncate = size_t.max, size_t depth = 0,
    LispObject*[] visited = null
){
    assert(context);
    dstring result = "";
    foreach(pair; map.asrange()){
        assert(pair.key && pair.value);
        if(result.length) result ~= ' ';
        result ~= (
            encode(context, pair.key, false, truncate, depth, visited) ~ ' ' ~
            encode(context, pair.value, false, truncate, depth, visited)
        );
    }
    return result;
}
dstring encode(
    LispContext* context, LispObject* object, bool inIdentifier,
    size_t truncate = size_t.max, size_t depth = 0,
    LispObject*[] visitedStack = null
){
    assert(context && object);
    const nDepth = depth + 1;
    // These helper functions help with detecting cyclic references
    LispObject*[] nextVisited(){
        return visitedStack ~ object;
    }
    bool checkVisited(){
        foreach(visited; visitedStack){
            if(visited.cyclicIdentical(object)){
                return true;
            }
        }
        return false;
    }
    dstring encodeVisited(){
        LispObject*[] identity = context.identifyObject(object);
        if(identity && identity.length){
            return encodeList(context, identity, true, truncate, nDepth, nextVisited);
        }else{
            return encode(context, object, inIdentifier, 0, 0, []);
        }
    }
    if(
        object.type is LispObject.Type.Null &&
        object.typeObject == context.Null
    ){
        return "null"d;
    }else if(
        object.type is LispObject.Type.Boolean &&
        object.typeObject == context.BooleanType
    ){
        return object.boolean ? "true"d : "false"d;
    }else if(
        object.type is LispObject.Type.Character &&
        object.typeObject == context.CharacterType
    ){
        return cast(dstring) ['\'', object.character, '\''];
    }else if(
        object.type is LispObject.Type.Number &&
        object.typeObject == context.NumberType
    ){
        return cast(dstring) utf8decode(
            writefloat!LispFloatSettings(object.number)
        ).asarray();
    }else if(
        object.type is LispObject.Type.Keyword &&
        object.typeObject == context.KeywordType
    ){
        if(inIdentifier){
            return object.keyword;
        }else{
            return ':' ~ object.keyword;
        }
    }else if(
        object.type is LispObject.Type.List &&
        object.typeObject == context.IdentifierType
    ){
        if(checkVisited()) return encodeVisited();
        return encodeList(
            context, object.list, true, truncate, nDepth, nextVisited
        );
    }else if(
        object.type is LispObject.Type.List &&
        object.typeObject == context.ExpressionType
    ){
        if(depth >= truncate){
            return "(...)"d;
        }
        if(checkVisited()) return encodeVisited();
        return '(' ~ encodeList(
            context, object.list, false, truncate, nDepth, nextVisited
        ) ~ ')';
    }else if(
        object.type is LispObject.Type.List &&
        object.typeObject == context.ListType
    ){
        if(object.listLength && object.list.objects.all!(
            i => i.type is LispObject.Type.Character
        )){
            return '"' ~ cast(dstring) object.list.map!(
                i => i.character
            ).asarray() ~ '"';
        }
        if(depth >= truncate){
            return "[...]"d;
        }
        if(checkVisited()) return encodeVisited();
        return '[' ~ encodeList(
            context, object.list, false, truncate, nDepth, nextVisited
        ) ~ ']';
    }else if(
        object.type is LispObject.Type.Map &&
        object.typeObject == context.MapType
    ){
        if(depth >= truncate){
            return "{...}"d;
        }
        if(checkVisited()) return encodeVisited();
        return '{' ~ encodeMap(
            context, object.map, truncate, nDepth, nextVisited
        ) ~ '}';
    }else if(
        object.type is LispObject.Type.NativeFunction &&
        object.typeObject == context.NativeFunctionType
    ){
        if(object.builtinIdentifier && object.builtinIdentifier.isList){
            return "(builtin "d ~ encodeList(
                context, object.builtinIdentifier.list,
                true, truncate, nDepth, nextVisited
            ) ~ ')';
        }else{
            return "(builtin)"d;
        }
    }else if(
        object.type is LispObject.Type.LispFunction &&
        object.typeObject == context.LispFunctionType
    ){
        if(checkVisited()) return encodeVisited();
        LispObject*[] argumentList = (
            object.lispFunction.argumentList
        );
        LispObject* expressionBody = (
            object.lispFunction.expressionBody
        );
        return "(function ["d ~
            encodeList(context, argumentList, false, truncate, nDepth, nextVisited) ~ "] "d ~
            encode(context, expressionBody, false, truncate, nDepth, nextVisited) ~
        ')';
    }else if(
        object.type is LispObject.Type.LispMethod &&
        object.typeObject == context.LispMethodType
    ){
        dstring contextObject = void;
        bool namedContextObject = false;
        if(!context.isLiteralType(
            object.lispMethod.contextObject.typeObject
        )){
            LispObject*[] identity = context.identifyObject(
                object.lispMethod.contextObject
            );
            if(identity){
                contextObject = encodeList(
                    context, identity, true, truncate, nDepth, nextVisited
                );
                namedContextObject = true;
            }
        }
        if(!namedContextObject){
            contextObject = encode(
                context, object.lispMethod.contextObject,
                false, truncate, nDepth, nextVisited
            );
        }
        if(checkVisited()) return encodeVisited();
        return "(method "d ~ contextObject ~ ' ' ~ encode(
            context, object.lispMethod.functionObject,
            false, truncate, nDepth, nextVisited
        ) ~ ')';
    }else if(
        object.type is LispObject.Type.Object &&
        object.typeObject == context.ObjectType
    ){
        if(object.mapLength == 0){
            return "{object}";
        }else if(depth >= truncate){
            return "{object ...}"d;
        }
        if(checkVisited()) return encodeVisited();
        return "{object "d ~ encodeMap(
            context, object.map, truncate, nDepth, nextVisited
        ) ~ '}';
    }else if(
        object.type is LispObject.Type.Context
    ){
        return "(context)"d;
    }else{
        dstring typeName = void;
        if(object.typeObject == object){
            typeName = "(%self-typed%)";
        }else{
            LispObject*[] typeIdentity = context.identifyObject(object.typeObject);
            typeName = (typeIdentity ?
                encodeList(context, typeIdentity, true, truncate, nDepth, nextVisited) :
                "(%anonymous object%)"d
            );
        }
        if(object.type is LispObject.Type.Object){
            if(object.mapLength == 0){
                return '{' ~ typeName ~ '}';
            }else if(depth >= truncate){
                return '{' ~ typeName ~ " ...}"d;
            }
            if(checkVisited()) return encodeVisited();
            return '{' ~ typeName ~ ' ' ~ encodeMap(
                context, object.map, truncate, nDepth, nextVisited
            ) ~ '}';
        }else{
            // TODO: Maybe get rid of this case?
            LispObject* normalizedObject = context.normalize(object);
            if(checkVisited()) return encodeVisited();
            return "(as "d ~ typeName ~ ' ' ~ encode(
                context, normalizedObject, false, truncate, nDepth, nextVisited
            ) ~ ')';
        }
    }
}
