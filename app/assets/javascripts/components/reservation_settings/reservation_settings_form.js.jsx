UI.define("ReservationSettings.Form", function() {
  var ReservationSettingsForm = React.createClass({
    getInitialState: function() {
      return {
        setting: this.props.setting,
        isAllBusinessHours: !this.props.setting.start_time && !this.props.setting.end_time
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

    render: function() {
      return (
        <form>
          <h3 className="frameInfo">予約枠 Informations<strong>必須項目</strong></h3>
          <div id="frameInfo" className="formRow">
            <dl>
              <dt>枠名</dt>
              <dd>
                <input type="text" placeholder="予約枠 Name" maxlength="30" defaultValue={this.state.setting.name}/>
              </dd>
            </dl>
            <dl>
              <dt>短縮名</dt>
              <dd>
                <input type="text" placeholder="予約枠 Shorten Name" maxlength="10" defaultValue={this.state.setting.short_name} />
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
            <label htmlFor="frameDay1"><span>All Business Days</span></label>

            <input
              type="radio"
              name="frameDay"
              id="frameDay2"
              data-value="weekly"
              checked={this.state.setting.day_type == "weekly"}
              onChange={this.swithDayType}
              />
            <label htmlFor="frameDay2"><span>Weekly</span></label>

            <input
              type="radio"
              name="frameDay"
              id="frameDay3"
              data-value="monthly"
              checked={this.state.setting.day_type == "monthly"}
              onChange={this.swithDayType}
              />
            <label htmlFor="frameDay3"><span>Monthly</span></label>
          </div>

          {
            this.state.setting.day_type == "weekly" ? (
              <div id="weeklyFrameSetting" className="setDetail formRow">
                <h3 className="frameDayMonthly">Weekly Frame Setting</h3>
                <dl>
                  <dt>Day of the week</dt>
                  <dd>
                    <div className="BTNselect">
                      { this.props.dayNames.map(function(dayName, i) {
                          return (
                            <div>
                              <input type="checkbox" name="frameDate" id={`frameDate${i}`} />
                              <label htmlFor={`frameDate${i}`}><span>{dayName}</span></label>
                            </div>
                          )
                        })}
                    </div>
                  </dd>
                </dl>
              </div>
            ) : null
          }

          {
            this.state.setting.day_type == "monthly" ? (
              <div id="MonthlyFrameSetting" className="setDetail formRow">
                <h3 className="frameDayMonthly">Monthly Frame Setting</h3>
                <dl>
                  <dt>
                    <input type="radio" name="frameDayMonthly" id="frameDayMonthly1" checked="" />
                    <label htmlFor="frameDayMonthly1">Number of the day</label>
                  </dt>
                  <dd>毎月<input type="number" size="2" maxlength="2" />日</dd>
                </dl>
                <dl>
                  <dt>
                    <input type="radio" name="frameDayMonthly" id="frameDayMonthly2" />
                    <label htmlFor="frameDayMonthly2">Number of the week</label>
                  </dt>
                  <dd>毎月第<input type="number" size="1" maxlength="1" /></dd>
                </dl>
                <dl>
                  <dt>Day of the week</dt>
                  <dd>
                    <div className="BTNselect">
                      { this.props.dayNames.map(function(dayName, i) {
                          return (
                            <div>
                              <input type="checkbox" name="frameDayMonthlyWeekday" id={`frameDayMonthlyWeekday${i}`} />
                              <label htmlFor={`frameDayMonthlyWeekday${i}`}><span>{dayName}</span></label>
                            </div>
                          )
                        })}
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
            <label htmlFor="frameTime1"><span>All Business Hours</span></label>
            <input
              type="radio"
              name="frameTime"
              id="frameTime2"
              defaultChecked={!this.state.isAllBusinessHours}
              data-value="custom_time"
              onClick={this.swithTimeType}
            />
            <label htmlFor="frameTime2"><span>個別設定</span></label>
          </div>
          {
            (this.state.isAllBusinessHours) ? null : (
              <div className="setDetail formRow">
                <dl>
                  <dt>Starts from</dt>
                  <dd><input type="time" /></dd>
                </dl>
                <dl>
                  <dt>Ends at</dt>
                  <dd><input type="time" /></dd>
                </dl>
              </div>
            )
          }

          <ul id="footerav">
            <li><a href="menu.html" className="BTNtarco">Cancel</a></li>
            <li><a href="menu.html" className="BTNyellow">保存</a></li>
          </ul>
        </form>
      );
    }
  });

  return ReservationSettingsForm;
});
