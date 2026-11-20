defmodule RcCarWs.ProtocolTest do
  use ExUnit.Case, async: true

  alias RcCarWs.Protocol

  test "accepts motor set messages" do
    assert {:ok, %{"type" => "motor_set", "left" => 1, "right" => -1}} =
             Protocol.decode(~s({"type":"motor_set","left":1,"right":-1}))
  end

  test "accepts motor state messages" do
    assert {:ok, %{"type" => "motor_state", "left" => 0, "right" => 0}} =
             Protocol.decode(~s({"type":"motor_state","left":0,"right":0}))
  end

  test "accepts shared VDO.Ninja view messages" do
    assert {:ok, %{"type" => "vdo_view_set", "url" => "https://vdo.ninja/?view=car"}} =
             Protocol.decode(~s({"type":"vdo_view_set","url":"https://vdo.ninja/?view=car"}))
  end

  test "rejects motor values outside the direction range" do
    assert {:error, :invalid_message} =
             Protocol.decode(~s({"type":"motor_set","left":2,"right":0}))
  end

  test "rejects the removed GPIO messages" do
    assert {:error, :invalid_message} =
             Protocol.decode(~s({"type":"gpio_set","channel":"d0","value":true}))
  end
end
