defmodule ICalendar.Props.VGeo do
  @moduledoc false
  use ICalendar.Props.Prop

  @enforce_keys [:value]
  defstruct ICalendar.Props.Prop.common_fields()

  def of({_lat, _lon} = value), do: %__MODULE__{value: value}

  defimpl ICal do
    def to_ical(%{value: {lat, lon} = _value} = _data), do: "#{lat};#{lon}"
  end
end