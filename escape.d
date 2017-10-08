module alisp.escape;

dstring escapeCharacter(in dchar ch){
    switch(ch){
        case 0: return "\\0"d;
        case '\a': return "\\a"d;
        case '\b': return "\\b"d;
        case 27: return "\\e"d;
        case '\f': return "\\f"d;
        case '\n': return "\\n"d;
        case '\r': return "\\r"d;
        case '\t': return "\\t"d;
        case '\v': return "\\v"d;
        default: return cast(dstring)[ch];
    }
}

dchar unescapeCharacter(in dchar ch){
    switch(ch){
        case '0': return 0;
        case 'a': return '\a';
        case 'b': return '\b';
        case 'e': return 27;
        case 'f': return '\f';
        case 'n': return '\n';
        case 'r': return '\r';
        case 't': return '\t';
        case 'v': return '\v';
        default: return ch;
    }
}
