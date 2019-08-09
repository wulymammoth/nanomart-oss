# you can buy just a few things at this nanomart
require 'highline'

class Nanomart
  class NoSale < StandardError; end

  attr_reader :considerations, :logfile

  def initialize(logfile, prompter)
    @logfile              = logfile
    @prompter             = prompter
    @considerations       = {}
  end

  def log_sale(item)
    File.open(logfile, 'a') { |f| f.write(item.nam.to_s + "\n") }
  end

  def sell_me(itm_type)
    key = itm_type.to_s.downcase.delete('_')
    raise "#{itm_type} not found" unless Item.registry.key? key

    considerations[:age] = @prompter.get_age

    item = Item.registry[key].new
    raise Nanomart::NoSale if item.restricted?(considerations)

    log_sale(item)
  end
end

class HighlinePrompter
  def get_age
    HighLine.new.ask('Age? ', Integer) # prompts for user's age, reads it in
  end
end


class Restriction
  DRINKING_AGE = 21
  SMOKING_AGE = 18

  attr_reader :considerations

  def initialize(considerations)
    @considerations = considerations
  end

  class DrinkingAge < Restriction
    def ck
      considerations[:age] >= DRINKING_AGE
    end
  end

  class SmokingAge < Restriction
    def ck
      considerations[:age] >= SMOKING_AGE
    end
  end

  class SundayBlueLaw < Restriction
    def ck
      Time.now.wday != 0 # 0 is Sunday
    end
  end
end

class Item
  @registry = {}

  class << self
    attr_reader :registry

    def inherited(subclass)
      @registry[subclass.to_s.split('::').last.downcase] = subclass
    end
  end

  attr_reader :nam

  def initialize
    class_string = self.class.to_s
    short_class_string = class_string.sub(/^Item::/, '')
    lower_class_string = short_class_string.downcase
    class_sym = lower_class_string.to_sym
    nam = class_sym
  end

  def rstrctns
    raise NotImplementedError
  end

  def restricted?(considerations)
    rstrctns.any? { |restriction| restriction.new(considerations).ck == false }
  end

  class Beer < Item
    def rstrctns
      [Restriction::DrinkingAge]
    end
  end

  class Whiskey < Item
    # you can't sell hard liquor on Sundays for some reason
    def rstrctns
      [Restriction::DrinkingAge, Restriction::SundayBlueLaw]
    end
  end

  class Cigarettes < Item
    # you have to be of a certain age to buy tobacco
    def rstrctns
      [Restriction::SmokingAge]
    end
  end

  class Cola < Item
    def rstrctns
      []
    end
  end

  class CannedHaggis < Item
    # the common-case implementation of Item.nam doesn't work here
    def nam
      :canned_haggis
    end

    def rstrctns
      []
    end
  end
end

