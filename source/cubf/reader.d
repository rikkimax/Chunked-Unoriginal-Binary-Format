module cubf.reader;
import std.typecons : Tuple, tuple;


struct CUBFReader {
	private {
		import std.system : Endian, endian;
		import std.bitmanip : bigEndianToNative, littleEndianToNative;

		ubyte[] source;
		bool requireChecksum, hadAnyChunksSoFar;
		Type current;
		Endian endianess;
		ubyte whereHeader;
		ulong headerOffset;
	}

	this(ubyte[] source, bool requireChecksum=false) {
		this.requireChecksum = requireChecksum;

		this.whereHeader = source[4];
		if (source[5] == 'B')
			this.endianess = Endian.bigEndian;
		else
			this.endianess = Endian.littleEndian;

		if (this.whereHeader == 'O') {
			if (endianess == Endian.bigEndian) {
				headerOffset = bigEndianToNative!ulong(source[8 .. 16])-16;
			} else {
				headerOffset = littleEndianToNative!ulong(source[8 .. 16])-16;
			}

			this.source = source[16 .. $];
		} else {
			this.source = source[8 .. $];
		}

		if (source.length > 0)
			popFront;
	}

	@property {
		Type front() {
			return current;
		}

		bool empty() {
			return source.length == 0 && current is Type.init;
		}
	}

	CUBFReader save() { 
		// implicit copy ;)
		return this;
	}

	void popFront() {
		if (source.length == 0) {
			current = Type.init;
			return;
		}

		uint length, hash;
		bool isHeader;

		if (endianess == Endian.bigEndian) {
			length = bigEndianToNative!uint(source[$-4 .. $][0 .. 4]);
			hash = bigEndianToNative!uint(source[$-8 .. $-4][0 .. 4]);
		} else {
			length = littleEndianToNative!uint(source[$-4 .. $][0 .. 4]);
			hash = littleEndianToNative!uint(source[$-8 .. $-4][0 .. 4]);
		}

		if (this.whereHeader == 'O') {
			isHeader = headerOffset == source.length-1;
		} else if (this.whereHeader == 'S') {
			isHeader = !this.hadAnyChunksSoFar;
		} else if (this.whereHeader == 'E') {
			isHeader = this.source.length <= length + 12;
		}
		this.hadAnyChunksSoFar = true;

		ubyte[] data;
		if (this.source.length > length + 12) {
			data = source[$-(length + 12) .. $-12];
			current = Type(cast(char[4])source[$-12 .. $-8][0 .. 4], data, isHeader);
			this.source = source[0 .. $-(length + 12)];
		} else {
			data = source[0 .. $-12];
			current = Type(cast(char[4])source[$-12 .. $-8][0 .. 4], data, isHeader);
			this.source = null;
		}

		if (requireChecksum) {
			import std.digest.crc;

			if (*cast(uint*)crc32Of(data).ptr != hash) {
				assert(0, "hash not equals for data");
			}
		}
	}

	alias Type = Tuple!(char[4], "name", ubyte[], "data", bool, "isHeader");
}
