"use strict";

import React from "react";
import { FieldArray } from 'react-final-form-arrays'
import { OnChange } from 'react-final-form-listeners'
import ReactSelect from "react-select";

import { Error } from "./components";
import { selectCustomStyles } from "../../libraries/styles";

const SelectMultipleInputs = ({options, selectLabel, collection_name, resultFields, hint, input, meta}) => {
  let menuSelector;

  return (
    <FieldArray name={collection_name}>
      {({ fields }) => (
        <div className="select-multiple-inputs">
          {resultFields(fields, collection_name)}
          <div className="select-input">
            <ReactSelect
              ref={(c) => menuSelector = c}
              className="menu-select-container"
              styles={selectCustomStyles}
              placeholder={selectLabel}
              options={options}
              onChange={(event) => {
                input.onChange(event);
                input.onBlur(event)
              }}
            />
            <OnChange name={input.name}>
              {(option) => {
                if (!option) return;

                let isFieldDuplicated = false;

                if (fields.value) {
                  fields.value.forEach((field) => {
                    if (field.value == option.value) {
                      isFieldDuplicated = true;
                    };
                  });
                }

                if (!isFieldDuplicated) {
                  fields.push({...option})
                }

                menuSelector.select.clearValue();
              }}
            </OnChange>
            { hint ? <span className="field-hint">{hint}</span> : ""}
            <Error name={`${input.name}`} />
          </div>
        </div>
      )}
    </FieldArray>
  );
};

export default SelectMultipleInputs;
