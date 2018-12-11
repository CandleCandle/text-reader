use "collections"
use "format"

/*

Read a byte stream line-by-line

API objectives:
 # reasonably usable
 # checking functions (has_line(), etc)

Implementation objectives:
 # no partial functions on the primary path (when there is actually an error, it's fine.)
 # as little memcopy as possible


example usage:
HTTP 1.0/1? client:

var _state: (ResponseLine | Headers | Body)
let _reader: LineReader iso
var _payload: Payload trn
let _body: Array[Array[U8]] iso

fun ref received(..., data Array[U8] iso, ...) =>
	match _state
	| ResponseLine => // "HTTP/1.{0,1} 200 OK\r\n"
		_reader.append(consume data)
		if _reader.has_line() then
			_parse_response_line(_reader.line())
			_state = Headers
		end
	| Headers => // one header per \r\n separated liner
		_reader.append(consume data)
		while _reader.has_line() then
			let str = _reader.line()
			if str == "" then
				// When `data` contains the start of the body beyond the \r\n\r\n
				_payload.body.extend(_reader.remainder())
				_state = Body
			else
				handle_header_line(str) // e.g. if Content-Length, update expected body size
			end
		end
	| Body =>
		// TODO logic to deal with `data` containing the end of one response and the start of the next; as per HTTP/1.1
		_payload.body.append(consume data)
		if _payload.is_complete() then
			_dispatch_payload(_payload = Payload()) // destructive read
		end
	end


00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
74 68 69 73 0D 0A 20 69 73 20 61 20 67 6F 6F 64
<-------------- first ------------------> <----

11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11
00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
20 69 64 65 61 0D 0A 72 65 61 6C 6C 79 2E 0D 0A
-- second ------> <------- third ------------->

22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22
00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
2E 0D 0A 2E 0D 0A 2E 0D 0A 2E 0D 0A 2E 2E 0D 0A
<----------------- fourth -------------------->

33 33 33 33 33 33 33 33 33 33 33 33 33 33 33 33
00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
74 68 69 73 20 69 73 20 69 73 20 0D 0A
<----- fifth ------------> <--- 6th -->


// then we get one-byte-at-a-time fed into the buffers; creating 7th -> 12th
33 33 33 33 33 33 33 33 33 33 33 33 33 33 33 33
00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
2E 0D 0A 2E 0D 0A


first:   size = 0x0e; position = 0x00; separator_idx = 0; separators = [0x04]
second:  size = 0x08; position = 0x00; separator_idx = 0; separators = [0x07]
third:   size = 0x0a; position = 0x01; separator_idx = 0; separators = [0x08]
fourth:  size = 0x10; position = 0x00; separator_idx = 0; separators = [0x01; 0x04; 0x07; 0x0a; 0x0e]
fifth:   size = 0x09; position = 0x00; separator_idx = 0; separators = []
sixth:   size = 0x04; position = 0x00; separator_idx = 0; separators = [0x02]
seventh: size = 0x01; position = 0x00; separator_idx = 0; separators = []
eigth:   size = 0x01; position = 0x00; separator_idx = 0; separators = [0x00]
nineth:  size = 0x01; position = 0x01; separator_idx = 0; separators = []
tenth:   size = 0x01; position = 0x00; separator_idx = 0; separators = []
eleventh:size = 0x01; position = 0x00; separator_idx = 0; separators = [0x00]
twelfth  size = 0x01; position = 0x01; separator_idx = 0; separators = []

first:   position < size; separator_idx < separators.size()
read_line => 74 68 69 73
first:   size = 0x0e; position = 0x06; separator_idx = 1; separators = [0x04]

first:   position < size; separator_idx < separators.size()
read_line => 20 69 73 20 61 20 67 6F.6F 64 20 69 64 65 61
first:   size = 0x0e; position = 0x0e; separator_idx = 1; separators = [0x04]
(shift)  position >= size; separator_idx >= separators.size()
second:  position < size; separator_idx < separators.size()
read_line => 20 69 73 20 61 20 67 6F.6F 64 20 69 64 65 61
second:  size = 0x08; position = 0x08 (or 0x09); separator_idx = 1; separators = [0x07]
(shift)  position >= size; separator_idx >= separators.size()

third:   position < size; separator_idx < separators.size()
read_line => 72 65 61 6C 6C 79 2E
third:   size = 0x0a; position = 0x0a; separator_idx = 1; separators = [0x08]
(shift) position >= size; separator_idx >= separators.size()

fourth: position < size; separator_idx < separators.size()
read_line => 2E
fourth:  size = 0x10; position = 0x03; separator_idx = 1; separators = [0x01; 0x04; 0x07; 0x0a; 0x0e]

fourth: position < size; separator_idx < separators.size()
read_line => 2E
fourth:  size = 0x10; position = 0x06; separator_idx = 2; separators = [0x01; 0x04; 0x07; 0x0a; 0x0e]

fourth: position < size; separator_idx < separators.size()
read_line => 2E
fourth:  size = 0x10; position = 0x09; separator_idx = 3; separators = [0x01; 0x04; 0x07; 0x0a; 0x0e]

fourth: position < size; separator_idx < separators.size()
read_line => 2E
fourth:  size = 0x10; position = 0x0c; separator_idx = 4; separators = [0x01; 0x04; 0x07; 0x0a; 0x0e]

fourth: position < size; separator_idx < separators.size()
read_line => 2E 2E
fourth:  size = 0x10; position = 0x10; separator_idx = 5; separators = [0x01; 0x04; 0x07; 0x0a; 0x0e]
(shift) position >= size; separator_idx >= separators.size()

*/

