require 'rexml/document'
require 'watir-webdriver'
require 'headless'

module GoogleApps
  
  # He only wants the letters for the stamps!
  class Trollusk
    
    class User < Struct.new(:username, :deliver_to_inbox, :inherit_routes, :routes)
    end
    class Route < Struct.new(:destination, :rewrite_to, :enabled)
    end

    @@connection_params = { }
    @@cpanel = "https://admin.google.com/meet.mit.edu/"
    # Add connection parameters.
    def self.connect_with(connection_params)
      @@connection_params.merge!(connection_params)
    end
    
    # Log in to the user-level email routing admin console.
    def self.connect
      yield MockTrollusk.new and return if @@connection_params[:mock]
      
      domain = @@connection_params[:domain]
      username = @@connection_params[:username]
      password = @@connection_params[:password]
      
      #raise TrolluskError.new("Missing #{jar}") unless File.exists? "#{path}/#{jar}"
      #cmd = "java -jar '#{path}/#{jar}' '#{domain}' '#{username}'"
      #IO.popen(cmd, 'r+') do |io|
      #  yield self.new(io, @@connection_params[:password])
      #  io.close_write
      #end
      self.new(domain, username, password)
    end
    
    def self.parse(user)
      if m = user.match(/Exception:(.*)/)
        raise m[1]
      end
      m = user.match(/UserEmailRouting<(.*?):(.*?),(.*?),\[(.*)\]>/)
      routes = m[4].scan(/UserEmailRoute<(.*?),(.*?),(.*?)>/).map do |arr|
        Route.new(arr[0], arr[1]!='-', arr[2]=='true')
      end
      User.new(m[1], m[2]!='-', m[3]!='-', routes)
    end
    
    def initialize(domain, username, password)
      #@c = Connection.new(domain, username, password)
      #@h = Headless.new
      #@h.start
      @b = Watir::Browser.start "https://www.google.com/a/cpanel/#{domain}"#, :chrome#, :path => '/usr/lib64/chromium-browser/chromium-browser'
      @b.text_field(:id => 'Email').set "#{username}@#{domain}"
      @b.text_field(:id => 'Passwd').set password
      @b.button(:id => 'signIn').click
      @domain = domain
      @current_user = nil
      #raise TrolluskError.new('Authentication missing') unless io.gets.strip == 'password'
      #io.puts self.class.obfuscate(password)
      #raise TrolluskError.new('Authentication failed') unless io.gets.strip == 'ok'
      #@io = io
    end
    
    def getBrowser
      @b
    end
    
    def get(username)
      # Load the user's page.
      open(username)
      inbox = deliver_to_inbox_elt.set?
      inherit = inherit_routes_elt.set?
      routes = []
      idx = 1
      while route_enabled_elt(idx).exists?
        enabled = route_enabled_elt(idx).set?
        destination = route_destination_elt(idx).value
        rewrite = route_rewrite_to_elt(idx).set?
        routes.push(Route.new(destination, rewrite==true, enabled==true))
        idx = idx + 1
      end
      User.new(username, inbox, inherit, routes)
    end
    
    # Set whether mail is delivered to the Google Apps inbox.
    def deliver_to_inbox(username, inbox)
      open(username)
      deliver_to_inbox_elt.set inbox
      save
      get(username)
    end
    
    # Add a routing destination.
    def add(username, destination)
      open(username)
      u = get(username)
      # Find the number of current routes:
      idx = u.routes.length + 1
      # Hit the button to add a new destination.
      @b.div(:text => 'Add another destination').click
      # Write the info:
      route_enabled_elt(idx).set true
      route_rewrite_to_elt(idx).set true
      route_destination_elt(idx).set destination
      save
      get(username)
    end
    
    # Replace a routing destination.
    def update(username, old_destination, new_destination)
      u = get(username)
      # Find the index of the destination
      idx = username.routes.find_index{|r| r.destination == old_destination} + 1
      route_destination_elt(idx).set new_destination
      save
      get(username)
    end
    
    # Remove a routing destination.
    def remove(username, destination)
      u = get(username)
      # Find the index of the destination
      idx = username.routes.find_index{|r| r.destination == old_destination} + 1
      raise TrolluskError.new("Unimplemented")
    end
    
    # If destination_or_inbox is +'inbox'+, deliver only to inbox; otherwise,
    # deliver only to the given destination, removing any other destinations.
    def only(username, destination_or_inbox)
      u = get(username)
      if destination_or_inbox == 'inbox'
        deliver_to_inbox(username, true)
        u.routes.for_each{|r| remove(username, r.destination)}
      end
      raise TrolluskError.new("Unimplemented")
    end
    
    def add_destination_elt
      @b.div(:xpath => "//div[.='Email routing']/ancestor::tr[1]//div[.='Add another destination']")
    end
    
    def save_changes_elt
      @b.div(:xpath => "//div[contains(@class, 'pendingPanel')]//div[.='Save changes']")
    end
    
    def remove_destination_elt(idx)
      @b.div(:xpath => "//input[@name='routeDestination#{idx}']/ancestor::tr[1]//div[.='Remove']")
    end

    private
      def deliver_to_inbox_elt
        @b.checkbox(:name => 'googleAppsEmailEnabled')
      end
      
      def inherit_routes_elt
        @b.checkbox(:name => 'inheritRoutesEnabled')
      end
      
      def route_enabled_elt(idx)
        @b.checkbox(:name => "routeEnabled#{idx}")
      end
      
      def route_rewrite_to_elt(idx)
        @b.checkbox(:name => "routeRewriteTo#{idx}")
      end
      
      def route_destination_elt(idx)
        @b.text_field(:name => "routeDestination#{idx}")
      end
      
      
      
      def save
        elt = save_changes_elt
        if elt.exists?
          elt.click
          true
        else
          false
        end
      end
      
      # Get current routing settings.
      def open(username)
        @b.goto "#{@@cpanel}Organization?userEmail=#{username}@#{@domain}" unless @current_user == username
        @current_user = username
        # Wait until all the stupid AJAX is done loading.
        done_loading = false
        while not deliver_to_inbox_elt.exists?
          sleep(0.5)
        end
      end
    end
  
  class MockTrollusk < Trollusk
    
    @@commands = [ ]
    
    def self.commands
      @@commands
    end
    
    def initialize
    end
    
    private
      
      def cmd(string)
        @@commands << string
      end
      
  end
  
  class TrolluskError < RuntimeError
  end
  
end
