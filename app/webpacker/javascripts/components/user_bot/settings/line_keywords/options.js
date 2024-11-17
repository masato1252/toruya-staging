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

import I18n from 'i18n-js/index.js.erb';
import { CommonServices } from "user_bot/api"
import { responseHandler } from "libraries/helper";
import { TopNavigationBar } from "shared/components";

const LineKeywordsOptions = ({props}) => {
  const [options, setOptions] = useState(props.keyword_options);
  const sensors = useSensors(
    useSensor(PointerSensor)
  );

  const handleDragEnd = (event) => {
    const {active, over} = event;

    if (active.id !== over.id) {
      setOptions((options) => {
        const oldIndex = options.findIndex(item => item.value === active.id);
        const newIndex = options.findIndex(item => item.value === over.id);
        const result = arrayMove(options, oldIndex, newIndex);
        console.log(result)
        return result;
      });
    }
  }

  const handleDragUp = (index) => {
    if (index == 0) return;

    setOptions((options) => {
      const result = arrayMove(options, index, index - 1);
      return result;
    });
  }

  const handleDragDown = (index) => {
    if (index == options.length - 1) return;

    setOptions((options) => {
      const result = arrayMove(options, index, index + 1);
      return result;
    });
  }

  const handleSubmit = async () => {
    const [error, response] = await CommonServices.update({
      url: props.upsert_path,
      data: { option_ids: options.map((option) => option.id) }
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
          <a href={props.previous_path}>
            <i className="fa fa-angle-left fa-2x"></i>
          </a>
        }
        title={props.title}
      />}
      <h3 className="header centerize break-line-content">{props.desc}</h3>
      <div className="margin-around">
        <label className="text-align-left">
          <ReactSelect
            placeholder={props.select_placeholder}
            value={ _.isEmpty(options) ? "" : { label: options[options.length - 1].label }}
            options={props.options.filter(option => !options.some(selectedOption => selectedOption.id === option.id))}
            onChange={
              (option) => {
                setOptions(_.uniqBy([...options, { value: option.value, label: option.label, id: option.id }], 'value'))
              }
            }
          />
        </label>
      </div>
      {options.length !== 0 && <div className="field-header">{props.select_placeholder}</div>}
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={handleDragEnd}
      >
        <SortableContext
          items={options}
        >
          {options.map(({id, label}, index) => {
            return (
              <SortableOptions
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
                  setOptions(options.filter(item => item.id !== id))
                }}
              />
            )
          })}
        </SortableContext>
      </DndContext>
      <div className="action-block">
        {options.length > props.line_columns_number_limit && <div className="warning">{I18n.t("user_bot.dashboards.settings.line_keywords.booking_options.limit_desc")}</div>}
        <button className="btn btn-yellow" onClick={handleSubmit} disabled={options.length === 0}>
          {I18n.t("action.save")}
        </button>
      </div>
    </>
  )
}

const SortableOptions= ({id, label, index, deleteCallback, upCallback, downCallback}) => {
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

export default LineKeywordsOptions
