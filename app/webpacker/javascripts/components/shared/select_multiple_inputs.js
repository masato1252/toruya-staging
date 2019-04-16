"use strict";

import React from "react";
import { Field } from "react-final-form";
import { FieldArray } from 'react-final-form-arrays'
import ReactSelect from "react-select";

import { Error } from "./components";

const renderMultipleSelectInputs = (fields, collection_name) => {
  return (
    <div>
      {fields.map((field, index) => {
        return (
         <li key={`${collection_name}-${index}`}>
           <Field
             name={`${field}label`}
             value={field.label}
             component="input"
             readOnly={true}
           />
           <Field
             name={`${field}value`}
             value={field.value}
             component="input"
             type="hidden"
           />
           <a
             href="#"
             className="btn btn-symbol btn-orange"
             onClick={() => fields.remove(index) }
             >
             <i className="fa fa-minus" aria-hidden="true" ></i>
           </a>
         </li>
        )
       })}
    </div>
  )
};

const SelectMultipleInputs = ({options, selectLabel, collection_name, input, meta}) => {
  return (
    <FieldArray name={collection_name}>
      {({ fields }) => (
        <ul>
          {renderMultipleSelectInputs(fields, collection_name)}
          <li>
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
            <Error name={`${collection_name}_error`} />
          </li>
        </ul>
      )}
    </FieldArray>
  );
};

export default SelectMultipleInputs;
