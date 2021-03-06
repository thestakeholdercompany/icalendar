defmodule ICalex.Components.Component do
  @moduledoc false
  alias ICalex.Props.{Factory, Parameters, VText}
  alias ICalex.Parsers.{ContentLines, ContentLine}

  @enforce_keys [:name]
  defstruct name: nil,
            properties: %{},
            components: [],
            required: [],
            singletons: [],
            multiple: [],
            exclusive: [],
            inclusive: [],
            canonical_order: []

  def is_empty(%__MODULE__{properties: properties, components: components} = _params),
    do: properties === %{} and components === []

  def sorted_keys(%__MODULE__{} = component) do
    keys = component.properties |> Map.keys() |> Enum.map(&String.downcase(&1))
    canonical_keys = component.canonical_order |> Enum.filter(&(&1 in keys))
    non_canonical_keys = keys -- canonical_keys
    canonical_keys ++ Enum.sort(non_canonical_keys)
  end

  def property_items(
        %__MODULE__{} = component,
        recursive \\ true,
        sorted \\ true
      ) do
    component_name = ICal.to_ical(%VText{value: component.name})
    properties = [{"BEGIN", component_name}]

    property_names = if sorted, do: sorted_keys(component), else: Map.keys(component.properties)

    properties =
      property_names
      |> Enum.reduce(properties, fn name, acc ->
        values = Map.get(component.properties, name)

        if is_list(values) do
          acc ++ Enum.map(values, fn value -> {String.upcase(name), value} end)
        else
          acc ++ [{String.upcase(name), values}]
        end
      end)

    properties =
      if recursive do
        component.components
        |> Enum.reduce(properties, fn component, acc ->
          acc ++ property_items(component, recursive, sorted)
        end)
      else
        properties
      end

    properties ++ [{"END", component_name}]
  end

  def to_ical(%__MODULE__{} = component) do
    component
    |> property_items
    |> Enum.map(fn {name, value} ->
      params =
        if is_map(value) and Map.has_key?(value, :params), do: value.params, else: %Parameters{}

      ContentLine.from_parts(name, params, value, true)
    end)
    |> ContentLines.to_ical()
  end

  def add_component(%__MODULE__{} = component, sub_component) do
    Map.put(component, :components, component.components ++ [sub_component])
  end

  def add(
        %__MODULE__{properties: properties} = component,
        name,
        value,
        parameters \\ nil,
        encode \\ true
      ) do
    name = String.downcase(name)

    value =
      case value do
        # set to UTC
        %NaiveDateTime{} when name in ["dtstamp", "created", "last-modified"] ->
          Timex.to_datetime(value)

        # TODO when TZID in Parameters or DateTime not utc
        _ ->
          value
      end

    value =
      if encode and is_list(value) and String.downcase(name) not in ["rdate", "exdate"] do
        for v <- value, do: encode(name, v, parameters, encode)
      else
        encode(name, value, parameters, encode)
      end

    value =
      if Map.has_key?(properties, name) do
        old_value = Map.get(properties, name)

        cond do
          is_list(old_value) and is_list(value) -> old_value ++ value
          is_list(old_value) -> old_value ++ [value]
          is_list(value) -> [old_value | value]
          true -> [old_value, value]
        end
      else
        value
      end

    Map.put(component, :properties, Map.put(properties, name, value))
  end

  defp encode(_, value, _, false), do: value
  defp encode(name, value, nil, encode), do: encode(name, value, %Parameters{}, encode)

  defp encode(name, value, %Parameters{} = parameters, _encode) do
    if ICalex.Props.is_prop(value) do
      value
    else
      Factory.get_type_name(name) |> Factory.get_type(value, parameters)
    end
  end

  defp encode(name, value, %{} = parameters, encode),
    do: encode(name, value, %Parameters{parameters: parameters}, encode)

  def validate(%__MODULE__{} = component) do
    _keys = component.properties |> Map.keys() |> Enum.map(&String.downcase(&1))
    # TODO validate
  end

  defimpl ICal do
    def to_ical(data),
      do: ICalex.Components.Component.to_ical(data)
  end
end
