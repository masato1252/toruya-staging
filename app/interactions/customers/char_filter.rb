class Customers::CharFilter < ActiveInteraction::Base
  PATTERN = [
    %w(あ ア い イ う ウ え エ お オ),
    %w(か カ き キ く ク け ケ こ コ が ガ ぎ ギ ぐ グ げ ゲ ご ゴ),
    %w(さ サ し シ す ス せ セ そ ソ ざ ザ じ ジ ず ズ ぜ ゼ ぞ ゾ),
    %w(た タ ち チ つ ツ て テ と ト だ ダ ぢ ヂ づ ヅ で デ ど ド),
    %w(な ナ に ニ ぬ ヌ ね ネ の ノ),
    %w(は ハ ひ ヒ ふ フ へ ヘ ほ ホ ば バ び ビ ぶ ブ べ ベ ぼ ボ ぱ パ ぴ ピ ぷ プ ぺ ペ ぽ ポ),
    %w(ま マ み ミ む ム め メ も モ),
    %w(や ヤ ゐ ヰ ゆ ユ ゑ ヱ よ ヨ),
    %w(ら ラ り リ る ル れ レ ろ ロ),
    %w(わ ワ を ヲ ん ン),
    ('a'..'z').to_a
  ]

  object :super_user, class: User
  object :current_user_staff, class: Staff
  integer :pattern_number
  integer :page, default: 1
  integer :pre_page, default: Customers::Search::PER_PAGE

  def execute
    scoped =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .jp_chars_order.includes(:rank, :contact_group, updated_by_user: :profile).page(page).per(pre_page)

    scoped.where("phonetic_last_name ~* ?", "^(#{regexp_pattern}).*$")
  end

  private

  def regexp_pattern
    @regexp_pattern ||= "#{PATTERN[pattern_number].join("|")}"
  end
end
