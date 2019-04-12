# you can buy just a few things at this nanomart
require 'highline'

class Nanomart
  class NoSale < StandardError; end
  class NoItem < StandardError; end

  attr_reader :prompter, :registry

  def initialize(prompter = HighlinePrompter.new, registry = Item.registry)
    @prompter = prompter
    @registry = registry
  end

  def items(&block)
    block_given? ? registry.each(&block) : registry
  end

  def sell_me(item_type)
    item? item_type
    purchase(item_type, prompter.prompt)
    log_sale(item)
  rescue NoItem
    puts "Sorry, the item you've requested doesn't seem to be in stock"
  rescue NoSale
    puts "Sorry, you're not of legal age to purchase #{item.name}"
  end

  private

  def item?(item_name)
    return true if registry.any? { |item| item.name == item_name }

    raise NoItem
  end

  def purchase(item, age)
    return item if item.restrictions.all? { |r| r.check? age }

    raise Nanomart::NoSale
  end

  def log_sale(item)
    File.open(@logfile, 'a') { |f| f.write(item.name.to_s + "\n") }
  end
end

class HighlinePrompter
  def prompt
    HighLine.new.ask('Age? ', Integer) # prompts for user's age, reads it in
  end
end

module Restriction
  class NotImplemented < StandardError; end

  class Base
    def check(subject_age)
      raise NotImplemented, "#{self.class} has not implemented #check"
    end
  end

  class Foo < Base; end

  class DrinkingAge < Base
    DRINKING_AGE = 21

    attr_reader :age

    def initialize
      @age = DRINKING_AGE
    end

    def check(subject_age)
      subject_age > age
    end
  end

  class SmokingAge < Base
    SMOKING_AGE = 18

    def initialize
      @age = SMOKING_AGE
    end

    def check(age)
      subject_age > age
    end
  end

  class SundayBlueLaw < Base
    def initialize; end

    def check(_no_opts)
      Time.now.wday != 0 # 0 is Sunday
    end
  end
end

class Item
  class << self
    def inherited(subclass)
      registry << subclass.to_s.sub(/Item::/, '').to_sym
    end

    def registry
      @registry ||= []
    end
  end

  attr_reader :restrictions

  def initialize(restrictions = [])
    @restrictions = restrictions
  end

  def name
    class_string = self.class.to_s
    short_class_string = class_string.sub(/^Item::/, '')
    lower_class_string = short_class_string.downcase
    class_sym = lower_class_string.to_sym
    class_sym
  end

  class Beer < Item
    def initialize(restrictions = [])
      super(restrictions + [Restriction::DrinkingAge.new])
    end
  end

  class Whiskey < Item
    # you can't sell hard liquor on Sundays for some reason
    def initialize(restrictions = [])
      super(restrictions + [Restriction::DrinkingAge.new, Restriction::SundayBlueLaw.new])
    end
  end

  class Cigarettes < Item
    # you have to be of a certain age to buy tobacco
    def initialize(restrictions = [])
      super(restrictions + [Restriction::SmokingAge.new])
    end
  end

  class Cola < Item; end

  class CannedHaggis < Item
    # the common-case implementation of Item.nam doesn't work here
    def name
      :canned_haggis
    end
  end
end
