defmodule WhatsappCloudApiWrapperTest do
  use ExUnit.Case
  doctest WhatsappCloudApiWrapper

  test "greets the world" do
    assert WhatsappCloudApiWrapper.hello() == :world
  end
end
