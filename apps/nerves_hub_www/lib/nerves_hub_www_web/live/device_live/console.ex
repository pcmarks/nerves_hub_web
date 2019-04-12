defmodule NervesHubWWWWeb.DeviceLive.Console do
  use Phoenix.LiveView

  alias NervesHubWebCore.{Accounts.Org, Devices}
  alias Phoenix.Socket.Broadcast

  @theme AnsiToHTML.Theme.new(container: :none)

  def render(assigns) do
    NervesHubWWWWeb.DeviceView.render("console.html", assigns)
  end

  def mount(session, socket) do
    if connected?(socket) do
      socket.endpoint.subscribe("console:#{session.device.id}")
    end

    socket = socket
    |> assign(:device, session.device)
    |> assign(:lines, ["NervesHub IEx Live"])
    |> assign(:active_line, nil)

    {:ok, socket}
  end

  def handle_event("init_console", _value, socket) do
    socket.endpoint.broadcast_from!(self(), "console:#{socket.assigns.device.id}", "init", %{})
    {:noreply, socket}
  end
  
  def handle_event("iex_submit", %{"iex_input" => "clear"}, socket) do
    {:noreply, assign(socket, :lines, [])}
  end
  
  def handle_event("iex_submit", %{"iex_input" => line}, %{assigns: %{active_line: active, lines: lines}} = socket) do
    new_lines = List.insert_at(lines, -1, active <> line)
    socket.endpoint.broadcast_from!(self(), "console:#{socket.assigns.device.id}", "io_reply", %{data: line, kind: "get_line"})
    {:noreply, assign(socket, :lines, new_lines)}
  end

  def handle_info(%{event: "init_failure"}, socket) do
    {:noreply, put_flash(socket, :error, "Failed to start remote IEx")}
  end

  def handle_info(%{event: "put_chars", payload: %{"data"=> line}}, %{assigns: %{lines: lines}} = socket) do
    line = AnsiToHTML.generate_phoenix_html(line, @theme)
    new_lines = List.insert_at(lines, -1, line)
    socket.endpoint.broadcast_from!(self(), "console:#{socket.assigns.device.id}", "io_reply", %{data: :ok, kind: "put_chars"})
    {:noreply, assign(socket, :lines, new_lines)}
  end
  
  def handle_info(%{event: "get_line", payload: %{"data"=> line}}, %{assigns: %{lines: lines}} = socket) do
    {:noreply, assign(socket, :active_line, line)}
  end

  # ignore unknown broadcasts
  def handle_info(%Broadcast{} = msg, socket) do
    unless msg.payload == %{data: :ok, kind: "put_chars"} do
      IO.inspect(msg, label: "UNKNOWN BROADCAST")
    end
    {:noreply, socket}
  end
end