# -*- ruby -*-
require 'active_record'

Numeric.class_eval do

  def ordinalize
    suffix = if (11..13).include?(self % 100)
      "th"
    else
      case self % 10
        when 1; "st"
        when 2; "nd"
        when 3; "rd"
        else    "th"
      end
    end
    "#{self}#{suffix}"
  end

  def to_money
    "$%.2f" % self
  end
  alias :money :to_money

  def to_dollars
    try(:/,100)
  end
  alias :to :to_dollars

  def to_cents
    try(:*,100).to_i
  end

  def as_time
    Time.at self
  end

  def to_pretty_time opts = {}
    as_time.pretty opts
  end
  alias :pretty :to_pretty_time

  def one?
    !!( self == 1 )
  end

  def two?
    !!( self == 2 )
  end

  def three?
    !!( self == 3 )
  end

  def not_zero?
    !!( self > 0 )
  end
  alias :ok? :not_zero?

  def as_phone
    to_s.as_phone_number
  end

end

Fixnum.class_eval do

  def to_d
    to_s.to_d
  end

  def to_money divisor=100
    to_d./(divisor).to_money
  end

  def to_dollar divisor=100
    to_d./(divisor)
  end
  alias :to_dollars :to_dollar

  def format_seconds
    if self > 60
      "%.1f min" % to_d./(60)
    else
      "%.1f sec" % to_d
    end
  end
  alias :to_minutes :format_seconds

end


String.class_eval do
  def remove pattern
    gsub pattern, ''
  end
  alias :cut :remove

  def dehumanize space_substitute = "-"
    if space_substitute.downcase.start_with?('camel')
      strip.downcase.cut(/[^a-z0-9\s]/).capitalize.gsub(/\s(.)/){$1.upcase}
    else
      strip.downcase.cut(/[^a-z0-9\s]/).gsub /\s/, space_substitute
    end
  end

  def as_time
    Time.at self.to_i
  end

  def to_cents
    to_d.to_cents
  end

  def numbers
    strip.remove(/\D/)
  end

  def phone_format
    strip.remove(/^\+?1/).remove(/\D/).gsub(/^(\d{3})(\d{3})(\d{3})/,'(\1) \2-\3')
  end

  def find_and_replace hash
    gsub Regexp.union(hash.keys), hash
  end

end

Date.class_eval do
  def pretty opts = {}
    to_time.pretty opts
  end

  def self.days_in_month month, year = Date.today.year
    new(year, month, -1).day
  end

  def weekday?
    to_time.weekday?
  end

  def school_year
    if Date.today.month > 7
      "#{Date.today.year}-#{Date.today.next_year.year.to_s[2..-1]}"
    else
      "#{Date.today.last_year.year}-#{Date.today.year.to_s[2..-1]}"
    end
  end

end

Time.class_eval do
  def pretty options = {}
    pretty = self.strftime('%B ')
    pretty = self.strftime('%b ') if options[:month] == :short
    pretty<< self.strftime('%d').to_i.ordinalize
    pretty<< self.strftime(', %Y') if options[:year] == true
    pretty<< self.strftime(" '%y") if options[:year] == :short
    pretty<< self.strftime(' at %-l:%M%P') if options[:time] == true
    pretty<< self.strftime(', %-l:%M%P') if options[:time] == :short
    pretty<< self.strftime(' (%-l%P)') if options[:time] == :hour
    pretty.prepend self.strftime('%A, ') if options[:day] == true
    pretty.prepend self.strftime('%a, ') if options[:day] == :short
    pretty
  end

  def to_epoch
    to_i
  end

  def to_serial_string
    strftime('%m%d%y%H%M%S')
  end

  def weekday?
    !!( monday? || tuesday? || wednesday? || thursday? || friday? )
  end

end

Hash.class_eval do
  def to_query_string
    Rack::Utils.build_nested_query self
  end
end


ActiveRecord::Base.class_eval do
  include ActiveModel::Serializers::JSON

  def self.attr_serializer *args
    aliases = args.extract_options!
    opt = {}
    define_method :attributes do
      args.each_with_object({}){ |attr,memo| memo[attr] = send(aliases[attr] || attr) }
    end
    define_method(:serializable_hash){ |opt| send(:attributes) }
  end

end
