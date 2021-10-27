"use strict"

import React, { useState } from "react";
import { sortableContainer, sortableElement } from "react-sortable-hoc";
import arrayMove from "array-move";

import { BookingOptionServices } from "user_bot/api"
import { DragHandle } from "shared/components";

const SortableMenuOption = sortableElement(({booking_option_id, menu, i18n}) => {
  const { menu_time_span, minute } = i18n;

  return (
    <div className="field-row with-next-arrow">
      <a href={Routes.edit_lines_user_bot_booking_option_path(booking_option_id, { menu_id: menu.value, attribute: "menu_required_time" })} className="menu-block">
        <div className="menu-info">
          <DragHandle />
          <div>
            <h3>{menu.label}</h3>
            <div className="desc">{i18n.required_time}{menu.required_time}{i18n.minute}</div>
          </div>
        </div>
        <i className="fa fa-angle-right"></i>
      </a>
      <a
        href={Routes.delete_menu_lines_user_bot_booking_option_path(booking_option_id, menu.value)}
        className="btn btn-orange"
        data-method="delete"
        data-confirm={i18n.are_you_sure_message}
      >
        {i18n.delete}
      </a>
      {menu.no_available_shop && <div className="warning">There is no available shop for this menu, please set up the shop for this menu or remove it</div> }
    </div>
  )
});

const SortableMenuList = sortableContainer(({booking_option_id, menus, i18n}) => {
  return (
    <div>
      {menus.map((menu, index) => (
        <SortableMenuOption
          key={`menu-${menu.value}-${index}`}
          booking_option_id={booking_option_id}
          menu={menu}
          i18n={i18n}
          index={index}
        />
      )) }
    </div>
  )
})

const BookingOptionMenus = (({props}) => {
  const i18n = props.i18n;
  const [menus, setMenus] = useState(props.booking_option.menus)

  const onSortEnd = ({oldIndex, newIndex}) => {
    const sorted_menus = arrayMove(menus, oldIndex, newIndex).map((menu, i) => {
      menu.priority = i
      return menu
    })

    setMenus(sorted_menus)

    BookingOptionServices.reorder({
      booking_option_id: props.booking_option.id,
      data: {sorted_menus_ids: sorted_menus.map(menu => menu.value) }
    })
  };

  return (
    <SortableMenuList
      useDragHandle
      booking_option_id={props.booking_option.id}
      menus={menus}
      i18n={i18n}
      onSortEnd={onSortEnd}
    />
  )
})

export default BookingOptionMenus;
