defmodule AwsCredentials.Providers.EnvironmentTest do
  use ExUnit.Case, async: true

  alias AwsCredentials.Credentials

  setup do
    all_vars = [
      "AWS_ACCESS_KEY_ID",
      "AWS_SECRET_ACCESS_KEY",
      "AWS_SESSION_TOKEN",
      "AWS_SECURITY_TOKEN",
      "AWS_DEFAULT_REGION",
      "AWS_REGION"
    ]

    Enum.each(all_vars, fn var -> System.delete_env(var) end)

    System.put_env("AWS_ACCESS_KEY_ID", "test-access-key")
    System.put_env("AWS_SECRET_ACCESS_KEY", "test-secret-access-key")
    System.put_env("AWS_SESSION_TOKEN", "test-session-token")
    System.put_env("AWS_DEFAULT_REGION", "us-west-2")
  end

  test "fetches credentials from environment variables" do
    {:ok,
     %Credentials{
       AccessKeyId: "test-access-key",
       SecretAccessKey: "test-secret-access-key",
       Token: "test-session-token",
       Region: "us-west-2",
       Expiration: nil
     }} = AwsCredentials.Providers.Environment.fetch()
  end

  test "returns value of AWS_REGION when AWS_REGION and AWS_DEFAULT_REGION are provided" do
    System.put_env("AWS_REGION", "us-east-1")

    {:ok, %Credentials{Region: "us-east-1"}} = AwsCredentials.Providers.Environment.fetch()
  end

  test "returns value of AWS_SECURITY_TOKEN when AWS_SESSION_TOKEN and AWS_SECURITY_TOKEN are provided" do
    System.put_env("AWS_SECURITY_TOKEN", "test-security-token")

    {:ok, %Credentials{Token: "test-security-token"}} =
      AwsCredentials.Providers.Environment.fetch()
  end

  test "returns error when AWS_REGION and AWS_DEFAULT_REGION are missing" do
    System.delete_env("AWS_REGION")
    System.delete_env("AWS_DEFAULT_REGION")

    {:error, "AWS_DEFAULT_REGION or AWS_REGION not found"} =
      AwsCredentials.Providers.Environment.fetch()
  end

  test "returns error when AWS_ACCESS_KEY_ID is missing" do
    System.delete_env("AWS_ACCESS_KEY_ID")

    {:error, "AWS_ACCESS_KEY_ID not found"} = AwsCredentials.Providers.Environment.fetch()
  end
end
