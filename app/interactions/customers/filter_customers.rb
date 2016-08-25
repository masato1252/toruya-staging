class Customers::FilterCustomers < ActiveInteraction::Base
  PATTERN = [
    %w(あ い う え お),
    %w(か き く け こ が ぎ ぐ げ ご),
    %w(さ し す せ そ ざ じ ず ぜ ぞ),
    %w(た ち つ て と だ ぢ づ で ど),
    %w(な に ぬ ね の),
    %w(は ひ ふ へ ほ ば び ぶ べ ぼ ぱ ぴ ぷ ぺ ぽ),
    %w(ま み む め も),
    %w(や ゆ よ),
    %w(ら り る れ ろ),
    %w(わ を ん),
    ('a'..'z').to_a
  ]
  integer :pattern_number

  def execute
    scoped = Customer.all
    scoped.
      where("jp_last_name SIMILAR TO ?", "(#{regexp_pattern})%").
      or(
        scoped.where("jp_first_name SIMILAR TO ?", "(#{regexp_pattern})%")
      )
  end

  private

  def regexp_pattern
    @regexp_pattern ||= "#{Customers::FilterCustomers::PATTERN[pattern_number].join("|")}"
  end
end
