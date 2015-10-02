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

  def handle_cast({:msg_receive, packet}, state) do
    case packet do
      [255, 255, 255, 255 | rest] ->
        {event, cvar_list, formatted_players} = parse_get_status(rest)

        new_state = %{
          connection: state.connection,
          poll_rate: state.poll_rate,
          player_list: formatted_players,
          cvar_list: cvar_list
        }

        GenServer.cast(self, :poll)

        {:noreply, new_state}

      _ -> {:noreply, state}
    end
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

  def handle_cast(:poll, state) do
    send state.connection, {:get_status}

    parent_process = self

    spawn fn ->
      :timer.sleep(state.poll_rate)
      GenServer.cast(parent_process, :poll)
    end

    {:noreply, state}
  end

  def handle_call({:connect, address, port}, from, state) do
    case start_connection({self, address, port}) do
      {:ok, connection} ->
        Process.link(connection)
        new_state = %{
          connection: connection,
          poll_rate: state.poll_rate,
          player_list: state.player_list,
          cvar_list: state.cvar_list
        }

        {:reply, {:ok, self}, new_state}

      {:err} -> {:reply, {:err}, state}
    end
  end

  def handle_call(:get_status, from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call(request, from, state) do
    super request, from, state
  end

  def handle_info(request, state) do
    {:noreply, state}
  end

  # PACKET HANDLE

  def parse_get_status(packet) do
    [event, cvars | players] = String.split(to_string(packet), "\n", trim: true)
    cvar_list = String.split(cvars, "\\", trim: true) |> Enum.chunk(2) |> Enum.map(fn (elem) -> List.to_tuple(elem) end)

    formatted_players = Enum.map players, fn (player) ->
      String.replace(player, ~r/"(.+)"/, "\\1\\") |> String.replace("^w*ES*", "") |> String.replace("\\", "") |> String.split()
    end

    {event, cvar_list, formatted_players}
  end
end
