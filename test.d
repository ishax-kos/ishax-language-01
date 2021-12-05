import std.stdio;

void main() {
    File* file = new File(`text.txt`, "rb");
    char[1] c;
    file.rawRead(c);
    writeln(file.tell());
}


