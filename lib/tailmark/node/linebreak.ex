defmodule Tailmark.Node.Linebreak do
  defstruct [:ref, :hard]

  def new(hard), do: %__MODULE__{ref: make_ref(), hard: hard}
end
