"use strict"

import React from "react";

const TextInput = ({register, name, placeholder}) => (
  <div className="field-row">
    <input autoFocus={true} ref={register({ required: true })} name={name} placeholder={placeholder} className="extend" type="text" />
  </div>
)

export default TextInput
