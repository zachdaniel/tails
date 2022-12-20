defmodule Tails do
  @moduledoc false
  use Tails.Custom, otp_app: :tails

  defmacro __using__(opts) do
    quote do
      use Tails.Custom, unquote(opts)
    end
  end
end
