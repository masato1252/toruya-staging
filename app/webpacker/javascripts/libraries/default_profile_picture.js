// 外部プレースホルダー(via.placeholder.com 等)に依存しないデフォルトアバター
export const DEFAULT_PROFILE_PICTURE_URL =
  "data:image/svg+xml," +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60"><rect fill="#d6d3d1" width="60" height="60"/><circle cx="30" cy="24" r="10" fill="#a8a29e"/><ellipse cx="30" cy="48" rx="16" ry="10" fill="#a8a29e"/></svg>'
  );

export const resolveProfilePictureUrl = (url) => {
  if (!url || url.includes("via.placeholder.com")) return DEFAULT_PROFILE_PICTURE_URL;
  return url;
};
