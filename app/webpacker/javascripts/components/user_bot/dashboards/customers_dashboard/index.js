"use strict"

import React, { useState, useEffect } from "react";
import { TopNavigationBar, BottomNavigationBar } from "shared/components"

const UserBotCustomersDashboard = ({props}) => {
  return (
    <div className="customers-dashboard">
      <TopNavigationBar
        leading={<i className="fa fa-angle-left fa-2x"></i>}
        title={"title"}
      />
      <BottomNavigationBar klassName="center">
        <span>Bottom</span>
      </BottomNavigationBar>
    </div>
  )
}

export default UserBotCustomersDashboard;
