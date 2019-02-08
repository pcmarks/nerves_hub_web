Ecto.Adapters.SQL.Sandbox.mode(NervesHubWebCore.Repo, :manual)

Bureaucrat.start()
ExUnit.start(formatters: [ExUnit.CLIFormatter, Bureaucrat.Formatter], exclude: [:ca_integration])
