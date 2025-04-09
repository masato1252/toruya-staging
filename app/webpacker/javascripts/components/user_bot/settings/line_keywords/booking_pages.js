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
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  useSortable
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import Routes from 'js-routes.js'

import I18n from 'i18n-js/index.js.erb';
import { CommonServices } from "user_bot/api"
import { responseHandler } from "libraries/helper";
import { TopNavigationBar } from "shared/components";

const LineKeywordsBookingPages = ({props}) => {
  const [booking_pages, setBookingPages] = useState(props.booking_pages);
  const sensors = useSensors(
    useSensor(PointerSensor)
  );

  const handleDragEnd = (event) => {
    const {active, over} = event;

    if (active.id !== over.id) {
      setBookingPages((booking_pages) => {
        const oldIndex = booking_pages.findIndex(item => item.value === active.id);
        const newIndex = booking_pages.findIndex(item => item.value === over.id);
        const result = arrayMove(booking_pages, oldIndex, newIndex);
        console.log(result)
        return result;
      });
    }
  }

  const handleDragUp = (index) => {
    if (index == 0) return;

    setBookingPages((booking_pages) => {
      const result = arrayMove(booking_pages, index, index - 1);
      return result;
    });
  }

  const handleDragDown = (index) => {
    if (index == booking_pages.length - 1) return;

    setBookingPages((booking_pages) => {
      const result = arrayMove(booking_pages, index, index + 1);
      return result;
    });
  }

  const handleSubmit = async () => {
    const [error, response] = await CommonServices.update({
      url: Routes.upsert_booking_pages_lines_user_bot_settings_line_keyword_path({ business_owner_id: props.business_owner_id, async: props.async, format: "json" }),
      data: { booking_page_ids: booking_pages.map((page) => page.id) }
    })

    if (!props.async) {
      responseHandler(error, response)
    }
    else if (props.modal_id) {
      $(`#${props.modal_id}`).modal('hide');
    }
  }

  return (
    <>
      {!props.async && <TopNavigationBar
        leading={
          <a href={Routes.lines_user_bot_booking_pages_path(props.business_owner_id)}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={I18n.t("user_bot.dashboards.settings.line_keywords.booking_pages.title")}
      />}
      <h3 className="header centerize break-line-content">{I18n.t("user_bot.dashboards.settings.line_keywords.booking_pages.desc")}</h3>
      <div className="margin-around">
        <label className="text-align-left">
          <ReactSelect
            placeholder={I18n.t("user_bot.dashboards.settings.line_keywords.booking_pages.list_desc")}
            value={ _.isEmpty(booking_pages) ? "" : { label: booking_pages[booking_pages.length - 1].label }}
            options={props.booking_page_options.filter(option => !booking_pages.some(selectedOption => selectedOption.id === option.id))}
            onChange={
              (booking_page) => {
                setBookingPages(_.uniqBy([...booking_pages, { value: booking_page.value, label: booking_page.label, id: booking_page.id }], 'value'))
              }
            }
          />
        </label>
      </div>
      {booking_pages.length !== 0 && <div className="field-header">{I18n.t("user_bot.dashboards.settings.line_keywords.booking_pages.list_desc")}</div>}
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={handleDragEnd}
      >
        <SortableContext
          items={booking_pages}
        >
          {booking_pages.map(({id, label}, index) => {
            return (
              <SortableBookingPage
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
                deleteCallback={() => {
                  setBookingPages(booking_pages.filter(item => item.id !== id))
                }}
              />
            )
          })}
        </SortableContext>
      </DndContext>
      <div className="action-block">
        {booking_pages.length > props.line_columns_number_limit && <div className="warning">{I18n.t("user_bot.dashboards.settings.line_keywords.booking_pages.limit_desc")}</div>}
        <button className="btn btn-yellow" onClick={handleSubmit}>
          {I18n.t("action.save")}
        </button>
      </div>
    </>
  )
}

const SortableBookingPage = ({id, label, index, deleteCallback, upCallback, downCallback}) => {
  const {
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
      <i
        className="fas fa-trash"
        onClick={deleteCallback}>
      </i>
    </a>
  );
}

export default LineKeywordsBookingPages
