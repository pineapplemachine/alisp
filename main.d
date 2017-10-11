import mach.io : Path, stdio;

import alisp.context : LispContext;
import alisp.obj : LispObject;
import alisp.parse : parse, LispParseException;
import alisp.repl : lispRepl;

import alisp.lib : registerBuiltins;

LispContext* getContext(){
    LispContext* context = new LispContext(null);
    registerBuiltins(context);
    context.logFunction = function void(string message){stdio.writeln(message);};
    return context;
}

int main(string[] args){
    if(args.length <= 1){
        lispRepl(getContext());
        return 0;
    }else{
        // Load the file
        string sourceString;
        const filePath = args[1];
        try{
            sourceString = cast(string) Path(filePath).readall();
        }catch(Exception e){
            stdio.writeln("Failed to open file \"", filePath, "\".");
            return 1;
        }
        // Parse the file contents
        LispContext* context = getContext();
        LispObject* sourceObject;
        try{
            sourceObject = parse(context, sourceString, filePath);
        }catch(LispParseException e){
            stdio.writeln("Parse error: ", e.msg);
            return 1;
        }
        // Evaluate the file contents
        LispObject* result = context.evaluate(sourceObject);
        stdio.writeln(context.stringify(result));
        return 0;
    }
}
