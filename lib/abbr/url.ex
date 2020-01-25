defmodule Abbr.Url do
  @moduledoc """
  Represents a mapping between original and shortened URL.

  Parameters:
  - original - contains the full original URL
  - short - contains only the hash value of the shortened URL
  """

  alias __MODULE__

  @enforce_keys [
    :short,
    :original
  ]

  defstruct [
    :short,
    :original
  ]

  @type short :: String.t()
  @type original :: String.t()

  @type t :: %Url{
          short: short(),
          original: original()
        }
end
