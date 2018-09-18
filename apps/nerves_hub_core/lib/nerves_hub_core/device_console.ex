defmodule NervesHubCore.DeviceConsole do
  use GenServer
  require Logger

  def alive?(device_id) do
    pid = GenServer.whereis(name(device_id))
    (pid && Process.alive?(pid)) || false
  end

  def connect(device_id, client_socket) do
    pid = GenServer.whereis(name(device_id))
    Process.link(pid)
    GenServer.call(pid, {:connect, client_socket})
  end

  def io_request(device_id, request, data) do
    GenServer.call(name(device_id), {:io_request, request, data})
  end

  def io_response(device_id, response, data) do
    GenServer.call(name(device_id), {:io_response, response, data})
  end

  def start_link(device_id, device_socket) do
    Logger.debug("Starting device console: #{inspect(name(device_id))}")
    GenServer.start_link(__MODULE__, [device_id, device_socket], name: name(device_id))
  end

  def stop(device_id) do
    Logger.debug("Stopping device console: #{inspect(name(device_id))}")
    GenServer.stop(name(device_id), :normal)
  end

  def init([device_id, device_socket]) do
    {:ok, %{device_id: device_id, device_socket: device_socket, client_socket: nil}}
  end

  def handle_call({:connect, client_socket}, _from, state) do
    Phoenix.Channel.push(state.device_socket, "connect", %{})
    {:reply, :ok, %{state | client_socket: client_socket}}
  end

  def handle_call({:io_request, request, data}, _from, state) do
    Phoenix.Channel.push(state.client_socket, "io_request:#{request}", data)
    {:reply, :ok, state}
  end

  def handle_call({:io_response, response, data}, _from, state) do
    Phoenix.Channel.push(state.device_socket, "io_response:#{response}", data)
    {:reply, :ok, state}
  end

  def handle_call(call, _from, state) do
    {:stop, {:unhandled_call, call}, state}
  end

  defp name(device_id) do
    :"#{NervesHubCore.DeviceConsole}-#{device_id}"
  end
end
