defmodule Multicodec.CodecTest do
  use ExUnit.Case

  defmodule TestCodec do
    use Multicodec.Codec

    @impl true
    def encode(data, _opts), do: "encoded:" <> data

    @impl true
    def decode(data, _opts), do: {:ok, "decoded:" <> data}

    @impl true
    def decode!(data, _opts), do: "decoded:" <> data
  end

  defmodule TestMultihashCodec do
    use Multicodec.Codec, multihash: true

    @impl true
    def encode(data, _opts), do: "hashed:" <> data
  end

  describe "Codec behaviour with use" do
    test "generates 1-arity encode/1 that delegates to encode/2" do
      assert TestCodec.encode("hello") == "encoded:hello"
    end

    test "generates 1-arity decode/1 that delegates to decode/2" do
      assert TestCodec.decode("hello") == {:ok, "decoded:hello"}
    end

    test "generates 1-arity decode!/1 that delegates to decode!/2" do
      assert TestCodec.decode!("hello") == "decoded:hello"
    end
  end

  describe "Codec behaviour with multihash: true" do
    test "generates encode/1" do
      assert TestMultihashCodec.encode("hello") == "hashed:hello"
    end

    test "decode/2 raises" do
      assert_raise RuntimeError, "Multihash codecs do not support decoding.", fn ->
        TestMultihashCodec.decode("hello")
      end
    end

    test "decode!/2 raises" do
      assert_raise RuntimeError, "Multihash codecs do not support decoding.", fn ->
        TestMultihashCodec.decode!("hello")
      end
    end
  end
end
