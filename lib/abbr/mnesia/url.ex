defmodule Abbr.Mnesia.Url do
  @moduledoc """
  Table definition to save URLs to
  """

  use Memento.Table,
    type: :set,
    attributes: [:short, :original]
end
