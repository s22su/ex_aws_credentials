defmodule AwsCredentials.Credentials do
  @moduledoc false

  @type t :: %__MODULE__{
          AccessKeyId: String.t(),
          SecretAccessKey: String.t(),
          Token: String.t(),
          Region: String.t(),
          Expiration: DateTime.t() | nil
        }

  defstruct [:AccessKeyId, :SecretAccessKey, :Token, :Region, :Expiration]
end
