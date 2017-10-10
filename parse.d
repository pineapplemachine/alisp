module alisp.parse;

import mach.range : asarray;
import mach.text.ascii : isdigit, iswhitespace;
import mach.text.numeric : parsefloat, parsehex;
import mach.text.text : text;
import mach.text.utf : utf8decode;

import alisp.escape : unescapeCharacter;
import alisp.context : LispContext;
import alisp.obj : LispObject, LispFloatSettings;

import mach.io : stdio;

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
                if(escapeSequence){
                    characters.store.list ~= context.character(unescapeCharacter(ch));
                }else{
                    characters.store.list ~= context.character(ch);
                }
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
            currentNode.store.list ~= parsedSymbol;
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
            if(!identifierStack[$ - 1] && currentNode.store.list.length){
                LispObject* lastSymbol = currentNode.store.list[$ - 1];
                LispObject* newNode = context.identifier([lastSymbol]);
                currentNode.store.list[$ - 1] = newNode;
                currentNode = newNode;
                nodeStack ~= newNode;
                lineNumberStack ~= lineNumber;
                identifierStack ~= true;
                parenStack ~= '\0';
            }
        }else if(ch == '(' || ch == '[' || ch == '{'){
            currentNode = context.expression();
            if(ch == '['){
                currentNode.store.list ~= context.identifier("list"d);
            }else if(ch == '{'){
                currentNode.store.list ~= context.identifier("map"d);
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
            nodeStack[$ - 1].store.list ~= currentNode;
            currentNode = nodeStack[$ - 1];
        }
    }
    terminateSymbol(source.length);
    terminateIdentifier();
    if(nodeStack.length > 1){
        throw new LispParseException(
            filePath, lineNumberStack[$ - 1], "Unterminated expression"
        );
    }
    //stdio.writeln(currentNode.store.list.map!(i => i.toString()));
    //stdio.writeln(currentNode.toString());
    if(currentNode.store.list.length == 1){
        return currentNode.store.list[0];
    }else{
        return context.expression(
            context.identifier("do"d) ~ currentNode.store.list
        );
    }
}
