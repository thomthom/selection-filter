#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
require 'TT_Lib2/core.rb'

TT::Lib.compatible?('2.6.0', 'TT Selection Filter')

#-------------------------------------------------------------------------------


module TT::Plugins::SelectionFilter
  
  ### CONSTANTS ### ------------------------------------------------------------
  
  # Plugin information
  PLUGIN_ID       = 'TT_SelectionFilter'.freeze
  PLUGIN_NAME     = 'Selection Filter'.freeze
  PLUGIN_VERSION  = '0.1.0'.freeze
  
  
  ### MODULE VARIABLES ### -----------------------------------------------------
  
  # Preference
  @settings = TT::Settings.new( PLUGIN_ID )
  @settings.set_default( :filter, 'FooBar' )
  
  def self.settings; @settings; end
  
  
  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    # Menus
    m = TT.menu( 'Plugins' )
    m.add_item( 'Selection Filter' ) { self.selection_filter }
  end 
  
  
  ### MAIN SCRIPT ### ----------------------------------------------------------
  
  # @since 0.1.0
  def self.selection_filter
    unless @window
      props = {
        :dialog_title => 'Selection Filter',
        :width => 300,
        :height => 85,
        :resizable => false
      }
      @window = TT::GUI::ToolWindow.new( props )
      @window.theme = TT::GUI::Window::THEME_GRAPHITE
      
      change_event = proc { |control|
        self.filter_changed( control.value )
      }
      
      txtFilter = TT::GUI::Textbox.new( @settings[:filter] )
      txtFilter.top = 5
      txtFilter.right = 5
      txtFilter.width = 250
      #txtFilter.add_event_handler( :change, &change_event )
      #txtFilter.add_event_handler( :keyup, &change_event )
      #txtFilter.add_event_handler( :cut, &change_event )
      #txtFilter.add_event_handler( :paste, &change_event )
      txtFilter.add_event_handler( :textchange, &change_event )
      @window.add_control( txtFilter )
      
      lblFilter = TT::GUI::Label.new( 'Filter:', txtFilter )
      lblFilter.top = 5
      lblFilter.left = 5
      @window.add_control( lblFilter )
      
      btnClose = TT::GUI::Button.new( 'Close' ) { |control|
        control.window.close
      }
      btnClose.size( 75, 23 )
      btnClose.right = 5
      btnClose.bottom = 5
      @window.add_control( btnClose )
    end
    
    @window.show_window
    @window
  end
  
  
  # Avoid modifiying the selection too often by adding a small delay and
  # ensuring the filter has changed since last time.
  #
  # @since 0.1.0
  def self.filter_changed( filter )
    @last_filter ||= ''
    return false if filter.empty?
    return false if filter == @last_filter
    
    UI.stop_timer( @timer ) if @timer
    @timer = UI.start_timer( 0.3, false ) {
      UI.stop_timer( @timer ) # Just to ensure it only runs once.
      self.select_by_filter( filter )
    }
  end
  
  
  # @since 0.1.0
  def self.select_by_filter( filter )
    selection = Sketchup.active_model.selection
    new_selection = []
    for entity in Sketchup.active_model.active_entities
      next unless TT::Instance.is?( entity )
      d = TT::Instance.definition( entity )
      if entity.name.include?( filter ) || d.name.include?( filter )
        new_selection << entity
      end
    end
    p "select_by_filter( '#{filter}', #{new_selection.size} )"
    selection.clear
    selection.add( new_selection )
    @last_filter = filter
    @settings[:filter] = filter
  end
  
  
  ### DEBUG ### ----------------------------------------------------------------
  
  # @note Debug method to reload the plugin.
  #
  # @example
  #   TT::Plugins::Shell.reload
  #
  # @param [Boolean] tt_lib
  #
  # @return [Integer]
  # @since 0.1.0
  def self.reload( tt_lib = false )
    original_verbose = $VERBOSE
    $VERBOSE = nil
    TT::Lib.reload if tt_lib
    # Core file (this)
    load __FILE__
    # Supporting files
    1
  ensure
    $VERBOSE = original_verbose
  end
  
  
end # module

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------