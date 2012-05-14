#!/usr/bin/ruby

require 'json'
require 'logger'
require 'gtk2'

require 'net/http'
require 'uri'

class RubyApp < Gtk::Window

  def initialize
    super

    set_title "Lua Parser"
    signal_connect "destroy" do
        Gtk.main_quit
    end

    @log = Logger.new(STDOUT)

    init_ui

    set_default_size 500, 300
    set_window_position Gtk::Window::POS_CENTER

    show_all

  end

  def populate_data
    @log.info("Hit here.")

    @data = ""

    Thread.new do
      @btn_fetch.sensitive = false
      if File.exists?("request.json")
        @log.info("Hit file.")
        req_file = File.open("request.json", "rb")
        begin
          @data = req_file.read
        rescue
          @log.info($!)
        end
      else
        @log.info("Hit request.")
        response = Net::HTTP.get_response("us.battle.net","/auction-data/ca865b592e25ff6e79f9d3a0fe7f2fac/auctions.json")
        @log.info("Hit downloaded.")
        @data = response.body

        @log.info("Hit parsed.")
        Thread.new do
          aFile = File.new("request.json", "w")
          aFile.write(response.body)
          aFile.close
          @log.info("Hit written.")
        end
      end

      @list_store_items.clear

      @log.info("Begin parsing.")

      begin
        @data = JSON.parse(@data)
      rescue
        @log.info($!)
      end

      @log.info("End parsing.")

      begin

        if !@data.empty? and !@data.nil?

          @log.info("Begin adding.")

          @data['horde']['auctions'].each do |a|
            cur = @list_store_items.append
            cur.set_value(0, "#{a['item']}")
            cur.set_value(1, a['owner'])
          end
        else
          @log.info("Data empty or nil.")
        end

        @log.info("End adding.")

      rescue
        @log.info($!)
      end
      @btn_fetch.sensitive = true
    end
  end

  def add_item_list

    tree_list = Gtk::TreeView.new
		@list_frame.add(tree_list)

		tree_column_item_name = Gtk::TreeViewColumn.new
		tree_column_item_name.title = "Item";

		tree_column_price = Gtk::TreeViewColumn.new
		tree_column_price.title = "Price";

		tree_list.append_column tree_column_item_name
    tree_list.append_column tree_column_price

		@list_store_items = Gtk::ListStore.new(String, String)
		tree_list.model = @list_store_items;

    cell_item_name = Gtk::CellRendererText.new
    tree_column_item_name.pack_start cell_item_name, true
    tree_column_item_name.add_attribute(cell_item_name, "text", 0)

    cell_price = Gtk::CellRendererText.new
    tree_column_price.pack_start cell_price, true
    tree_column_price.add_attribute(cell_price, "text", 1)

  end

  def init_ui

    parent_vbox = Gtk::VBox.new false, 2





    mb = Gtk::MenuBar.new

    filemenu = Gtk::Menu.new
    filem = Gtk::MenuItem.new "File"
    filem.set_submenu filemenu

    agr = Gtk::AccelGroup.new
    add_accel_group agr

    menu_open = Gtk::ImageMenuItem.new Gtk::Stock::OPEN, agr
    key, mod = Gtk::Accelerator.parse "O"
    menu_open.add_accelerator("activate", agr, key,
      mod, Gtk::ACCEL_VISIBLE)
    menu_open.signal_connect "activate" do
      @log.info("Activated.")
    end
    filemenu.append menu_open

    menu_quit = Gtk::ImageMenuItem.new Gtk::Stock::QUIT, agr
    key, mod = Gtk::Accelerator.parse "Q"
    menu_quit.add_accelerator("activate", agr, key,
      mod, Gtk::ACCEL_VISIBLE)
    menu_quit.signal_connect "activate" do
      Gtk.main_quit
    end
    filemenu.append menu_quit

    mb.append filem
    parent_vbox.pack_start mb, false, false, 0





    set_border_width 15

    table = Gtk::Table.new 8, 4, false
    table.set_column_spacings 3

    halign = Gtk::Alignment.new 0, 0, 0, 0

    table.attach(halign, 0, 1, 0, 1, Gtk::FILL,
        Gtk::FILL, 0, 0)

    @list_frame = Gtk::ScrolledWindow.new
    @list_frame.set_size_request(200, 300)

    table.attach(@list_frame, 0, 2, 1, 3, Gtk::FILL | Gtk::EXPAND,
        Gtk::FILL | Gtk::EXPAND, 1, 1)

    add_item_list

    @btn_fetch = Gtk::Button.new "Fetch"
    @btn_fetch.set_size_request 50, 30
    @btn_fetch.signal_connect "clicked" do
      populate_data
    end
    table.attach(@btn_fetch, 3, 4, 1, 2, Gtk::FILL,
        Gtk::SHRINK, 1, 1)

    #valign = Gtk::Alignment.new 0, 0, 0, 0
    #close = Gtk::Button.new "Close"
    #close.set_size_request 70, 30
    #valign.add close
    #table.set_row_spacing 1, 3
    #table.attach(valign, 3, 4, 2, 3, Gtk::FILL,
    #    Gtk::FILL | Gtk::EXPAND, 1, 1)

    halign2 = Gtk::Alignment.new 0, 1, 0, 0
    help = Gtk::Button.new "Help"
    help.set_size_request 70, 30
    help.signal_connect "clicked" do
      @log.info("CLicking!")
    end
    halign2.add help
    table.set_row_spacing 3, 6
    table.attach(halign2, 0, 1, 4, 5, Gtk::FILL,
        Gtk::FILL, 0, 0)

    #ok = Gtk::Button.new "OK"
    #ok.set_size_request 70, 30
    #table.attach(ok, 3, 4, 4, 5, Gtk::FILL,
    #    Gtk::FILL, 0, 0)

    parent_vbox.pack_start table, false, false, 0
    add parent_vbox
  end
end

Gtk.init
  window = RubyApp.new
Gtk.main
