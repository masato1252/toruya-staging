"use strict"

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import ImageUploader from "react-images-upload";
import { TopNavigationBar, BottomNavigationBar, CircleButtonWithWord } from "shared/components";
import { CommonServices } from "user_bot/api";
import I18n from 'i18n-js/index.js.erb';

const EventContentForm = ({ props }) => {
  const isEdit = !!props.event_content?.id;
  const [thumbnail, setThumbnail] = useState(null);
  const [thumbnailPreview, setThumbnailPreview] = useState(props.event_content?.thumbnail_url || null);
  const [images, setImages] = useState(props.event_content?.images || []);
  const [monitorEnabled, setMonitorEnabled] = useState(props.event_content?.monitor_enabled || false);
  const [upsellEnabled, setUpsellEnabled] = useState(props.event_content?.upsell_booking_enabled || false);

  const { register, handleSubmit, formState, watch } = useForm({
    defaultValues: {
      content_type: props.event_content?.content_type || "seminar",
      title: props.event_content?.title || "",
      description: props.event_content?.description || "",
      introduction: props.event_content?.introduction || "",
      shop_id: props.event_content?.shop_id || "",
      online_service_id: props.event_content?.online_service_id || "",
      start_at: props.event_content?.start_at ? props.event_content.start_at.slice(0, 16) : "",
      end_at: props.event_content?.end_at ? props.event_content.end_at.slice(0, 16) : "",
      capacity: props.event_content?.capacity || "",
      position: props.event_content?.position || 0,
      pre_ad_video_url: props.event_content?.pre_ad_video_url || "",
      post_ad_video_url: props.event_content?.post_ad_video_url || "",
      direct_download_url: props.event_content?.direct_download_url || "",
      upsell_booking_page_id: props.event_content?.upsell_booking_page_id || "",
      upsell_booking_enabled: props.event_content?.upsell_booking_enabled || false,
      monitor_enabled: props.event_content?.monitor_enabled || false,
      monitor_name: props.event_content?.monitor_name || "",
      monitor_price: props.event_content?.monitor_price || "",
      monitor_limit: props.event_content?.monitor_limit || "",
      monitor_form_url: props.event_content?.monitor_form_url || "",
    }
  });

  const contentType = watch("content_type");

  const onSubmit = async (data) => {
    if (formState.isSubmitting) return;

    const formData = new FormData();
    Object.keys(data).forEach(k => formData.append(k, data[k] ?? ""));
    if (thumbnail) formData.append("thumbnail", thumbnail);

    const [error, response] = await (isEdit
      ? CommonServices.update({ url: props.action_url, data: formData })
      : CommonServices.create({ url: props.action_url, data: formData })
    );

    if (error) {
      toastr.error(error.response?.data?.error_message || "エラーが発生しました");
    } else {
      window.location = response.data.redirect_to;
    }
  };

  const handleUploadImage = async (files) => {
    if (!files || files.length === 0) return;
    const formData = new FormData();
    formData.append("image", files[0]);
    const [error, response] = await CommonServices.create({ url: props.upload_image_url, data: formData });
    if (!error) {
      setImages(prev => [...prev, { id: response.data.id, url: response.data.url }]);
    }
  };

  const handleDestroyImage = async (imageId) => {
    const url = props.destroy_image_base_url.replace("_IMAGE_ID_", imageId);
    const [error] = await CommonServices.destroy({ url });
    if (!error) {
      setImages(prev => prev.filter(img => img.id !== imageId));
    }
  };

  const backUrl = isEdit
    ? Routes.lines_user_bot_event_content_path(props.business_owner_id, props.event_content?.id)
    : Routes.lines_user_bot_event_path(props.business_owner_id, props.event_id);

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-sm-8 px-0 settings-view">
          <div className="form with-top-bar">
            <TopNavigationBar
              leading={<a href={backUrl}><i className="fa fa-angle-left fa-2x"></i></a>}
              title={isEdit ? "コンテンツ編集" : "コンテンツ作成"}
            />

            <div className="field-header">コンテンツ種別 <span className="text-red-500">*</span></div>
            <div className="field-row">
              <label className="mr-4">
                <input ref={register()} type="radio" name="content_type" value="seminar" /> セミナー動画
              </label>
              <label>
                <input ref={register()} type="radio" name="content_type" value="booth" /> 展示ブース(PDF)
              </label>
            </div>

            <div className="field-header">タイトル <span className="text-red-500">*</span></div>
            <div className="field-row">
              <input ref={register({ required: true })} name="title" type="text" className="form-control" placeholder="コンテンツタイトル" />
            </div>

            <div className="field-header">サムネイル画像</div>
            <div className="field-row">
              {thumbnailPreview && <img src={thumbnailPreview} className="mb-2 rounded" style={{ maxHeight: 150, maxWidth: "100%", objectFit: "cover" }} />}
              <ImageUploader
                withIcon={false}
                withPreview={false}
                withLabel={false}
                singleImage={true}
                buttonText="サムネイルを選択"
                onChange={(files, urls) => { setThumbnail(files[0]); setThumbnailPreview(urls[0]); }}
                imgExtension={[".jpg", ".png", ".jpeg", ".gif"]}
                maxFileSize={5242880}
              />
            </div>

            <div className="field-header">紹介文</div>
            <div className="field-row">
              <textarea ref={register()} name="introduction" rows={3} className="form-control" placeholder="コンテンツの一言紹介（カード一覧表示用）" />
            </div>

            <div className="field-header">説明文</div>
            <div className="field-row">
              <textarea ref={register()} name="description" rows={5} className="form-control" placeholder="コンテンツの詳細説明" />
            </div>

            <div className="field-header">掲載店舗</div>
            <div className="field-row">
              <select ref={register()} name="shop_id" className="form-control">
                <option value="">選択してください</option>
                {(props.shops || []).map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>

            <div className="field-header">連携オンラインサービス</div>
            <div className="field-row">
              <select ref={register()} name="online_service_id" className="form-control">
                <option value="">なし</option>
                {(props.online_services || []).map(os => <option key={os.id} value={os.id}>{os.name}</option>)}
              </select>
            </div>

            <div className="field-header">サービス開始日時</div>
            <div className="field-row">
              <input ref={register()} name="start_at" type="datetime-local" className="form-control" />
            </div>

            <div className="field-header">サービス終了日時</div>
            <div className="field-row">
              <input ref={register()} name="end_at" type="datetime-local" className="form-control" />
            </div>

            <div className="field-header">利用開始上限人数</div>
            <div className="field-row">
              <input ref={register()} name="capacity" type="number" min="1" className="form-control" placeholder="空欄で無制限" />
            </div>

            <div className="field-header">表示順</div>
            <div className="field-row">
              <input ref={register()} name="position" type="number" min="0" className="form-control" defaultValue={0} />
            </div>

            {contentType === "seminar" && (
              <>
                <div className="field-header">広告動画URL（前）</div>
                <div className="field-row">
                  <input ref={register()} name="pre_ad_video_url" type="url" className="form-control" placeholder="https://www.youtube.com/watch?v=..." />
                  <small className="text-gray-500">YouTube または Google ドライブの共有URL</small>
                </div>

                <div className="field-header">広告動画URL（後）</div>
                <div className="field-row">
                  <input ref={register()} name="post_ad_video_url" type="url" className="form-control" placeholder="https://www.youtube.com/watch?v=..." />
                </div>

                <div className="field-header">資料ダウンロードURL（直接DL）</div>
                <div className="field-row">
                  <input ref={register()} name="direct_download_url" type="url" className="form-control" placeholder="https://..." />
                </div>
              </>
            )}

            {contentType === "booth" && (
              <>
                <div className="field-header">スライド画像（PDFプレビュー用）</div>
                <div className="field-row">
                  <div className="flex flex-wrap gap-2 mb-2">
                    {images.map(img => (
                      <div key={img.id} className="relative" style={{ width: 100 }}>
                        <img src={img.url} style={{ width: 100, height: 70, objectFit: "cover", borderRadius: 4 }} />
                        <button
                          type="button"
                          onClick={() => handleDestroyImage(img.id)}
                          className="absolute top-0 right-0 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs"
                        >×</button>
                      </div>
                    ))}
                  </div>
                  {isEdit && (
                    <ImageUploader
                      withIcon={false}
                      withPreview={false}
                      withLabel={false}
                      singleImage={true}
                      buttonText="スライド画像を追加"
                      onChange={handleUploadImage}
                      imgExtension={[".jpg", ".png", ".jpeg"]}
                      maxFileSize={5242880}
                    />
                  )}
                  {!isEdit && <small className="text-gray-500">保存後に画像を追加できます</small>}
                </div>
              </>
            )}

            <hr className="my-4" />
            <div className="field-header">アップセル設定</div>

            <div className="field-row">
              <label className="flex items-center gap-2">
                <input
                  ref={register()}
                  type="checkbox"
                  name="upsell_booking_enabled"
                  onChange={e => setUpsellEnabled(e.target.checked)}
                />
                無料相談予約を設定する
              </label>
            </div>

            {upsellEnabled && (
              <div className="field-row">
                <div className="field-header">誘導先の予約ページ</div>
                <select ref={register()} name="upsell_booking_page_id" className="form-control">
                  <option value="">選択してください</option>
                  {(props.booking_pages || []).map(bp => <option key={bp.id} value={bp.id}>{bp.name}</option>)}
                </select>
              </div>
            )}

            <div className="field-row mt-3">
              <label className="flex items-center gap-2">
                <input
                  ref={register()}
                  type="checkbox"
                  name="monitor_enabled"
                  onChange={e => setMonitorEnabled(e.target.checked)}
                />
                モニター募集を設定する
              </label>
            </div>

            {monitorEnabled && (
              <>
                <div className="field-row">
                  <div className="field-header">モニターサービス名</div>
                  <input ref={register()} name="monitor_name" type="text" className="form-control" />
                </div>
                <div className="field-row">
                  <div className="field-header">モニター金額（円）</div>
                  <input ref={register()} name="monitor_price" type="number" min="0" className="form-control" />
                </div>
                <div className="field-row">
                  <div className="field-header">モニター上限人数</div>
                  <input ref={register()} name="monitor_limit" type="number" min="1" className="form-control" />
                </div>
                <div className="field-row">
                  <div className="field-header">応募フォームURL（Googleフォーム）</div>
                  <input ref={register()} name="monitor_form_url" type="url" className="form-control" placeholder="https://forms.gle/..." />
                </div>
              </>
            )}

            <BottomNavigationBar klassName="centerize transparent">
              <span></span>
              <CircleButtonWithWord
                disabled={formState.isSubmitting}
                onHandle={handleSubmit(onSubmit)}
                icon={formState.isSubmitting ? <i className="fa fa-spinner fa-spin fa-2x"></i> : <i className="fa fa-save fa-2x"></i>}
                word={I18n.t("action.save")}
              />
            </BottomNavigationBar>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EventContentForm;
