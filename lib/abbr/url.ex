defmodule Abbr.Url do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :original, :string
    field :short, :string
  end
end
