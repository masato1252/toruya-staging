"use strict";

import React from "react";
import I18n from 'i18n-js/index.js.erb';
import { DemoEditButton } from 'shared/components';

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
const LessonContent = ({lesson, demo, jump, light}) => {
  return (
    <div className="online-service-page">
      <div className="online-service-body centerize">
        <h2 className="name">
          {lesson.name}
          <DemoEditButton demo={demo} jump={() => jump(0)} />
        </h2>
        <div className="my-4">
          <DemoEditButton demo={demo} jump={() => jump(1)} />
          <Solution
            solution_type={lesson.solution_type}
            content_url={lesson.content_url}
            light={light}
          />
        </div>
        <div className="text-left break-line-content">
          <DemoEditButton demo={demo} jump={() => jump(2)} />
          {lesson.note}
        </div>
      </div>
    </div>
  )
}

export default LessonContent;
