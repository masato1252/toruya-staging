"use strict";

import React from "react";
import AutosizeInput from 'react-input-autosize';
import { SwatchesPicker } from 'react-color';
import Popup from 'reactjs-popup';

const data = {
  edit: [
    { _uid: "BUY6Drn9e1", component: "input", name: "target", placeholder: "ターゲット", title: "この販売ページのターゲットは誰ですか？", type: "text" },
    { _uid: "BUY6Drn9e4", component: "word", content: "の" },
    { _uid: "BUY6Drn9e3", component: "input", type: "text", name: "problem", placeholder: "悩み", title: "ターゲットの悩みは何ですか？" },
    { _uid: "BUY9e4", component: "word", content: "を" },
    { _uid: "Drn9e2", component: "br", },
    { _uid: "BUY6Dreh", component: "input", type: "text", name: "result", placeholder: "解決後の状態", title: "この予約メニューを利用することで 悩みが解決されたターゲットは どんな未来を手に入れられますか？" },
    { _uid: "BUY6n9e4", component: "word", content: "にする" },
    { _uid: "BUY6Drn9e2", component: "br", },
    { _uid: "B6n9e4", component: "word", tag: "h4", name: "product_name", },
  ],
  view: [
    { _uid: "BUY6Drn9e1", component: "word", name: "target" },
    { _uid: "BUY6Drn9e4", component: "word", content: "の", tag: "span" },
    { _uid: "BUY6Drn9e3", component: "word", name: "problem" },
    { _uid: "BUY9e4", component: "word", content: "を", tag: "span" },
    { _uid: "Drn9e2", component: "br", },
    { _uid: "rn9e3", component: "word", name: "result", color: "#C6A654", font_size: "22px", color_editable: true },
    { _uid: "BUY6n9e4", component: "word", content: "にする", tag: "span" },
    { _uid: "BUY6Drn9e2", component: "br", },
    { _uid: "B6n9e4", component: "word", tag: "h4", name: "product_name", color: "#64B14D", font_size: "24px", color_editable: true },
  ]
}

const Input = ({block, onChange, onFocus, onBlur, ...rest}) => {
  const { name, placeholder } =  block
  return (
    <AutosizeInput
      type={block.type || "text"}
      name={name}
      placeholder={placeholder}
      defaultValue={rest[name]}
      onChange={(event) => onBlur(name, event.target.value)}
      onFocus={() => {
        onFocus(name)
      }}
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
      { style:
        {
          color: rest[`${block.name}_color`] || block.color,
          fontSize: rest[`${block.name}_font_size`] || block.font_size
        }
      },
      rest[block.name] || block.content
    )
  )
}

const SupportComponents = {
  input: Input,
  br: LineBreak,
  word: Word,
};

const Components = ({block, ...props})=> {
  // component does exist
  if (typeof SupportComponents[block.component] !== "undefined") {
    return React.createElement(SupportComponents[block.component], {
      key: block._uid,
      block,
      ...props
    });
  }
}

const EditTemplate = ({...props}) => {
  return (
    <div className="sales-template">
      {data.edit.map(block => Components({block, ...props}))}
    </div>
  )
}

const ViewTemplate = ({...props}) => {
  return (
    <div className="sales-template">
      {data.view.map(block => Components({block, ...props}))}
    </div>
  )
}

const HintTitle = ({focus_field}) => {
  return (
    <h3>
      {data.edit.find(block => block.name == focus_field)?.title}
    </h3>
  )
}

const ColorPopup = ({handleColorChange, block, ...rest}) => {
  return (
    <Popup
      trigger={
        <button
          className="btn"
          style={{backgroundColor: rest[`${block.name}_color`] || block.color}}
        >
          {rest[`${block.name}_color`] || block.color}
        </button>
      }
      position="bottom center">
      <div>
        <SwatchesPicker onChange={handleColorChange} />
      </div>
    </Popup>
  )
}

const WordColorPickers = ({onChange, ...rest}) => {
  return (
    <div className="word-color-pickers">
      {data.view.filter(block => block.color_editable).map(editable_block => (
        <ColorPopup
          {...rest}
          block={editable_block}
          key={editable_block._uid}
          handleColorChange={(color) => {
            onChange(`${editable_block.name}_color`, color.hex)
          }}
        />
      ))}
    </div>
  )
}

export {
  EditTemplate,
  ViewTemplate,
  data,
  HintTitle,
  WordColorPickers
}
