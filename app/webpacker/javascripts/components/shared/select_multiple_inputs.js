"use strict";

import React from "react";
import { FieldArray } from 'react-final-form-arrays'
import ReactSelect from "react-select";

import { Error } from "./components";
import { selectCustomStyles } from "../../libraries/styles";

const SelectMultipleInputs = ({options, selectLabel, collection_name, resultFields, hint, input, meta}) => {
  return (
    <FieldArray name={collection_name}>
      {({ fields }) => (
        <div className="select-multiple-inputs">
          {resultFields(fields, collection_name)}
          <div className="select-input">
            <ReactSelect
              ref={(c) => this.menuSelector = c}
              className="menu-select-container"
              placeholder={selectLabel}
              options={options}
              onChange={input.onChange}
              styles={selectCustomStyles}
              />
            <a
              href="#"
              className={`btn btn-symbol btn-yellow after-field-btn ${input.value ? "" : "disabled"}`}
              onClick={(event) => {
                event.preventDefault();
                let isFieldDuplicated = false;

                if (fields.value) {
                  fields.value.forEach((field) => {
                    if (field.value == input.value.value) {
                      isFieldDuplicated = true;
                    };
                  });
                }

                if (!isFieldDuplicated) {
                  fields.push({...input.value})
                }
                this.menuSelector.select.clearValue();
              }}
              >
              <i className="fa fa-plus" aria-hidden="true" ></i>
            </a>
            { hint ? <span className="field-hint">{hint}</span> : ""}
            <Error name={`${input.name}`} />
          </div>
        </div>
      )}
    </FieldArray>
  );
};

export default SelectMultipleInputs;
