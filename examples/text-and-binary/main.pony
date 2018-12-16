use "../../text-reader"
use "net"


actor Main
	new create(env: Env) =>
		try
			TCPListener(
					env.root as AmbientAuth,
					recover SimpleMixtureListen end, "localhost", "6543"
			)
		end

class SimpleMixtureListen is TCPListenNotify
	fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
		SimpleMixtureNotify

	fun ref not_listening(listen: TCPListener ref) =>
		None

primitive _Text
primitive _Binary
type State is ( _Text | _Binary )

class SimpleMixtureNotify is TCPConnectionNotify
	let _reader: LineReader = LineReader
	var _state: State = _Text
	var _payload: Payload trn = Payload.empty()

	fun ref connected(conn: TCPConnection ref) =>
		None

	fun ref connect_failed(conn: TCPConnection ref) =>
		None
	
	fun ref received(
			conn: TCPConnection ref,
			data: Array[U8] iso,
			times: USize
			): Bool =>
		match _state
		| _Text =>
			_reader.apply(consume data)
			while _reader.has_line() do
				_payload.add_line(_reader.read_line())
				if _payload.text_complete() then
					_state = _Binary
					_payload.extend(_reader.remaining())
					if _payload.complete() then
						_dispatch(_payload = Payload.empty())
					end
					break
				end
			end
		| _Binary =>
			_payload.push(consume data)
			if _payload.complete() then
				_dispatch(_payload = Payload.empty())
			end
		end
		true

	fun _dispatch(payload: Payload val) =>
		@printf[None]("Complete payload\n".cstring())
		@printf[None]("data size: %d\n".cstring(), payload.size())
		@printf[None]("lines:\n".cstring())
		for (idx, line) in payload.lines.pairs() do
			@printf[None]("%d => %s\n".cstring(), idx, line.cstring())
		end

class Payload
	let lines: Array[String val] = Array[String val].create()
	let data: Array[ByteSeq val] = Array[ByteSeq val].create()
	var _size: USize = 0
	var _text_complete: Bool = false

	new trn empty() =>
		None

	fun text_complete(): Bool => _text_complete

	fun size(): USize => _size

	fun ref add_line(line: String val) =>
		if line.size() == 0 then
			_text_complete = true
		else
			lines.push(line)
		end

	fun ref extend(arr: Array[ByteSeq] val) =>
		for seq in arr.values() do
			data.push(seq)
			_size = _size + seq.size()
		end

	fun ref push(seq: ByteSeq val) =>
		data.push(seq)
		_size = _size + seq.size()

	fun complete(): Bool => true



