# Channel the device is connected to
defmodule NervesHubDeviceWeb.ConsoleChannel do
  use NervesHubDeviceWeb, :channel
  alias NervesHubCore.{Devices, DeviceConsole}

  @uploader Application.get_env(:nerves_hub_core, :firmware_upload)

  def join("console:" <> _serial_number, _payload, socket) do
    with {:ok, certificate} <- get_certificate(socket),
         {:ok, device} <- Devices.get_device_by_certificate(certificate) do
      send(self(), :after_join)
      {:ok, assign(socket, :device_id, device.id)}
    else
      {:error, _} = err -> err
    end
  end

  def terminate(_, socket) do
    DeviceConsole.stop(socket.assigns.device_id)
    {:shutdown, :closed}
  end

  def handle_info(:after_join, socket) do
    {:ok, _console} = DeviceConsole.start_link(socket.assigns.device_id, socket)
    {:noreply, socket}
  end

  def handle_in("io_request:" <> kind, payload, socket) do
    :ok = DeviceConsole.io_request(socket.assigns.device_id, kind, payload)
    {:reply, {:ok, %{response: "ok"}}, socket}
  end

  defp get_certificate(%{assigns: %{certificate: certificate}}), do: {:ok, certificate}

  defp get_certificate(_), do: {:error, :no_device_or_org}
end
