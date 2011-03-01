require 'rubygems'
require 'bundler/setup'

require 'google-apps-trollusk'

require 'test/unit'

class UserTest < Test::Unit::TestCase
  
  T = GoogleApps::Trollusk
  
  def test_parse
    assert_equal T::User.new('user', true, true, []),
                 T.parse('UserEmailRouting<user:inbox,inherit,[]>')
    
    assert_equal T::User.new('user', false, true, []),
                 T.parse('UserEmailRouting<user:-,inherit,[]>')
    
    assert_equal T::User.new('alice', false, true, [ T::Route.new('user@example.com', false, true) ]),
                 T.parse('UserEmailRouting<alice:-,inherit,[UserEmailRoute<user@example.com,-,true>]>')
    
    assert_equal T::User.new('bob', true, false, [ T::Route.new('user@example.com', false, false),
                                                   T::Route.new('mail@example.net', true, true) ]),
                 T.parse('UserEmailRouting<bob:inbox,-,[UserEmailRoute<user@example.com,-,false>, UserEmailRoute<mail@example.net,rewrite,true>]>')
  end
  
end
