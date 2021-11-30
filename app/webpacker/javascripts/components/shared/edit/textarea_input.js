"use strict"

import React from "react";
import TextareaAutosize from 'react-autosize-textarea';

const TextareaInput = ({register, name, placeholder}) => (
  <div className="field-row">
    <TextareaAutosize
      className="extend with-border"
      ref={register({ required: true })}
      name={name}
      placeholder={placeholder}
    />
  </div>
)

export default TextareaInput
