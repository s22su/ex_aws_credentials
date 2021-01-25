defmodule AwsCredentialsTest do
  use ExUnit.Case

  import Mox
  alias AwsCredentials.Credentials

  @provider AwsCredentials.MockProvider

  setup :set_mox_global

  test "fetches credentials from cache when they don't expire" do
    expected_result =
      {:ok,
       %Credentials{
         AccessKeyId: "test-access-key",
         SecretAccessKey: "test-secret-access-key",
         Token: "test-session-token",
         Region: "us-west-2",
         Expiration: nil
       }}

    expect(@provider, :fetch, fn -> expected_result end)

    {:ok, _} = AwsCredentials.start_link(provider: @provider)
    assert expected_result == AwsCredentials.fetch()
    assert expected_result == AwsCredentials.fetch()
    assert expected_result == AwsCredentials.fetch()
  end

  test "fetches credentials from provider when they expire" do
    expiring_credentials =
      {:ok,
       %Credentials{
         AccessKeyId: "test-access-key",
         SecretAccessKey: "test-secret-access-key",
         Token: "test-session-token",
         Region: "us-west-2",
         Expiration: DateTime.add(DateTime.utc_now(), -61, :second)
       }}

    non_expiring_credentials =
      {:ok,
       %Credentials{
         AccessKeyId: "test-access-key",
         SecretAccessKey: "test-secret-access-key",
         Token: "test-session-token",
         Region: "us-west-2",
         Expiration: nil
       }}

    # AwsCredentials.start_link() call
    expect(@provider, :fetch, fn -> expiring_credentials end)

    #  AwsCredentials.fetch() calls
    expect(@provider, :fetch, fn -> expiring_credentials end)
    expect(@provider, :fetch, fn -> expiring_credentials end)
    expect(@provider, :fetch, fn -> non_expiring_credentials end)

    {:ok, _} = AwsCredentials.start_link(provider: @provider, expiration_threshold: 60)

    assert expiring_credentials == AwsCredentials.fetch()
    assert expiring_credentials == AwsCredentials.fetch()
    assert non_expiring_credentials == AwsCredentials.fetch()
  end

  @tag capture_log: true
  test "fails with error when fetching credentials fails on start" do
    expect(@provider, :fetch, fn -> {:error, "provider error"} end)

    Process.flag(:trap_exit, true)
    AwsCredentials.start_link(provider: @provider)

    receive do
      {:EXIT, _from, reason} ->
        assert :shutdown == reason
    end
  end

  @tag capture_log: true
  test "fails with error when fetching credentials fails when credentials expired" do
    expiring_credentials =
      {:ok,
       %Credentials{
         AccessKeyId: "test-access-key",
         SecretAccessKey: "test-secret-access-key",
         Token: "test-session-token",
         Region: "us-west-2",
         Expiration: DateTime.add(DateTime.utc_now(), -61, :second)
       }}

    #  AwsCredentials.start_link() call
    expect(@provider, :fetch, fn -> expiring_credentials end)

    #  AwsCredentials.fetch() calls
    expect(@provider, :fetch, fn -> expiring_credentials end)
    expect(@provider, :fetch, fn -> {:error, "provider error"} end)

    Process.flag(:trap_exit, true)

    {:ok, pid} = AwsCredentials.start_link(provider: @provider, expiration_threshold: 60)

    assert expiring_credentials == AwsCredentials.fetch()

    AwsCredentials.fetch()

    receive do
      {:EXIT, ^pid, reason} ->
        assert :shutdown == reason
    end
  end
end
