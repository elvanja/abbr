defmodule Abbr.Url do
  @moduledoc """
  Represents a mapping between original and shortened URL.

  Parameters:
  - original - contains the full original URL
  - short - contains only the hash value of the shortened URL
  """

  use Ecto.Schema

  @type original :: String.t()
  @type short :: String.t()

  embedded_schema do
    field :original, :string
    field :short, :string
  end
end
