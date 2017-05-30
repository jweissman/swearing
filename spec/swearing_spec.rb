require 'spec_helper'
require 'swearing'

describe Swearing do
  it "should have a VERSION constant" do
    expect(subject.const_get('VERSION')).to_not be_empty
  end
end

describe Swearing::Component do
  it 'should define a simple label component' do
    ExampleComponent = Swearing::Component.define(
      # values we expect to receive (from parent ctx)
      properties: {
        name: {
          type: String,
          required: true
        }
      },

      # expression to interpolate values into...
      template: "Hello %{name}"
    )

    example_component = ExampleComponent.new(name: "world")

    expect(example_component.render(:plaintext)).to eq("Hello world")
  end

  it 'should pass props through to children????' do
    InnerComponent = Swearing::Component.define(
      properties: {
        whom: {
          type: String,
          required: true
        }
      },
      template: "Hello %{whom}"
    )

    OuterComponent = Swearing::Component.define(
      properties: {
        whom: String
      },
      components: {
        my_child: InnerComponent
      }
    )

    outer_component = OuterComponent.new(whom: 'there')
    expect(outer_component.render(:plaintext)).to eq(["Hello there"])
    expect(outer_component.components[:my_child]).to be_a(InnerComponent)
  end

  it 'should be interactive/keep data streams separate' do
    Counter = Swearing::Component.define(
      data: ->() {
        { counter: 0 }
      },
      on: {
        click: ->(data) {
          data[:counter] += 1
        }
      },
      template: "Current value is %{counter}"
    )

    a_counter = Counter.new
    another_counter = Counter.new

    a_counter.click!

    expect(a_counter.render(:plaintext)).to eq("Current value is 1")
    expect(another_counter.render(:plaintext)).to eq("Current value is 0")
  end
end
