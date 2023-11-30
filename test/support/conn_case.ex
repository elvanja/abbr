defmodule AbbrWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias AbbrWeb.Router.Helpers, as: Routes

      import Plug.Conn
      import Phoenix.ConnTest

      @endpoint AbbrWeb.Endpoint
    end
  end

  setup do
    # credo:disable-for-lines:1 Credo.Check.Design.AliasUsage
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
