"use strict";

import React from "react";

import { BookingEndInfo, AddLineFriendInfo } from "shared/booking";

const BookingEndedView = ({ social_account_add_friend_url }) => {
  return (
    <>
      <BookingEndInfo />
      <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
    </>
  )
}

export default BookingEndedView
