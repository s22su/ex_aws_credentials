defmodule AwsCredentials.ProviderBehaviour do
  @moduledoc false

  alias AwsCredentials.Credentials

  @callback fetch() ::
              {:ok, Credentials.t()} | {:error, any()} | {:error, Integer.t(), String.t()}
end
