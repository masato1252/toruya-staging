"use strict";

import React from "react";

import _ from "lodash";

const EditTagsInput = ({new_tag, tags, existing_tags, setNewTag, setTags}) => {
  return (
    <>
      <input
        type="text"
        value={new_tag || ""}
        className="extend with-border"
        onChange={(event) => setNewTag(event.target.value)}
      />
      <button
        disabled={!new_tag}
        onClick={() => {
          if (!new_tag) return;

          setTags(_.uniq([...tags, new_tag]))
          setNewTag(null)
        }}
        className="btn btn-orange mar">
        {I18n.t("action.add_more")}
      </button>
      <div className="margin-around">
        {tags.map(tag => (
          <button
            className="btn btn-gray mx-2 my-2"
            onClick={() => setTags(tags.filter(item => item !== tag))}>
            {tag}
          </button>
        ))}
      </div>

      <div className="margin-around">
        {existing_tags.map(tag => (
          <button
            className="btn btn-gray mx-2 my-2"
            onClick={() => setTags(_.uniq([...tags, tag]))}>
            {tag}
          </button>
        ))}
      </div>
    </>
  )
}

export default EditTagsInput
