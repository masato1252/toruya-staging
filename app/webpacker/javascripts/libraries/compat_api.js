import axios from "axios";

const COMPAT_API_PREFIX = "/v1/compat";

const EXCLUDED_PATH_PREFIXES = ["/stripe_", "/api/images", "/admin/compat_read"];

const COMPAT_PATH_PREFIXES = [
  "/lines/",
  "/surveys/",
  "/customer_verification/",
  "/booking/",
  "/booking_pages/",
  "/sale_pages/",
  "/admin/",
];

let compatAxiosConfigured = false;
let compatFetchInstalled = false;

function readCompatApiOrigin() {
  const meta = document.querySelector('meta[name="compat-api-origin"]');
  if (!meta || !meta.content) return null;
  return meta.content.replace(/\/$/, "");
}

function readCompatApiReadEnabled() {
  const meta = document.querySelector('meta[name="compat-api-read-enabled"]');
  return meta?.content === "true";
}

export { readCompatApiReadEnabled };

function readCompatApiContext() {
  const context = {};
  const socialServiceUserId = document.querySelector(
    'meta[name="compat-api-social-service-user-id"]'
  )?.content;
  const businessOwnerId = document.querySelector(
    'meta[name="compat-api-business-owner-id"]'
  )?.content;
  const currentUserId = document.querySelector(
    'meta[name="compat-api-current-user-id"]'
  )?.content;

  if (socialServiceUserId) context.social_service_user_id = socialServiceUserId;
  if (businessOwnerId) context.business_owner_id = businessOwnerId;
  if (currentUserId) context.current_user_id = currentUserId;

  return context;
}

function appendCompatContextToUrl(url) {
  const context = readCompatApiContext();
  if (!Object.keys(context).length || typeof url !== "string") return url;

  try {
    const parsed = new URL(url, window.location.origin);
    Object.entries(context).forEach(([key, value]) => {
      if (!parsed.searchParams.has(key)) {
        parsed.searchParams.set(key, value);
      }
    });
    return parsed.toString();
  } catch (_error) {
    return url;
  }
}

function isExcludedPath(pathname) {
  return EXCLUDED_PATH_PREFIXES.some((prefix) => pathname.startsWith(prefix));
}

function isCompatCandidatePath(pathname) {
  if (COMPAT_PATH_PREFIXES.some((prefix) => pathname.startsWith(prefix))) return true;
  if (pathname.startsWith("/online_services/")) return true;
  return false;
}

export function compatApiPath(relativePath) {
  const path = relativePath.startsWith("/") ? relativePath : `/${relativePath}`;
  if (path === COMPAT_API_PREFIX || path.startsWith(`${COMPAT_API_PREFIX}/`)) {
    return path;
  }
  return `${COMPAT_API_PREFIX}${path}`;
}

