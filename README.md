## Chunked Unoriginal Binary Format

A simplistic format, meant for read only data.

Sister format for [command sequence data](https://github.com/rikkimax/csuf).

### Chunks
Chunks seperate groups of data. Each should be clearly defined in the form of a struct, array or plain data types (e.g. ubyte, int, float).

Chunk names are defined per the specification of the format on top of this. Those that are defined by that format use upper case for the first character. Chunks defined by extensions will utilize a lower case first character.

There is one chunk defined by CUBF, End Of Chunk Input ``EOCI``. This should be the closest chunk to the magic number and may contain arbituary information specific to the format stored.

Unlike End Of Chunk Input, the header chunk is implied based upon the magic value and is defined by the format specification.

### Format:
The format has two things, chunks and a magic value at the start.
The chunk format is:

- ubyte[0 .. (Length-8)]: Values
- char[4]: Name
- uint: Hash, crc32
- uint: Length, (Hash length) + (Name length) + (Values length)

The magic value has the form (in bytes):

- ['c', 'u', 'b', 'f']
- One of: 'S'tart, 'E'nd, 'O'ffset, 'I'nvalid
- One of: ['L', 'E'] or ['B', 'E']
- 0

If 'S'tart is selected, then the header will be immediately after the magic value.

If 'E'nd is selected, then the header will be the first chunk at the end of the file.

If 'O'ffset is selected, then an offset of 8 bytes is specified immediately after the magic value. At that offset is the header chunk (offset == length of chunk).

If 'I'nvalid is selected, then no header will be used.

Examples of the magic value (with offset) are: ``cubfSLE0``, ``cubfOBE068210000``.
