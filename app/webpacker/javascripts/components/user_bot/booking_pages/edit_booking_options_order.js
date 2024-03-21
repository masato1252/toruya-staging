"use strict";

import React, { useState } from "react";
import ReactSelect from "react-select";
import _ from "lodash";
import {
  DndContext,
  closestCenter,
  PointerSensor,
  useSensor,
  useSensors,
  DragOverlay
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  verticalListSortingStrategy,
  useSortable
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import Routes from 'js-routes.js'

import I18n from 'i18n-js/index.js.erb';
import { CommonServices } from "user_bot/api"
import { responseHandler } from "libraries/helper";
import { TopNavigationBar } from "shared/components";

const EditBookingOptionsOrder = ({props}) => {
  const [booking_options, setBookingOptions] = useState(props.booking_options);
  const sensors = useSensors(
    useSensor(PointerSensor)
  );

  const handleDragEnd = (event) => {
    const {active, over} = event;

    if (active.id !== over.id) {
      setBookingOptions((booking_options) => {
        const oldIndex = booking_options.findIndex(item => item.value === active.id);
        const newIndex = booking_options.findIndex(item => item.value === over.id);
        const result = arrayMove(booking_options, oldIndex, newIndex);
        console.log(result)
        return result;
      });
    }
  }

  const handleDragUp = (index) => {
    if (index == 0) return;

    setBookingOptions((booking_options) => {
      const result = arrayMove(booking_options, index, index - 1);
      return result;
    });
  }

  const handleDragDown = (index) => {
    if (index == booking_options.length - 1) return;

    setBookingOptions((booking_options) => {
      const result = arrayMove(booking_options, index, index + 1);
      return result;
    });
  }

  const handleSubmit = async () => {
    const [error, response] = await CommonServices.update({
      url: Routes.update_booking_options_order_lines_user_bot_booking_page_path(props.business_owner_id, props.booking_page_id, { format: "json" }),
      data: { booking_option_ids: booking_options.map((option) => option.id) }
    })

    responseHandler(error, response)
  }

  return (
    <div className="form with-top-bar settings-flow centerize">
      <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_booking_page_path(props.business_owner_id, props.booking_page_id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.booking_pages.form.booking_options_order_title")}
      />
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={handleDragEnd}
      >
        <SortableContext
          items={booking_options}
        >
          {booking_options.map(({id, label}, index) => {
            return (
              <SortableBookingOptions
                index={index}
                key={id}
                id={id}
                label={label}
                upCallback={() => {
                  handleDragUp(index)
                }}
                downCallback={() => {
                  handleDragDown(index)
                }}
              />
            )
          })}
        </SortableContext>
      </DndContext>
      <div className="action-block">
        <button className="btn btn-yellow" onClick={handleSubmit}>
          {I18n.t("action.save")}
        </button>
      </div>
    </div>
  )
}

const SortableBookingOptions = ({id, label, index, upCallback, downCallback}) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
  } = useSortable({id: id});

  const style = {
    transform: CSS.Transform.toString(transform),
    transition
  };

  return (
    <a className="field-row with-next-arrow with-format" ref={setNodeRef} style={style} >
      <span className="dotdotdot">
        <span className="p-3">
          <i className="fa fa-solid fa-arrow-up" onClick={upCallback}></i>
        </span>
        <span className="p-3">
          <i className="fa fa-solid fa-arrow-down" onClick={downCallback}></i>
        </span>
        {index + 1}: {label}
      </span>
    </a>
  );
}

export default EditBookingOptionsOrder
