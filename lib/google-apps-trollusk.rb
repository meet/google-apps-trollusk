require 'rexml/document'

module GoogleApps
  
  # He only wants the letters for the stamps!
  class Trollusk
    
    class User < Struct.new(:username, :deliver_to_inbox?, :inherit_routes?, :routes)
    end
    class Route < Struct.new(:destination, :rewrite_to?, :enabled?)
    end
    
    # Log in to the user-level email routing admin console.
    def self.connect(domain, username, password)
      path = File.expand_path('../../', __FILE__)
      doc = REXML::Document.new(File.new("#{path}/pom.xml"))
      name = doc.elements['project/artifactId'].text
      version = doc.elements['project/version'].text
      cmd = "java -jar '#{path}/target/#{name}-#{version}-jar-with-dependencies.jar' '#{domain}' '#{username}'"
      IO.popen(cmd, 'r+') do |io|
        yield self.new(io, password)
        io.close_write
      end
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
    
    def initialize(io, password)
      raise 'Expected password prompt' unless io.gets.strip == 'password'
      io.puts password
      raise 'Expected ok' unless io.gets.strip == 'ok'
      @io = io
    end
    
    # Get current routing settings.
    def get(username)
      cmd("#{username} get")
    end
    
    # Set whether mail is delivered to the Google Apps inbox.
    def deliver_to_inbox(username, inbox)
      cmd("#{username} inbox #{inbox}")
    end
    
    # Add a routing destination.
    def add(username, destination)
      cmd("#{username} add #{destination}")
    end
    
    # Replace a routing destination.
    def update(username, old_destination, new_destination)
      cmd("#{username} update #{old_destination} #{new_destination}")
    end
    
    # Remove a routing destination.
    def remove(username, destination)
      cmd("#{username} remove #{destination}")
    end
    
    # If destination_or_inbox is +'inbox'+, deliver only to inbox; otherwise,
    # deliver only to the given destination, removing any other destinations.
    def only(username, destination_or_inbox)
      cmd("#{username} only #{destination_or_inbox}")
    end
    
    private
      
      def cmd(string)
        @io.puts(string)
        self.class.parse(@io.gets.strip)
      end
      
  end
  
end
