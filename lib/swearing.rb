require 'pry'
require 'logger'
require 'curses'
require 'ostruct'
# require 'erb'

require 'swearing/version'
require 'swearing/component'
require 'swearing/application'

# a little wrapper around curses
module Swearing
  module Layout
    def self.flip_orientation(mode)
      case mode
      when :row then :column
      when :column then :row
      else raise "Unknown orientation mode: #{mode} (must be :row/:column)"
      end
    end

    def self.subdivide(n, dims:, mode:)
      w,h = *dims

      case mode
      when :column then w / n
      when :row then h / n
      end
    end

    def self.layout(elements, mode:, origin: [0,0], dims:)
      ox,oy = *origin
      w,h = *dims
      elements_count = elements.count
      return elements unless elements_count > 0

      share_per_container = subdivide(elements_count, dims: dims, mode: mode)

      elements.map.with_index do |element, index|
        if mode == :row
          element._origin = [ ox, oy + (index*share_per_container) ]
          element._dims   = [ w, share_per_container ]
          element.contents = layout(element.contents, mode: :column, origin: element._origin, dims: element._dims) if element.contents.any?
        elsif mode == :column
          element._origin = [ ox + (index*share_per_container), oy ]
          element._dims   = [ share_per_container, h ]
          element.contents = layout(element.contents, mode: :row, origin: element._origin, dims: element._dims) if element.contents.any?
        end
        element
      end
    end
  end

  # elements are atomic things that can't be simplified, are
  # actually renderable...
  class Element
    attr_accessor :_origin, :_dims
  end

  class Text < Element
    attr_reader :value
    def initialize(value:)
      @value = value
    end

    def ==(other)
      other.value == value
    end

    def inspect
      "Text['#{value}']"
    end

    def self.[](val)
      new value: val
    end

    def contents; [] end
  end

  class Container < Element
    attr_accessor :contents

    # for layout use only -- maybe a separate obj?

    def initialize(contents:)
      @contents = contents
      @_origin = [0,0]
      @_dims = [0,0]
    end

    def inspect
      "Container[#{contents.map(&:inspect).join(';')}]"
    end

    def ==(other)
      contents == other.contents
    end

    # def layout!(mode: :column, origin: @_origin, dims: @_dims)
    #   # log.info "=== LAYOUT ==="
    #   # log.info "origin: #{origin} -- dims: #{dims}"
    #   # log.info "elements to #{mode} layout: #{elements.inspect}"
    #   layout elements...
    #   Layout.layout(self.contents, origin...)
    # end

    def self.[](*contents)
      new contents: contents
    end
  end

  ###

  module UI
    Label = Swearing::Component.define(
      :label,
      properties: {
        text: {
          type: String,
          required: true
        },
        # x: Integer,
        # y: Integer
      },
      render: ->(data) {
        template_string = data[:text]
        interpolated = template_string % data  #$???
        Text[interpolated] #.new(value: interpolated)
        # x,y = data[:x], data[:y]
        # render string at x,y
        # [text: interpolated]
      }
    )

    # Container = Swearing::Component.define(
    #   render: ->(data, components) {
    #     # lerp components...?
    #     # binding.pry
    #     # self.class.components.inject({})
    #     # need to orient subcomponents within container space...
    #     # 'hmmm'
    #   }
    # )
  end

  module Demo
  # class DemoAppView < Swearing::UI::Container
  # end
    # HelloWorld = Swearing::Component.define(:hello, render: ->(*) { Text['hello there!'] })

    class App < Swearing::Application
      def view_model
        [
          Text['hi there'],
          Text['welcome'],
          Container[
            Text['these'],
            Text['should'],
            Text['be in a row']
          ]
        ]
          # [ HelloWorld.new ]

          # [
          #   container: [ :hello ]
          # ]
          # @view_model ||= Swearing::UI::Container.new(
          #   # elements: [ Swearing::UI::Label.new(text: 'hello world') ]
          # )
      end
    end
  end

  # class Component
  #   include Curses

  #   def log
  #     @logger = Logger.new('log/swearing.log')
  #   end

  #   def inscribe(figure: 'X', at:)
  #     x, y = *at
  #     setpos(y, x)
  #     addstr(figure)
  #   end
  # end

  # class Label < Component
  #   def initialize(x:, y:, text:)
  #     @x, @y, @text = x, y, text
  #   end

  #   def draw(offset: [0,0])
  #     ox, oy = *offset
  #     inscribe figure: @text, at: [@x + ox, @y + oy]
  #   end
  # end

  # # a labelled inscription
  # class Sigil < Swearing::Component
  #   def initialize(x:, y:, figure:, text:)
  #     @x, @y, @figure, @text = x, y, figure, text
  #   end

  #   def draw(offset: [0,0])
  #     ox, oy = *offset
  #     inscribe figure: @figure, at: [@x + ox, @y + oy]
  #     inscribe figure: @text,   at: [@x + ox - @text.length/2, @y + oy + 1]
  #   end
  # end

  # class Grid < Component
  #   attr_accessor :x, :y
  #   def initialize(x:, y:, field:, legend:)
  #     @x, @y, @field = x, y, field
  #     @legend = legend
  #     @marks = []
  #   end

  #   def show(mark)
  #     @marks << mark
  #   end

  #   def figure_at(px,py)
  #     @legend[value_at(px,py)]
  #   end

  #   def value_at(px,py)
  #     @field[py][px]
  #   end

  #   def width
  #     @field[0].length
  #   end

  #   def height
  #     @field.length
  #   end

  #   def each_position
  #     (0...width).each do |xi|
  #       (0...height).each do |yi|
  #         yield [xi,yi]
  #       end
  #     end
  #   end

  #   def draw
  #     each_position do |(xi,yi)|
  #       figure = figure_at(xi, yi)
  #       position = [ @x + xi, @y + yi ]
  #       inscribe figure: figure, at: position
  #     end

  #     @marks.each do |mark|
  #       mark.draw(offset: [@x, @y])
  #       # inscribe figure: mark.text, at: [ @x + mark.x, @y + mark.y]
  #     end
  #   end
  # end

  # class Container < Component
  #   def initialize(elements:, width:, height:, x: 0, y: 0)
  #     @elements = elements
  #     @x, @y, @width, @height = x, y, width, height
  #   end

  #   def draw
  #     begin
  #       cx, cy = @width/2, @height/2
  #       @elements.each do |element|
  #         translated_element = element.dup
  #         translated_element.x += (cx - translated_element.width/2)
  #         translated_element.y += (cy - translated_element.height/2)
  #         translated_element.draw
  #       end
  #     rescue
  #       log.error $!
  #     end
  #   end
  # end

  # class UI
  #   include Curses

  #   def initialize(keypress:, view:)
  #     @keypress_handler = keypress
  #     @render_view = view
  #   end

  #   def draw
  #     @render_view.call
  #     true
  #   end

  #   def launch!
  #     @ui = ui_core_thread
  #     @refresh = refresh_loop_thread
  #     [ @ui, @refresh ].map(&:join)
  #   end

  #   def quit?
  #     @quit ||= false
  #   end

  #   def quit!
  #     # EventMachine.stop
  #     @quit = true
  #   end

  #   def log
  #     @logger ||= Logger.new('log/screen.log')
  #   end

  #   protected
  #   def wait_for_keypress
  #     log.info "WAIT FOR KEYPRESS!!!!"
  #     @keypress_handler.call(getch)
  #   end

  #   private
  #   def refresh_loop_thread
  #     Thread.new do
  #       until quit?
  #         begin
  #           clear
  #           draw
  #           refresh
  #           sleep 0.1
  #         rescue
  #           log.error $!
  #         end
  #       end
  #     end
  #   end

  #   def ui_core_thread
  #     Thread.new do
  #       begin
  #         noecho
  #         init_screen
  #         wait_for_keypress until quit?
  #       rescue
  #         log.error $!
  #       ensure
  #         close_screen
  #       end
  #     end
  #   end
  # end
end
