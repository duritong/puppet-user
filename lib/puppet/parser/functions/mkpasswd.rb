module Puppet::Parser::Functions
  newfunction(:mkpasswd, :type => :rvalue, :doc =>
    "Returns a salted md5 hash to be used for shadowed passwords") do |args|
    raise Puppet::ParseError, "Wrong number of arguments" unless args.length == 2
    raise Puppet::ParseError, "Salt must be 8 characters long" unless args[1].length == 8
    args[0].crypt('$1$' << args[1] << '$')
  end
end
