defmodule RetWeb.Api.V1.AssetsView do
  use RetWeb, :view
  alias Ret.{OwnedFile}

  defp render_asset(asset) do
    %{
      asset_id: asset.asset_sid,
      name: asset.name,
      file_url: asset.asset_owned_file |> OwnedFile.uri_for() |> URI.to_string(),
      thumbnail_url: asset.thumbnail_owned_file |> OwnedFile.uri_for() |> URI.to_string(),
      type: asset.type,
      content_type: asset.asset_owned_file.content_type,
      content_length: asset.asset_owned_file.content_length
    }
  end

  def render("show.json", %{asset: asset}) do
    %{
      assets: [render_asset(asset)]
    }
  end

end
