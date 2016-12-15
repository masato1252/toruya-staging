class Customers::Filter < ActiveInteraction::Base
  PATTERN = [
    %w(あ い う え お ア イ ウ エ オ),
    %w(か き く け こ カ キ ク ケ コ),
    %w(さ し す せ そ サ シ ス セ ソ),
    %w(た ち つ て と タ チ ツ テ ト),
    %w(な に ぬ ね の ナ ニ ヌ ネ ノ),
    %w(は ひ ふ へ ほ ハ ヒ フ ヘ ホ),
    %w(ま み む め も マ ミ ム メ モ),
    %w(や ゐ ゆ ゑ よ ヤ ヰ ユ ヱ ヨ),
    %w(ら り る れ ろ ラ リ ル レ ロ),
    %w(わ を ん ワ ヲ ン),
    ('a'..'z').to_a
  ]
  object :super_user, class: User
  integer :pattern_number
  integer :last_customer_id, default: nil
  integer :pre_page, default: 50

  def execute
    scoped = super_user.customers.order("id").limit(pre_page)
    scoped = scoped.where("id > ?", last_customer_id) if last_customer_id

    scoped.
      where("phonetic_last_name SIMILAR TO ?", "(#{regexp_pattern})%").
      or(
        scoped.where("phonetic_first_name SIMILAR TO ?", "(#{regexp_pattern})%")
      )
  end

  private

  def regexp_pattern
    @regexp_pattern ||= "#{PATTERN[pattern_number].join("|")}"
  end
end
