defmodule AwsCredentials.Providers.EC2 do
  @moduledoc """
  Module that fetches AWS credentials for an application that runs on EC2 instance.

  Docs: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
  """

  @credentials_url "http://169.254.169.254/latest/meta-data/iam/security-credentials/"
  @document_url "http://169.254.169.254/latest/dynamic/instance-identity/document"
  @hackney_options [:with_body, {:recv_timeout, 3000}, {:connect_timeout, 3000}]

  @behaviour AwsCredentials.ProviderBehaviour

  alias AwsCredentials.Credentials

  @impl true
  def fetch do
    with {:ok, role} <- fetch_role(),
         {:ok, metadata} <- fetch_metadata(role),
         {:ok, document} <- fetch_document() do
      expiration = metadata["Expiration"] |> DateTime.from_iso8601() |> elem(1)

      %Credentials{
        AccessKeyId: metadata["AccessKeyId"],
        SecretAccessKey: metadata["SecretAccessKey"],
        Token: metadata["Token"],
        Region: document["region"],
        Expiration: expiration
      }
    else
      error -> error
    end
  end

  defp fetch_role do
    case :hackney.request(:get, @credentials_url, [], "", @hackney_options) do
      {:ok, 200, _, role} -> {:ok, role}
      error -> handle_error(error)
    end
  end

  defp fetch_metadata(role) do
    case :hackney.request(:get, @credentials_url <> role, [], "", @hackney_options) do
      {:ok, 200, _, metadata} -> {:ok, Jason.decode!(metadata)}
      error -> handle_error(error)
    end
  end

  defp fetch_document do
    case :hackney.request(:get, @document_url, [], "", @hackney_options) do
      {:ok, 200, _, document} -> {:ok, Jason.decode!(document)}
      error -> handle_error(error)
    end
  end

  defp handle_error(error) do
    case error do
      {:ok, status_code, _, body} -> {:error, status_code, body}
      err -> err
    end
  end
end
