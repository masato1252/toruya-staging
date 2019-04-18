"use strict";

import React from "react";
import { FieldArray } from 'react-final-form-arrays'
import ReactSelect from "react-select";

import { Error } from "./components";

const SelectMultipleInputs = ({options, selectLabel, collection_name, resultFields, input, meta}) => {
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
              />
            <a
              href="#"
              className={`btn btn-symbol btn-yellow ${input.value ? "" : "disabled"}`}
              onClick={() =>  {
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
            <Error name={`${input.name}`} />
          </div>
        </div>
      )}
    </FieldArray>
  );
};

export default SelectMultipleInputs;
