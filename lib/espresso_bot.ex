defmodule EspressoBot do
  @moduledoc """
  THE Espresso bot
  """

  use Application

  def start(_type, []) do
    children = []

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
