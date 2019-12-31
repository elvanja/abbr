defmodule Abbr.Url do
  use Ecto.Schema

  embedded_schema do
    field :original, :string
    field :short, :string
  end
end
