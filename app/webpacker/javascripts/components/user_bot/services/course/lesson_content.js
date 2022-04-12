"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js'
import { DemoEditButton } from 'shared/components';
import { CommonServices } from "user_bot/api";

import Solution from "../online_service_page/solution";
// lesson:
// {
//   name: $name,
//   note: $note,
//   solution_type: video/pdf,
//   content_url: $url
// }
//
// demo: true/false
// jump: $function
// light: true/false
const LessonContent = ({course, lesson, preview, demo, jump, light, done, nextLesson, prevLesson, setWatchLessons}) => {
  if (!lesson) return <></>

  return (
    <div className="online-service-body centerize">
      <h2 className="name">
        {lesson.name}
        <DemoEditButton demo={demo} jump={() => jump(0)} />
      </h2>
      <div className="my-4">
        <DemoEditButton demo={demo} jump={() => jump(1)} />
        {(demo || lesson.started_for_customer || preview) ? (
          <Solution
            solution_type={lesson.solution_type}
            content_url={lesson.content_url}
            light={light}
          />
        ) : (
          <div className="reminder-mark">
            {I18n.t("course.lesson_start_on")}{lesson.customer_start_time}
          </div>
        )}
      </div>
      {!demo && (
        <div className="flex justify-between">
          {prevLesson && <div onClick={prevLesson}><i className="fas fa-2x fa-arrow-left text-tarco"></i></div>}
          <button
            disabled={done || !lesson.started_for_customer || preview}
            className="btn btn-tarco"
            onClick={async () => {
              const [error, response] = await CommonServices.update({
                url: Routes.watch_lesson_online_service_path({slug: course.slug, lesson_id: lesson.id}),
                data: {}
              })

              setWatchLessons(response.data.watched_lesson_ids)
            }}>{I18n.t("course.mark_lesson_done")}</button>
          {nextLesson && <div onClick={nextLesson}><i className="fas fa-2x fa-arrow-right text-tarco"></i></div>}
        </div>
      )}
      {(demo || lesson.started_for_customer || preview) && (
        <div className="text-left break-line-content rounded mt-1">
          <DemoEditButton demo={demo} jump={() => jump(2)} />
          {lesson.note}
        </div>
      )}
    </div>
  )
}

export default LessonContent;
