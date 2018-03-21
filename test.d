module alisp.test;

import mach.io.file.path : Path;
import mach.io.stdio : stdio;
import mach.range : split, headis, map, asarray;

import alisp.context : LispContext;
import alisp.obj : LispObject, LispArguments;
import alisp.parse : parse, LispParseException;
import alisp.repl : lispRepl;

import alisp.lib : registerBuiltins;

size_t failedTests = 0;
size_t passedTests = 0;

int runTests(in string[] paths){
    failedTests = 0;
    passedTests = 0;
    
    LispContext* rootContext = new LispContext(null);
    rootContext.logFunction = delegate void(in string message){
        stdio.writeln(message);
    };
    registerBuiltins(rootContext);
    
    rootContext.registerBuiltin("test",
        function LispObject*(LispContext* context, LispArguments args){
            if(args.length < 2) return context.Null;
            LispObject* testTitle = context.evaluate(args[0]);
            LispContext* testContext = new LispContext(context);
            testContext.errorHandler = context.nativeFunction(
                function LispObject*(LispContext* context, LispObject*[] args){
                    assert(args.length && args[0]);
                    stdio.writeln("Handling a test error: ", context.stringify(args[0]));
                    context.error = args[0];
                    return args[0];
                }
            );
            testContext.evaluate(args[1]);
            if(testContext.error){
                failedTests++;
                LispObject* message = testContext.error.getAttribute(
                    context.keyword("message")
                ).object;
                if(message){
                    stdio.writeln("Test failed: ", context.stringify(testTitle), ". ",
                        context.stringify(message)
                    );
                }else{
                    stdio.writeln("Test failed: ", context.stringify(testTitle),
                        ". Error object: ", context.stringify(testContext.error)
                    );
                }
                return context.False;
            }else{
                passedTests++;
                return context.True;
            }
        }
    );

    LispObject* runTestsInFile(in string filePath){
        const fileContent = cast(string) Path(filePath).readall();
        LispContext* fileContext = new LispContext(rootContext);
        LispObject* fileObject = parse(fileContext, fileContent, filePath);
        return fileContext.evaluate(fileObject);
    }
    
    void runTestsInDirectory(in string dirPath){
        foreach(testFile; Path(dirPath).traversedir){
            if(testFile.isdir){
                runTestsInDirectory(testFile.path);
            }else{
                runTestsInFile(testFile.path);
            }
        }
    }
    
    try{
        foreach(path; paths){
            stdio.writeln("Running tests in \"", path, "\".");
            if(Path(path).isdir){
                runTestsInDirectory(path);
            }else{
                runTestsInFile(path);
            }
        }
    }catch(Exception e){
        stdio.writeln(e);
        return 1;
    }
    
    const totalTests = passedTests + failedTests;
    stdio.writeln("Passed ", passedTests, " of ", totalTests, " tests.");
    
    return passedTests == totalTests ? 0 : 1;
}
