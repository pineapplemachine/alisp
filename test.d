module alisp.test;

import mach.io.file.path : Path;
import mach.io.stdio : stdio;
import mach.range : split, headis, map, asarray;

import alisp.context : LispContext;
import alisp.obj : LispObject;
import alisp.parse : parse, LispParseException;
import alisp.repl : lispRepl;

import alisp.lib : registerBuiltins;

void main(){
    stdio.writeln("Running tests...");
    
    LispObject*[] identifierErrors = [];
    LispObject*[] expressionErrors = [];
    
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
    registerBuiltins(rootContext);
    
    enum Header: string{
        Test = "// test:",
        ExpectedOutput = "// output:",
        IdentifierError = "// error: identifier",
        ExpressionError = "// error: expression",
    }
    
    size_t totalTests = 0;
    size_t passedTests = 0;
    
    auto testsDir = Path.join(Path(__FILE_FULL_PATH__).directory, "tests");
    foreach(testFile; testsDir.traversedir){
        const testData = Path(testFile.path).readall();
        auto lines = testData.split('\n');
        string testTitle = "UNTITLED";
        LispObject* expectedOutput = null;
        LispObject* expectedIdentifierError = null;
        size_t expectedExpressionErrors = 0;
        string testBody = "";
        void runTest(){
            LispContext* testContext = new LispContext(rootContext);
            totalTests++;
            try{
                LispObject* object = parse(testContext, testBody);
                LispObject* output = testContext.evaluate(object);
                if(expectedOutput && !output.sameKey(expectedOutput)){
                    stdio.writeln("FAILED ", testFile.path.basename, " :", testTitle);
                    stdio.writeln("Expected ", testContext.encode(expectedOutput), " but got ", testContext.encode(output));
                }else if(expectedIdentifierError && (identifierErrors.length != 1 ||
                    !expectedIdentifierError.sameKey(identifierErrors[0])
                )){
                    stdio.writeln("FAILED ", testFile.path.basename, " :", testTitle);
                    stdio.writeln("Expected error for identifier ", testContext.encode(expectedIdentifierError));
                }else if(expectedIdentifierError ?
                    identifierErrors.length != 1 : identifierErrors.length
                ){
                    stdio.writeln("FAILED ", testFile.path.basename, " :", testTitle);
                    foreach(error; identifierErrors){
                        stdio.writeln("Encountered invalid identifier ", testContext.encode(error), ".");
                    }
                }else if(expressionErrors.length != expectedExpressionErrors){
                    stdio.writeln("FAILED ", testFile.path.basename, " :", testTitle);
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
                    stdio.writeln("Passed ", testFile.path.basename, " :", testTitle);
                }
            }catch(LispParseException e){
                stdio.writeln("FAILED ", testFile.path.basename, " :", testTitle);
                stdio.writeln("Parse error: ", e.msg);
            }
            testTitle = "UNTITLED";
            testBody = "";
            expectedOutput = null;
            expectedIdentifierError = null;
            expectedExpressionErrors = 0;
            identifierErrors.length = 0;
            expressionErrors.length = 0;
        }
        foreach(line; lines.map!(l => l.asarray!(immutable char)())){
            if(line.headis(Header.Test)){
                if(testBody && testBody.length) runTest();
                testTitle = line[Header.Test.length .. $];
            }else if(line.headis(Header.ExpectedOutput)){
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
        if(testBody && testBody.length) runTest();
    }
    
    stdio.writeln("Passed ", passedTests, " of ", totalTests, " tests.");
}
