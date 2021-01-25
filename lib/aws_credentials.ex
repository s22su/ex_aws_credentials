defmodule AwsCredentials do
  @moduledoc """
  GenServer that catches the fetched credendials and re-fetches them when they expire

  Usage:
    ```
    # Start the application with env provider
    {:ok, _pid} = AwsCredentials.start_link(provider: AwsCredentials.Providers.Environment)

    # Or start the application with EC2 provider
    {:ok, _pid} = AwsCredentials.start_link(provider: AwsCredentials.Providers.Environment, expiration_threshold: 600)

    # Fetch credentials whenever they are required by the application
    credentials = AwsCredentials.fetch()
  """

  use GenServer
  require Logger

  alias AwsCredentials.Credentials

  @default_provider AwsCredentials.Providers.Environment
  @default_expiration_threshold_sec 600

  def start_link(opts \\ []) do
    provider = Keyword.get(opts, :provider, @default_provider)

    expiration_threshold =
      Keyword.get(opts, :expiration_threshold, @default_expiration_threshold_sec)

    GenServer.start_link(
      __MODULE__,
      [provider: provider, expiration_threshold: expiration_threshold],
      name: __MODULE__
    )
  end

  @impl true
  def init(opts) do
    provider = Keyword.get(opts, :provider)
    expiration_threshold = Keyword.get(opts, :expiration_threshold)

    case fetch_new(provider) do
      {:ok, credentials} ->
        state = %{
          provider: provider,
          credentials: credentials,
          expiration_threshold: expiration_threshold
        }

        {:ok, state}

      error ->
        log_error(error)
        {:stop, :shutdown}
    end
  end

  def fetch() do
    case GenServer.call(__MODULE__, :fetch) do
      {:ok, credentials} ->
        {:ok, credentials}

      error ->
        log_error(error)
        GenServer.stop(__MODULE__, :shutdown)
    end
  end

  defp fetch_new(provider) do
    provider.fetch()
  end

  @impl true
  def handle_call(:fetch, _, %{provider: provider, credentials: credentials} = state) do
    if expired?(credentials, state) do
      case fetch_new(provider) do
        {:ok, new_credentials} ->
          new_state = Map.merge(state, %{credentials: new_credentials})

          {:reply, {:ok, new_credentials}, new_state}

        error ->
          {:reply, error, error}
      end
    else
      {:reply, {:ok, credentials}, state}
    end
  end

  defp log_error({:error, reason}) do
    Logger.error("Failed to fetch AWS credentials", reason: reason)
  end

  defp log_error({:error, status_code, reason}) do
    Logger.error("Failed to fetch AWS credentials", status_code: status_code, reason: reason)
  end

  defp expired?(%Credentials{Expiration: exp}, %{expiration_threshold: expiration_threshold}) do
    cond do
      is_nil(exp) ->
        false

      DateTime.diff(exp, DateTime.utc_now(), :second) <= expiration_threshold ->
        true

      true ->
        true
    end
  end
end
