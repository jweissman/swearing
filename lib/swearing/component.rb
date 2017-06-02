module Swearing
  # class Element
  # end
  # class Property
  # end

  # class Template
  # end

  class Component
    # include Curses
    attr_reader :components

    def initialize #(data={})
      # @data = data # OpenStruct.new(properties)
      # could validate properties according to schema?
      # and emit warnings if things don't conform...

      if self.class.data
        @data = self.class.data.call
        log.info "---> Initialized #{self.class.name} component with data: #@data"
      end

      # verify! #(@properties)
      log.info "---> Initializiation of #{self.class.name} component complete"
    end

    # mode = :screen / :plain
    def render(data={}) #(mode=:screen) #, props={})
      render_tree(data)
    end

    def resolve(tree)
      # tree is an array of hashes
      #
      log.info "---> RESOLVE TREE: #{tree.inspect}"
      binding.pry
      # recursively resolve components
      # in effect, we need to walk the tree...
      resolved_tree = tree.map do |elements_hash|
        elements_hash.inject({}) do |hash, (descriptor,args)|
          binding.pry
          hash[descriptor] = args
        end
        # elements.map(&method(:resolve_element))
      end
      log.info "---> RESOLVED TREE => #{resolved_tree}"
      resolved_tree
    end

    def resolve_element(element)
      # components_in_view = self.class.components # + Swearing::UI.components...
      (descriptor,args) = *element
      _desc,component = self.class.components.detect {|desc,_| desc == descriptor }
      if component
        log.info "---> Found component in view for #{descriptor}, rendering..."
        rendered = component.new.render(args)
        binding.pry
        rendered
      else
        log.info "---> No matching component for #{descriptor}, leaving alone..."
        element
      end
    end

    def render_tree(data={})
      log.info "---> Rendering tree for #{self.class.name} component started, with data #{data}"
      active_data = @data.nil? ? data : @data.merge(data)
      # merged_props = (@properties.merge(props))
      # binding.pry
      if self.class.render_method
        log.info "RENDER METHOD"
        if self.class.components
          @components = self.class.components.inject({}) do |hash, (name, component_type)|
            # only pass @data that subcomponent actually needs???
            subcomponent = component_type.new #(@data)
            hash[name] = subcomponent
            hash
          end

          self.class.render_method.call(active_data, @components) #@properties.merge(props))

        else
          self.class.render_method.call(active_data) #@properties.merge(props))
        end
      elsif self.class.template
        log.info "RENDER TEMPLATE"
        Text[self.class.template % active_data]
        # [ text: self.class.template % active_data ]
        # self.class.template.map do |subcomponent|
        #   subcomponent.render(mode, merged_props)
        # end

      # should parents manually have to render children????
      # elsif self.class.components
      #   @components = self.class.components.inject({}) do |hash, (name, component_type)|
      #     # only pass @data that subcomponent actually needs???
      #     subcomponent = component_type.new(@data)
      #     hash[name] = subcomponent
      #     hash
      #   end

      #   @components.map do |name, component|
      #     component.render(mode) #, @properties)
      #   end
      else
        log.warn "NO RENDER STRATEGY FOR #{self.class.name} COMPONENT?"
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
      @logger = Logger.new('swearing.log')
    end

    class << self
      attr_accessor :descriptor, :properties, :data, :template, :render_method, :components, :on
      def define(descriptor, properties: {}, template: nil, render: nil, components: {}, data: nil, on: {})
        klass = Class.new(Component)
        klass.descriptor = descriptor
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
