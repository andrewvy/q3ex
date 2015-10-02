defmodule Q3ex.Connection do
  @get_status_packet <<255, 255, 255, 255>> <> "getstatus"

  def connect({client_pid, addr, port})do
    {:ok, socket} = :gen_udp.open(port, [])

    :gen_udp.send(socket, addr, port, @get_status_packet)

    receive do
      {udp, socket, host, port, binary} ->
        GenServer.cast client_pid, {:msg_receive, binary}
        {:ok, spawn fn -> Q3ex.Connection.server({client_pid, socket, addr, port}) end}
      after 1000 ->
        {:err}
    end
  end

  def server({client_pid, socket, addr, port}) do
    loop({client_pid, socket, addr, port})
  end

  def loop({client_pid, socket, addr, port}) do
    receive do
      {udp, socket, host, port, binary} ->
        GenServer.cast client_pid, {:msg_receive, binary}
        loop({client_pid, socket, addr, port})
      {:send, bin} ->
        :gen_udp.send(socket, addr, port, bin)
        loop({client_pid, socket, addr, port})
      {:get_status} ->
        :gen_udp.send(socket, addr, port, @get_status_packet)
        loop({client_pid, socket, addr, port})
      _ -> #
    end
  end

  def parse_ip(address) do
    case :inet.parse_address(address) do
      {:ok, ip} ->
        ip
      {:error, :einval} ->
        nil
    end
  end
end