class BufferElement
	// the role of this class is to contain the array buffers and know where
	// the separators are and which bytes have been consumed.
	let buffer: Array[U8] val
	var position: USize = 0 // current position
	let _separators: Array[USize] val
	var separator_idx: USize
	let _uid: USize

	new create(uid: USize, buffer': Array[U8] val, separators': Array[USize] val) =>
		_uid = uid
		buffer = buffer'
		position = 0
		separator_idx = 0
		_separators = separators'

	fun box consumed(): Bool =>
		position >= buffer.size()

	fun box copy_to(): (USize, Bool) =>
		if separator_idx >= _separators.size() then
			(buffer.size(), false)
		else
			try (_separators(separator_idx)?, true) else (0, true) end
		end

	fun box string(): String iso^ =>
		let result: String iso = recover String end
		result.append("index = ")
		result.append(Format.int[USize](_uid where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", size = ")
		result.append(Format.int[USize](buffer.size() where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", position = ")
		result.append(Format.int[USize](position where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", separator_idx = ")
		result.append(Format.int[USize](separator_idx where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", separators = [")
		var first = true
		for sep in _separators.values() do
			if not first then result.append("; ") end
			result.append(Format.int[USize](sep where fmt=FormatHex))
			first = false
		end
		result.append("], [")
		first = true
		for b in buffer.values() do
			if not first then result.append(" ") end
			result.append(Format.int[U8](b where width=2, fmt=FormatHex, align=AlignRight, prec=2))
			first = false
		end
		result.append("]")
		result

class LineReader
	// The role of this class is to contain the external interface
	let _buffer: List[BufferElement] = List[BufferElement]()
	var _available: USize = 0
	var _lines: USize = 0
	let _separator: Array[U8] val = [0xd;0xa]
	var _uid: USize = 0

	fun ref apply(arr: Array[U8] val) =>
		// if there's the beginning of a separator at the end of this `arr` then add it as an additional separator
		// count the number of bytes of the separator that are in the previous `arr`, look for the remaining
		// parts of the separator at the beginning of this `arr`, if found, increment the `position` to point to
		// beyond the separator. This may cause the `arr` to be consumed. Only push it into `_buffer` if not consumed.

		var sep = ArraySearch.indexes_of(arr, _separator)

		(let trailing_position, let trailing_length) = ArraySearch.trailing_prefix(arr, _separator)
		if (trailing_length > 0) and (trailing_length < _separator.size()) then
			sep = recover val
				let sep' = sep.clone()
				sep'.>push(trailing_position)
			end
		end

		let seperator_count = sep.size()
		let element = BufferElement.create(_uid, arr, sep)

		(let leading_position, let leading_length) = ArraySearch.leading_suffix(arr, _separator)
		if (leading_length > 0) and (leading_length < _separator.size()) then
			element.position = leading_length
		end

		if not element.consumed() then
			_buffer.push(element)
			_uid = _uid + 1
			_available = _available + arr.size()
			_lines = _lines + seperator_count
		end

		_dump_buffer_status()


	fun box _dump_buffer_status() =>
		var counter: USize = 0
		for b in _buffer.values() do
			@printf[None]("    %4d: %s\n".cstring(),
				counter, b.string().cstring()
			)
			counter = counter + 1
		end

	fun box available(): USize => _available

	fun box has_line(): Bool => _lines > 0

	fun box line_count(): USize =>
		"""
		returns the number of complete lines that can be read from the buffer.
		"""
		_lines

	fun ref read_line(): String =>
		@printf[None]("***************** start read_line *****************\n".cstring())
		_dump_buffer_status()
		try
			let s: String iso = recover iso String.create() end // TODO pre-calculate the expected size of the string.
			var current: BufferElement = _buffer.head()?()?
			@printf[None]("lines: %d, available: %d\n".cstring(), _lines, _available)
			while not current.consumed() do
				(let copy_to, let line) = current.copy_to()

				@printf[None]("%s\n".cstring(), current.string().cstring())
				@printf[None]("copy_from: %d, copy_to: %d, length: %d\n".cstring(), current.position, copy_to, copy_to-current.position)
				s.append(current.buffer, current.position, copy_to-current.position)
				@printf[None]("s: --%s--\n".cstring(), s.cstring())
				current.position = copy_to + _separator.size()
				current.separator_idx = current.separator_idx + 1
				if current.consumed() then
					@printf[None]("consumed...\n".cstring())
					_buffer.shift()?
					if _buffer.size() > 0 then
						current = _buffer.head()?()?
					end
				end
				if line then break end
			end
			_lines = _lines - 1
			_available = (_available - s.size()) - _separator.size()
			@printf[None]("lines: %d, available: %d\n".cstring(), _lines, _available)
			_dump_buffer_status()
			@printf[None]("***************** end read_line *****************\n".cstring())
			s
		else
			""
		end

	fun ref remaining(): Array[ByteSeq] val =>
		let size = _buffer.size()
		let result: Array[ByteSeq] iso = recover iso Array[ByteSeq](size) end
		for b in _buffer.values() do
			if b.position != 0 then
				result.push(recover val b.buffer.slice(b.position, b.buffer.size()) end)
			else
				result.push(b.buffer)
			end
		end
		_buffer.clear()
		_lines = 0
		_available = 0
		result

primitive ArraySearch
	// the role of this primitive is to encapsulate the array searching functions in a
	// easily testable way.

	fun index_of(haystack: Array[U8] val, needle: Array[U8] val, haystack_offset: USize = 0, needle_offset: USize = 0): USize =>
		"""
		returns the next index of the needle after offset.
		if needle does not exist then the result will be >= haystack.size()
		UB when haystack.size() == USize.max
		"""
		var haystack_idx: USize = haystack_offset
		var needle_idx: USize = needle_offset
		try
			while haystack_idx < haystack.size() do
				@printf[None]("h: %x n: %x hi: %d ni: %d\n".cstring(), haystack(haystack_idx)?, needle(needle_idx)?, haystack_idx, needle_idx)
				if haystack(haystack_idx)? == needle(needle_idx)? then
					if (needle_idx+1) >= needle.size() then
						@printf[None]("found with hi: %d, ni: %d, ns: %d\n".cstring(), haystack_idx, needle_idx, needle.size())
						return haystack_idx - (needle_idx - needle_offset)
					end
					needle_idx = needle_idx + 1
				else
					needle_idx = needle_offset // reset when not found
				end
				haystack_idx = haystack_idx + 1
			end
		end
		haystack_idx

	fun count_needles(haystack: Array[U8] val, needle: Array[U8] val): USize =>
		if haystack.size() < needle.size() then return 0 end
		indexes_of(haystack, needle).size()

	fun indexes_of(haystack: Array[U8] val, needle: Array[U8] val): Array[USize] val =>
		if haystack.size() < needle.size() then return [as USize: ] end
		let result: Array[USize] iso = recover Array[USize]() end
		var haystack_idx: USize = 0
		while haystack_idx < haystack.size() do
			let found = ArraySearch.index_of(haystack, needle, haystack_idx)
			if found < haystack.size() then
				result.push(found)
			end
			haystack_idx = found + needle.size()
		end
		result

	fun leading_suffix(haystack: Array[U8] val, needle: Array[U8] val): (USize, USize) =>
		"""
		returned tuple entries:
			1: position in the needle for starting the needle suffix
			2: length of the needle suffix found

		note: probably does not need to return a tuple as given the size of the needle, one of the entries can be calculated from the other.
		"""
		if (haystack.size() == 0) or (needle.size() == 0) then return (0, 0) end
		for (needle_idx, unused) in needle.pairs() do
			let suffix = recover val needle.slice(needle_idx, needle.size()) end
			let ret = index_of(haystack, suffix)
			@printf[None]("needle idx: %d, needle size: %d, ret: %d\n".cstring(), needle_idx, needle.size(), ret)
			if ret == 0 then
				return (needle_idx, suffix.size())
			end
		end
		(0, 0)

	fun trailing_prefix(haystack: Array[U8] val, needle: Array[U8] val): (USize, USize) =>
		"""
		returned tuple entries:
			1: position in the haystack for starting the needle prefix
			2: length of the needle found

		note: probably does not need to return a tuple as given the size of the needle and size of the haystack, one of the entries can be calculated from the other.
		"""
		if (haystack.size() == 0) or (needle.size() == 0) then return (0, 0) end
		for (needle_idx, unused) in needle.pairs() do
			let prefix = recover val needle.slice(0, needle.size()-needle_idx) end
			let ret = index_of(haystack, prefix, haystack.size()-prefix.size())
			var offset = haystack.size()-prefix.size()
			@printf[None]("needle idx: %d, needle size: %d, ret: %d, prefix size: %d, haystack offset: %d\n".cstring(), needle_idx, needle.size(), ret, prefix.size(), offset)
			if offset >= haystack.size() then continue end // offset can be "-ive" when haystack.size() < needle.size() (note that given the numbers are all unsigned, offset will be very large, hence the >=)

			if ret == offset then
				return (offset, prefix.size())
			end
		end
		(0, 0)




