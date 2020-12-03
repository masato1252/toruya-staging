"use strict";

import React, { useState } from "react";

export const FlowController = ({ children }) => {
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

  return (
    childrenArray[step]({next, prev, jump, step})
  )
}

export default FlowController;
