defmodule Tailmark.Document do
  defstruct [:frontmatter, :ref, :parent, children: [], open?: true, type: :document]
end
