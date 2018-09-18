# Channel the Frontend is connected to
defmodule NervesHubWWWWeb.ConsoleChannel do
  use NervesHubWWWWeb, :channel
  alias NervesHubCore.{Devices, DeviceConsole, Accounts}
  alias NervesHubDevice.Presence

  def join("console:" <> device_identifier, %{"org_id" => org_id}, socket) do
    org_id = String.to_integer(org_id)
    {:ok, org} = Accounts.get_org(org_id)
    {:ok, device} = Devices.get_device_by_identifier(org, device_identifier)
    send(self(), :after_join)

    if DeviceConsole.alive?(device.id) do
      {:ok, assign(socket, :device_id, device.id)}
    else
      {:error, %{reason: "not alive"}}
    end
  end

  def handle_info(:after_join, socket) do
    :ok = DeviceConsole.connect(socket.assigns.device_id, socket)
    {:noreply, socket}
  end

  def handle_in("io_response:" <> response, payload, socket) do
    DeviceConsole.io_response(socket.assigns.device_id, response, payload)
    {:reply, {:ok, %{response: "ok"}}, socket}
  end
end
