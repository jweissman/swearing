require 'spec_helper'
require 'swearing'

describe Swearing do
  it "should have a VERSION constant" do
    expect(subject.const_get('VERSION')).to_not be_empty
  end
end

describe Swearing::Layout do
  let(:hello) { Text['hello'] }
  let(:world) { Text['world'] }

  it 'should layout elements in columns' do
    #  |--------------------|
    #  |  hello   |  world  |
    #  |--------------------|

    laid_out = Layout.layout([hello, world], mode: :column, dims: [10,5])

    hello = laid_out.first
    expect(hello.value).to eq('hello')
    world = laid_out.last
    expect(world.value).to eq('world')

    expect(hello._dims).to eq([5,5])
    expect(hello._origin).to eq([0,0])
    expect(world._dims).to eq([5,5])
    expect(world._origin).to eq([5,0])
  end

  it 'should layout elements in rows' do
    #  |-------|
    #  | hello |
    #  |-------|
    #  | world |
    #  |-------|
    #
    laid_out = Layout.layout([hello, world], mode: :row, dims: [5,10])

    hello = laid_out.first
    expect(hello.value).to eq('hello')
    world = laid_out.last
    expect(world.value).to eq('world')

    expect(hello._dims).to eq([5,5])
    expect(hello._origin).to eq([0,0])
    expect(world._dims).to eq([5,5])
    expect(world._origin).to eq([0,5])
  end

  it 'should layout elements recursively' do
    #  |-------------------|
    #  |      hello        |
    #  |-------------------|
    #  |      world        |
    #  |-------------------|
    #  | one | two | three |
    #  |-------------------|
    #
    one = Text['one']
    two = Text['two']
    three = Text['three']
    elements = [hello, world, Container[one, two, three]]

    laid_out = Layout.layout(elements, mode: :row, dims: [15,15])
    hello, world, cont = *laid_out
    one, two, three = *cont.contents
    expect(hello.value).to eq('hello')
    expect(world.value).to eq('world')
    expect(one.value).to eq('one')
    expect(two.value).to eq('two')
    expect(three.value).to eq('three')

    expect(hello._dims).to eq([15,5])
    expect(hello._origin).to eq([0,0])

    expect(world._dims).to eq([15,5])
    expect(world._origin).to eq([0,5])

    expect(cont._dims).to eq([15,5])
    expect(cont._origin).to eq([0,10])

    expect(one._dims).to eq([5,5])
    expect(one._origin).to eq([0,10])

    expect(two._dims).to eq([5,5])
    expect(two._origin).to eq([5,10])

    expect(three._dims).to eq([5,5])
    expect(three._origin).to eq([10,10])

    # binding.pry
  end
end

describe Swearing::Component do
  it 'should define a simple label component' do
    ExampleComponent = Swearing::Component.define(
      :example,
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

    example_component = ExampleComponent.new #(name: "world")

    expect(example_component.render(name: 'world')).to eq(Text['Hello world']) #[ text: "Hello world" ])
  end

  it 'should pass props through to children / recursively resolve components' do
    InnerComponent = Swearing::Component.define(
      :inner,
      properties: {
        whom: {
          type: String,
          required: true
        }
      },
      template: "Hello %{whom}"
    )

    OuterComponent = Swearing::Component.define(
      :outer,
      properties: {
        whom: String
      },
      components: {
        my_child: InnerComponent
      },
      render: ->(data, components) {
        [ my_child: { whom: data[:whom] } ]
        # components[:my_child].render(whom: data[:whom])
      }
    )

    outer_component = OuterComponent.new #(whom: 'there')
    expect(outer_component.render(whom: 'there')).to eq([my_child: {whom: "there"}]) #"Hello there"])
    expect(outer_component.components[:my_child]).to be_a(InnerComponent)
  end

  it 'should be interactive/keep data streams separate' do
    Counter = Swearing::Component.define(
      :counter,
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

    expect(a_counter.render).to eq(Text["Current value is 1"])
    expect(another_counter.render).to eq(Text["Current value is 0"])
  end
end

describe Swearing::Application do
  context 'a blank application' do
    subject(:blank_app) do
      Swearing::Application.new #(view: ->() { container.render })
    end

    # let(:container) do
    #   Swearing::UI::Container.new(
    #     elements: [
    #       Swearing::UI::Label.new(text: 'hello world')
    #     ]
    #   )
    # end

    it 'can be launched okay!' do
      expect { blank_app.launch!(dry_run: true) }.not_to raise_error
    end
  end

  context 'the demo app' do
    subject(:demo_app) do
      Swearing::Demo::App.new
    end

    it 'can be launched okay' do
      expect { demo_app.launch!(dry_run: true) }.not_to raise_error
    end
  end
end
