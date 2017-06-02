module Swearing
  # how could this *be* a component
  # is that worth it
  class Application
    include Curses

    def initialize #(view:)
      # @keypress_handler = keypress
      # @render_view = view
    end

    # should probably be private
    def inscribe(figure: 'X', at:)
      x, y = *at
      setpos(y, x)
      addstr(figure)
    end

    def draw(elements: view_model, origin: [0,0], dims: [cols, lines], mode: :row) #width: cols, height: lines)
      log.info "==== SWEARING::APPLICATION DRAW BEGIN (mode #{mode}) ==="
      # view = view_model #.map(&:render)
      log.info "view: #{elements.inspect}"
      # treat like lines for now?
      # ox,oy = *origin
      # width,height = *dims

      log.info "---> About to layout elements #{elements} in mode #{mode}"
      laid_out_elements = Layout.layout(elements, mode: mode, origin: origin, dims: dims)
      log.info "---> LAID OUT ELEMS: #{laid_out_elements}"

      laid_out_elements.each do |element| #, row_index|
        case element
        when Text then
          x,y = element._origin
          w,h = element._dims
          center = [x + w/2 - element.value.length/2, y + h/2]
          log.info "---> Inscribing #{element.value} at #{center}"
          inscribe(figure: element.value, at: center)
        when Container then
          draw(elements: element.contents, origin: element._origin, dims: element._dims, mode: Layout.flip_orientation(mode))
        else
          log.warn("unknown type of element: #{element}")
        end
      end
      log.info "==== SWEARING::APPLICATION DRAW COMPLETE ==="
      true
    end

    def launch!(dry_run: false)
      @ui = ui_core_thread(dry_run: dry_run)
      @refresh = refresh_loop_thread(dry_run: dry_run)
      [ @ui, @refresh ].map(&:join) unless dry_run
    end

    def quit?
      @quit ||= false
    end

    def quit!
      # EventMachine.stop
      @quit = true
    end

    def log
      @logger ||= Logger.new('swearing.log')
    end

    protected
    def wait_for_keypress
      # log.info "WAIT FOR KEYPRESS!!!!"
      key = getch
      case key
      when 'q', 'x' then quit!
      else log.info "PRESSED #{key}"
      end
    end

    private
    def refresh_loop_thread(dry_run:)
      Thread.new do
        return if dry_run
        until quit?
          begin
            clear
            draw
            refresh
            sleep 0.1
          rescue
            log.error $!
          end
        end
      end
    end

    def ui_core_thread(dry_run:)
      Thread.new do
        return if dry_run
        begin
          noecho
          init_screen
          wait_for_keypress until quit?
        rescue
          log.error $!
        ensure
          close_screen
        end
      end
    end
  end
end
