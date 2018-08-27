defmodule ICalendarTest.Components do
  use ExUnit.Case
  doctest ICalendar

  alias ICalendar.Props

  alias ICalendar.Components.{
    Factory,
    Component
  }

  describe "Alarm" do
    test "to_ical with no sub components" do
      component_name = "VALARM"
      component = Factory.get_component("alarm")
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)

      component =
        component
        |> Component.add("prodid", "-//my product//")

      assert component.properties["prodid"] == %Props.VText{value: "-//my product//"}

      # TODO: c.add('rdate', [datetime(2013, 3, 28), datetime(2013, 3, 27)])
      #      self.assertTrue(isinstance(c.decoded('rdate'), prop.vDDDLists))
    end

    test "to_ical with properties" do
      component =
        Factory.get_component(
          "alarm",
          %{
            "ATTENDEE" => "Max M"
          }
        )

      assert Component.is_empty(component) == false
      assert Component.to_ical(component) == "BEGIN:VALARM\r\nATTENDEE:Max M\r\nEND:VALARM\r\n"
    end
  end

  describe "Calendar" do
    test "to_ical with no sub components" do
      component_name = "VCALENDAR"
      component = Factory.get_component("calendar")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end

    test "to_ical with properties" do
      component =
        Factory.get_component(
          "calendar",
          %{
            "DESCRIPTION" => "Paragraph one\n\nParagraph two"
          }
        )

      assert Component.is_empty(component) == false

      #     FIXME assert Component.to_ical(component) == "BEGIN:VCALENDAR\r\nDESCRIPTION:Paragraph one\\n\\nParagraph two\r\nEND:VCALENDAR\r\n"
    end

    test "to_ical with sub components" do
      component = Factory.get_component("calendar")

      component =
        component
        |> Component.add("attendee", "John")

      event = Factory.get_component("event")

      event =
        event
        |> Component.add("summary", "A brief history of time")
        |> Component.add("dtend", "20000102T000000", nil, false)
        |> Component.add("dtstart", "20000101T000000", nil, false)

      assert Component.to_ical(event) ==
               "BEGIN:VEVENT\r\nDTEND:20000102T000000\r\nDTSTART:20000101T000000\r\nSUMMARY:A brief history of time\r\nEND:VEVENT\r\n"

      component =
        component
        |> Component.add_component(event)

      assert component.components == [
               %ICalendar.Components.Component{
                 components: [],
                 name: "VEVENT",
                 properties: %{
                   "dtend" => "20000102T000000",
                   "dtstart" => "20000101T000000",
                   "summary" => %ICalendar.Props.VText{
                     params: %ICalendar.Props.Parameters{
                       parameters: %{}
                     },
                     value: "A brief history of time"
                   }
                 }
               }
             ]

      assert Component.to_ical(component) ==
               "BEGIN:VCALENDAR\r\nATTENDEE:John\r\nBEGIN:VEVENT\r\nDTEND:20000102T000000\r\nDTSTART:20000101T000000\r\nSUMMARY:A brief history of time\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
    end

    test "a compliant calendar" do
      dtend = DateTime.utc_now()
      dtstart = DateTime.utc_now()
      dtend_str = Props.VDatetime.format_date(
        dtend.year,
        dtend.month,
        dtend.day,
        dtend.hour,
        dtend.minute,
        dtend.second
      ) <> "Z"
      dtstart_str = Props.VDatetime.format_date(
        dtstart.year,
        dtstart.month,
        dtstart.day,
        dtstart.hour,
        dtstart.minute,
        dtstart.second
      ) <> "Z"
      event_a =
        Factory.get_component("event")
        |> Component.add("description", "Let's go see Star Wars.")
        |> Component.add("dtend", dtend)
        |> Component.add("dtstart", dtstart)
        |> Component.add("location", "123 Fun Street, Toronto ON, Canada")
        |> Component.add("summary", "Film with Amy and Adam")

      event_b =
        Factory.get_component("event")
        |> Component.add("description", "A big long meeting with lots of details.")
        |> Component.add("dtend", dtend)
        |> Component.add("dtstart", dtstart)
        |> Component.add("location", "456 Boring Street, Toronto ON, Canada")
        |> Component.add("summary", "Morning meeting")

      component =
        Factory.get_component("calendar", %{}, [event_a, event_b])
        |> Component.add("calscale", "GREGORIAN")
        |> Component.add("version", "2.0")
      expected =
        "BEGIN:VCALENDAR\r\nCALSCALE:GREGORIAN\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\n"
        <> "DESCRIPTION:Let's go see Star Wars.\r\nDTEND:#{dtend_str}\r\nDTSTART:#{dtstart_str}\r\n"
        <> "LOCATION:123 Fun Street\, Toronto ON\, Canada\r\nSUMMARY:Film with Amy and Adam\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\n"
        <> "DESCRIPTION:A big long meeting with lots of details.\r\nDTEND:#{dtend_str}\r\nDTSTART:#{dtstart_str}\r\n"
        <> "LOCATION:456 Boring Street\, Toronto ON\, Canada\r\nSUMMARY:Morning meeting\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"

      assert Component.to_ical(component) == expected
    end
  end

  describe "Event" do
    test "to_ical with no sub components" do
      component_name = "VEVENT"
      component = Factory.get_component("event")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end

    test "add properties" do
      component = Factory.get_component("event")
      email = "one@email.com"

      component =
        component
        |> Component.add("attendee", email)

      assert %Props.VCalAddress{value: value} = component.properties["attendee"]
      assert email == value

      component =
        component
        |> Component.add("attendee", ["test@test.com", "test2@test.com"])

      assert is_list(component.properties["attendee"])
      assert length(component.properties["attendee"]) == 3

      component =
        component
        |> Component.add("attendee", "maxm@mxm.dk")

      assert length(component.properties["attendee"]) == 4
      assert %Props.VCalAddress{value: value} = List.first(component.properties["attendee"])
      assert email == value
    end
  end

  describe "FreeBusy" do
    test "to_ical with no sub components" do
      component_name = "VFREEBUSY"
      component = Factory.get_component("freebusy")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end
  end

  describe "Journal" do
    test "to_ical with no sub components" do
      component_name = "VJOURNAL"
      component = Factory.get_component("journal")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end
  end

  describe "Timezone" do
    test "to_ical with no sub components" do
      component_name = "VTIMEZONE"
      component = Factory.get_component("timezone")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end
  end

  describe "TimezoneDaylight" do
    test "to_ical with no sub components" do
      component_name = "DAYLIGHT"
      component = Factory.get_component("daylight")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end
  end

  describe "TimezoneStandard" do
    test "to_ical with no sub components" do
      component_name = "STANDARD"
      component = Factory.get_component("standard")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end
  end

  describe "Todo" do
    test "to_ical with no sub components" do
      component_name = "VTODO"
      component = Factory.get_component("todo")
      assert component.name == component_name
      assert component.name == component_name

      assert Component.to_ical(component) ==
               "BEGIN:#{component_name}\r\nEND:#{component_name}\r\n"

      assert Component.is_empty(component)
    end
  end
end
