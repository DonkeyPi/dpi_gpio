defmodule Dpi.Gpio.Buttons do
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

  @event :buttons

  def start_link(opts) do
    {:ok, spawn_link(fn -> init(opts) end)}
  end

  def init(opts) do
    delay = Keyword.get(opts, :delay, 0)
    if delay > 0, do: :timer.sleep(delay)

    event = Keyword.get(opts, :event, @event)
    start = Keyword.fetch!(opts, :start)
    stop = Keyword.fetch!(opts, :stop)
    State.put(:opts, %{event: event, start: start, stop: stop})

    if Nerves.on() do
      {:ok, start} = Circuits.GPIO.open(start, :input)
      {:ok, stop} = Circuits.GPIO.open(stop, :input)
      # keep references from being garbage collected
      State.put(:refs, %{start: start, stop: stop})
      Circuits.GPIO.set_interrupts(start, :rising)
      Circuits.GPIO.set_interrupts(stop, :falling)
    end

    loop()
  end

  defp loop() do
    %{event: event, start: start, stop: stop} = State.get(:opts)

    receive do
      {:circuits_gpio, ^start, _, value} ->
        Bus.dispatch!(event, {:start, value})
        loop()

      {:circuits_gpio, ^stop, _, value} ->
        Bus.dispatch!(event, {:stop, value})
        loop()
    end
  end
end
