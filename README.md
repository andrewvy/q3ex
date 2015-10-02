Q3ex
====

[WIP] Quake 3 Server Status API in Elixir

# Using

```elixir
	addr = 'IP_HERE'
	port = PORT_INT
	{:ok, client} = Q3ex.start(addr, port)
```

`Q3ex.get_status(client)` -> Returns current status of the server.

`Q3ex.set_poll_rate(client, int)` -> Sets the polling rate of the client to the server
