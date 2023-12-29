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
Facter.add("subids") do
  confine :kernel => 'Linux'
  confine { File.readable?("/etc/subuid") }
  confine { File.readable?("/etc/subgid") }
  setcode do
    Hash[['uid','gid'].collect do |i|
      ["#{i}s",SubIdsHelper.parse("/etc/sub#{i}")]
    end]
  end
end
