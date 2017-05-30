module Swearing
  # class Property
  # end

  # class Template
  # end

  class Component
    include Curses
    attr_reader :components

    def initialize(data={})

      @data = data # OpenStruct.new(properties)
      # could validate properties according to schema?
      # and emit warnings if things don't conform...

      if self.class.data
        @data.merge!(self.class.data.call)
      end

      # verify! #(@properties)
      puts "---> Initialized #{self.class.name} component with data: #@data"
    end

    # mode = :screen / :plain
    def render(mode=:screen) #, props={})
      # merged_props = (@properties.merge(props))
      # binding.pry
      if self.class.render_method
        puts "RENDER METHOD"
        self.class.render_method.call(@data) #@properties.merge(props))
      elsif self.class.template
        puts "RENDER TEMPLATE"
        self.class.template % @data
        # self.class.template.map do |subcomponent|
        #   subcomponent.render(mode, merged_props)
        # end
      elsif self.class.components
        @components = self.class.components.inject({}) do |hash, (name, component_type)|
          # only pass @data that subcomponent actually needs???
          subcomponent = component_type.new(@data)
          hash[name] = subcomponent
          hash
        end

        @components.map do |name, component|
          component.render(mode) #, @properties)
        end
      end
    end

    def click!
      handler = self.class.on[:click]
      if handler
        handler.call(@data)
      else
        raise "no click handler registered for #{self.class.name}"
      end
    end

    protected
    def log
      @logger = Logger.new('log/swearing.log')
    end

    class << self
      attr_accessor :properties, :data, :template, :render_method, :components, :on
      def define(properties: {}, template: nil, render: nil, components: {}, data: nil, on: {})
        klass = Class.new(Component)
        klass.properties = properties
        klass.template = template
        klass.render_method = render
        klass.components = components
        klass.data = data
        klass.on = on
        klass
      end
    end
  end
end
