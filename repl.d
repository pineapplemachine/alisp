module alisp.repl;

import mach.io : stdio;
import core.stdc.stdlib : exit;
import core.stdc.signal : signal, SIGINT;

import alisp.context : LispContext;
import alisp.obj : LispObject;
import alisp.parse : parse, LispParseException;

import alisp.libutils : stringify;

extern(C) void handleSignal(int signal) nothrow @nogc @system{
    exit(0);
}

void lispRepl(LispContext* context){
    signal(SIGINT, &handleSignal);
    stdio.writeln("Alisp 0.1.0");
    while(true){
        stdio.write(">> ");
        string expression;
        while(true){
            expression ~= stdio.readln();
            size_t parenNest = 0;
            foreach(const ch; expression){
                if(ch == '(' || ch == '[' || ch == '{'){
                    parenNest++;
                }else if(ch == ')' || ch == ']' || ch == '}'){
                    if(parenNest == 0) goto evaluateLabel;
                    parenNest--;
                }
            }
            if(parenNest == 0){
                break;
            }else{
                expression ~= "\n";
                stdio.write(".. ");
                stdio.flushout();
            }
        }
        evaluateLabel:
        if(expression.length){
            LispObject* expressionObject = null;
            try{
                expressionObject = parse(context, expression);
            }catch(LispParseException e){
                stdio.writeln(e.msg);
            }
            if(expressionObject){
                stdio.writeln(context.evaluate(expressionObject).stringify());
            }
        }
    }
}
