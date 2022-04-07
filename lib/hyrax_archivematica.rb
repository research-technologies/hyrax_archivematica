class HyraxArchivematica
  class << self
    def self.hi
      puts "Archivematica is here!"
    end

    # this function maps the vars from your app into your engine
    def self.config
      yield self
    end
  end
end
