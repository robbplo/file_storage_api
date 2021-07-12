defmodule FileStorageApi.API.S3.FileTest do
  use ExUnit.Case

  import Mox

  alias FileStorageApi.API.S3.File

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(File.module_info())
  end

  test "able to create a public url for files" do
    {:ok, url} =
      File.public_url(
        "block-store-container",
        "test.png",
        Timex.now(),
        Timex.add(Timex.now(), Timex.Duration.from_days(1))
      )

    uri = URI.parse(url)

    assert "/block-store-container/test.png" == uri.path
  end

  test "able to create a public url for files also works with / at start" do
    {:ok, url} =
      File.public_url(
        "block-store-container",
        "/test.png",
        Timex.now(),
        Timex.add(Timex.now(), Timex.Duration.from_days(1))
      )

    uri = URI.parse(url)

    assert "/block-store-container/test.png" == uri.path
  end

  test "timestamps should be correctly set in url" do
    start_time = Timex.now()
    expire_time = Timex.add(Timex.now(), Timex.Duration.from_hours(1))
    {:ok, url} = File.public_url("block-store-container", "test.png", start_time, expire_time)
    uri = URI.parse(url)

    %{"X-Amz-Expires" => "3600"} = URI.decode_query(uri.query)
  end

  test "delete bucket operation" do
    path = "awesome/test.png"

    expect(AwsMock, :request, fn operation, _config ->
      assert %{http_method: :delete, path: "test.png"} = operation
      {:ok, %{}}
    end)

    assert {:ok, %{}} == File.delete("block-store-container", path)
  end

  test "upload a file with mime type" do
    file_path = "./test/support/test_icon.png"

    expect(AwsMock, :request, fn operation, _config ->
      assert %{http_method: :put, path: "test_icon.png", headers: %{"content-type" => "image/png"}} = operation
      {:ok, %{status_code: 200}}
    end)

    assert {:ok, Path.basename(file_path)} == File.upload("block-store-container", file_path, nil)
  end

  test "failing upload should return error tuple" do
    file_path = "./test/support/test_icon.png"

    expect(AwsMock, :request, fn operation, _config ->
      assert %{http_method: :put, path: "test_icon.png", headers: %{"content-type" => "image/png"}} = operation
      {:error, %{status_code: 400}}
    end)

    assert {:error, %{}} = File.upload("block-store-container", file_path, nil)
  end
end
