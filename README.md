# Multicodec

An Elixir implementation of the [multicodec](https://github.com/multiformats/multicodec) specification — a self-describing codec identifier table and the composition layer for the multiformats ecosystem.

Multicodec assigns a unique varint-prefixed code to every codec, hash algorithm, serialization format, and addressing scheme in the multiformats universe. This library provides:

- A **built-in compendium** of codec entries generated from the [official multicodec table](https://github.com/multiformats/multicodec/blob/master/table.csv)
- **Encode/decode** functions for prepending and stripping varint-prefixed codec identifiers
- A **runtime registry** for extending the codec table with custom entries
- A **`Codec` behaviour** for libraries that implement data serialization codecs

## Usage

### Looking up codecs

Look up a codec by its integer code or human-readable name:

```elixir
Multicodec.get(0x12)
# => %{code: 0x12, prefix: <<18>>, name: "sha2-256", ...}

Multicodec.get("dag-cbor")
# => %{code: 0x71, prefix: "q", name: "dag-cbor", ...}
```

### Encoding

Prepend a codec's varint-encoded identifier to binary data:

```elixir
{:ok, encoded} = Multicodec.encode(<<1, 2, 3>>, "sha2-256")
# => {:ok, <<18, 1, 2, 3>>}

encoded = Multicodec.encode!(<<1, 2, 3>>, "sha2-256")
# => <<18, 1, 2, 3>>
```

### Decoding

Strip the varint prefix and identify the codec:

```elixir
{:ok, {"sha2-256", <<1, 2, 3>>}} = Multicodec.decode(<<18, 1, 2, 3>>)
```

### Parsing prefixes

Extract the codec metadata and remaining bytes from a binary:

```elixir
{%{name: "dag-cbor", code: 0x71, ...}, rest} = Multicodec.parse_prefix(binary)
```

## Runtime Registry

The codec table is fixed at compile time — you cannot define new codecs at runtime. However, you can register **handler modules** for existing codecs. This lets higher-level libraries dispatch encode/decode calls through a central entrypoint.

Handler modules should implement the `Multicodec.Codec` behaviour:

```elixir
defmodule MyApp.DagCbor do
  @behaviour Multicodec.Codec

  @impl true
  def encode(data, _opts), do: # ...

  @impl true
  def decode(data, _opts), do: # ...

  @impl true
  def decode!(data, _opts), do: # ...
end
```

Then register it against a known codec name:

```elixir
:ok = Multicodec.Registry.register("dag-cbor", MyApp.DagCbor)

{:ok, MyApp.DagCbor} = Multicodec.Registry.fetch_handler("dag-cbor")
```

Registration fails if the codec name isn't in the compiled table:

```elixir
{:error, :unknown_codec} = Multicodec.Registry.register("nonexistent", MyApp.Foo)
```

Register multiple handlers at once with `Multicodec.Registry.register_all/1` — the entire batch is validated before any are stored. See the `Multicodec.Registry` module documentation for the full API.

## Regenerating the codec table

The built-in codec entries are generated from a CSV file using a Mix task:

```sh
mix multicodec.gen path/to/table.csv -o lib
```

This reads the CSV and writes a new `multicodec.ex` module with compiled function heads for every entry. You can use the official table or a custom one.

## Related behaviours

The `Multicodec.Codec` behaviour defines the encode/decode interface that handler modules should implement. For base encoding modules, see the `Multibase.Codec` behaviour in the [multibase](https://github.com/tyler-eon/multibase) library. For hash algorithm modules, see the `Multihash.Algorithm` behaviour in the [multihash](https://github.com/tyler-eon/multihash) library.

## Ecosystem

Multicodec is the composition layer for a family of Elixir multiformats libraries:

| Library | Purpose |
|---------|---------|
| **multicodec** (this library) | Codec identifier table and runtime registry |
| [multibase](https://github.com/tyler-eon/multibase) | Self-describing base encodings |
| [multihash](https://github.com/tyler-eon/multihash) | Self-describing hash digests |
| [cid](https://github.com/tyler-eon/cid) | Content Identifiers (CIDv0 and CIDv1) |
