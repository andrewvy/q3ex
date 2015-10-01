defmodule Q3exTest do
  use ExUnit.Case

  test "Connects to server" do
    addr = '66.160.179.212'
    port = 27960
    {:ok, client} = Q3ex.start(addr, port)
  end
end
