defmodule Multicodec.RegistryTest do
  use ExUnit.Case

  defmodule FakeCodec do
    @behaviour Multicodec.Codec

    @impl true
    def encode(data, _opts), do: "encoded:" <> data

    @impl true
    def decode(data, _opts), do: {:ok, "decoded:" <> data}

    @impl true
    def decode!(data, _opts), do: "decoded:" <> data
  end

  defmodule AnotherCodec do
    @behaviour Multicodec.Codec

    @impl true
    def encode(data, _opts), do: data

    @impl true
    def decode(data, _opts), do: {:ok, data}

    @impl true
    def decode!(data, _opts), do: data
  end

  setup do
    Multicodec.Registry.clear()
    on_exit(fn -> Multicodec.Registry.clear() end)
  end

  describe "register/2" do
    test "succeeds for a known codec by name" do
      assert :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
    end

    test "succeeds for a known codec by integer code" do
      assert :ok = Multicodec.Registry.register(0x71, FakeCodec)
    end

    test "fails for an unknown codec name" do
      assert {:error, :unknown_codec} = Multicodec.Registry.register("nonexistent-codec", FakeCodec)
    end

    test "fails for an unknown codec code" do
      assert {:error, :unknown_codec} = Multicodec.Registry.register(0xBEEF, FakeCodec)
    end

    test "handler is retrievable after registration" do
      :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
      assert {:ok, FakeCodec} = Multicodec.Registry.fetch_handler("dag-cbor")
    end

    test "registration by code stores under the codec name" do
      :ok = Multicodec.Registry.register(0x71, FakeCodec)
      assert {:ok, FakeCodec} = Multicodec.Registry.fetch_handler("dag-cbor")
    end

    test "re-registration replaces the previous handler" do
      :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
      :ok = Multicodec.Registry.register("dag-cbor", AnotherCodec)
      assert {:ok, AnotherCodec} = Multicodec.Registry.fetch_handler("dag-cbor")
    end
  end

  describe "register_all/1" do
    test "registers multiple handlers at once" do
      assert :ok = Multicodec.Registry.register_all(%{
        "dag-cbor" => FakeCodec,
        "raw" => AnotherCodec
      })

      assert {:ok, FakeCodec} = Multicodec.Registry.fetch_handler("dag-cbor")
      assert {:ok, AnotherCodec} = Multicodec.Registry.fetch_handler("raw")
    end

    test "accepts integer codes as keys" do
      assert :ok = Multicodec.Registry.register_all(%{
        0x71 => FakeCodec,
        0x55 => AnotherCodec
      })

      assert {:ok, FakeCodec} = Multicodec.Registry.fetch_handler("dag-cbor")
      assert {:ok, AnotherCodec} = Multicodec.Registry.fetch_handler("raw")
    end

    test "rejects entire batch if any codec is unknown" do
      assert {:error, {:unknown_codec, "nonexistent"}} =
        Multicodec.Registry.register_all(%{
          "dag-cbor" => FakeCodec,
          "nonexistent" => AnotherCodec
        })

      # dag-cbor should NOT have been registered either
      assert :error = Multicodec.Registry.fetch_handler("dag-cbor")
    end
  end

  describe "fetch_handler/1" do
    test "returns :error for unregistered codec" do
      assert :error = Multicodec.Registry.fetch_handler("dag-cbor")
    end

    test "returns {:ok, module} for registered codec" do
      :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
      assert {:ok, FakeCodec} = Multicodec.Registry.fetch_handler("dag-cbor")
    end
  end

  describe "get_handler/1" do
    test "returns nil for unregistered codec" do
      assert Multicodec.Registry.get_handler("dag-cbor") == nil
    end

    test "returns module for registered codec" do
      :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
      assert Multicodec.Registry.get_handler("dag-cbor") == FakeCodec
    end
  end

  describe "all/0" do
    test "returns empty map when nothing is registered" do
      assert Multicodec.Registry.all() == %{}
    end

    test "returns all registered handlers" do
      :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
      :ok = Multicodec.Registry.register("raw", AnotherCodec)
      assert Multicodec.Registry.all() == %{"dag-cbor" => FakeCodec, "raw" => AnotherCodec}
    end
  end

  describe "clear/0" do
    test "removes all handlers" do
      :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
      :ok = Multicodec.Registry.clear()
      assert Multicodec.Registry.all() == %{}
      assert :error = Multicodec.Registry.fetch_handler("dag-cbor")
    end
  end

  describe "Multicodec.get/1 does NOT fall back to registry" do
    test "get/1 returns nil for unknown codecs even with handlers registered" do
      :ok = Multicodec.Registry.register("dag-cbor", FakeCodec)
      # get/1 still returns built-in metadata, unaffected by registry
      assert %{name: "dag-cbor"} = Multicodec.get("dag-cbor")
      # unknown codec still returns nil
      assert Multicodec.get("nonexistent") == nil
    end
  end
end
