use "collections"

/*

HTTP 1.0 client:

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
				// When `data` contains the start of the body beyond the \r\n
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


000000000011111111112222222222333333333344444444445555555555
012345678901234567890123456789012345678901234567890123456789

0000000000000000111111111111111122222222222222223333333333333333
0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
this.. is a good idea..really...

00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11
00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff 00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
74 68 69 73 0D 0A 20 69 73 20 61 20 67 6F 6F 64 20 69 64 65 61 0D 0A 72 65 61 6C 6C 79 2E 0D 0A
<-------------- first ------------------> <---- second ---------> <------- third ------------->

arr = first
available = 13
separators = [4]
lines = 1
separator_idx = 0
position = 0

readline ->
first.copy_to(out, 0, position, separators[separator_idx])
position = separators[separator_idx]
if arr(position) == 0D: position += 1
if arr(position) == 0A: position += 1
separator_idx += 1
lines -= 1





*/

class BufferElement
	// the role of this class is to contain the array buffers and know where
	// the separators are and which bytes have been consumed.
	let buffer: Array[U8] val
	var position: USize = 0 // current position
	let separators: Array[USize] val
	var separator_idx: USize

	new create(buffer': Array[U8] val, separators': Array[USize] val) =>
		buffer = buffer'
		position = 0
		separator_idx = 0
		separators = separators'

	fun box consumed(): Bool =>
		separator_idx >= separators.size()

	fun box copy_to(): USize =>
		try separators(separator_idx)? else 0 end

class LineReader
	// The role of this class is to contain the external interface
	let _buffer: List[BufferElement] = List[BufferElement]()
	var _available: USize = 0
	var _lines: USize = 0
	let _separator: Array[U8] val = [0x13;0x10]

	fun ref apply(arr: Array[U8] val) =>
		let sep = ArraySearch.indexes_of(arr, _separator)
		_buffer.push(BufferElement.create(arr, sep))
		_available = _available + arr.size()
		//
		_lines = _lines + sep.size()

	fun box available(): USize => _available

	fun box has_line(): Bool => _lines > 0

	fun box line_count(): USize =>
		"""
		returns the number of complete lines that can be read from the buffer.
		"""
		_lines

	fun ref read_line(): String =>
		try
			let s: String iso = recover iso String.create() end
			var current: BufferElement = _buffer.head()?()?
			@printf[None]("lines: %d, available: %d\n".cstring(), _lines, _available)
			while not current.consumed() do
				let copy_to = current.copy_to()
				@printf[None]("copy_to: %d\n".cstring(), copy_to)
				s.append(current.buffer, current.position, copy_to)
				@printf[None]("s: --%s--\n".cstring(), s.cstring())
				current.separator_idx = current.separator_idx + 1
				if current.consumed() then
					@printf[None]("consumed...\n".cstring())
					_buffer.shift()?
					if _buffer.size() > 0 then
						current = _buffer.head()?()?
					end
				end
			end
			_lines = _lines - 1
			_available = (_available - s.size()) - 2
			@printf[None]("lines: %d, available: %d\n".cstring(), _lines, _available)
			s
		else
			""
		end

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


