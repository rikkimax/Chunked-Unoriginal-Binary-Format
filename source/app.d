module app;

void main() {
	import std.stdio : writeln;
	import cubf.writer;
	import cubf.reader;

	CUBFWriter writer = new CUBFWriter;
	writer.appendChunk("abcd", cast(ubyte[])"some chunk goes here");
	writer.appendHeaderChunk("ihdr", cast(ubyte[])"this is my header");
	writer.appendChunk("abcd", cast(ubyte[])"Hi there! you're cool right?");

	import std.file : write, read;
	write("test.cubf", writer.finalize());

	foreach(v; CUBFReader(cast(ubyte[])read("test.cubf"))) {
		writeln(v.name, "\t", cast(string)v.data, "\t", v.isHeader);
	}
}