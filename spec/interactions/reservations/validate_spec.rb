# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Validate do
  before do
    Timecop.freeze(Time.local(2016, 12, 22, 10))
  end

  let(:shop) { FactoryBot.create(:shop) }
  let(:user) { shop.user }
  let(:reservation) { shop.reservations.new }
  let(:menu1) { FactoryBot.create(:menu, shop: shop, user: user, interval: 5) }
  let(:menu2) { FactoryBot.create(:menu, shop: shop, user: user, interval: 10) }
  let(:menu3) { FactoryBot.create(:menu, shop: shop, user: user, interval: 15) }
  let(:staff1) { FactoryBot.create(:staff, :full_time, shop: shop, user: user, menus: [ menu1, menu2, menu3 ]) }
  let(:staff2) { FactoryBot.create(:staff, :full_time, shop: shop, user: user, menus: [ menu1, menu2, menu3 ]) }
  let(:staff3) { FactoryBot.create(:staff, :full_time, shop: shop, user: user, menus: [ menu1, menu2, menu3 ]) }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:start_time) { Time.zone.local(2016, 12, 22, 10) }
  # XXX: end time == start time + menus total required time
  let(:end_time) { start_time.advance(minutes: menu_staffs_list.sum { |h| h[:menu_required_time] } ) }
  let(:menu_staffs_list) do
    [
      {
        menu_id: menu1.id,
        position: 0,
        menu_required_time: menu1.minutes,
        menu_interval_time: menu1.interval,
        staff_ids: [
          {
            staff_id: staff1.id.to_s,
            state: "pending"
          }
        ]
      },
      {
        menu_id: menu2.id,
        position: 1,
        menu_required_time: menu2.minutes,
        menu_interval_time: menu2.interval,
        staff_ids: [
          {
            staff_id: staff2.id.to_s,
            state: "pending"
          },
          {
            staff_id: staff3.id.to_s,
            state: "pending"
          }
        ]
      }
    ]
  end
  let(:customers_list) do
    [
      {
        customer_id: customer.id.to_s,
        state: "accepted"
      }
    ]
  end
  let(:params) do
    {
      start_time: start_time,
      end_time: end_time,
      menu_staffs_list: menu_staffs_list,
      customers_list: customers_list
    }
  end
  let(:args) do
    {
      reservation: reservation,
      params: params
    }
  end
  let(:outcome) { described_class.run(args) }

  before do
    # Shop open on during that time on that day(wday) from 09~17
    FactoryBot.create(:business_schedule, shop: shop, start_time: Time.zone.local(2016, 12, 22, 9), end_time: Time.zone.local(2016, 12, 22, 17))
  end
  # menus are available to booking during shop's business days
  let!(:menu_schedule1) { FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu1) }
  let!(:menu_schedule2) { FactoryBot.create(:reservation_setting, day_type: "business_days", menu: menu2) }

  describe "#execute" do
    context "when there is no error or warning" do
      it "returns empty hash" do
        result = outcome.result

        expect(result).to eq({})
      end
    end

    context "when shop has closed custom schedule" do
      let!(:custom_schedule) do
        FactoryBot.create(
          :custom_schedule, :for_shop, shop: shop,
          start_time: Time.zone.local(2016, 12, 22, 9),
          end_time: Time.zone.local(2016, 12, 22, 17)
        )
      end

      # shop_closed: "shop_closed",
      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :date => {
        #         :shop_closed => "休業日"
        #       }
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:date]).to be_present
      end
    end

    context "when working time is short than menu required time" do
      let(:menu_staffs_list) do
        [
          {
            menu_id: menu1.id,
            position: 0,
            menu_required_time: menu1.minutes - 1,
            menu_interval_time: menu1.interval,
            staff_ids: [
              {
                staff_id: staff1.id.to_s,
                state: "pending"
              }
            ]
          },
          {
            menu_id: menu2.id,
            position: 1,
            menu_required_time: menu2.minutes,
            menu_interval_time: menu2.interval,
            staff_ids: [
              {
                staff_id: staff2.id.to_s,
                state: "pending"
              },
              {
                staff_id: staff3.id.to_s,
                state: "pending"
              }
            ]
          }
        ]
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :errors => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {
        #             :time_not_enough => "所要時間不足"
        #           }
        #         },
        #         [1] {
        #           :menu_id => {}
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:errors][:reservation_form][:menu_staffs_list][0][:menu_id][:time_not_enough]).to be_present
        expect(result[:errors][:reservation_form][:menu_staffs_list][1][:menu_id][:time_not_enough]).to be_blank
      end
    end

    context "when menu doesn't start yet" do
      before { MenuReservationSettingRule.where(menu: menu2).last.update_columns(start_date: Date.tomorrow) }

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {
        #             :unschedule_menu => "予約枠外"
        #           }
        #         }
        #       ]
        #     }
        #   },
        #   :errors => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {
        #             :start_yet => "受付開始 2016年12月23日"
        #           }
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:errors][:reservation_form][:menu_staffs_list][0][:menu_id][:start_yet]).to be_blank
        expect(result[:errors][:reservation_form][:menu_staffs_list][1][:menu_id][:start_yet]).to be_present
      end
    end

    context "when menu was over" do
      context "when rule had a particular end date" do
        before do
          menu2.menu_reservation_setting_rule.update(end_date: Date.yesterday)
        end

        it "returns expected error" do
          result = outcome.result

          # {
          #   :warnings => {
          #     :reservation_form => {
          #       :menu_staffs_list => [
          #         [0] {
          #           :menu_id => {}
          #         },
          #         [1] {
          #           :menu_id => {
          #             :unschedule_menu => "予約枠外"
          #           }
          #         }
          #       ]
          #     }
          #   },
          #   :errors => {
          #     :reservation_form => {
          #       :menu_staffs_list => [
          #         [0] {
          #           :menu_id => {}
          #         },
          #         [1] {
          #           :menu_id => {
          #             :is_over => "受付終了"
          #           }
          #         }
          #       ]
          #     }
          #   }
          # }
          expect(result[:errors][:reservation_form][:menu_staffs_list][0][:menu_id][:is_over]).to be_blank
          expect(result[:errors][:reservation_form][:menu_staffs_list][1][:menu_id][:is_over]).to be_present
        end
      end
    end

    context "when there is not enough staffs for menus" do
      let(:menu1) { FactoryBot.create(:menu, shop: shop, user: user, interval: 5, min_staffs_number: 2) }

      it "returns expected error" do
        result = outcome.result

        # {
        #   :errors => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {
        #             :lack_staffs => "対応スタッフ不足"
        #           }
        #         },
        #         [1] {
        #           :menu_id => {}
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:errors][:reservation_form][:menu_staffs_list][0][:menu_id][:lack_staffs]).to be_present
        expect(result[:errors][:reservation_form][:menu_staffs_list][1][:menu_id][:lack_staffs]).to be_blank
      end
    end

    context "when start time is earlier than shop open time" do
      let(:start_time) { Time.zone.local(2016, 12, 22, 8, 59) }

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :start_time => {
        #         :invalid_time => "予約時間が正しくありません。"
        #       }
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:start_time][:invalid_time]).to be_present
      end
    end

    context "when the overlap happened on previous reservation" do
      let!(:previous_reservation) do
        FactoryBot.create(:reservation, shop: shop, menus: [ menu1 ],
                          start_time: start_time.advance(minutes: -menu1.minutes),
                          force_end_time: start_time,
                          staffs: staff1)
      end

      context "when the interval time is not enough for previous reservation" do
        it "is invalid" do
          result = outcome.result

          # {
          #   :warnings => {
          #     :reservation_form => {
          #       :start_time => {
          #         :interval_too_short => "インターバル不足"
          #       }
          #     }
          #   }
          # }
          expect(result[:warnings][:reservation_form][:start_time][:interval_too_short]).to be_present
        end
      end
    end

    context "when end time is later than shop close time" do
      let(:start_time) { Time.zone.local(2016, 12, 22, 16, 59) }
      let(:end_time) { Time.zone.local(2016, 12, 22, 17, 1) }

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :end_time => {
        #         :invalid_time => "予約時間が正しくありません。"
        #       }
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:end_time][:invalid_time]).to be_present
      end
    end

    context "when the overlap happened on next reservation" do
      let!(:next_reservation) do
        FactoryBot.create(
          :reservation, shop: shop, menus: [ menu1 ],
          start_time: end_time,
          force_end_time: end_time.advance(minutes: menu1.minutes),
          staffs: [staff2, staff3]
        )
      end

      context "when the interval time is not enough for current reservation" do
        it "returns expected error" do
          result = outcome.result

          # {
          #   :warnings => {
          #     :reservation_form => {
          #       :end_time => {
          #         :interval_too_short => "インターバル不足"
          #       }
          #     }
          #   }
          # }
          expect(result[:warnings][:reservation_form][:end_time][:interval_too_short]).to be_present
        end
      end
    end

    context "when menu doesn't allow to be booked on that date" do
      let!(:menu_schedule2) { } # none

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {
        #             :unschedule_menu => "予約枠外"
        #           }
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][0][:menu_id][:unschedule_menu]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:menu_id][:unschedule_menu]).to be_present
      end
    end

    context "when some menus doesn't have enough seats for customers" do
      let(:menu1) { FactoryBot.create(:menu, shop: shop, user: user, interval: 5, max_seat_number: 2) }
      let(:menu2) { FactoryBot.create(:menu, shop: shop, user: user, interval: 10, max_seat_number: 1) }
      let(:customers_list) do
        [
          {
            customer_id: customer.id,
            state: "accepted"
          },
          {
            customer_id: FactoryBot.create(:customer, user: user).id,
            state: "accepted"
          }
        ]
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {
        #             :not_enough_seat => "席数不足",
        #             :shop_or_staff_not_enough_ability => "Over Shop or Staff capability"
        #           }
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][0][:menu_id][:not_enough_seat]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:menu_id][:not_enough_seat]).to be_present
        expect(result[:warnings][:reservation_form][:menu_staffs_list][0][:menu_id][:shop_or_staff_not_enough_ability]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:menu_id][:shop_or_staff_not_enough_ability]).to be_present
      end
    end

    context "when staff is a full time staff, had a personal schedule(off schedule) during the period" do
      before do
        FactoryBot.create(:custom_schedule, :closed, user: staff1.staff_account.user, start_time: start_time, end_time: end_time)
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {},
        #           :staff_ids => [
        #             [0] {
        #               :staff_id => {
        #                 :ask_for_leave => "休暇中"
        #               }
        #             }
        #           ]
        #         },
        #         [1] {
        #           :menu_id => {}
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][0][:staff_ids][0][:staff_id][:ask_for_leave]).to be_present
      end
    end

    context "when staff is a part time staff, doesn't work on that day" do
      let(:staff3) { FactoryBot.create(:staff, user: user, shop: shop, menus: [ menu1, menu2, menu3 ]) }
      before do
        FactoryBot.create(:business_schedule, :opened, staff: staff3, shop: shop)
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {},
        #           :staff_ids => [
        #             [0] {
        #               :staff_id => {}
        #             },
        #             [1] {
        #               :staff_id => {
        #                 :unworking_staff => "休暇中"
        #               }
        #             }
        #           ]
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][0][:staff_id][:unworking_staff]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][1][:staff_id][:unworking_staff]).to be_present
      end
    end

    context "when some staff doesn't have enough ability for customers" do
      let(:customers_list) do
        [
          {
            customer_id: customer.id,
            state: "accepted"
          },
          {
            customer_id: FactoryBot.create(:customer, user: user).id,
            state: "accepted"
          }
        ]
      end
      before do
        StaffMenu.find_by(menu: menu2, staff: staff3).update_columns(max_customers: 1)
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {
        #             :shop_or_staff_not_enough_ability => "Over Shop or Staff capability"
        #           },
        #           :staff_ids => [
        #             [0] {
        #               :staff_id => {}
        #             },
        #             [1] {
        #               :staff_id => {
        #                 :not_enough_ability => "対応人数超"
        #               }
        #             }
        #           ]
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][0][:menu_id][:shop_or_staff_not_enough_ability]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:menu_id][:shop_or_staff_not_enough_ability]).to be_present
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][0][:staff_id][:not_enough_ability]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][1][:staff_id][:not_enough_ability]).to be_present
      end
    end

    context "when some staffs don't work on that date" do
      context "when staff is a freelancer" do
        let(:staff3) { FactoryBot.create(:staff, user: user, shop: shop, menus: [ menu1, menu2, menu3 ]) }

        it "returns expected error" do
          result = outcome.result
          # {
          #   :warnings => {
          #     :reservation_form => {
          #       :menu_staffs_list => [
          #         [0] {
          #           :menu_id => {}
          #         },
          #         [1] {
          #           :menu_id => {},
          #           :staff_ids => [
          #             [0] {
          #               :staff_id => {}
          #             },
          #             [1] {
          #               :staff_id => {
          #                 :freelancer => "勤務時間未設定"
          #               }
          #             }
          #           ]
          #         }
          #       ]
          #     }
          #   }
          # }
          expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][0][:staff_id][:freelancer]).to be_blank
          expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][1][:staff_id][:freelancer]).to be_present
        end
      end
    end

    context "when some staffs already had reservation in other shops" do
      let!(:existing_reservation) do
        FactoryBot.create(:reservation, shop: FactoryBot.create(:shop), staffs: [staff3], start_time: start_time, end_time: end_time)
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {},
        #           :staff_ids => [
        #             [0] {
        #               :staff_id => {}
        #             },
        #             [1] {
        #               :staff_id => {
        #                 :other_shop => "他店勤務中"
        #               }
        #             }
        #           ]
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][0][:staff_id][:other_shop]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][1][:staff_id][:other_shop]).to be_present
      end
    end

    context "when some staffs already had overlap reservation in the same shop" do
      let!(:existing_reservation) do
        FactoryBot.create(:reservation, menus: [ menu1 ], shop: shop, staffs: [staff3], start_time: start_time, force_end_time: end_time)
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :errors => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {
        #             :time_not_enough => "所要時間不足"
        #           }
        #         }
        #       ]
        #     }
        #   },
        #   :warnings => {
        #     :reservation_form => {
        #       :end_time => {
        #         :interval_too_short => "インターバル不足"
        #       },
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {},
        #           :staff_ids => [
        #             [0] {
        #               :staff_id => {}
        #             },
        #             [1] {
        #               :staff_id => {
        #                 :overlap_reservations => "重複予約あり"
        #               }
        #             }
        #           ]
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][0][:staff_id][:overlap_reservations]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][1][:staff_id][:overlap_reservations]).to be_present
      end
    end

    context "when some staffs don't have ability for some menus" do
      let(:staff3) { FactoryBot.create(:staff, :full_time, user: user, shop: shop, menus: [menu1]) }

      it "returns expected error" do
        result = outcome.result

        # {
        #   :warnings => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {},
        #           :staff_ids => [
        #             [0] {
        #               :staff_id => {}
        #             },
        #             [1] {
        #               :staff_id => {
        #                 :incapacity_menu => "非対応メニュー"
        #               }
        #             }
        #           ]
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][0][:staff_id][:incapacity_menu]).to be_blank
        expect(result[:warnings][:reservation_form][:menu_staffs_list][1][:staff_ids][1][:staff_id][:incapacity_menu]).to be_present
      end
    end

    context "when some menus duplicate" do
      let(:menu_staffs_list) do
        [
          {
            menu_id: menu1.id,
            position: 0,
            menu_required_time: menu1.minutes,
            menu_interval_time: menu1.interval,
            staff_ids: [
              {
                staff_id: staff1.id.to_s,
                state: "pending"
              }
            ]
          },
          {
            menu_id: menu1.id,
            position: 1,
            menu_required_time: menu1.minutes,
            menu_interval_time: menu1.interval,
            staff_ids: [
              {
                staff_id: staff1.id.to_s,
                state: "pending"
              }
            ]
          }
        ]
      end

      it "returns expected error" do
        result = outcome.result

        # {
        #   :errors => {
        #     :reservation_form => {
        #       :menu_staffs_list => [
        #         [0] {
        #           :menu_id => {}
        #         },
        #         [1] {
        #           :menu_id => {
        #             :duplicate => "同じメニューは追加できません。予約時間を変更したい場合は所要時間を編集して\nください。"
        #           }
        #         }
        #       ]
        #     }
        #   }
        # }
        expect(result[:errors][:reservation_form][:menu_staffs_list][1][:menu_id][:duplicate]).to be_present
      end
    end
  end
end
