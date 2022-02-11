"use strict";

import React, { useState } from "react";

export const FlowController = ({ new_version, children }) => {
  const [step, setStep] = useState(0)
  const childrenArray = Array.isArray(children) ? children : Array.of(children)

  const next = () => {
    setStep(s => {
      return s + 1 >= childrenArray.length ? s : s + 1
    })
  }

  const prev = () => {
    setStep(s => {
      return s - 1 <= 0 ?  0 : s - 1
    })
  }

  const jump = (step) => {
    setStep(step)
  }

  const jumpByKey = (key) => {
    let indexStep = childrenArray.findIndex(child => child.key === key)
    setStep(indexStep)
  }

  const lastStep = (pre = 1) => {
    setStep(childrenArray.length - pre)
  }

  if (new_version) {
    return (
      React.cloneElement(childrenArray[step], {next, prev, jump, jumpByKey, step, lastStep})
    )
  }

  return (
    childrenArray[step]({next, prev, jump, jumpByKey, step, lastStep})
  )
}

export default FlowController;
