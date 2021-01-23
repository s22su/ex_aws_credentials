defmodule AwsCredentials.Providers.EC2Test do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures")
    :ok
  end

  test "returns credentials struct with all keys present" do
    use_cassette "ec2_successful_responses" do
      %AwsCredentials.Credentials{
        AccessKeyId: "12345678901",
        Region: "us-east-1",
        SecretAccessKey: "v/12345678901",
        Token: "TEST92test48TEST+y6RpoTEST92test48TEST/8oWVAiBqTEsT5Ky7ty2tEStxC1T=="
      } = AwsCredentials.Providers.EC2.fetch()
    end
  end

  test "returns credentials struct with expiration converted to DateTime" do
    use_cassette "ec2_successful_responses" do
      %AwsCredentials.Credentials{Expiration: exp} = AwsCredentials.Providers.EC2.fetch()

      assert DateTime.from_unix!(1_609_556_645) == exp
    end
  end

  test "returns error when credentials response returns 401 forbidden" do
    use_cassette "ec2_not_found_role" do
      {:error, 404, _} = AwsCredentials.Providers.EC2.fetch()
    end
  end
end
