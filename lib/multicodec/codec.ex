defmodule Multicodec.Codec do
  @moduledoc """
  A behaviour that defines common encode/decode operations for data codecs.

  This is a general-purpose behaviour for modules that transform binary data
  in both directions (encode and decode). It is suitable for serialization
  formats (e.g. DAG-CBOR, Protobuf) or any other codec that can be identified
  by a multicodec entry.

  For base encoding modules, see `Multibase.Codec` instead.
  For hash algorithm modules, see `Multihash.Algorithm` instead.

  ## Usage

  You can either declare `@behaviour Multicodec.Codec` directly, or
  `use Multicodec.Codec` to get auto-generated 1-arity wrappers.

  ## Example

      defmodule MyApp.DagJson do
        @behaviour Multicodec.Codec

        @impl true
        def encode(data, _opts), do: Jason.encode!(data)

        @impl true
        def decode(data, _opts) do
          case Jason.decode(data) do
            {:ok, term} -> {:ok, term}
            {:error, _} = err -> err
          end
        end

        @impl true
        def decode!(data, _opts), do: Jason.decode!(data)
      end
  """

  @doc """
  Encodes binary data with a set of optional arguments.
  """
  @callback encode(binary(), any()) :: binary()

  @doc """
  Decodes binary data, returning `{:ok, binary()}` if successful or `{:error, atom()}` if not.
  """
  @callback decode(binary(), any()) :: {:ok, binary()} | {:error, atom()}

  @doc """
  Decodes binary data, raising an error if the decoding fails.
  """
  @callback decode!(binary(), any()) :: binary()

  @doc """
  Adds the `@behaviour` attribute to the module and generates the 1-arity versions of the functions, which just call the 2-arity versions with an empty list for the second argument.

  You may optionally pass in `multihash: true` in the options argument to have `decode/2` and `decode!/2` stubs generated in the resulting code, with each one simply raising a runtime error. This is `false` by default, i.e. it is assumed this is not a `multihash` codec.
  """
  defmacro __using__(opts) do
    multihash = Keyword.get(opts, :multihash, false)

    quote do
      @behaviour Multicodec.Codec

      @doc """
      Encodes binary data using the default set of options.
      """
      def encode(data), do: encode(data, [])

      @doc """
      Decodes binary data using the default set of options.
      """
      def decode(data), do: decode(data, [])

      @doc """
      Decodes binary data using the default set of options, raising an error if the decoding fails.
      """
      def decode!(data), do: decode!(data, [])

      if unquote(multihash) do
        @doc """
        Not implemented.
        """
        def decode(_data, _opts), do: raise("Multihash codecs do not support decoding.")

        @doc """
        Not implemented.
        """
        def decode!(_data, _opts), do: raise("Multihash codecs do not support decoding.")
      end
    end
  end
end
