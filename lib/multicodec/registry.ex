defmodule Multicodec.Registry do
  @moduledoc """
  A runtime registry for associating handler modules with known codecs.

  The registry does **not** allow defining new codecs — every codec must
  already exist in the compiled `Multicodec` module (generated from the
  multicodec CSV table). The registry only lets you attach a handler module
  to an existing codec so that higher-level libraries can dispatch
  encode/decode calls through a single entrypoint.

  Handler modules should implement the `Multicodec.Codec` behaviour.

  Backed by `:persistent_term` for near-zero-cost lookups.

  ## Usage

  Register a handler at application startup (e.g. in your `Application.start/2`):

      Multicodec.Registry.register("dag-cbor", MyApp.DagCbor)

  After registration, retrieve the handler:

      {:ok, MyApp.DagCbor} = Multicodec.Registry.fetch_handler("dag-cbor")

  ## Batch registration

      Multicodec.Registry.register_all(%{
        "dag-cbor" => MyApp.DagCbor,
        "dag-json" => MyApp.DagJson
      })
  """

  @registry_key {__MODULE__, :handlers}

  @doc """
  Registers a handler module for a known codec.

  The `codec` can be a codec name (string) or integer code. It must be
  recognized by `Multicodec.get/1` or registration will fail.

  Returns `:ok` on success or `{:error, :unknown_codec}` if the codec
  is not in the compiled codec table.
  """
  @spec register(binary() | integer(), module()) :: :ok | {:error, :unknown_codec}
  def register(codec, module) when is_atom(module) do
    case Multicodec.get(codec) do
      nil ->
        {:error, :unknown_codec}

      %{name: name} ->
        handlers = Map.put(get_handlers(), name, module)
        :persistent_term.put(@registry_key, handlers)
        :ok
    end
  end

  @doc """
  Registers handler modules for multiple known codecs.

  Accepts a map of `codec_name_or_code => module` pairs. All codecs are
  validated before any are registered — if any codec is unknown, no changes
  are made.

  Returns `:ok` on success or `{:error, {:unknown_codec, codec}}` identifying
  the first unrecognized codec.
  """
  @spec register_all(%{(binary() | integer()) => module()}) :: :ok | {:error, {:unknown_codec, binary() | integer()}}
  def register_all(entries) when is_map(entries) do
    # Validate all codecs first.
    resolved =
      Enum.reduce_while(entries, {:ok, []}, fn {codec, module}, {:ok, acc} ->
        case Multicodec.get(codec) do
          nil -> {:halt, {:error, {:unknown_codec, codec}}}
          %{name: name} -> {:cont, {:ok, [{name, module} | acc]}}
        end
      end)

    case resolved do
      {:error, _} = err ->
        err

      {:ok, pairs} ->
        handlers =
          Enum.reduce(pairs, get_handlers(), fn {name, module}, acc ->
            Map.put(acc, name, module)
          end)

        :persistent_term.put(@registry_key, handlers)
        :ok
    end
  end

  @doc """
  Fetches the handler module for a codec by name.

  Returns `{:ok, module}` or `:error` if no handler is registered.
  """
  @spec fetch_handler(binary()) :: {:ok, module()} | :error
  def fetch_handler(name) when is_binary(name) do
    case Map.get(get_handlers(), name) do
      nil -> :error
      module -> {:ok, module}
    end
  end

  @doc """
  Gets the handler module for a codec by name, or `nil` if none is registered.
  """
  @spec get_handler(binary()) :: module() | nil
  def get_handler(name) when is_binary(name) do
    Map.get(get_handlers(), name)
  end

  @doc """
  Returns all registered handler associations as a map of `%{name => module}`.
  """
  @spec all() :: %{binary() => module()}
  def all do
    get_handlers()
  end

  @doc """
  Removes all handler registrations.
  """
  @spec clear() :: :ok
  def clear do
    :persistent_term.put(@registry_key, %{})
    :ok
  end

  defp get_handlers do
    :persistent_term.get(@registry_key, %{})
  end
end
