module alisp.test;

import mach.io.file.path : Path;
import mach.io.stdio : stdio;
import mach.range : split, headis, map, asarray;

import alisp.context : LispContext;
import alisp.obj : LispObject;
import alisp.parse : parse, LispParseException;
import alisp.repl : lispRepl;

import alisp.lib : registerBuiltins;

int runTests(in string[] paths){
    LispObject*[] identifierErrors = [];
    LispObject*[] expressionErrors = [];
    LispObject*[] assertionErrors = [];
    
    LispContext* rootContext = new LispContext(null);
    rootContext.logFunction = delegate void(in string message){
        stdio.writeln(message);
    };
    rootContext.onIdentifierError = delegate void(LispObject* identifier){
        identifierErrors ~= identifier;
    };
    rootContext.onExpressionError = delegate void(LispObject* expression){
        expressionErrors ~= expression;
    };
    rootContext.onAssertionError = delegate void(LispObject* error){
        assertionErrors ~= error;
    };
    registerBuiltins(rootContext);
    
    enum Header: string{
        Test = "// test:",
        EndTest =  "// end test",
        ExpectedOutput = "// output:",
        IdentifierError = "// error: identifier",
        ExpressionError = "// error: expression",
    }
    
    size_t totalTests = 0;
    size_t passedTests = 0;
    
    void runTestsInFile(in string filePath){
        const testData = Path(filePath).readall();
        auto lines = testData.split('\n');
        bool inTestBody = false;
        string testTitle = "UNTITLED";
        LispObject* expectedOutput = null;
        LispObject* expectedIdentifierError = null;
        size_t expectedExpressionErrors = 0;
        string testBody = "";
        void runTest(){
            LispContext* testContext = new LispContext(rootContext);
            totalTests++;
            try{
                LispObject* object = parse(testContext, testBody, filePath);
                LispObject* output = testContext.evaluate(object);
                if(assertionErrors.length){
                    stdio.writeln("FAILED ", Path(filePath).basename, " :", testTitle);
                    foreach(error; assertionErrors){
                        if(error && error !is testContext.Null){
                            stdio.writeln("Encountered assertion error: ", rootContext.stringify(error));
                        }else{
                            stdio.writeln("Encountered assertion error.");
                        }
                    }
                }else if(expectedOutput && !output.sameKey(expectedOutput)){
                    stdio.writeln("FAILED ", Path(filePath).basename, " :", testTitle);
                    stdio.writeln("Expected ", testContext.encode(expectedOutput), " but got ", testContext.encode(output));
                }else if(expectedIdentifierError && (identifierErrors.length != 1 ||
                    !expectedIdentifierError.sameKey(identifierErrors[0])
                )){
                    stdio.writeln("FAILED ", Path(filePath).basename, " :", testTitle);
                    stdio.writeln("Expected error for identifier ", testContext.encode(expectedIdentifierError));
                }else if(expectedIdentifierError ?
                    identifierErrors.length != 1 : identifierErrors.length
                ){
                    stdio.writeln("FAILED ", Path(filePath).basename, " :", testTitle);
                    foreach(error; identifierErrors){
                        stdio.writeln("Encountered invalid identifier ", testContext.encode(error), ".");
                    }
                }else if(expressionErrors.length != expectedExpressionErrors){
                    stdio.writeln("FAILED ", Path(filePath).basename, " :", testTitle);
                    if(expectedExpressionErrors == 0){
                        stdio.writeln("Encountered malformed expression.");
                    }else if(expectedExpressionErrors == 1){
                        if(!expressionErrors.length){
                            stdio.writeln("Expected an expression error but there was none.");
                        }else{
                            stdio.writeln("Expected one expression error but there were ", expressionErrors.length, ".");
                        }
                    }else{
                        stdio.writeln(
                            "Expected ", expectedExpressionErrors, " expression errors ",
                            "but there were ", expressionErrors.length, "."
                        );
                    }
                }else{
                    passedTests++;
                    stdio.writeln("Passed ", Path(filePath).basename, " :", testTitle);
                }
            }catch(LispParseException e){
                stdio.writeln("FAILED ", Path(filePath).basename, " :", testTitle);
                stdio.writeln("Parse error: ", e.msg);
            }
            testTitle = "UNTITLED";
            testBody = "";
            expectedOutput = null;
            expectedIdentifierError = null;
            expectedExpressionErrors = 0;
            identifierErrors.length = 0;
            expressionErrors.length = 0;
            assertionErrors.length = 0;
        }
        foreach(line; lines.map!(l => l.asarray!(immutable char)())){
            if(line.headis(Header.Test)){
                inTestBody = true;
                if(testBody && testBody.length) runTest();
                testTitle = line[Header.Test.length .. $];
            }else if(line.headis(Header.EndTest)){
                if(testBody && testBody.length) runTest();
                inTestBody = false;
            }else if(inTestBody){
                if(line.headis(Header.ExpectedOutput)){
                    expectedOutput = rootContext.evaluate(parse(
                        rootContext, line[Header.ExpectedOutput.length .. $]
                    ));
                }else if(line.headis(Header.IdentifierError)){
                    expectedIdentifierError = parse(
                        rootContext, line[Header.IdentifierError.length .. $]
                    );
                }else if(line.headis(Header.ExpressionError)){
                    expectedExpressionErrors++;
                }else{
                    if(testBody) testBody ~= '\n';
                    testBody ~= line;
                }
            }
        }
        if(testBody && testBody.length) runTest();
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
    
    stdio.writeln("Passed ", passedTests, " of ", totalTests, " tests.");
    
    return passedTests == totalTests ? 0 : 1;
}
