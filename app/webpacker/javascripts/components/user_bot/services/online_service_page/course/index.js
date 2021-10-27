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

const Chapter = ({chapter, setLessonId, selected_chaper_id}) => {
  console.log("chapter", chapter.name)

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
              className="p-3"
              onClick={() => setLessonId(lesson.id)}>
              {lesson.name}
            </div>
          )
        })}
      </div>
    </div>
  )
}

const CoursePage = ({course, lesson_id}) => {
  const [lessonId, setLessonId] = useState(parseInt(lesson_id))
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
    return course.lessons.find((lesson) => lesson.id === lessonId)
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
        lesson={lesson()}
        demo={false}
        light={false}
        nextLesson={nextLessonId() ? () => setLessonId(nextLessonId()) : null}
        prevLesson={prevLessonId() ? () => setLessonId(prevLessonId()) : null}
      />

      {course.chapters.map(
        (chapter) => (
          <Chapter
            key={`chapter-${chapter.id}`}
            chapter={chapter}
            setLessonId={setLessonId}
            selected_chaper_id={lesson()?.chapter_id}
          />
        )
      )}
    </div>
  )
}

export default CoursePage;
