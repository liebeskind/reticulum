defmodule Ret.OAuthToken do
  @moduledoc """
  OAuthTokens are used in the "state" parameter in our community integration OAuth flows.
  They allow us to verify that an incoming OAuth request can be trusted and they contain state used to complete
  the OAuth flow.
  """
  use Guardian, otp_app: :ret, secret_fetcher: Ret.OAuthTokenSecretFetcher

  def subject_for_token(_, _), do: {:ok, nil}

  def resource_from_claims(_), do: nil

  def token_for_hub(hub_sid) do
    {:ok, token, _claims} =
      Ret.OAuthToken.encode_and_sign(
        # OAuthTokens do not have a resource associated with them
        nil,
        %{hub_sid: hub_sid, aud: :ret_oauth},
        allowed_algos: ["HS512"],
        ttl: {5, :minutes},
        allowed_drift: 60 * 1000
      )

    token
  end
end

defmodule Ret.OAuthTokenSecretFetcher do
  def fetch_signing_secret(mod, _opts) do
    {:ok, Application.get_env(:ret, mod)[:oauth_token_key] |> JOSE.JWK.from_oct()}
  end

  def fetch_verifying_secret(mod, _token_headers, _opts) do
    {:ok, Application.get_env(:ret, mod)[:oauth_token_key] |> JOSE.JWK.from_oct()}
  end
end