function extractPathname(url) {
  if (typeof url !== "string") return null;

  if (url.startsWith("http://") || url.startsWith("https://")) {
    try {
      const parsed = new URL(url);
      if (parsed.origin !== window.location.origin) return null;
      return parsed.pathname;
    } catch (_error) {
      return null;
    }
  }

  if (url.startsWith("/")) {
    const cutIndex = url.search(/[?#]/);
    return cutIndex === -1 ? url : url.slice(0, cutIndex);
  }

  return null;
}

function extractSuffix(url) {
  if (typeof url !== "string" || !url.startsWith("/")) return "";
  const cutIndex = url.search(/[?#]/);
  return cutIndex === -1 ? "" : url.slice(cutIndex);
}

function getRequestHeaders(input, init) {
  const headers = new Headers();

  if (input instanceof Request) {
    input.headers.forEach((value, key) => headers.set(key, value));
  }

  if (init && init.headers) {
    new Headers(init.headers).forEach((value, key) => headers.set(key, value));
  }

  return headers;
}

function getRequestMethod(input, init) {
  if (init && init.method) return init.method.toUpperCase();
  if (input instanceof Request) return input.method.toUpperCase();
  return "GET";
}

export function shouldRewriteCompatRequest(url, input, init) {
  if (!readCompatApiOrigin()) return false;

  const pathname = extractPathname(url);
  if (!pathname || isExcludedPath(pathname)) return false;
  if (!isCompatCandidatePath(pathname)) return false;

  // Paid LINE notice approval stays on Rails for its Stripe/3DS flow. Rails
  // proxies a migrated owner's free-trial approval to v1 server-side.
  if (/\/line_notice_requests\/\d+\/approve\/?$/.test(pathname)) return false;
  // Admin mutations not yet on v1 — keep Rails until write cutover.
  if (/\/admin\/business_applications\/\d+\/(approve|reject|mark_paid)\/?$/.test(pathname)) return false;
  if (/\/admin\/chats(\/|$)/.test(pathname) && getRequestMethod(input, init) !== "GET") return false;
  if (/\/admin\/custom_messages(\/|$)/.test(pathname) && getRequestMethod(input, init) !== "GET") return false;
  if (/\/admin\/docs(\/|$)/.test(pathname) && getRequestMethod(input, init) !== "GET") return false;

  const headers = getRequestHeaders(input, init);
  const accept = (headers.get("Accept") || "").toLowerCase();
  const contentType = (headers.get("Content-Type") || "").toLowerCase();
  const method = getRequestMethod(input, init);

  if (pathname.includes(".json")) return true;
  if (accept.includes("application/json")) return true;
  if (contentType.includes("application/json")) return true;
  if (method !== "GET" && method !== "HEAD") return true;

  if (method === "GET" && readCompatApiReadEnabled() && accept.includes("application/json")) {
    return true;
  }

  if (method === "GET" && headers.get("X-Requested-With") === "XMLHttpRequest") {
    if (!accept.includes("application/json") && !pathname.includes(".json")) {
      return false;
    }
  }

  if (method === "GET" && !accept.includes("text/html")) return true;

  return false;
}

function rewriteBookingPagesPath(pathname) {
  const match = pathname.match(/^\/booking_pages\/([^/]+)(\/.*)?$/);
  if (!match) return pathname;
  const slug = match[1];
  const rest = match[2] ?? "";
  if (rest === "/calendar.json") return `/booking/${slug}/calendar.json`;
  if (rest === "/booking_times") return `/booking/${slug}/booking_times`;
  if (rest === "/booking_reservation") return `/booking/${slug}/booking_reservation`;
  return `/booking/${slug}${rest}`;
}

export function rewriteCompatUrl(url, input, init) {
  const origin = readCompatApiOrigin();
  if (!origin || typeof url !== "string") return url;
  if (!shouldRewriteCompatRequest(url, input, init)) return url;

  let pathname = extractPathname(url);
  if (!pathname) return url;

  if (pathname.startsWith("/booking_pages/")) {
    pathname = rewriteBookingPagesPath(pathname);
  }

  // Admin authorization is evaluated from the Devise session in Rails. Keep
  // browser admin reads same-origin so Rails can sign the v1 request; never
  // expose a user id or proxy secret to the client.
  if (pathname.startsWith("/admin/") && getRequestMethod(input, init) === "GET") {
    return `/admin/compat_read?path=${encodeURIComponent(`${pathname}${extractSuffix(url)}`)}`;
  }

  const compatPath = compatApiPath(pathname);
  const suffix = extractSuffix(url);

  if (url.startsWith("http://") || url.startsWith("https://")) {
    try {
      const parsed = new URL(url);
      return appendCompatContextToUrl(`${origin}${compatPath}${parsed.search}${parsed.hash}`);
    } catch (_error) {
      return url;
    }
  }

  return appendCompatContextToUrl(`${origin}${compatPath}${suffix}`);
}

function withCredentialsInit(init) {
  if (!readCompatApiOrigin()) return init;
  return { credentials: "include", ...init };
}

const nativeFetch = window.fetch.bind(window);

export function installCompatFetch() {
  if (compatFetchInstalled) return;
  compatFetchInstalled = true;

  window.fetch = (input, init) => {
    if (typeof input === "string") {
      const rewritten = rewriteCompatUrl(input, input, init);
      return nativeFetch(rewritten, withCredentialsInit(init));
    }

    if (input instanceof Request) {
      const rewritten = rewriteCompatUrl(input.url, input, init);
      if (rewritten === input.url) return nativeFetch(input, init);

      const request = new Request(rewritten, input);
      return nativeFetch(request, withCredentialsInit(init));
    }

    return nativeFetch(input, init);
  };
}

export function configureCompatAxios() {
  if (compatAxiosConfigured) return;
  compatAxiosConfigured = true;

  axios.defaults.withCredentials = true;
  axios.interceptors.request.use((config) => {
    if (config.url) {
      config.url = rewriteCompatUrl(config.url, config.url, config);
    }
    return config;
  });
}

export function installCompatApi() {
  configureCompatAxios();
  installCompatFetch();
}

export async function compatRead(path) {
  const url = rewriteCompatUrl(path, path, {
    method: "GET",
    headers: { Accept: "application/json" },
  });
  const response = await fetch(url, {
    method: "GET",
    headers: { Accept: "application/json" },
    credentials: "include",
  });
  if (!response.ok) {
    throw new Error(`compatRead failed: ${response.status}`);
  }
  return response.json();
}
