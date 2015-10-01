defmodule Q3ex do
  def start(addr, port) do
    Q3ex.Client.start_link(addr, port)
  end

  def get_status(pid) do
    GenServer.call(pid, :get_status)
  end

  def set_poll_rate(pid, poll_rate) do
    GenServer.cast(pid, {:set_poll_rate, poll_rate})
  end
end
