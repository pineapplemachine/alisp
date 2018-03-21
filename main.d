import mach.io : Path, stdio;

import alisp.context : LispContext;
import alisp.obj : LispObject;
import alisp.parse : parse, LispParseException;
import alisp.repl : lispRepl;
import alisp.test : runTests;

import alisp.lib : registerBuiltins;

LispContext* getContext(){
    LispContext* context = new LispContext(null);
    context.logFunction = delegate void(in string message){
        stdio.writeln(message);
    };
    registerBuiltins(context);
    context.errorHandler = context.nativeFunction(
        function LispObject*(LispContext* context, LispObject*[] args){
            assert(args.length && args[0]);
            LispObject* messageKeyword = context.keyword("message");
            if(args[0].isMap() && args[0].map.get(messageKeyword)){
                stdio.writeln("Unhandled error: ",
                    context.stringify(args[0].map.get(messageKeyword))
                );
            }else{
                stdio.writeln("Unhandled error.");
            }
            return args[0];
        }
    );
    return context;
}

int runFile(in string filePath){
    // Load the file
    string sourceString;
    try{
        sourceString = cast(string) Path(filePath).readall();
    }catch(Exception e){
        stdio.writeln("Failed to open file \"", filePath, "\".");
        return 1;
    }
    return runSource(sourceString, filePath);
}

int runSource(in string sourceString, in string filePath = ""){
    LispContext* context = getContext();
    LispObject* sourceObject;
    try{
        sourceObject = parse(context, sourceString, filePath);
    }catch(LispParseException e){
        stdio.writeln("Parse error: ", e.msg);
        return 1;
    }
    // Evaluate the file contents
    if(sourceObject){
        LispObject* result = context.evaluate(sourceObject);
        stdio.writeln(context.stringify(result));
    }
    return 0;
}

int main(string[] args){
    if(args.length <= 1){
        lispRepl(getContext());
        return 0;
    }else if(args[1] == "test"){
        if(args.length <= 2){
            return runTests([
                Path.join(Path(__FILE_FULL_PATH__).directory, "tests")
            ]);
        }else{
            return runTests(args[2 .. $]);
        }
    }else if(args[1] == "run"){
        if(args.length <= 2){
            stdio.writeln("You must provide a file path.");
            return 1;
        }
        return runFile(args[2]);
    }else if(args[1] == "eval"){
        if(args.length <= 2){
            return 0;
        }
        string sourceString = "";
        for(size_t i = 2; i < args.length; i++){
            if(sourceString.length) sourceString ~= ' ';
            sourceString ~= args[i];
        }
        return runSource(sourceString);
    }else{
        return runFile(args[1]);
    }
}
