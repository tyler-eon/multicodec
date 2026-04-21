defmodule MulticodecTest do
  use ExUnit.Case

  describe "get/1" do
    test "returns codec metadata by integer code" do
      result = Multicodec.get(0x00)
      assert result.name == "identity"
      assert result.code == 0x00
      assert result.tag == "multihash"
      assert result.status == "permanent"
    end

    test "returns codec metadata by name" do
      result = Multicodec.get("identity")
      assert result.name == "identity"
      assert result.code == 0x00
    end

    test "name lookup and code lookup return the same result" do
      assert Multicodec.get(0x12) == Multicodec.get("sha2-256")
      assert Multicodec.get(0x71) == Multicodec.get("dag-cbor")
      assert Multicodec.get(0x55) == Multicodec.get("raw")
    end

    test "returns nil for unknown codec" do
      assert Multicodec.get(0xFFFFFF) == nil
      assert Multicodec.get("nonexistent-codec") == nil
    end

    test "returns correct metadata for sha2-256" do
      result = Multicodec.get("sha2-256")
      assert result.code == 0x12
      assert result.prefix == <<18>>
      assert result.tag == "multihash"
    end

    test "returns correct metadata for cidv1" do
      result = Multicodec.get("cidv1")
      assert result.code == 0x01
      assert result.prefix == <<1>>
      assert result.tag == "cid"
    end

    test "returns correct metadata for dag-cbor" do
      result = Multicodec.get("dag-cbor")
      assert result.code == 0x71
      assert result.tag == "ipld"
    end

    test "returns correct prefix for multi-byte varint codec" do
      result = Multicodec.get("sha2-256-trunc254-padded")
      assert result.code == 0x1012
      # 0x1012 encoded as LEB128 varint is <<146, 32>>
      assert result.prefix == <<146, 32>>
    end
  end

  describe "encode/2" do
    test "encodes binary data with a codec name" do
      data = "hello"
      {:ok, encoded} = Multicodec.encode(data, "identity")
      assert encoded == <<0>> <> data
    end

    test "encodes binary data with a codec integer" do
      data = "hello"
      {:ok, encoded} = Multicodec.encode(data, 0x00)
      assert encoded == <<0>> <> data
    end

    test "returns :error for unknown codec" do
      assert Multicodec.encode("hello", "nonexistent") == :error
    end

    test "encodes with sha2-256 codec prefix" do
      data = <<1, 2, 3>>
      {:ok, encoded} = Multicodec.encode(data, "sha2-256")
      assert encoded == <<18, 1, 2, 3>>
    end

    test "encodes with multi-byte varint prefix" do
      data = <<1, 2, 3>>
      {:ok, encoded} = Multicodec.encode(data, "sha2-256-trunc254-padded")
      assert encoded == <<146, 32, 1, 2, 3>>
    end
  end

  describe "encode!/2" do
    test "returns encoded binary directly" do
      data = "hello"
      encoded = Multicodec.encode!(data, "identity")
      assert encoded == <<0>> <> data
    end

    test "raises on unknown codec" do
      assert_raise MatchError, fn ->
        Multicodec.encode!("hello", "nonexistent")
      end
    end
  end

  describe "decode/1" do
    test "decodes identity-prefixed data" do
      data = <<0, "hello">>
      assert {:ok, {"identity", "hello"}} = Multicodec.decode(data)
    end

    test "decodes sha2-256-prefixed data" do
      data = <<18, 1, 2, 3>>
      assert {:ok, {"sha2-256", <<1, 2, 3>>}} = Multicodec.decode(data)
    end

    test "decodes multi-byte varint prefix" do
      data = <<146, 32, 1, 2, 3>>
      assert {:ok, {"sha2-256-trunc254-padded", <<1, 2, 3>>}} = Multicodec.decode(data)
    end

    test "returns error for unknown codec" do
      # Use a prefix that doesn't match any known codec
      data = <<255, 255, 255, 127, 1, 2, 3>>
      assert {:error, _} = Multicodec.decode(data)
    end

    test "roundtrip encode then decode" do
      original = "test data"
      {:ok, encoded} = Multicodec.encode(original, "raw")
      {:ok, {"raw", decoded}} = Multicodec.decode(encoded)
      assert decoded == original
    end
  end
end
