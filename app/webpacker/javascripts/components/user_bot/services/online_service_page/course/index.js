"use strict";

import React, { useState, useEffect } from "react";
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js';

import LessonContent from "user_bot/services/course/lesson_content";

const LessonRow = ({lesson}) => {
  console.log("chapter", chapter.name)

  return (
    <div>
      {chapter.name}
      {chapter.lessons.map((lesson) => <LessonRow lesson={lesson} /> )}
    </div>
  )
}

const Chapter = ({chapter, setLessonId, lessonId, selected_chaper_id, watched_lesson_ids}) => {
  return (
    <div data-controller="collapse" data-collapse-status={`${selected_chaper_id === chapter.id ? "open" : "closed"}`}>
      <div className="p-3 bg-gray border border-solid border-white flex justify-between" data-action="click->collapse#toggle">
        {chapter.name}

        <span className="booking-option-details-toggler">
          <a className="toggler-link" data-target="collapse.openToggler"><i className="fa fa-chevron-up" aria-hidden="true"></i></a>
          <a className="toggler-link" data-target="collapse.closeToggler"><i className="fa fa-chevron-down" aria-hidden="true"></i></a>
        </span>
      </div>
      <div data-target="collapse.content">
        {chapter.lessons.map((lesson) => {
          return (
            <div
              key={`lesson-${lesson.id}`}
              className="p-3 flex justify-between border-0 border-b border-solid border-gray-500"
              onClick={() =>{
                setLessonId(lesson.id)
              }}
            >
              <div>
                {watched_lesson_ids.includes(lesson.id.toString()) ? (
                  <i className="fas fa-2x fa-check-circle mr-2"></i>
                ) : (lesson.solution_type === 'pdf' ? <i className="fa fa-2x fa-file-pdf mr-2 text-gray-300"></i> : <i className="far fa-2x fa-play-circle mr-2 text-gray-300"></i>)}
                <span className={`${lessonId == lesson.id ? 'font-bold' : ''}`}>{lesson.name}</span>
              </div>
              <div>
                {lesson.customer_start_time}{lesson.customer_start_time && I18n.t("course.lesson_public")}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

const CoursePage = ({course, lesson_id, lesson_ids, preview}) => {
  const [lessonId, setLessonId] = useState(parseInt(lesson_id))
  const [watched_lesson_ids, setWatchLessons] = useState(lesson_ids)
  const [lessonIndex, setLessonIndex] = useState()

  useEffect(() => {
    if (!lessonId) {
      setLessonIndex(0)
      setLessonId(course.lessons[0]?.id)
    }
  }, [])

  useEffect(() => {
    const lessonIndex = course.lessons.findIndex((lesson) => lesson.id === lessonId)

    setLessonIndex(lessonIndex)
  }, [lessonId])

  const lesson = () => {
    return course.lessons.find((lesson) => lesson.id === lessonId) || course.lessons[0]
  }

  const nextLessonId = () => {
    return course.lessons[(lessonIndex + 1) % course.lessons.length]?.id
  }

  const prevLessonId = () => {
    return course.lessons[(lessonIndex - 1 + course.lessons.length) % course.lessons.length]?.id
  }

  return (
    <div className="online-service-page">
      <div className="online-service-header">
        {course.company_info.logo_url ?  <img className="logo" src={course.company_info.logo_url} /> : <h2>{course.company_info.name}</h2> }
      </div>
      <LessonContent
        preview={preview}
        lesson={lesson()}
        course={course}
        demo={false}
        light={false}
        done={watched_lesson_ids.includes(lessonId?.toString())}
        setWatchLessons={setWatchLessons}
        nextLesson={nextLessonId() ? () => setLessonId(nextLessonId()) : null}
        prevLesson={prevLessonId() ? () => setLessonId(prevLessonId()) : null}
      />

      {course.chapters.map(
        (chapter) => (
          <Chapter
            key={`chapter-${chapter.id}`}
            chapter={chapter}
            setLessonId={setLessonId}
            lessonId={lessonId}
            selected_chaper_id={lesson()?.chapter_id}
            watched_lesson_ids={watched_lesson_ids}
          />
        )
      )}
      {course.lessons.length === 0 && (
        <div className="reminder-mark centerize">
          {I18n.t("course.no_lesson_yet")}
        </div>
      )}
    </div>
  )
}

export default CoursePage;
