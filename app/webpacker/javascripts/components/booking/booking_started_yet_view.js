"use strict";

import React from "react";

import { BookingStartInfo, AddLineFriendInfo } from "shared/booking";

const BookingStartedYetView = ({start_at, social_account_add_friend_url}) => {
  return (
    <>
      <BookingStartInfo start_at={start_at} />
      <AddLineFriendInfo social_account_add_friend_url={social_account_add_friend_url} />
    </>
  )
}

export default BookingStartedYetView
