module cubf.writer;
import std.experimental.allocator : theAllocator, IAllocator, makeArray, dispose, expandArray;

final class CUBFWriter {
	private {
		size_t numberOfChunksSoFar, numberOfChunksAfterHeader;
		ubyte* ptrToHeaderLength;

		ubyte[] data;
		IAllocator allocator;

		bool finalized;
	}

	this(Endianess endianToUse = Endianess.Native, IAllocator allocator = theAllocator()) {
		if (endianToUse == Endianess.Native) {
			import std.system : Endian, endian;

			if (endian == Endian.bigEndian) {
				endianToUse = Endianess.Big;
			} else {
				endianToUse = Endianess.Little;
			}
		}

		this.allocator = allocator;
		// allocates enough space to hold the 'magic' number.
		data = allocator.makeArray!ubyte(16);

		data[8 .. 12] = cast(ubyte[])"cubf";
		data[12] = 'I';
		data[13 .. 15] = cast(ubyte[])(endianToUse == Endianess.Big ? "BE" : "LE");
		data[15] = 0;
	}

	~this() {
		allocator.dispose(data);
	}

	void appendChunk(char[4] name, ubyte[] data) {
		import std.bitmanip : nativeToBigEndian, nativeToLittleEndian, littleEndianToNative;
		import std.digest.crc;

		assert(!finalized);

		size_t realSize = data.length + 12;
		allocator.expandArray(this.data, realSize);
		this.data[$-realSize .. $-12] = data;
		this.data[$-12 .. $-8] = cast(ubyte[4])name;
		this.data[$-8 .. $-4] = crc32Of(data);

		if (data[14] == 'B') {
			this.data[$-8 .. $-4] = nativeToBigEndian(littleEndianToNative!uint(crc32Of(data)));
			this.data[$-4 .. $] = nativeToBigEndian(cast(uint)data.length);
		} else {
			this.data[$-8 .. $-4] = nativeToLittleEndian(littleEndianToNative!uint(crc32Of(data)));
			this.data[$-4 .. $] = nativeToLittleEndian(cast(uint)data.length);
		}

		numberOfChunksSoFar++;
		if (ptrToHeaderLength !is null) {
			numberOfChunksAfterHeader++;
		}
	}

	void appendHeaderChunk(char[4] name, ubyte[] data) {
		assert(!finalized);
		assert(ptrToHeaderLength is null);

		appendChunk(name, data);
		ptrToHeaderLength = this.data.ptr + this.data.length;
	}

	/// any appending after this is invalid.
	ubyte[] finalize() {
		import std.bitmanip : nativeToBigEndian, nativeToLittleEndian;

		if (!finalized) {
			finalized = true;

			if (ptrToHeaderLength !is null) {
				if (numberOfChunksAfterHeader == 0) {
					data[12] = 'E';
					data = data[8 .. $];
				} else if (numberOfChunksAfterHeader == numberOfChunksSoFar-1) {
					data[12] = 'S';
					data = data[8 .. $];
				} else {
					ulong offset = cast(ulong)(ptrToHeaderLength - (data.ptr + 1));
					data[0 .. 8] = data[8 .. 16];
					data[4] = 'O';

					if (data[6] == 'B') {
						data[8 .. 16] = nativeToBigEndian(offset);
					} else {
						data[8 .. 16] = nativeToLittleEndian(offset);
					}
				}
			} else {
				data = data[8 .. $];
			}
		}

		return data;
	}

	enum Endianess {
		Native,
		Little,
		Big
	}
}
