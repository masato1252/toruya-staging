"use strict";

import React from "react";
import AutosizeInput from 'react-input-autosize';
import { SwatchesPicker } from 'react-color';
import Popup from 'reactjs-popup';

const Input = ({block, onChange, onFocus, onBlur, inputDisabled, ...rest}) => {
  const { name, placeholder } =  block
  return (
    <AutosizeInput
      type={block.type || "text"}
      name={name}
      placeholder={placeholder}
      defaultValue={rest[name]}
      onChange={(event) => onBlur(name, event.target.value)}
      onFocus={() => onFocus(name)}
      disabled={inputDisabled}
      inputStyle={ { fontSize: block.font_size } }
    />
  )
}
const LineBreak = ({block}) => {
  return <br />
}

const Word = ({block, ...rest}) => {
  return (
    React.createElement(
      block.tag || "span",
      { 
        style: {
          color: rest[`${block.name}_color`] || block.color,
          fontSize: rest[`${block.name}_font_size`] || block.font_size
        },
        dangerouslySetInnerHTML: {
          __html: rest[block.name] || block.content
        }
      }
    )
  )
}

const SupportComponents = {
  input: Input,
  br: LineBreak,
  word: Word,
};

const Components = ({block, index, ...props})=> {
  // component does exist
  if (typeof SupportComponents[block.component] !== "undefined") {
    return React.createElement(SupportComponents[block.component], {
      key: `${block.component}-${block.name}-${index}`, 
      block,
      ...props
    });
  }
}

const Template = ({template, onClick, klass, ...props}) => {
  return (
    <div
      className={klass || "sale-template-content"}
      onClick={onClick}>
      {template.map((block, index) => Components({block, index, ...props}))}
    </div>
  )
}

const HintTitle = ({template,  focus_field}) => {
  return (
    <h4 className="centerize break-line-content">
      {template.find(block => block.name == focus_field)?.title}
    </h4>
  )
}

const ColorPopup = ({handleColorChange, block, ...rest}) => {
  return (
    <Popup
      modal={true}
      trigger={
        <button
          className="btn"
          style={{backgroundColor: rest[`${block.name}_color`] || block.color}}
        >
          {rest[`${block.name}_color`] || block.color}
        </button>
      }>
      {close => (
        <div>
          <SwatchesPicker onChange={(color) => {
            handleColorChange(color)
            close()
          }}
        />
        </div>
      )}
    </Popup>
  )
}

const WordColorPickers = ({template, onChange, ...rest}) => {
  return (
    <div className="word-color-pickers">
      {template.filter(block => block.color_editable).map((editable_block, index) => (
        <label key={`${editable_block.component}-${editable_block.name}-${index}`}>
          <b>{editable_block.color_editable_label}</b>
          <ColorPopup
            {...rest}
            block={editable_block}
            handleColorChange={(color) => {
              onChange(`${editable_block.name}_color`, color.hex)
            }}
          />
        </label>
      ))}
    </div>
  )
}

export {
  Template,
  HintTitle,
  WordColorPickers
}
