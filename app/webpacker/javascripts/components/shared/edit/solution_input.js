"use strict";

import React from "react";

import EditTextInput from "shared/edit/text_input";
import EditVideoUrl from "shared/edit/video_url";
import EditUrlInput from "shared/edit/url_input";

const SolutionInput = ({solutions, attribute, solution_type, placeholder, register, errors, watch, setValue}) => {
  const renderUrlInput = () => {
    switch (solution_type) {
      case "video":
        return <EditVideoUrl register={register} errors={errors} watch={watch} name={attribute} placeholder={placeholder} />;
      case "pdf":
        return <EditUrlInput register={register} errors={errors} name={attribute} placeholder={placeholder} />;
      case "external":
        return <EditTextInput register={register} errors={errors} watch={watch} name={attribute} placeholder={placeholder} />;
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
              {solution.description && (
                <p className="break-line-content text-align-left">
                  {solution.description}
                </p>
              )}
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
