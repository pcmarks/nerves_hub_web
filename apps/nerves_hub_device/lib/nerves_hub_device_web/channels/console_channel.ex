# Channel the device is connected to
defmodule NervesHubDeviceWeb.ConsoleChannel do
  use NervesHubDeviceWeb, :channel
  alias NervesHubWebCore.{Devices, DeviceConsole}

  alias Phoenix.Socket.Broadcast

  def join("console", _payload, socket) do
    with {:ok, certificate} <- get_certificate(socket),
         {:ok, device} <- Devices.get_device_by_certificate(certificate) do
      send(self(), :after_join)
      {:ok, assign(socket, :device, device)}
    else
      {:error, _} = err -> err
    end
  end

  def terminate(_, socket) do
    {:shutdown, :closed}
  end

  def handle_info(:after_join, %{assigns: %{device: device}} = socket) do
    socket.endpoint.subscribe("console:#{device.id}")
    {:noreply, socket}
  end

  def handle_in("init_attempt", %{"success" => success?}, socket) do
    unless success? do
      socket.endpoint.broadcast_from(self(), "console:#{socket.assigns.device.id}", "init_failure", %{})
    end
    {:noreply, socket}
  end

  def handle_in("io_reply", payload, socket) do
    {:reply, {:ok, %{response: "ok"}}, socket}
  end

  def handle_in(event, payload, socket) when event in ["put_chars", "get_line"] do
    socket.endpoint.broadcast_from!(self(), "console:#{socket.assigns.device.id}", event, payload)
    {:noreply, socket}
  end

  def handle_in("test", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_info(%{event: "phx_leave"}, socket) do
    {:noreply, socket}
  end

  def handle_info(%Broadcast{payload: payload, event: event}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  defp get_certificate(%{assigns: %{certificate: certificate}}), do: {:ok, certificate}

  defp get_certificate(_), do: {:error, :no_device_or_org}
end