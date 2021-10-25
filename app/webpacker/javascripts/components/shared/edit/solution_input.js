"use strict";

import React, { useState } from "react";

import EditTextInput from "shared/edit/text_input";
import EditVideoUrl from "shared/edit/video_url";

const SolutionInput = ({solutions, attribute, solution_type, placeholder, register, watch, setValue}) => {
  const renderUrlInput = () => {
    switch (solution_type) {
      case "video":
        return <EditVideoUrl register={register} watch={watch} name={attribute} placeholder={placeholder} />;
      case "pdf":
      case "external":
        return <EditTextInput register={register} watch={watch} name={attribute} placeholder={placeholder} />;
      default:
        return <></>
    }
  }

  const renderSolutionOptions = () => {
    return (
      <>
        {solutions.map((solution) => {
          return (
            <button
              onClick={() => {
                if (!solution.enabled) return;

                setValue('solution_type', solution.key)
              }}
              className="btn btn-tarco btn-extend btn-flexible margin-around m10 relative"
              disabled={!solution.enabled}
              key={solution.key}>
              <h4>{solution.name}</h4>
              <p className="break-line-content text-align-left">
                {solution.description}
              </p>
              {!solution.enabled && <span className="preparing">{I18n.t('common.preparing')}</span>}
            </button>
          )
        })}
      </>
    )
  }

  return (
    <div className="form settings-flow centerize">
      {renderUrlInput()}
      <input ref={register} name="solution_type" type='hidden' />
      {solution_type ? <></> : renderSolutionOptions()}
    </div>
  )
}

export default SolutionInput
