defmodule Ret.Application do
  use Application
  import Cachex.Spec

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    :ok = Ret.Statix.connect()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Ret.Repo, []),
      supervisor(RetWeb.Endpoint, []),
      supervisor(RetWeb.Presence, []),

      # Quantum scheduler
      worker(Ret.Scheduler, []),
      # Quantum singleton scheduler
      worker(Ret.SingletonScheduler, []),
      # Room assigner monitor
      worker(Ret.RoomAssignerMonitor, []),
      # Storage for rate limiting
      worker(PlugAttack.Storage.Ets, [RetWeb.RateLimit.Storage, [clean_period: 60_000]]),
      # Media resolution cache
      worker(
        Cachex,
        [
          :media_urls,
          [
            expiration: expiration(default: :timer.minutes(5)),
            fallback: fallback(default: &Ret.MediaResolver.resolve/1)
          ]
        ],
        id: :media_url_cache
      ),

      # Media search cache
      worker(
        Cachex,
        [
          :media_search_results,
          [
            expiration: expiration(default: :timer.minutes(5)),
            fallback: fallback(default: &Ret.MediaSearch.search/1)
          ]
        ],
        id: :media_search_cache
      ),

      # Long-lived media search cache, used for common queries that have quotas
      worker(
        Cachex,
        [
          :media_search_results_long,
          [
            expiration: expiration(default: :timer.hours(24)),
            fallback: fallback(default: &Ret.MediaSearch.search/1)
          ]
        ],
        id: :media_search_cache_long
      ),

      # Discord API cache
      worker(
        Cachex,
        [
          :discord_api,
          [
            expiration: expiration(default: :timer.minutes(1)),
            fallback: fallback(default: &Ret.DiscordClient.api_request/1)
          ]
        ],
        id: :discord_api_cache
      ),

      # Page origin chunk cache
      worker(
        Cachex,
        [
          :page_chunks,
          [
            warmers: [warmer(module: Ret.PageOriginWarmer)]
          ]
        ],
        id: :page_chunk_cache
      ),

      # Janus load status cache
      worker(
        Cachex,
        [
          :janus_load_status,
          [
            warmers: [warmer(module: Ret.JanusLoadStatus)]
          ]
        ],
        id: :janus_load_status
      ),
      supervisor(TheEnd.Of.Phoenix, [[timeout: 10_000, endpoint: RetWeb.Endpoint]])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ret.Supervisor]
    :ok = :error_logger.add_report_handler(Sentry.Logger)
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RetWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
