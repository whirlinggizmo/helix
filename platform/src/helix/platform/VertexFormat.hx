package helix.platform;

/** Specifies how a vertex attribute's values are stored in a buffer's records.

	Every format is read by a float input (`float`, `vecN`, a matrix's column): floats and half floats as they are, a normalized format's
	integers as floats from 0 to 1 (unsigned) or -1 to 1 (signed, the lowest value reading -1 as the next one up does, 0 reading 0). These
	are the formats every backend has; an input of more components than its format reads the rest as 0, 0, 1 as (0, 0, 0, 1) has them,
	and one of fewer reads the first ones. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract VertexFormat(Int) to Int {
	/** One float, 4 bytes. */
	var Float1 = 0;

	/** Two floats, 8 bytes. */
	var Float2 = 1;

	/** Three floats, 12 bytes. */
	var Float3 = 2;

	/** Four floats, 16 bytes. */
	var Float4 = 3;

	/** Four unsigned bytes, each read as its value over 255: 4 bytes, a color as RGBA8 stores it. */
	var UByte4Norm = 4;

	/** Four signed bytes, each read as its value over 127, -128 reading -1: 4 bytes. */
	var Byte4Norm = 5;

	/** Two unsigned 16-bit integers, little-endian, each read as its value over 65535: 4 bytes. */
	var UShort2Norm = 6;

	/** Two signed 16-bit integers, little-endian, each read as its value over 32767, -32768 reading -1: 4 bytes. */
	var Short2Norm = 7;

	/** Four unsigned 16-bit integers, little-endian, each read as its value over 65535: 8 bytes. */
	var UShort4Norm = 8;

	/** Four signed 16-bit integers, little-endian, each read as its value over 32767, -32768 reading -1: 8 bytes. */
	var Short4Norm = 9;

	/** Two half floats (IEEE binary16, little-endian): 4 bytes. */
	var Half2 = 10;

	/** Four half floats (IEEE binary16, little-endian): 8 bytes. */
	var Half4 = 11;

	/** Gets the bytes one value takes in a record: 4, 8, 12 or 16. */
	public var bytes(get, never):Int;

	/** Gets the number of components one value holds, 1 to 4. */
	public var componentCount(get, never):Int;

	function get_bytes():Int
		return abstract == Float3 ? 12 : abstract == Float4 ? 16 : abstract == Float2 || abstract == UShort4Norm || abstract == Short4Norm
			|| abstract == Half4 ? 8 : 4;

	function get_componentCount():Int
		return abstract == Float1 ? 1 : abstract == Float3 ? 3 : abstract == Float2 || abstract == UShort2Norm || abstract == Short2Norm
			|| abstract == Half2 ? 2 : 4;
}
