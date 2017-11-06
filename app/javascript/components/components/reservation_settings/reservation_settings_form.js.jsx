UI.define("ReservationSettings.Form", function() {
  var ReservationSettingsForm = React.createClass({
    getInitialState: function() {
      return {
        setting: this.props.setting,
        isAllBusinessHours: !this.props.setting.start_time && !this.props.setting.end_time,
        number_of_day_monthly: !!this.props.setting.day,
      }
    },

    swithDayType: function(event) {
      this.state.setting.day_type = event.target.dataset.value;
      this.setState({setting:  this.state.setting});
    },

    swithTimeType: function(event) {
      if (event.target.dataset.value == "custom_time") {
        this.setState({isAllBusinessHours: false});
      }
      else {
        this.setState({isAllBusinessHours: true});
      }
    },

    switchMonthlyType: function(event) {
      if (event.target.dataset.value == "number_of_day_monthly") {
        this.setState({number_of_day_monthly: true});
      }
      else {
        this.setState({number_of_day_monthly: false});
      }
    },

    handleSettingChange: function(event) {
      this.state.setting[event.target.dataset.name] = event.target.value
      this.setState({setting: this.state.setting});
    },

    render: function() {
      return (
        <form acceptCharset="UTF-8" action={this.props.saveSettingPath} method="post">
          <input name="utf8" type="hidden" value="✓" />
          { this.props.setting.id ?  <input name="_method" type="hidden" value="PUT" /> : null }
          <input name="authenticity_token" type="hidden" value={this.props.formAuthenticityToken} />

          <h3 className="frameInfo">{this.props.infoLabel}<strong>必須項目</strong></h3>
          <div id="frameInfo" className="formRow">
            <dl>
              <dt>{this.props.nameLabel}</dt>
              <dd>
                <input
                  type="text"
                  placeholder={this.props.nameLabel}
                  maxlength="30"
                  name="reservation_setting[name]"
                  data-name="name"
                  value={this.state.setting.name}
                  onChange={this.handleSettingChange}
                  />
              </dd>
            </dl>
            <dl>
              <dt>{this.props.shortName}</dt>
              <dd>
                <input
                  type="text"
                  placeholder={this.props.shortName}
                  maxlength="10"
                  name="reservation_setting[short_name]"
                  data-name="short_name"
                  value={this.state.setting.short_name}
                  onChange={this.handleSettingChange}
                />
              </dd>
            </dl>
          </div>

          <h3 className="frameDate">受付日</h3>
          <div id="frameDate" className="BTNswitch">
            <input
              type="radio"
              name="frameDay"
              id="frameDay1"
              data-value="business_days"
              checked={this.state.setting.day_type == "business_days"}
              onChange={this.swithDayType}
              />
              <label htmlFor="frameDay1"><span>{this.props.allBusinessDaysLabel}</span></label>

            <input
              type="radio"
              name="frameDay"
              id="frameDay2"
              data-value="weekly"
              checked={this.state.setting.day_type == "weekly"}
              onChange={this.swithDayType}
              />
            <label htmlFor="frameDay2"><span>{this.props.weeklyLabel}</span></label>

            <input
              type="radio"
              name="frameDay"
              id="frameDay3"
              data-value="monthly"
              checked={this.state.setting.day_type == "monthly"}
              onChange={this.swithDayType}
              />
            <label htmlFor="frameDay3"><span>{this.props.monthlyLabel}</span></label>
            <input type="hidden" name="reservation_setting[day_type]" value={this.state.setting.day_type} />
          </div>

          {
            this.state.setting.day_type == "weekly" ? (
              <div id="weeklyFrameSetting" className="setDetail formRow">
                <h3 className="frameDayMonthly">{this.props.weeklySettingLabel}</h3>
                <dl>
                  <dt>{this.props.dayLabel}</dt>
                  <dd>
                    <div className="BTNselect">
                      { this.props.dayNames.map(function(dayName, i) {
                          return (
                            <div key={`frameDate${i}`}>
                              <input
                                type="checkbox"
                                name="reservation_setting[days_of_week][]"
                                defaultChecked={_.contains(this.state.setting.days_of_week, `${i}`)}
                                value={i}
                                id={`frameDate${i}`}
                              />
                              <label htmlFor={`frameDate${i}`}><span>{dayName}</span></label>
                            </div>
                          )
                        }.bind(this))}
                    </div>
                  </dd>
                </dl>
              </div>
            ) : null
          }

          {
            this.state.setting.day_type == "monthly" ? (
              <div id="MonthlyFrameSetting" className="setDetail formRow">
                <h3 className="frameDayMonthly">{this.props.monthlySettingLabel}</h3>
                <dl>
                  <dt className="check-area">
                    <input
                      type="radio"
                      name="frameDayMonthly"
                      id="frameDayMonthly1"
                      data-value="number_of_day_monthly"
                      checked={this.state.number_of_day_monthly}
                      onChange={this.switchMonthlyType}
                      />
                    <label htmlFor="frameDayMonthly1">{this.props.numberOfDayLabel}</label>
                  </dt>
                  <dd>毎月
                    <input
                      type="number"
                      size="2"
                      maxlength="2"
                      name="reservation_setting[day]"
                      disabled={!this.state.number_of_day_monthly}
                      defaultValue={this.state.setting.day}
                    />
                      日
                    </dd>
                </dl>
                <dl>
                  <dt className="check-area">
                    <input
                      type="radio"
                      name="frameDayMonthly"
                      id="frameDayMonthly2"
                      data-value="days_of_week_monthly"
                      checked={!this.state.number_of_day_monthly}
                      onChange={this.switchMonthlyType}
                    />
                    <label htmlFor="frameDayMonthly2">{this.props.numberOfWeekLabel}</label>
                  </dt>
                  <dd>毎月第
                    <input
                      type="number"
                      size="1"
                      maxlength="1"
                      name="reservation_setting[nth_of_week]"
                      disabled={this.state.number_of_day_monthly}
                      defaultValue={this.state.setting.nth_of_week}
                      />
                  </dd>
                </dl>
                <dl>
                  <dt>{this.props.dayLabel}</dt>
                  <dd>
                    <div className="BTNselect">
                      { this.props.dayNames.map(function(dayName, i) {
                          return (
                            <div key={`frameDayMonthlyWeekday${i}`}>
                              <input
                                type="checkbox"
                                name="reservation_setting[days_of_week][]"
                                value={i}
                                defaultChecked={_.contains(this.state.setting.days_of_week, `${i}`)}
                                disabled={this.state.number_of_day_monthly}
                                id={`frameDayMonthlyWeekday${i}`} />
                              <label htmlFor={`frameDayMonthlyWeekday${i}`}><span>{dayName}</span></label>
                            </div>
                          )
                        }.bind(this))}
                    </div>
                  </dd>
                </dl>
              </div>
            ) : null
          }

          <h3 className="frameTime">受付時間</h3>
          <div id="frameTime" className="BTNswitch">
            <input
              type="radio"
              name="frameTime"
              id="frameTime1"
              defaultChecked={this.state.isAllBusinessHours}
              data-value="all_time"
              onClick={this.swithTimeType}
               />
               <label htmlFor="frameTime1"><span>{this.props.allBusinessHoursLabel}</span></label>
            <input
              type="radio"
              name="frameTime"
              id="frameTime2"
              defaultChecked={!this.state.isAllBusinessHours}
              data-value="custom_time"
              onClick={this.swithTimeType}
            />
            <label htmlFor="frameTime2"><span>{this.props.customTimeLabel}</span></label>
          </div>
          {
            (this.state.isAllBusinessHours) ? null : (
              <div className="setDetail formRow">
                <dl>
                  <dt>{this.props.startTimeLabel}</dt>
                  <dd>
                    <input
                      type="time"
                      name="reservation_setting[start_time]"
                      defaultValue={moment(this.state.setting.start_time).tz(this.props.timezone).format("HH:mm")}
                      />
                  </dd>
                </dl>
                <dl>
                  <dt>{this.props.endTimeLabel}</dt>
                  <dd>
                    <input
                      type="time"
                      name="reservation_setting[end_time]"
                      defaultValue={moment(this.state.setting.end_time).tz(this.props.timezone).format("HH:mm")}
                      />
                  </dd>
                </dl>
              </div>
            )
          }

          <ul id="footerav">
            <li>
              <a className="BTNtarco" href={this.props.cancelPath}>{this.props.cancelBtn}</a>
            </li>
            <li>
              <input
                type="submit"
                name="commit"
                value="保存"
                className="BTNyellow"
                disabled={!this.state.setting.name || !this.state.setting.short_name}
                data-disable-with="保存"
                />
              </li>
          </ul>
        </form>
      );
    }
  });

  return ReservationSettingsForm;
});
