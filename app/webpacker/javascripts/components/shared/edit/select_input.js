"use strict"

import React from "react";
import { SelectOptions } from "shared/components"

const SelectInput = ({register, name, options}) => (
  <div className="field-row">
    <select autoFocus={true} className="extend" name={name} ref={register({ required: true })}>
      <SelectOptions options={options} />
    </select>
  </div>
)

export default SelectInput
