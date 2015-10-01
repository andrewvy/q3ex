defmodule Q3ex.Connection do
  def connect({client_pid, addr, port})do
    {:ok, socket} = :gen_udp.open(port, [])

    bin = <<255, 255, 255, 255>> <> "getstatus"
    :gen_udp.send(socket, addr, port, bin)

    receive do
      {udp, socket, host, port, binary} = msg ->
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
      {udp, socket, host, port, binary} = msg ->
        GenServer.cast client_pid, {:msg_receive, binary}
        loop({client_pid, socket, addr, port})
      {:send, bin} ->
        :gen_udp.send(socket, addr, port, bin)
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
