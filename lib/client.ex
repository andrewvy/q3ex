defmodule Q3ex.Client do
  use GenServer

  @get_status_packet <<255, 255, 255, 255>> <> "getstatus"

  def start_link(address, port) do
    {:ok, client} = GenServer.start_link(__MODULE__, {})
    GenServer.call(client, {:connect, address, port})
  end

  def get_status(pid) do
    GenServer.call(pid, {:get_status, 1234})
  end

  # SERVER

  def start_connection({client, address, port}) do
    ip = Q3ex.Connection.parse_ip(address)
    Q3ex.Connection.connect({client, ip, port})
  end

  def init(_args) do
    state = %{
      connection: nil,
      poll_rate: 500,
      player_list: [],
      cvar_list: []
    }

    {:ok, state}
  end

  def handle_cast({:msg_receive, binary}, state) do
    IO.puts "RECEIVED"
    {:noreply, state}
  end

  def handle_cast({:set_poll_rate, poll_rate}, state) do
    new_state = %{
      connection: state.connection,
      poll_rate: poll_rate,
      player_list: state.player_list,
      cvar_list: state.cvar_list
    }

    {:noreply, new_state}
  end

  def handle_call({:connect, address, port}, from, state) do
    {:ok, connection} = start_connection({self, address, port})
    Process.link(connection)

    new_state = %{
      connection: connection,
      poll_rate: state.poll_rate,
      player_list: state.player_list,
      cvar_list: state.cvar_list
    }

    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call(:get_status, from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call(request, from, state) do
    super request, from, state
  end


  def handle_info(request, state) do
    IO.puts request
  end

  # SOCKET

  def setup_socket(port) do
    :gen_udp.open(port, [])
  end

  def recv(socket, length) do

  end
end
