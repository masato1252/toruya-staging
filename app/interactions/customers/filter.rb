class Customers::Filter < ActiveInteraction::Base
  PATTERN = [
    %w(あ い う え お ア イ ウ エ オ),
    %w(か き く け こ が ぎ ぐ げ ご カ キ ク ケ コ ガ ギ グ ゲ ゴ),
    %w(さ し す せ そ ざ じ ず ぜ ぞ サ シ ス セ ソ ザ ジ ズ ゼ ゾ),
    %w(た ち つ て と だ ぢ づ で ど タ チ ツ テ ト ダ ヂ ヅ デ ド),
    %w(は ひ ふ へ ほ ば び ぶ べ ぼ ぱ ぴ ぷ ぺ ぽ ハ ヒ フ ヘ ホ バ ビ ブ ベ ボ パ ピ プ ペ ポ),
    %w(は ひ ふ へ ほ ハ ヒ フ ヘ ホ),
    %w(ま み む め も マ ミ ム メ モ),
    %w(や ゐ ゆ ゑ よ ヤ ヰ ユ ヱ ヨ),
    %w(ら り る れ ろ ラ リ ル レ ロ),
    %w(わ を ん ワ ヲ ン),
    ('a'..'z').to_a
  ]

  object :super_user, class: User
  integer :pattern_number
  integer :page, default: 1
  integer :pre_page, default: Customers::Search::PER_PAGE

  def execute
    scoped = super_user.customers.jp_chars_order.includes(:rank, :contact_group, :updated_by_user).page(page).per(pre_page)

    scoped.where("phonetic_last_name ~* ?", "^(#{regexp_pattern}).*$")
  end

  private

  def regexp_pattern
    @regexp_pattern ||= "#{PATTERN[pattern_number].join("|")}"
  end
end
