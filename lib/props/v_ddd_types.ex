defmodule ICalendar.Props.VDDDTypes do
  @moduledoc false
  use ICalendar.Props

  @enforce_keys [:value]
  defstruct ICalendar.Props.common_fields()

  def of(%Date{} = value), do: %__MODULE__{value: value}
  def of(%DateTime{} = value), do: %__MODULE__{value: value}
  def of(%NaiveDateTime{} = value), do: %__MODULE__{value: value}
  def of({_hours, _minutes, _seconds} = value), do: %__MODULE__{value: value}

  defimpl ICal do
    def to_ical(%{value: value} = _data) do
      case value do
        %DateTime{} ->
          ICal.to_ical(ICalendar.Props.VDatetime.of(value))

        %NaiveDateTime{} ->
          ICal.to_ical(ICalendar.Props.VDatetime.of(value))

        %Date{} ->
          ICal.to_ical(ICalendar.Props.VDate.of(value))

        {_hours, _minutes, _seconds} ->
          ICal.to_ical(ICalendar.Props.VTime.of(value))
          #          # TODO: add VDuration and VPeriod
      end
    end
  end
end
