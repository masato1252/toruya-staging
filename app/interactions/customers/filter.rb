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
  SORT_ORDER = %w(あ ア い イ う ウ え エ お オ か カ き キ く ク け ケ こ コ さ サ し シ す ス せ セ そ ソ た タ ち チ つ ツ て テ と ト な ナ に ニ ぬ ヌ ね ネ の ノ は ハ ひ ヒ ふ フ へ ほ ホ ま マ み ミ む ム め メ も モ や ヤ ゐ ヰ ゆ ユ ゑ ヱ よ ヨ ら ラ り リ る ル れ レ ろ ロ わ ワ を ヲ ん ン)
  COMPARE_LENGTH = SORT_ORDER.length

  object :super_user, class: User
  integer :pattern_number
  integer :last_customer_id, default: nil
  integer :pre_page, default: 50

  def execute
    scoped = super_user.customers.includes(:rank, :contact_group).order("id").limit(pre_page)
    scoped = scoped.where("id > ?", last_customer_id) if last_customer_id

    scoped = scoped.
      where("phonetic_last_name ~* ?", "^(#{regexp_pattern}).*$").
      or(
        scoped.where("phonetic_first_name ~* ?", "^(#{regexp_pattern}).*$")
      )

    scoped.to_a.sort do |x, y|
      result = 0
      n = 0

      if x.phonetic_name.nil? || y.phonetic_name.nil?
        if x.phonetic_name.present?
          -1
        elsif y.phonetic_name.present?
          1
        else
          0
        end
      else
        begin
          # XXX: becasue there is unexpected characters so we need COMPARE_LENGTH to make sure we have a value to compare.
          first_word_character_index = (SORT_ORDER.index(x.phonetic_name_for_compare[n]) || COMPARE_LENGTH)
          another_word_character_index = (SORT_ORDER.index(y.phonetic_name_for_compare[n]) || COMPARE_LENGTH)
          result = first_word_character_index <=> another_word_character_index

          n += 1
        end until result != 0

        result
      end
    end
  end

  private

  def regexp_pattern
    @regexp_pattern ||= "#{PATTERN[pattern_number].join("|")}"
  end
end
