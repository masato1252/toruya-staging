"use strict"

import React, { useState, useRef, useEffect } from "react";
import { useForm, Controller } from "react-hook-form";
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
import { CommonServices } from "user_bot/api"
import I18n from 'i18n-js/index.js.erb';
import { debounce } from "lodash";

const ChaptersIndex =({props}) => {
  const [items, setItems] = useState(props.chapter_with_lessons);
  const containers = items.map(item => item.chapter_id)
  const [activeId, setActiveId] = useState(null);
  const sensors = useSensors(
    useSensor(PointerSensor)
  );

  const findContainer = (id) => {
    if (items.map(item => item.chapter_id).includes(id)) {
      // id might be a chapter_id
      return id;
    }

    // id might be lesson_id
    return items.find(item => item.lessons.includes(id)).chapter_id
  };

  const handleDragStart = (event) => {
    const { active } = event;
    const { id } = active;

    // console.log("handleDragStart", event)
    setActiveId(id);
  }

  const handleDragEnd = React.useRef(
    debounce(async (newItems) => {
      console.log('handleDragEnd', items)
      console.log('handleDragEnd', newItems)

      const [error, response] = await CommonServices.update({
        url: Routes.reorder_lines_user_bot_service_chapters_path(props.online_service_id),
        data: { items: newItems }
      })

      window.location = response.data.redirect_to;
    }, 3000)
  ).current

  const debounceHandleDragEnd = event => {
    // console.log('debounceHandleDragEnd', event)
    console.log('debounceHandleDragEnd', items)
    handleDragEnd(items)
  }

  const handleDragOver = (event) => {
    // console.log('handleDragOver', event)
    const { active, over } = event;

    const overId = over.id;
    const oldChapterId = findContainer(active.id);
    const newChapterId = findContainer(overId);
    const oldChapterIndex = items.findIndex(item => item.chapter_id === oldChapterId);
    const newChapterIndex = items.findIndex(item => item.chapter_id === newChapterId);

    if (containers.includes(active.id) && containers.includes(overId)) {
      // drag chapter
      const newItems = [...arrayMove(items, oldChapterIndex, newChapterIndex)]
      console.log('newItems', newItems)

      setItems((prevItems) => {
        return  newItems;
      })
    }
    else if (!containers.includes(active.id)){
      // drag lesson
      const newLessonIndex = items[newChapterIndex].lessons.indexOf(overId);
      const oldLessonIndex = items[oldChapterIndex].lessons.indexOf(active.id);
      let newIndex;

      if (containers.includes(overId)) {
        // drag lesson cross a chapter
        newIndex = items.find(item => item.chapter_id == overId).lessons.length + 1;
      } else {
        // drag lesson cross a lesson
        const isBelowOverItem =
          over &&
          active.rect.current.translated &&
          active.rect.current.translated.top >
          over.rect.top + over.rect.height;

        const modifier = isBelowOverItem ? 1 : 0;

        newIndex = newLessonIndex + modifier;
      }

      setItems((prevItems) => {
        prevItems[oldChapterIndex].lessons = prevItems[oldChapterIndex].lessons.filter(lessonId => lessonId != active.id)
        prevItems[newChapterIndex].lessons.splice(newIndex, 0, active.id)

        return [...prevItems]
      });
    }
  }

  return (
    <DndContext 
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={debounceHandleDragEnd}
      onDragOver={handleDragOver}
    >
      <SortableContext
        items={items.map(chapter => chapter.chapter_id)}
        strategy={verticalListSortingStrategy}
      >
        {items.map(({chapter_id, lessons, id}) => {
          return (
            <SortableChapter
              props={props}
              key={chapter_id}
              id={id}
              chapter_id={chapter_id}
              lessons={lessons}
            />
          )
        }) }
        <DragOverlay>
          {activeId ? (
            containers.includes(activeId) ? (
              <SortableChapter
                props={props}
                chapter_id={activeId}
                id={items.find(item => item.chapter_id === activeId).id}
                lessons={items.find(item => item.chapter_id === activeId).lessons}
              />
            ) : <SortableItem props={props} chapter_id={items.find(item => item.lessons.includes(activeId)).id} id={activeId} />
          ): null}
        </DragOverlay>
      </SortableContext>
    </DndContext>
  )
}

const SortableChapter = ({props, id, chapter_id, lessons}) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
  } = useSortable({id: chapter_id});

  const style = {
    transform: CSS.Transform.toString(transform),
    transition
  };

  return (
    <div ref={setNodeRef} style={style}>
      <a className="field-row with-next-arrow with-format header-row" href={Routes.edit_lines_user_bot_service_chapter_path(props.online_service_id, id)}>
        <span className="dotdotdot">
          <span  {...attributes} {...listeners} className="drag-handler">
            <i className="fa fa-ellipsis-v"></i>
          </span>
          {props.chapters[id].name}
        </span>
        <i className="fa fa-angle-right"></i>
      </a>
      <SortableContext
        id={chapter_id}
        items={lessons}
        strategy={verticalListSortingStrategy}
      >
        {lessons.map(lessonId => <SortableItem props={props} key={lessonId} chapter_id={id} id={lessonId} />)}
      </SortableContext>
      <div className="action-block">
        <a className="btn btn-tarco btn-extend" href={Routes.new_lines_user_bot_service_chapter_lesson_path(props.online_service_id, id)}>
          {I18n.t("user_bot.dashboards.settings.course.add_a_lesson")}
        </a>
      </div>
    </div>
  );
}

const SortableItem = ({props, chapter_id, id}) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
  } = useSortable({id: id});

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  return (
    <a
      ref={setNodeRef}
      style={style}
      className="field-row with-next-arrow with-format"
      href={Routes.lines_user_bot_service_chapter_lesson_path(props.online_service_id, chapter_id, id)}
    >
      <span className="dotdotdot">
        <span  {...attributes} {...listeners} className="drag-handler">
          <i className="fa fa-ellipsis-v"></i>
        </span>
        {props.lessons[id].name}
      </span>
      <i className="fa fa-angle-right"></i>
    </a>
  );
}


export default ChaptersIndex;
