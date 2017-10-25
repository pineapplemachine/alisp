module alisp.repl;

import mach.io : stdio;
import mach.range : contains, split, asarray;
import mach.text.ansi : EscapeSequenceParser;
import mach.text.ascii : isdigit, isalphanum;
import core.stdc.stdlib : exit;
//import core.stdc.signal : signal, SIGINT;

import alisp.terminal;

import alisp.context : LispContext;
import alisp.obj : LispObject;
import alisp.parse : parse, LispParseException;

//extern(C) void handleSignal(int signal) nothrow @nogc @system{
//    const char buffer = '\n';
//    fwrite(&buffer, 1, 1, stdout);
//    exit(0);
//}

/*
(
    test
    yo
)
*/

void lispRepl(LispContext* context){
    auto terminal = Terminal(ConsoleOutputType.linear);
    auto lineGetter = new LineGetter(&terminal);
    auto input = RealTimeConsoleInput(
        &terminal, ConsoleInputFlags.raw | ConsoleInputFlags.paste
    );
    
    context.logFunction = delegate void(in string message){
        terminal.writeln(message);
    };
    
    terminal.setTitle("Alisp 0.1.0");
    terminal.writeln("Alisp 0.1.0");
    terminal.write(">> ");
    
    string expression = "";
    size_t parens = 0;
    
    void evaluateInput(in string expression){
        if(expression.length){
            LispObject* expressionObject = null;
            try{
                expressionObject = parse(context, expression);
            }catch(LispParseException e){
                terminal.writeln(e.msg);
            }
            if(expressionObject){
                terminal.writeln(context.stringify(
                    context.evaluate(expressionObject)
                ));
            }
        }
    }
    
    bool addLine(in string line){
        foreach(ch; line){
            if(ch == '(' || ch == '[' || ch == '{'){
                parens++;
            }else if(ch == ')' || ch == ']' || ch == '}'){
                if(parens == 0) break;
                parens--;
            }
        }
        expression ~= line;
        if(parens == 0){
            evaluateInput(expression);
            expression = "";
        }
        return parens == 0;
    }
    
    lineGetter.startGettingLine();
    
    while(true){
        auto event = input.nextEvent();
        final switch(event.type){
            // Ignored events
            case InputEvent.Type.CharacterEvent: goto case;
            case InputEvent.Type.NonCharacterKeyEvent: goto case;
            case InputEvent.Type.MouseEvent: goto case;
            case InputEvent.Type.CustomEvent: goto case;
            case InputEvent.Type.SizeChangedEvent:
                break;
            // Termination events
            case InputEvent.Type.UserInterruptionEvent: goto case;
            case InputEvent.Type.HangupEvent: goto case;
            case InputEvent.Type.EndOfFileEvent:
                terminal.writeln();
                return;
            // Keypress event
            case InputEvent.Type.KeyboardEvent:
                const key = event.get!(InputEvent.Type.KeyboardEvent).which;
                if(key == '\n'){
                    string completedLine = lineGetter.finishGettingLine();
                    terminal.writeln();
                    terminal.flush();
                    bool completedExpression = addLine(completedLine);
                    terminal.write(completedExpression ? ">> " : ".. ");
                    lineGetter.startGettingLine();
                }else{
                    lineGetter.workOnLine(event);
                }
                break;
            // Paste event
            case InputEvent.Type.PasteEvent:
                string pasted = event.get!(InputEvent.Type.PasteEvent).pastedText;
                if(!pasted.contains('\n')){
                    lineGetter.justHitTab = false;
                    lineGetter.addString(pasted);
                    lineGetter.redraw();
                }else{
                    auto lines = pasted.split('\n');
                    lineGetter.justHitTab = false;
                    lineGetter.addString(cast(string) lines.front.asarray());
                    lineGetter.redraw();
                    lines.popFront();
                    string completedFirstLine = lineGetter.finishGettingLine();
                    terminal.writeln();
                    terminal.flush();
                    bool completedFirstExpression = addLine(completedFirstLine);
                    terminal.write(completedFirstExpression ? ">> " : ".. ");
                    lineGetter.startGettingLine();
                    while(!lines.empty){
                        string lineString = cast(string) lines.front.asarray();
                        lines.popFront();
                        if(lines.empty){
                            lineGetter.startOfLineY = terminal.cursorY;
                            lineGetter.addString(lineString);
                            lineGetter.redraw();
                        }else{
                            terminal.writeln(lineString);
                            bool completedExpression = addLine(lineString);
                            terminal.write(completedExpression ? ">> " : ".. ");
                        }
                    }
                }
        }
    }
}
