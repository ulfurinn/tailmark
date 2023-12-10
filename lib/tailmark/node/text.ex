defmodule Tailmark.Node.Text do
  defstruct [:ref, content: ""]

  def new(content) do
    %__MODULE__{ref: make_ref(), content: content}
  end
end
