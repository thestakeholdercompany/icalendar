defmodule ICalendar.Props.VDate do
  @moduledoc false
  alias ICalendar.Props.Parameters

  @enforce_keys [:value]
  defstruct ICalendar.Props.Prop.common_fields() ++
              [params: %Parameters{parameters: %{value: "DATE"}}]

  def to_ical(%ICalendar.Props.VDate{value: value} = _data) do
    %Date{year: year, month: month, day: day} = value
    format = fn n -> n |> Integer.to_string() |> String.pad_leading(2, "0") end
    "#{year}#{format.(month)}#{format.(day)}"
  end
end
