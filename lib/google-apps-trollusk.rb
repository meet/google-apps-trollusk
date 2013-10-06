require 'watir-webdriver'
require 'headless'

module GoogleApps
  
  # He only wants the letters for the stamps!
  class Trollusk
    
    class Connection
      
      def initialize(domain, username, password, headless = false)
        @headless = headless
        if headless
          @h = Headless.new
          @h.start
        end
        @b = Watir::Browser.start "https://www.google.com/a/cpanel/#{domain}"#, :chrome#, :path => '/usr/lib64/chromium-browser/chromium-browser'
        @b.text_field(:id => 'Email').set "#{username}@#{domain}"
        @b.text_field(:id => 'Passwd').set password
        @b.button(:id => 'signIn').click
        @domain = domain
        @current_user = nil
        @cpanel = "https://admin.google.com/#{domain}/"
      end
      
      def open(username)
        @b.goto "#{@cpanel}Organization?userEmail=#{username}@#{@domain}" unless @current_user == username
        @current_user = username
        
        # Wait until all the AJAX is done loading.
        @b.checkbox(:name => 'googleAppsEmailEnabled').wait_until_present
        @b
      end
      
      def get_user(username)
        User.new(username, self)
      end
      
      def close
        @b.close
        @h.destroy if @headless
      end
    end
    
    class User #< Struct.new(:username, :deliver_to_inbox, :inherit_routes, :routes)
      attr_accessor :username, :deliver_to_inbox, :inherit_routes, :routes
      
      def initialize(username, conn)
        @username = username
        @conn = conn
        load_from_conn
      end

      #Set whether email is delivered to the GMail inbox
      def deliver_to_inbox(inbox)
        deliver_to_inbox_elt.set inbox
        # @deliver_to_inbox = inbox
      end
      
      # Add a routing destination.
      def add_route(destination)
        # Find the number of current routes:
        idx = @routes.length + 1
        # Hit the button to add a new destination.
        add_destination_elt.click
        
        # Write the info:
        route_enabled_elt(idx).set true
        route_rewrite_to_elt(idx).set true
        route_destination_elt(idx).set destination
        
        # @routes.push(Route.new(destination, true, true))
      end

      def remove_route(old_destination)
        # Find the index of the destination
        idx = @routes.find_index{|r| r.destination == old_destination}
        return false if @routes.nil?
        idx = idx + 1
        remove_destination_elt(idx).click
        # @routes.delete_at(idx - 1)
        true
      end
      
      def remove_all_routes
        Array.new(@routes).map{|r| remove_route(r.destination)}
        @routes
      end
      
      def update_route(old_destination, new_destination)
        # Find the index of the destination
        idx = @routes.find_index{|r| r.destination == old_destination} + 1
        route_destination_elt(idx).set new_destination
        # @routes[idx].destination = new_destination
      end
      
      def save_changes
        elt = save_changes_elt
        return false unless elt.exists?
        elt.click
        raise TrolluskError.new("Routing error.") if route_error_elt.exists?
        load_from_conn
        true
      end
      
      def undo_changes
        elt = discard_changes_elt
        return false unless elt.exists?
        elt.click
        load_from_conn
        true
      end
      
      def load_from_conn
        ensure_user_open
        @deliver_to_inbox = deliver_to_inbox_elt.set?
        @inherit_routes = inherit_routes_elt.set?
        @routes = []
        idx = 1
        while route_enabled_elt(idx).exists?
          enabled = route_enabled_elt(idx).set?
          destination = route_destination_elt(idx).value
          rewrite = route_rewrite_to_elt(idx).set?
          @routes.push(Route.new(destination, rewrite==true, enabled==true))
          idx = idx + 1
        end
      end
      
      private
      def ensure_user_open
        @b = @conn.open(username)
      end
      
      def add_destination_elt
        ensure_user_open
        @b.div(:xpath => "//div[.='Email routing']/ancestor::tr[1]//div[.='Add another destination']").when_present
      end
      
      def save_changes_elt
        ensure_user_open
        @b.div(:xpath => "//div[contains(@class, 'pendingPanel')]//div[.='Save changes']").when_present
      end
      
      def discard_changes_elt
        ensure_user_open
        @b.div(:xpath => "//div[contains(@class, 'pendingPanel')]//div[.='Discard changes']").when_present
      end
      
      def remove_destination_elt(idx)
        ensure_user_open
        @b.div(:xpath => "//input[@name='routeDestination#{idx}']/ancestor::tr[1]//div[.='Remove']").when_present
      end
      
      def deliver_to_inbox_elt
        ensure_user_open
        @b.checkbox(:name => 'googleAppsEmailEnabled').when_present
      end
      
      def inherit_routes_elt
        ensure_user_open
        @b.checkbox(:name => 'inheritRoutesEnabled').when_present
      end
      
      def route_enabled_elt(idx)
        ensure_user_open
        @b.checkbox(:name => "routeEnabled#{idx}")
      end
      
      def route_rewrite_to_elt(idx)
        ensure_user_open
        @b.checkbox(:name => "routeRewriteTo#{idx}")
      end
      
      def route_destination_elt(idx)
        ensure_user_open
        @b.text_field(:name => "routeDestination#{idx}")
      end
      
      def route_error_elt
        ensure_user_open
        @b.div(:xpath => "//div[.='Email routing']/ancestor::tr[1]//div[contains(@class, 'errormsg') and normalize-space()!='']")
      end
    end
    
    class Route #< Struct.new(:destination, :rewrite_to, :enabled)
      attr_accessor :destination, :rewrite_to, :enabled
      
      def initialize(destination, rewrite_to, enabled)
        @destination = destination
        @rewrite_to = rewrite_to
        @enabled = enabled
      end
    end

    @@connection_params = { }
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
      headless = @@connection_params[:headless]
      
      t = self.new(domain, username, password, headless)
      yield t
      t.close
    end
    
    def initialize(domain, username, password, headless)
      @c = Connection.new(domain, username, password, headless)
    end
    
    def get(username)
      @c.get_user username
    end

    def close
      @c.close
    end
    
    # Set whether mail is delivered to the Google Apps inbox.
    def deliver_to_inbox(username, inbox)
      u = get(username)
      u.deliver_to_inbox inbox
      u.save_changes
    end
    
    # Add a routing destination.
    def add(username, destination)
      u = get(username)
      u.add_route(destination)
      u.save_changes
    end
    
    # Replace a routing destination.
    def update(username, old_destination, new_destination)
      u = get(username)
      u.update_route(old_destination, new_destination)
      u.save_changes
    end
    
    # Remove a routing destination.
    def remove(username, destination)
      u = get(username)
      u.remove_route(destination)
      u.save_changes
    end
    
    # If destination_or_inbox is +'inbox'+, deliver only to inbox; otherwise,
    # deliver only to the given destination, removing any other destinations.
    def only(username, destination_or_inbox)
      u = get(username)
      if destination_or_inbox == 'inbox'
        u.deliver_to_inbox true
        u.remove_all_routes
      else
        u.deliver_to_inbox false
        u.remove_all_routes
        u.add_route destination_or_inbox
      end
      u.save_changes
    end

  end
  
  class MockTrollusk < Trollusk
    
    @@commands = [ ]
    
    def self.commands
      @@commands
    end
    
    def initialize
    end

    def only(username, destination_or_inbox)
      cmd("#{username} only #{destination_or_inbox}")
    end
    
    def remove(username, destination)
      cmd("#{username} remove #{destination}")
    end
    
    def update(username, old_destination, new_destination)
      cmd("#{username} update #{old_destination} #{new_destination}")
    end
    
    def add(username, destination)
      cmd("#{username} add #{destination}")
    end
    
    def deliver_to_inbox(username, inbox)
      cmd("#{username} inbox #{inbox}")
    end

    def get(username)
      cmd("#{username} get")
    end
    
    private
      
      def cmd(string)
        @@commands << string
      end
      
  end
  
  class TrolluskError < RuntimeError
  end
  
end
