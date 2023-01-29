defmodule Dpi.Gpio.Tower do
  alias Dpi.Api.Nerves
  alias Dpi.Api.State
  alias Dpi.Api.Bus

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      type: :worker,
      shutdown: 500
    }
  end

  @event :tower

  def start_link(opts) do
    {:ok, spawn_link(fn -> init(opts) end)}
  end

  def init(opts) do
    delay = Keyword.get(opts, :delay, 0)
    if delay > 0, do: :timer.sleep(delay)

    event = Keyword.get(opts, :event, @event)
    buzzer = Keyword.fetch!(opts, :buzzer)
    green = Keyword.fetch!(opts, :green)
    red = Keyword.fetch!(opts, :red)

    if Nerves.on() do
      {:ok, buzzer} = Circuits.GPIO.open(buzzer, :output)
      {:ok, green} = Circuits.GPIO.open(green, :output)
      {:ok, red} = Circuits.GPIO.open(red, :output)
      State.put(:opts, %{event: event, buzzer: buzzer, green: green, red: red})
    else
      State.put(:opts, %{event: event, buzzer: nil, green: nil, red: nil})
    end

    Bus.register!(event)
    loop()
  end

  def step(event \\ @event), do: Bus.dispatch!(event, :step)
  def pass(event \\ @event), do: Bus.dispatch!(event, :pass)
  def error(event \\ @event), do: Bus.dispatch!(event, :error)

  defp loop() do
    %{event: event} = State.get(:opts)

    receive do
      {:event, {^event, _, action}} ->
        handle(action, State.get(:opts))
        loop()
    end
  end

  defp handle(:step, %{buzzer: buzzer, green: green}) do
    beep(buzzer, green, 100)
  end

  defp handle(:pass, %{buzzer: buzzer, green: green}) do
    beep(buzzer, green, 100)
    :timer.sleep(100)
    beep(buzzer, green, 100)
    :timer.sleep(100)
    beep(buzzer, green, 100)
  end

  defp handle(:error, %{buzzer: buzzer, red: red}) do
    beep(buzzer, red, 800)
    :timer.sleep(100)
    beep(buzzer, red, 800)
  end

  defp beep(nil, nil, toms) do
    Process.sleep(toms)
  end

  defp beep(buzzer, color, toms) do
    Circuits.GPIO.write(buzzer, 1)
    Circuits.GPIO.write(color, 1)
    Process.sleep(toms)
    Circuits.GPIO.write(buzzer, 0)
    Circuits.GPIO.write(color, 0)
  end
end
