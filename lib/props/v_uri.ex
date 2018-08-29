defmodule ICalendar.Props.VUri do
  @moduledoc false
  use ICalendar.Props.Prop

  @enforce_keys [:value]
  defstruct ICalendar.Props.Prop.common_fields()

  def of(value) when is_bitstring(value), do: %__MODULE__{value: value}

  defimpl ICal do
    def to_ical(%{value: value} = _data), do: value
  end
end
