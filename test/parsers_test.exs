defmodule ICalendarTest.Parsers do
  use ExUnit.Case
  doctest ICalendar
  alias ICalendar.Parsers.{ContentLine, ContentLines}
  alias ICalendar.Props.{VText, VInt}

  describe "ContentLine" do
    test "to_ical" do
      assert ContentLine.to_ical("foo") == "foo"

      assert ContentLine.to_ical(
               "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum convallis imperdiet dui posuere."
             ) ==
               "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum conval\r\n lis imperdiet dui posuere."

      assert ContentLine.to_ical("foobar", 4) == "foo\r\n bar"

      assert ContentLine.to_ical("DESCRIPTION:АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ", 44) ==
               "DESCRIPTION:АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭ\r\n ЮЯ"
    end

    test "from_parts" do
      assert ContentLine.from_parts("ATTENDEE", %{}, "MAILTO:maxm@example.com") ==
               "ATTENDEE:MAILTO:maxm@example.com"

      assert ContentLine.from_parts(
               "ATTENDEE",
               %{"role" => "REQ-PARTICIPANT", "CN" => "Max Rasmussen"},
               "MAILTO:maxm@example.com"
             ) == "ATTENDEE;CN=\"Max Rasmussen\";ROLE=REQ-PARTICIPANT:MAILTO:maxm@example.com"

      assert ContentLine.from_parts(
               "ATTENDEE",
               %{},
               %VText{value: "MAILTO:maxm@example.com"}
             ) == "ATTENDEE:MAILTO:maxm@example.com"

      assert ContentLine.from_parts(
               "SOMETHING",
               %{},
               %VInt{value: 1}
             ) == "SOMETHING:1"

      assert ContentLine.from_parts(
               "SUMMARY",
               %{},
               %VText{value: "International char æ ø å"}
             ) == "SUMMARY:International char æ ø å"
    end
  end

  describe "ContentLines" do
    test "to_ical" do
      expected =
        "BEGIN:VEVENT\r\n123456789 123456789 123456789 123456789 123456789 123456789 123456789 1234\r\n 56789 123456789 123456789 \r\n"

      assert [
               "BEGIN:VEVENT",
               Stream.cycle(["123456789 "])
               |> Enum.take(10)
               |> Enum.join("")
             ]
             |> ContentLines.to_ical() == expected
    end
  end
end
