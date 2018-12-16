use "../../text-reader"
use "net"


actor Main
	new create(env: Env) =>
		try
			TCPListener(
					env.root as AmbientAuth,
					recover SimpleListen end, "localhost", "6543"
			)
		end

class SimpleListen is TCPListenNotify
	fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
		SimpleNotify

	fun ref not_listening(listen: TCPListener ref) =>
		None

class SimpleNotify is TCPConnectionNotify
	let _reader: LineReader = LineReader
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
		@printf[None]("Received data; size: %d\n".cstring(), data.size())
		_reader.apply(consume data)
		while _reader.has_line() do
			_payload.add_line(_reader.read_line())
			if _payload.complete() then
				_dispatch(_payload = Payload.empty())
				break
			end
		end
		true

	fun _dispatch(payload: Payload val) =>
		@printf[None]("Complete payload\n".cstring())
		@printf[None]("lines:\n".cstring())
		for (idx, line) in payload.lines.pairs() do
			@printf[None]("%d => %s\n".cstring(), idx, line.cstring())
		end

class Payload
	let lines: Array[String val] = Array[String val].create()
	var _complete: Bool = false

	new trn empty() =>
		None

	fun ref add_line(line: String val) =>
		if line.size() == 0 then
			_complete = true
		else
			lines.push(line)
		end

	fun complete(): Bool =>
		_complete



