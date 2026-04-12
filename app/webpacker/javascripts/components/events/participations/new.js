"use strict"

import React, { useState } from "react";
import I18n from 'i18n-js/index.js.erb';

const MAX_CONCERNS = 6;

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
    "紹介だけに頼っていて自分で集客する方法が分からない"
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
    "単価を上げたいがどうすれば良いか分からない",
    "確定申告や税金・お金の管理が不安",
    "売上はあっても手元にお金が残らない"
  ]},
  { category: "時間・仕組み化", items: [
    "集客・事務作業に時間がかかりすぎて施術に集中できない",
    "リピーターが少なく毎月集客し直しになっている",
    "予約管理や顧客対応の仕組みをもっと整えたい"
  ]},
  { category: "その他", items: ["その他（自由記述）"] }
];

const ParticipationForm = ({ props }) => {
  const [selectedBusinessTypes, setSelectedBusinessTypes] = useState([]);
  const [businessAge, setBusinessAge] = useState("");
  const [concernLabels, setConcernLabels] = useState([]);
  const [concernOther, setConcernOther] = useState("");
  const [firstName, setFirstName] = useState(props.initial_first_name || "");
  const [lastName, setLastName] = useState(props.initial_last_name || "");
  const [phoneNumber, setPhoneNumber] = useState(props.initial_phone_number || "");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const toggleBusinessType = (type) => {
    setSelectedBusinessTypes(prev =>
      prev.includes(type) ? prev.filter(t => t !== type) : [...prev, type]
    );
  };

  const toggleConcern = (item) => {
    setConcernLabels(prev => {
      if (prev.includes(item)) {
        return prev.filter(c => c !== item);
      }
      if (prev.length >= MAX_CONCERNS) {
        return prev;
      }
      return [...prev, item];
    });
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
          concern_labels: concernLabels,
          concern_other: concernOther,
          first_name: firstName,
          last_name: lastName,
          phone_number: phoneNumber
        })
      });
      const data = await response.json();
      if (data.success) {
        window.location = data.redirect_to;
      } else {
        toastr.error(data.error_message || data.error || "エラーが発生しました");
        setIsSubmitting(false);
      }
    } catch (e) {
      toastr.error("エラーが発生しました");
      setIsSubmitting(false);
    }
  };

  const remainingConcerns = MAX_CONCERNS - concernLabels.length;

  return (
    <div className="booking-content" style={{ maxWidth: 600, margin: "0 auto", padding: "0 16px 40px" }}>
      <div style={{ padding: "24px 0 16px", borderBottom: "1px solid #eee", marginBottom: 20 }}>
        <h2 style={{ fontSize: 20, fontWeight: "bold", marginBottom: 4 }}>{props.event_title}</h2>
        <p style={{ color: "#666", fontSize: 14 }}>参加登録 — プロフィール入力</p>
      </div>

      <div style={{ background: "#f0fdfa", border: "1px solid #99f6e4", padding: "16px 18px", marginBottom: 28 }}>
        <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 6, color: "#134e4a" }}>
          🎯 業種やお悩みに合わせた最適な出展者をお勧めします
        </div>
        <div style={{ fontSize: 13, color: "#44403c", lineHeight: 1.6 }}>
          回答は任意ですが、ご入力いただくとイベントをより活用いただけます！
        </div>
      </div>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ fontSize: 16, fontWeight: "bold", marginBottom: 12 }}>お名前</h3>
        <div style={{ display: "flex", gap: 8 }}>
          <input
            type="text"
            value={lastName}
            onChange={e => setLastName(e.target.value)}
            placeholder="姓"
            style={{ flex: 1, padding: "10px 12px", border: "1px solid #ddd", borderRadius: 8, fontSize: 14 }}
          />
          <input
            type="text"
            value={firstName}
            onChange={e => setFirstName(e.target.value)}
            placeholder="名"
            style={{ flex: 1, padding: "10px 12px", border: "1px solid #ddd", borderRadius: 8, fontSize: 14 }}
          />
        </div>
      </section>

      <section style={{ marginBottom: 32 }}>
        <h3 style={{ fontSize: 16, fontWeight: "bold", marginBottom: 12 }}>電話番号</h3>
        <input
          type="tel"
          value={phoneNumber}
          onChange={e => setPhoneNumber(e.target.value)}
          placeholder="090-1234-5678"
          style={{ width: "100%", padding: "10px 12px", border: "1px solid #ddd", borderRadius: 8, fontSize: 14 }}
        />
      </section>

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
                border: `2px solid ${selectedBusinessTypes.includes(type) ? "#0d9488" : "#d6d3d1"}`,
                background: selectedBusinessTypes.includes(type) ? "#0d9488" : "#fff",
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
        <h3 style={{ fontSize: 16, fontWeight: "bold", marginBottom: 4 }}>3. 今の悩み（複数選択可・最大{MAX_CONCERNS}件）</h3>
        <p style={{ fontSize: 12, color: "#888", marginBottom: 12 }}>
          {concernLabels.length > 0
            ? `${concernLabels.length}件選択中（残り${remainingConcerns}件）`
            : "当てはまるものを選んでください"
          }
        </p>
        {CONCERNS.map(group => (
          <div key={group.category} style={{ marginBottom: 16 }}>
            <div style={{ fontSize: 12, color: "#888", marginBottom: 6, fontWeight: "bold" }}>{group.category}</div>
            {group.items.map(item => {
              const isSelected = concernLabels.includes(item);
              const isDisabled = !isSelected && concernLabels.length >= MAX_CONCERNS;
              return (
                <label
                  key={item}
                  onClick={() => { if (!isDisabled) toggleConcern(item); }}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 10,
                    padding: "8px 12px",
                    border: `2px solid ${isSelected ? "#0d9488" : "#e7e5e4"}`,
                    marginBottom: 6,
                    cursor: isDisabled ? "not-allowed" : "pointer",
                    background: isSelected ? "#f0fdfa" : "#fff",
                    opacity: isDisabled ? 0.5 : 1,
                    transition: "all 0.15s"
                  }}
                >
                  <span style={{
                    display: "inline-flex",
                    alignItems: "center",
                    justifyContent: "center",
                    width: 20,
                    height: 20,
                    borderRadius: 4,
                    border: `2px solid ${isSelected ? "#0d9488" : "#ccc"}`,
                    background: isSelected ? "#0d9488" : "#fff",
                    color: "#fff",
                    fontSize: 12,
                    flexShrink: 0
                  }}>
                    {isSelected && "✓"}
                  </span>
                  <span style={{ fontSize: 14 }}>{item}</span>
                </label>
              );
            })}
          </div>
        ))}
        {concernLabels.includes("その他（自由記述）") && (
          <textarea
            value={concernOther}
            onChange={e => setConcernOther(e.target.value)}
            placeholder="自由にご記入ください"
            rows={3}
            style={{ width: "100%", padding: 10, border: "1px solid #ddd", borderRadius: 8, fontSize: 14 }}
          />
        )}
      </section>

      <div style={{ marginTop: 8, display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
        <button
          onClick={handleSubmit}
          disabled={isSubmitting}
          style={{
            width: "100%",
            padding: "14px",
            background: isSubmitting ? "#a8a29e" : "#0d9488",
            color: "#fff",
            border: "none",
            borderRadius: 8,
            fontSize: 16,
            fontWeight: "bold",
            cursor: isSubmitting ? "not-allowed" : "pointer"
          }}
        >
          {isSubmitting ? "登録中..." : "プロフィール登録する"}
        </button>
        <button
          onClick={handleSubmit}
          disabled={isSubmitting}
          style={{
            background: "none",
            border: "none",
            color: "#9ca3af",
            fontSize: 13,
            cursor: isSubmitting ? "not-allowed" : "pointer",
            textDecoration: "underline",
            padding: "4px 0"
          }}
        >
          スキップする
        </button>
      </div>
    </div>
  );
};

export default ParticipationForm;
