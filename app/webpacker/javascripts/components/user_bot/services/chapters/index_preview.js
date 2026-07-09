"use strict";

import React, { useEffect, useState } from "react";
import CoursePage from "user_bot/services/online_service_page/course";
import { compatRead } from "../../../libraries/compat_api";

const ChaptersIndexPreview = ({ pageContextPath }) => {
  const [course, setCourse] = useState(null);
  const [publicUrl, setPublicUrl] = useState(null);

  useEffect(() => {
    if (!pageContextPath) return undefined;
    let cancelled = false;
    compatRead(pageContextPath)
      .then((body) => {
        if (cancelled) return;
        const form = body.data?.index_form;
        setCourse(form?.course ?? null);
        setPublicUrl(form?.public_url ?? null);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [pageContextPath]);

  if (!course) return null;

  return (
    <>
      {publicUrl ? (
        <input type="text" className="extend" readOnly value={publicUrl} />
      ) : null}
      <div className="fake-mobile-layout">
        <CoursePage course={course} lesson_ids={[]} preview={true} />
      </div>
    </>
  );
};

export default ChaptersIndexPreview;
