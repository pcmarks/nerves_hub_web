Logger.remove_backend(:console)

assert_timeout = String.to_integer(System.get_env("ELIXIR_ASSERT_TIMEOUT") || "200")

Bureaucrat.start()

ExUnit.start(
  formatters: [ExUnit.CLIFormatter, Bureaucrat.Formatter],
  assert_receive_timeout: assert_timeout
)

Ecto.Adapters.SQL.Sandbox.mode(NervesHubWebCore.Repo, :manual)
