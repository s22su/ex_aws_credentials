defmodule AwsCredentials.Providers.Environment do
  @moduledoc """
  Module that fetches AWS credentials from environment variables.

  When multiple environment variables are provided for the same credential,
  the value of the last one in the list will be used.
  """

  @behaviour AwsCredentials.ProviderBehaviour

  alias AwsCredentials.Credentials

  @env_access ["AWS_ACCESS_KEY_ID"]
  @env_secret ["AWS_SECRET_ACCESS_KEY"]
  @env_session ["AWS_SESSION_TOKEN", "AWS_SECURITY_TOKEN"]
  @env_region ["AWS_DEFAULT_REGION", "AWS_REGION"]

  @credentials_env_vars_mapping %{
    aws_access_key_id: %{env_vars: @env_access},
    aws_secret_access_key: %{env_vars: @env_secret},
    aws_token: %{env_vars: @env_session},
    aws_region: %{env_vars: @env_region}
  }

  @impl true
  def fetch do
    credentials_map = fetch_from_env()
    first_missing_credential = find_first_missing_credential(credentials_map)

    if first_missing_credential do
      {_, %{env_vars: missing_env_vars}} = first_missing_credential

      {:error, Enum.join(missing_env_vars, " or ") <> " not found"}
    else
      %Credentials{
        AccessKeyId: fetch_credential_value(credentials_map, :aws_access_key_id),
        SecretAccessKey: fetch_credential_value(credentials_map, :aws_secret_access_key),
        Token: fetch_credential_value(credentials_map, :aws_token),
        Region: fetch_credential_value(credentials_map, :aws_region),
        Expiration: nil
      }
    end
  end

  defp fetch_from_env() do
    @credentials_env_vars_mapping
    |> Enum.map(fn {credential, %{env_vars: env_vars}} ->
      %{credential => %{env_vars: env_vars, value: get_env(env_vars)}}
    end)
    |> Enum.reduce(&Map.merge/2)
  end

  defp fetch_credential_value(credentials_map, credential) do
    credentials_map
    |> Map.get(credential)
    |> Map.get(:value)
  end

  defp get_env(var_list) do
    get_env(var_list, nil)
  end

  defp get_env([var | tail], current_value) do
    new_value = get_value(var) || current_value

    get_env(tail, new_value)
  end

  defp get_env([], current_value) when is_binary(current_value) do
    current_value
  end

  defp get_env([], current_value) when is_nil(current_value) do
    :not_found
  end

  defp get_value(var) do
    System.get_env(var, nil)
  end

  defp find_first_missing_credential(credentials_map) do
    Enum.find(credentials_map, fn {_, %{value: value}} -> value == :not_found end)
  end
end
