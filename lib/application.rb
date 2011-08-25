require 'rubygems'
require 'hotcocoa'

class Square
  attr_accessor :flagged, :mined, :x, :y, :exposed, :neighboring_mines

  def initialize(x, y, mined)
    self.x = x
    self.y = y
    self.mined = mined
    self.flagged = false
    self.exposed = false
    self.neighboring_mines = nil
  end

  def mines_near
    count = 0
    [-1, 0, 1].each do |y_adj|
      [-1, 0, 1].each do |x_adj|
        index = ((y + y_adj) * 20) + (x + x_adj)
        next unless (0..400).include?(index)
        square = Application.board[index]
        next unless square
        count += 1 if square.mined
      end
    end
    count
  end

  def expose_neighbors
    [-1, 0, 1].each do |y_adj|
      [-1, 0, 1].each do |x_adj|
        next if y_adj == 0 && x_adj == 0
        index = ((y + y_adj) * 20) + (x + x_adj)
        next unless (0..400).include?(index)
        square = Application.board[index]
        next unless square
        next if square.exposed || square.neighboring_mines || square.flagged
        count = square.mines_near
        if count > 0
          square.neighboring_mines = count
        else
          square.exposed = true
          square.expose_neighbors
        end
      end
    end
  end
end

class SquareView < NSBox
  include HotCocoa::Behaviors

  DefaultSize = [30, 30]

  def self.create
    alloc.initWithFrame([0, 0, *DefaultSize])
  end

  def initWithFrame(frame)
    super
    self.layout = {}
    self.square = nil
    self
  end

  attr_accessor :square

  def drawRect(rect)
    NSColor.darkGrayColor.set
    NSRectFill(rect)
    (@square.exposed ? NSColor.whiteColor : NSColor.grayColor).set
    NSRectFill(NSInsetRect(rect, 1, 1))

    if @square.flagged
      img = NSImage.alloc.initWithContentsOfFile("resources/flag.png")
    elsif @square.mined && @square.exposed
      img = NSImage.alloc.initWithContentsOfFile("resources/bomb.png")
    end

    img.drawInRect(rect,fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0) if img

    if @square.neighboring_mines
      attributes = {
        NSForegroundColorAttributeName => NSColor.blueColor,
        NSFontAttributeName => NSFont.boldSystemFontOfSize(16.0)
      }
      str = @square.neighboring_mines.to_s
      str.drawAtPoint(NSPoint.new(10, 5), withAttributes:attributes)
    end
  end

  def mouseDown(event)
    if event.modifierFlags & NSCommandKeyMask == NSCommandKeyMask
      @square.flagged = !@square.flagged
      @square.neighboring_mines = @square.flagged ? nil : @square.mines_near
    else
      @square.exposed = true
      @square.neighboring_mines = nil
      end_game if @square.mined
      @square.expose_neighbors
    end
    self.borderType = NSLineBorder
    Application.boardView.setNeedsDisplay(true)
    #    self.needs_display = true
  end

  def end_game
    puts "Game Over"
  end

  def rightMouseDown(event)
    @square.flagged = true
    self.borderType = NSLineBorder
  end
end

class Application

  include HotCocoa

  def self.board
    @board
  end
  def self.board=(b)
    @board = b
  end

  def self.boardView
    @boardView
  end
  def self.boardView=(bv)
    @boardView = bv
  end

  def start
    reset_game
    application :name => "Minesweeper" do |app|
      app.delegate = self
        window :size => [620,620], :center => true, :title => "Minesweeper", :style => [:titled, :closable, :miniaturizable] do |win|
        win.will_close { exit }

        win.view = layout_view(:layout => {:expand => [:width, :height],
                                           :padding => 0, :margin => 0}) do |vert|
          # vert << layout_view(:frame => [0, 0, 0, 40], :mode => :horizontal,
          #                     :layout => {:padding => 0, :margin => 0,
          #                                 :start => false, :expand => [:width]}) do |horiz|
          #   horiz << @current_score = label(:text => "00", :layout => {:align => :center, :expand => [:width]})
          #   horiz << @clock_label = label(:text => "00:00", :layout => {:align => :center, :expand => [:width]})
          # end

          vert << Application.boardView = collection_view(:layout => {:expand => [:width, :height]}) do |board|
            board.item_view = view = SquareView.create
            view.bind "square", toObject:board.item_prototype,  withKeyPath:"representedObject", options:nil
            board.rows = 20
            board.columns = 20
            board.content = @board
          end
        end

      end
    end
  end

  # file/open
  #def on_open(menu)
  #end
  #

  # file/new
  def on_new(menu)
    reset_game
  end

  def reset_game
    Application.board = @board = []
    20.times do |y|
      20.times do |x|
        @board << Square.new(x, y, rand(400) < 50)
      end
    end
  end

  # help menu item
  def on_help(menu)
  end

  # This is commented out, so the minimize menu item is disabled
  def on_minimize(menu)
  end

  # window/zoom
  def on_zoom(menu)
  end

  # window/bring_all_to_front
  def on_bring_all_to_front(menu)
  end
end

Application.new.start
