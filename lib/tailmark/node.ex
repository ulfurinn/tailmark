defmodule Tailmark.Node do
  defstruct [
    :type,
    :ref,
    :level,
    :parent,
    :fenced,
    :fence_char,
    :fence_length,
    :fence_offset,
    children: [],
    content: "",
    info: nil,
    open?: true
  ]
end
