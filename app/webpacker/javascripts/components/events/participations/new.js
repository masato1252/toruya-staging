"use strict"

import React, { useState } from "react";
import I18n from 'i18n-js/index.js.erb';

const BUSINESS_TYPES = [
  "セラピスト", "整体師", "ネイリスト", "アイリスト",
  "Yoga講師", "ピラティス講師", "美容師", "スクール講師", "その他"
];

const BUSINESS_AGES = [
  { value: "under_one_year", label: "1年未満" },
  { value: "one_to_three_years", label: "1〜3年" },
  { value: "over_three_years", label: "3年以上" }
];

const CONCERNS = [
  { category: "集客・認知", items: [
    "新規のお客様がなかなか増えない",
    "SNSやホームページを頑張っているのに予約に繋がらない",
    "紹介だけに頼っていて、自分で集客する方法が分からない"
  ]},
  { category: "LINE・デジタルツール活用", items: [
    "LINEを導入したが使いこなせていない",
    "LINEはメッセージ送受信にしか使えていない",
    "ホームページやSNSの見た目・デザインをもっとよくしたい"
  ]},
  { category: "コンテンツ・発信", items: [
    "発信したいことはあるのにうまく言葉にできない",
    "ブログや文章を書くのが苦手で続かない",
    "集客のための文章や資料をどう作ればいいか分からない"
  ]},
  { category: "経営・売上", items: [
    "予約は入っているのに売上が安定しない",
    "単価を上げたいが、どうすれば良いか分からない",
    "確定申告や税金・お金の管理が不安",
    "売上はあっても手元にお金が残らない"
  ]},
  { category: "時間・仕組み化", items: [
    "集客・事務作業に時間がかかりすぎて施術に集中できない",
    "リピーターが少なく、毎月集客し直しになっている",
    "予約管理や顧客対応の仕組みをもっと整えたい"
  ]},
  { category: "その他", items: ["その他（自由記述）"] }
];

const ParticipationForm = ({ props }) => {
  const [selectedBusinessTypes, setSelectedBusinessTypes] = useState([]);
  const [businessAge, setBusinessAge] = useState("");
  const [concernLabel, setConcernLabel] = useState("");
  const [concernOther, setConcernOther] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const toggleBusinessType = (type) => {
    setSelectedBusinessTypes(prev =>
      prev.includes(type) ? prev.filter(t => t !== type) : [...prev, type]
    );
  };

  const handleSubmit = async () => {
    if (isSubmitting) return;
    setIsSubmitting(true);

    try {
      const response = await fetch(props.action_url, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content },
        body: JSON.stringify({
          business_types: selectedBusinessTypes,
          business_age: businessAge,
          concern_label: concernLabel,
          concern_other: concernOther
        })
      });
      const data = await response.json();
      if (data.success) {
        window.location = data.redirect_to;
      } else {
        toastr.error(data.error || "エラーが発生しました");
        setIsSubmitting(false);
      }
    } catch (e) {
      toastr.error("エラーが発生しました");
      setIsSubmitting(false);
    }
  };

  return (
    <div className="booking-content" style={{ maxWidth: 600, margin: "0 auto", padding: "0 16px 80px" }}>
      <div style={{ padding: "24px 0 16px", borderBottom: "1px solid #eee", marginBottom: 24 }}>
        <h2 style={{ fontSize: 20, fontWeight: "bold", marginBottom: 4 }}>{props.event_title}</h2>
        <p style={{ color: "#666", fontSize: 14 }}>参加登録 — プロフィール入力（全て任意）</p>
      </div>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ fontSize: 16, fontWeight: "bold", marginBottom: 12 }}>1. 事業内容（複数選択可）</h3>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
          {BUSINESS_TYPES.map(type => (
            <button
              key={type}
              type="button"
              onClick={() => toggleBusinessType(type)}
              style={{
                padding: "8px 14px",
                borderRadius: 20,
                border: `2px solid ${selectedBusinessTypes.includes(type) ? "#00b900" : "#ddd"}`,
                background: selectedBusinessTypes.includes(type) ? "#00b900" : "#fff",
                color: selectedBusinessTypes.includes(type) ? "#fff" : "#333",
                cursor: "pointer",
                fontSize: 13
              }}
            >
              {type}
            </button>
          ))}
        </div>
      </section>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ fontSize: 16, fontWeight: "bold", marginBottom: 12 }}>2. 開業歴</h3>
        <div style={{ display: "flex", gap: 12 }}>
          {BUSINESS_AGES.map(age => (
            <label key={age.value} style={{ display: "flex", alignItems: "center", gap: 6, cursor: "pointer" }}>
              <input
                type="radio"
                name="business_age"
                value={age.value}
                checked={businessAge === age.value}
                onChange={() => setBusinessAge(age.value)}
              />
              {age.label}
            </label>
          ))}
        </div>
      </section>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ fontSize: 16, fontWeight: "bold", marginBottom: 12 }}>3. 今の一番の悩み</h3>
        {CONCERNS.map(group => (
          <div key={group.category} style={{ marginBottom: 16 }}>
            <div style={{ fontSize: 12, color: "#888", marginBottom: 6, fontWeight: "bold" }}>{group.category}</div>
            {group.items.map(item => (
              <label
                key={item}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  padding: "8px 12px",
                  border: `2px solid ${concernLabel === item ? "#00b900" : "#eee"}`,
                  borderRadius: 8,
                  marginBottom: 6,
                  cursor: "pointer",
                  background: concernLabel === item ? "#f0fff0" : "#fff"
                }}
              >
                <input
                  type="radio"
                  name="concern_label"
                  value={item}
                  checked={concernLabel === item}
                  onChange={() => setConcernLabel(item)}
                  style={{ display: "none" }}
                />
                <span style={{ fontSize: 14 }}>{item}</span>
              </label>
            ))}
          </div>
        ))}
        {concernLabel === "その他（自由記述）" && (
          <textarea
            value={concernOther}
            onChange={e => setConcernOther(e.target.value)}
            placeholder="自由にご記入ください"
            rows={3}
            style={{ width: "100%", padding: 10, border: "1px solid #ddd", borderRadius: 8, fontSize: 14 }}
          />
        )}
      </section>

      <div style={{ position: "fixed", bottom: 0, left: 0, right: 0, background: "#fff", padding: "16px", borderTop: "1px solid #eee" }}>
        <button
          onClick={handleSubmit}
          disabled={isSubmitting}
          style={{
            width: "100%",
            padding: "14px",
            background: isSubmitting ? "#ccc" : "#00b900",
            color: "#fff",
            border: "none",
            borderRadius: 8,
            fontSize: 16,
            fontWeight: "bold",
            cursor: isSubmitting ? "not-allowed" : "pointer"
          }}
        >
          {isSubmitting ? "登録中..." : "イベントに参加登録する"}
        </button>
      </div>
    </div>
  );
};

export default ParticipationForm;
