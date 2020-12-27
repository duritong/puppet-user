class SubIdsHelper
  def self.parse(file)
    File.readlines(file).each_with_object({}) do |line,res|
      line.chomp!
      next if line !~ /^[^:]+:[^:]+:[^:]+$/
      id,start,count = line.split(':',3)
      next unless id && start && count
      res[id] = { 'start' => start, 'count' => count }
    end
  end
end
['uid','gid'].each do |i|
  Facter.add("subids.#{i}s") do
    confine :kernel => 'Linux'
    confine { File.readable?("/etc/sub#{i}") }
    setcode do
      SubIdsHelper.parse("/etc/sub#{i}")
    end
  end
end
