use "collections"




class _BufferElement
	let _buffer: Array[U8] val
	let _offsets: Array[USize] val
	var _current: USize = 0 // index into _offsets

	new create(buffer: Array[U8] val) =>
		_buffer = buffer
		_offsets = recover val Array[USize]() end

	fun append_to(str: String iso): (String iso, Bool) =>
		"""
		returns the string that was appended to; true if we read to an end-of-line
		"""
		(consume str, false)
	// is_consumed(): Bool

	fun remaining(): USize =>
		"""
		number of bytes remaining to be read in the _buffer.
		"""
		0

class LineReader
	let _buffer: List[_BufferElement] = List[_BufferElement]()
	var _available: USize = 0
	var _lines: USize = 0
	let _separator: Array[U8] val = [0x13;0x10]

	fun ref apply(arr: Array[U8] val) =>
		_buffer.push(_BufferElement.create(arr))
		_available = _available + arr.size()
		// 
		_lines = _lines + ArraySearch.count_needles(arr, _separator)

	fun box available(): USize => _available

	fun box has_line(): Bool => _lines > 0

	fun box line_count(): USize => _lines

	fun ref read_line(): String =>
//		try
//			var str: String iso = recover iso String(42) end // TODO pre-calculate the size.
//			var current = _buffer.head()?.apply()?
//			(str, let next: Bool) = current.append_to(str)
//			consume str
//		else
			""
//		end

primitive ArraySearch

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
		var count: USize = 0
		var haystack_idx: USize = 0
		while haystack_idx < haystack.size() do
			let found = ArraySearch.index_of(haystack, needle, haystack_idx)
			if found < haystack.size() then
				count = count + 1
			end
			haystack_idx = found + needle.size()
		end
		count

